Shader "Custom/WorleyTexVar4-2-Tiles-With-Moss"
{
    Properties
    {
        _MainTex ("Color LUT", 2D) = "white" {}
        _MossTex("Moss Color LUT", 2D) = "white" {}
        _WorleyScale("Worley Scale", Float) = 10.0
        _MossGrowthIntensity("Moss Growth Intensity", Range(0.0, 0.5)) = 0.18
        _TileNoiseIntensity("Tile Noise Intensity", Range(0.0, 0.6)) = 0.25
        _GrooveWidth("Tile Groove Width", Range(0.0, 0.15)) = 0.05
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _MainTex;
        sampler2D _MossTex;
        float _WorleyScale;
        float _TileNoiseIntensity;
        float _MossGrowthIntensity;
        float _GrooveWidth;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        //struct holds the distances of the four nearest feature points
        struct WorleyNoiseData
        {
            float f1;
            float f1_id;
            float f2;
            float f3;
            float f4;
        };

        //returns: float value between 0 and 1
        float2 randomNumGenerator(float2 gridPosition)
        {
           /*Random number generation described by Patricio Gonzalez Vivo and Jen Lowe in The Book of Shaders
           fraction of sin function produces a result that appears pseudorandom
           this result is a float value between 0 and 1*/
           return frac(sin(float2(dot(gridPosition, float2(127.1, 311.7)), dot(gridPosition, float2(269.5, 183.3)))) * 43758.5453);
        }

        WorleyNoiseData worley(float2 uv)
        {
            WorleyNoiseData noiseData;

            //dividing surface into grid
            float2 gridPos = floor(uv);
            //getting remainder or position within the specific tile within the grid
            float2 gridPosRem = frac(uv);

            //initializing final distances between pixel position and feature points
            noiseData.f1 = 1000.0;
            noiseData.f2 = 1000.0;
            noiseData.f3 = 1000.0;
            noiseData.f4 = 1000.0;

            /*iterate through neighborhood of current grid position where the
            point exists. Checking if feature points in neighboring tiles are closer to the pixel position
            to prevent discontinuity*/
            for (int i = -1; i <= 1; i++)
            {
                for (int k = -1; k <= 1; k++)
                {
                    //current neighbor position
                    float2 neighbor = float2(i, k);

                    //position of current feature point
                    float2 curPoint = randomNumGenerator(gridPos + neighbor);

                    //euclidian distance from position of pixel to feature point
                    float dist = length(neighbor + curPoint - gridPosRem);
                    
                    //checking if distance to feature point is closer than any of the currently stored distances
                    if (dist < noiseData.f1)
                    {
                        noiseData.f4 = noiseData.f3;
                        noiseData.f3 = noiseData.f2;
                        noiseData.f2 = noiseData.f1;
                        noiseData.f1 = dist;
                        noiseData.f1_id = curPoint;
                    }
                    else if (dist < noiseData.f2)
                    {
                        noiseData.f4 = noiseData.f3;
                        noiseData.f3 = noiseData.f2;
                        noiseData.f2 = dist;
                    }
                    else if (dist < noiseData.f3)
                    {
                        noiseData.f4 = noiseData.f3;
                        noiseData.f3 = dist;
                    }
                    else if (dist < noiseData.f4)
                    {
                        noiseData.f4 = dist;
                    }
                }
            }

            return noiseData;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //scale the UV depending on how many sites we want for the Worley noise
            float2 scaledUV = IN.uv_MainTex * _WorleyScale;

            //generating the Worley noise data
            WorleyNoiseData noiseData = worley(scaledUV);

            //combination of distances
            float distanceComb = noiseData.f1_id;
            float distanceComb2 = noiseData.f2 - noiseData.f1;

            //BEGIN - CREATING TILES
            //float that holds fractal noise to be used on tiles themselves
            float fractalValue;

            //computing different fractal version
            for (int i = 0; i < 5; i++)
            {
                WorleyNoiseData noiseData = worley(pow(2, i) * IN.uv_MainTex * _WorleyScale);

                //summing noise at different scales
                fractalValue += pow(2, -i) * noiseData.f1;
            }

            fractalValue = smoothstep(0.0, 1.5, fractalValue);

            //reducing range to reduce intensity of effect
            float fractalValueTile = lerp(1-_TileNoiseIntensity, 1.0, fractalValue);

            //position of color in LUT
            float lutColorTile = smoothstep(0.0, 2.0, (1 - distanceComb) + fractalValueTile);

            //checking if it should be tile or edges between tile and determining the final LUT color that way

            if(distanceComb2 <= _GrooveWidth)
                lutColorTile = 0.0;
            //END - CREATING TILES
            
            //BEGIN - CREATING MOSS
            float lutColorMoss = smoothstep(0.0, 2.0, noiseData.f1 + fractalValue);

            lutColorMoss = lutColorMoss;
            //END - CREATING MOSS

            float2 uv = float2(lutColorMoss, 0.5);

            uv.x = clamp(uv.x, 0.01, 0.99);

            fixed4 finalColor = tex2D(_MossTex, uv);

            //adding Moss on top of tile
            //this check is kind of like step function to see when to transition to tile instead of moss
            if (uv.x <= (1-_MossGrowthIntensity))
            {
                uv = float2(lutColorTile, 0.5);

                uv.x = clamp(uv.x, 0.01, 0.99);

                finalColor = tex2D(_MainTex, uv);
            }

            fixed4 c = finalColor;

            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
