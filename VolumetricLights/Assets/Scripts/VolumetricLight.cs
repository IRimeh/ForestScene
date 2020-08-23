using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class VolumetricLight : MonoBehaviour
{
    public Light light;
    public Camera depthCamera = null;
    public RenderTexture renderTex = null;
    private RenderDepthTexture depthScript = null;
    private GameObject camObj = null;
    [Range(0.0f, 10.0f)]
    public float volumetricLightMultiplier = 1.0f;

    private int lightIndex = 0;


    private void Start()
    {
        lightIndex = VolumetricLightManager.Instance.AddVolumetricLight(this);
    }

    // Start is called before the first frame update
    private void OnEnable()
    {
        light = GetComponent<Light>();

        CreateCamera();

        lightIndex = VolumetricLightManager.Instance.AddVolumetricLight(this);
    }

    private void OnDisable()
    {
        VolumetricLightManager.Instance.RemoveVolumetricLight(this);
    }

    // Update is called once per frame
    private void Update()
    {
        UpdateValues();

        if (depthCamera == null || renderTex == null)
            CreateCamera();
        else
            UpdateCamera();
        depthCamera.targetTexture = renderTex;
    }

    private void CreateCamera()
    {
        CreateTextures();

        //Check if obj already exists
        foreach (Transform child in transform)
        {
            if (child.name == "DepthCamera")
            {
                camObj = child.gameObject;
                break;
            }
        }

        //Create obj
        if (camObj == null)
        {
            camObj = new GameObject("DepthCamera");
            camObj.transform.SetParent(transform);
        }

        //Add camera component
        depthCamera = camObj.GetComponent<Camera>();
        if (depthCamera == null)
            depthCamera = camObj.AddComponent<Camera>();

        //Add depth script
        depthScript = camObj.GetComponent<RenderDepthTexture>();
        if(depthScript == null)
            depthScript = camObj.AddComponent<RenderDepthTexture>();

        //Set values
        camObj.transform.position = transform.position;
        camObj.transform.rotation = transform.rotation;
        depthCamera.targetTexture = renderTex;
        depthCamera.fieldOfView = light.spotAngle;
        depthCamera.farClipPlane = Mathf.Floor(light.range);
        depthCamera.nearClipPlane = 0.01f;
        depthCamera.depthTextureMode = DepthTextureMode.Depth;
        depthCamera.clearFlags = CameraClearFlags.SolidColor;
        depthCamera.depth = 10;
    }

    private void UpdateCamera()
    {
        camObj.transform.position = transform.position;
        camObj.transform.rotation = transform.rotation;
        depthCamera.fieldOfView = light.spotAngle;
        depthCamera.farClipPlane = Mathf.Floor(light.range);
    }

    private void CreateTextures()
    {
        if (renderTex != null)
        {
            renderTex.Release();
        }

        if (renderTex == null)
        {
            renderTex = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGB32);
            renderTex.volumeDepth = 8;
            renderTex.useMipMap = false;
            renderTex.autoGenerateMips = false;
            renderTex.enableRandomWrite = true;
            renderTex.wrapMode = TextureWrapMode.Repeat;
        }
    }

    private void UpdateValues()
    {
        VolumetricLightManager.Instance._lightPositions[lightIndex] = transform.position;
        VolumetricLightManager.Instance._lightDirections[lightIndex] = transform.forward;
        VolumetricLightManager.Instance._lightUpDirections[lightIndex] = transform.up;
        VolumetricLightManager.Instance._lightEndPositions[lightIndex] = transform.forward * light.range;
        VolumetricLightManager.Instance._lightRanges[lightIndex] = light.range;
        float opposite = Mathf.Tan(light.spotAngle * 0.5f * Mathf.Deg2Rad) * light.range;
        VolumetricLightManager.Instance._lightRadius[lightIndex] = opposite;
        VolumetricLightManager.Instance._lightColors[lightIndex] = light.color;
        VolumetricLightManager.Instance._lightIntensities[lightIndex] = light.intensity * volumetricLightMultiplier;
    }
}
