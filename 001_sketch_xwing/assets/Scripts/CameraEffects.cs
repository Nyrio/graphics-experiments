﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraEffects : MonoBehaviour
{
  public Material material;

  void Start()
  {
    GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;
  }

  void OnRenderImage (RenderTexture source, RenderTexture destination)
  {
    Graphics.Blit (source, destination, material);
  }
}
