using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectController : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
      Vector3 angles = GetComponent<Transform>().eulerAngles;
      angles.y += 20f * Time.deltaTime;
      GetComponent<Transform>().eulerAngles = angles;

      if (Input.GetButton("Escape")) {
        Application.Quit();
      }
    }
}
