using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CaptureScreenshot : MonoBehaviour
{
    [SerializeField]
    private int superSizeValue;

    [SerializeField]
    private string screenshotName = "screenshot";

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.S))
        {
            ScreenCapture.CaptureScreenshot(screenshotName + ".png", superSizeValue);
            Debug.Log("Screenshot " + screenshotName + " taken");
        }
    }
}
