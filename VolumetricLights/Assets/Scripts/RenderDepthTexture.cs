using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class RenderDepthTexture : MonoBehaviour
{
    [SerializeField]
    private Material material = null;
    private Camera camera = null;

    private void OnEnable()
    {
        camera = GetComponent<Camera>();
        if (camera)
            camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null)
            Graphics.Blit(source, destination, material);
    }
}
