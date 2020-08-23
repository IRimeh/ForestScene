using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEditor;
using UnityEngine;
using Utility;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class ObjectPlacer : MonoBehaviour
{
    [SerializeField]
    private Material _material;

    private GameObject _placementSpherePrefab;
    private GameObject _placementSphere;
    private GameObject _deletionSpherePrefab;
    private GameObject _deletionSphere;

    private Camera _camera;

    private float _placementStatus = 0;
    private bool _button1PressedLastFrame = false;

    private Material _objectPlacerMaterial;
    private Vector3 _mousePos;
    private float _shouldShowRadius = 0;
    private Color _radiusColor = new Color(0,0,0.2f,0);

    //Global variables
    public enum PlacementTechnique
    {
        Proximity,
        Frequency
    };
    private PlacementTechnique _placementTechnique = PlacementTechnique.Proximity;
    private LayerMask _layerMask;
    private float _radius;
    private GameObject _parentObject;
    private int _density = 1;
    private int _frequency = 60;
    private float _minXRotation = 0;
    private float _maxXRotation = 0;
    private float _minYRotation = 0;
    private float _maxYRotation = 360;
    private float _minZRotation = 0;
    private float _maxZRotation = 0;
    private float _minXScale = 1;
    private float _maxXScale = 1;
    private float _minYScale = 1;
    private float _maxYScale = 1;
    private float _minZScale = 1;
    private float _maxZScale = 1;

    //Placement variables
    private List<GameObject> _prefabsToPlace;

    //Deletion variables

    // Start is called before the first frame update
    void OnEnable()
    {
        //Start update loop
        EditorApplication.update -= SimpleUpdate;
        EditorApplication.update += SimpleUpdate;
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
        _objectPlacerMaterial = (Material)Resources.Load("ObjectPlacerMaterial", typeof(Material));
    }

    private void Init()
    {
        GameObject[] gameObjects = (GameObject[])GameObject.FindObjectsOfType(typeof(GameObject));
        for (int i = 0; i < gameObjects.Length; i++)
        {
            if (gameObjects[i].name.Contains("PlacementSphere") || gameObjects[i].name.Contains("DeletionSphere"))
            {
                DestroyImmediate(gameObjects[i]);
            }
        }

        //onInit();
    }

    public void SimpleUpdate()
    {
        _camera = UnityEditor.SceneView.lastActiveSceneView.camera;

        _shouldShowRadius = 0;

        Placement();
        Deletion();

        _objectPlacerMaterial.SetVector("_MousePos", _mousePos);
        _objectPlacerMaterial.SetFloat("_Radius", _radius * 0.5f);
        _objectPlacerMaterial.SetFloat("_ShowRadius", _shouldShowRadius);
        _objectPlacerMaterial.SetColor("_Color", _radiusColor);
    }

    private void Placement()
    {
        if (MouseHelper.Button1Pressed)
        {
            RaycastHit hit;
            Ray ray = _camera.ScreenPointToRay(new Vector2(MouseHelper.Position.x, _camera.pixelHeight - MouseHelper.Position.y));
            if (Physics.Raycast(ray, out hit, Mathf.Infinity, _layerMask))
            {
                _mousePos = hit.point;
                _shouldShowRadius = 1;
                _radiusColor = new Color(0, 0, 0.75f, 0);
            }

            if (!_button1PressedLastFrame)
            {
                for (int i = 0; i < _density; i++)
                {
                    PlaceObject(hit);
                }
            }
            else
            {
                _placementStatus += (float)_frequency / 60.0f;
                if (_placementStatus >= 1.0f)
                {
                    for (int i = 0; i < _density; i++)
                    {
                        PlaceObject(hit);
                    }
                    _placementStatus -= 1.0f;
                }
            }
            _button1PressedLastFrame = true;
        }
        else
        {
            _button1PressedLastFrame = false;
        }
    }

    private void Deletion()
    {
        if (MouseHelper.Button2Pressed)
        {
            RaycastHit hit;
            Ray ray = _camera.ScreenPointToRay(new Vector2(MouseHelper.Position.x, _camera.pixelHeight - MouseHelper.Position.y));
            if (Physics.Raycast(ray, out hit, Mathf.Infinity, _layerMask))
            {
                _mousePos = hit.point;
                _shouldShowRadius = 1;
                _radiusColor = new Color(0.75f, 0, 0, 1);
            }

            DeleteObjects(hit);
        }
    }

    private void PlaceObject(RaycastHit hit)
    {
        if(_prefabsToPlace != null && _prefabsToPlace.Count >= 1)
        {
            int index = UnityEngine.Random.Range(0, _prefabsToPlace.Count);
            Vector2 randomCircle = UnityEngine.Random.insideUnitCircle * (_radius / 2);
            Vector3 pos = hit.point;
            GameObject temp = new GameObject();
            temp.transform.rotation = Quaternion.FromToRotation(Vector3.up, hit.normal);

            pos += temp.transform.right * randomCircle.x;
            pos += temp.transform.forward * randomCircle.y;
            pos += temp.transform.up * _radius / 2;

            RaycastHit hit2;
            if(Physics.Raycast(pos, -hit.normal, out hit2, _radius, _layerMask))
            {
                GameObject obj;
                Quaternion rot = Quaternion.FromToRotation(Vector3.up, hit2.normal);
                temp.transform.rotation = rot;
                temp.transform.Rotate(Vector3.forward, UnityEngine.Random.Range(_minXRotation, _maxXRotation));
                temp.transform.Rotate(Vector3.up, UnityEngine.Random.Range(_minYRotation, _maxYRotation));
                temp.transform.Rotate(Vector3.right, UnityEngine.Random.Range(_minZRotation, _maxZRotation));
                rot = temp.transform.rotation;

                if (_parentObject != null)
                    obj = Instantiate(_prefabsToPlace[index], hit2.point, rot, _parentObject.transform);
                else
                    obj = Instantiate(_prefabsToPlace[index], hit2.point, rot);

                if(_parentObject != null)
                    obj.transform.localScale = new Vector3(UnityEngine.Random.Range(_minXScale, _maxXScale) / _parentObject.transform.lossyScale.x, UnityEngine.Random.Range(_minYScale, _maxYScale) / _parentObject.transform.lossyScale.y, UnityEngine.Random.Range(_minZScale, _maxZScale) / _parentObject.transform.lossyScale.z);
            }

            DestroyImmediate(temp);
        }
    }

    private void DeleteObjects(RaycastHit hit)
    {
        if (_parentObject != null)
        {
            for (int i = 0; i < _parentObject.transform.childCount; i++)
            {
                if (Vector3.Distance(_parentObject.transform.GetChild(i).position, hit.point) <= _radius / 2)
                {
                    DestroyImmediate(_parentObject.transform.GetChild(i).gameObject);
                }
            }
        }
        else
        {
            GameObject[] gameObjects = (GameObject[])GameObject.FindObjectsOfType(typeof(GameObject));
            for (int i = 0; i < gameObjects.Length; i++)
            {
                if (gameObjects[i] != _placementSphere && gameObjects[i] != _deletionSphere)
                {
                    if (Vector3.Distance(gameObjects[i].transform.position, hit.point) <= _radius / 2)
                    {
                        DestroyImmediate(gameObjects[i]);
                    }
                }
            }
        }
    }

    private void OnDestroy()
    {
        EditorApplication.update -= SimpleUpdate;
    }

    public void SetScale(float scale)
    {
        _radius = scale;
    }

    public void SetLayerMask(LayerMask layerMask)
    {
        _layerMask = layerMask;
    }

    public void SetPrefabsToPlace(List<GameObject> prefabsToPlace)
    {
        _prefabsToPlace = prefabsToPlace;
    }

    public void SetParentObject(GameObject parentObj)
    {
        _parentObject = parentObj;
    }

    public void SetRandomRotations(float minXRotation, float maxXRotation, float minYRotation, float maxYRotation, float minZRotation, float maxZRotation)
    {
        _minXRotation = minXRotation;
        _maxXRotation = maxXRotation;
        _minYRotation = minYRotation;
        _maxYRotation = maxYRotation;
        _minZRotation = minZRotation;
        _maxZRotation = maxZRotation;
    }

    public void SetRandomScales(float minXScale, float maxXScale, float minYScale, float maxYScale, float minZScale, float maxZScale)
    {
        _minXScale = minXScale;
        _maxXScale = maxXScale;
        _minYScale = minYScale;
        _maxYScale = maxYScale;
        _minZScale = minZScale;
        _maxZScale = maxZScale;
    }

    public void SetDensity(int density)
    {
        _density = density;
    }

    public void SetFrequency(int frequency)
    {
        _frequency = frequency;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(_objectPlacerMaterial != null)
            RaycastCornerBlit(source, destination, _objectPlacerMaterial);
    }

    void RaycastCornerBlit(RenderTexture source, RenderTexture dest, Material mat)
    {
        // Compute Frustum Corners
        float camFar = _camera.farClipPlane;
        float camFov = _camera.fieldOfView;
        float camAspect = _camera.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = _camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = _camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (_camera.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (_camera.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (_camera.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (_camera.transform.forward - toRight - toTop);
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
}
