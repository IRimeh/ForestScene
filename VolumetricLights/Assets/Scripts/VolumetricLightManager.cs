using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class VolumetricLightManager : MonoBehaviour
{
    public static VolumetricLightManager Instance;

    [SerializeField]
    private Material material;
    [SerializeField]
    private bool updateVariables;

    private Camera camera;
    private List<VolumetricLight> volumetricLights = new List<VolumetricLight>();


    private int _numLights;
    [HideInInspector]
    public List<Vector4> _lightPositions = new List<Vector4>();
    [HideInInspector]
    public List<Vector4> _lightDirections = new List<Vector4>();
    [HideInInspector]
    public List<Vector4> _lightUpDirections = new List<Vector4>();
    [HideInInspector]
    public List<Vector4> _lightEndPositions = new List<Vector4>();
    [HideInInspector]
    public List<float> _lightRanges = new List<float>();
    [HideInInspector]
    public List<float> _lightRadius = new List<float>();
    [HideInInspector]
    public List<Color> _lightColors = new List<Color>();
    [HideInInspector]
    public List<float> _lightIntensities = new List<float>();
    private List<RenderTexture> _lightDepthTextures = new List<RenderTexture>();
    private Texture2DArray _lightDepthTexArr = null;

    private RenderTexture texArray;

    private void OnEnable()
    {
        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.Depth;
        Instance = this;
        UpdateLightVariables();

        CreateTexArray();
    }

    private void CreateTexArray()
    {
        texArray = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGB32);
        texArray.dimension = UnityEngine.Rendering.TextureDimension.Tex2DArray;

        texArray.volumeDepth = 8;
        texArray.useMipMap = false;
        texArray.autoGenerateMips = false;
        texArray.filterMode = FilterMode.Point;
        texArray.Create();
    }

    private void OnValidate()
    {
        if(updateVariables)
        {
            updateVariables = false;
        }
    }

    private void Update()
    {
        if (_numLights > 0)
        {
            //Create texture array for cookies
            if (volumetricLights.Count > 0)
            {
                for (int i = 0; i < volumetricLights.Count; i++)
                {
                    if (texArray)
                        Graphics.CopyTexture(volumetricLights[i].renderTex, 0, texArray, i);
                    else
                        CreateTexArray();
                }
            }

            material.SetInt("_NumLights", _numLights);
            material.SetVectorArray("_LightPositions", _lightPositions);
            material.SetVectorArray("_LightDirections", _lightDirections);
            material.SetVectorArray("_LightUpDirections", _lightUpDirections);
            material.SetVectorArray("_LightEndPositions", _lightEndPositions);
            material.SetFloatArray("_LightRanges", _lightRanges);
            material.SetFloatArray("_LightRadius", _lightRadius);
            material.SetColorArray("_LightColors", _lightColors);
            material.SetFloatArray("_LightIntensities", _lightIntensities);
            material.SetTexture("_LightDepthTextures", texArray);
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetVector("_CameraPos", Camera.main.transform.position);

        RaycastCornerBlit(source, destination, material);
    }

    void RaycastCornerBlit(RenderTexture source, RenderTexture dest, Material mat)
    {
        // Compute Frustum Corners
        float camFar = camera.farClipPlane;
        float camFov = camera.fieldOfView;
        float camAspect = camera.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (camera.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (camera.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (camera.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (camera.transform.forward - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;

        // Custom Blit, encoding Frustum Corners as additional Texture Coordinates
        RenderTexture.active = dest;

        mat.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        mat.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.MultiTexCoord(1, bottomLeft);
        GL.Vertex3(0.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.MultiTexCoord(1, bottomRight);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.MultiTexCoord(1, topRight);
        GL.Vertex3(1.0f, 1.0f, 0.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.MultiTexCoord(1, topLeft);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    public int AddVolumetricLight(VolumetricLight light)
    {
        int index = 0;

        if (!volumetricLights.Contains(light) && light != null)
        {
            _lightDepthTextures.Add(light.renderTex);
            volumetricLights.Add(light);
            _numLights++;

            if (_lightDepthTexArr != null)
            {
                if (Application.isEditor)
                    DestroyImmediate(_lightDepthTexArr);
                else
                    Destroy(_lightDepthTexArr);
                _lightDepthTexArr = null;
            }

            index = volumetricLights.Count - 1;
        }
        else
            index = volumetricLights.IndexOf(light);

        UpdateLightVariables();
        return index;
    }

    public void RemoveVolumetricLight(VolumetricLight light)
    {
        if (volumetricLights.Contains(light))
        {
            _lightDepthTextures.Remove(light.renderTex);
            volumetricLights.Remove(light);
            _numLights--;
        }

        if (_lightDepthTexArr != null)
        {
            if (Application.isEditor)
                DestroyImmediate(_lightDepthTexArr);
            else
                Destroy(_lightDepthTexArr);
            _lightDepthTexArr = null;
        }

        UpdateLightVariables();
    }

    public void UpdateLightVariables()
    {
        _lightPositions.Clear();
        _lightDirections.Clear();
        _lightUpDirections.Clear();
        _lightEndPositions.Clear();
        _lightRanges.Clear();
        _lightRadius.Clear();
        _lightColors.Clear();
        _lightIntensities.Clear();

        foreach (VolumetricLight light in volumetricLights)
        {
            _lightPositions.Add(light.transform.position);
            _lightDirections.Add(light.transform.forward);
            _lightUpDirections.Add(light.transform.up);
            _lightEndPositions.Add(light.transform.forward * light.light.range);
            _lightRanges.Add(light.light.range);
            float opposite = Mathf.Tan(light.light.spotAngle * 0.5f * Mathf.Deg2Rad) * light.light.range;
            _lightRadius.Add(opposite);
            _lightColors.Add(light.light.color);
            _lightIntensities.Add(light.light.intensity * light.volumetricLightMultiplier);
        }
    }
}
