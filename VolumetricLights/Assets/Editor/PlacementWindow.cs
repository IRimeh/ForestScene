using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using Utility;

public class PlacementWindow : EditorWindow
{
    private bool _hasLoadedSettings = false;

    //Keymapping
    private bool showKeymappingVariables = false;
    private KeyCode button1 = KeyCode.G;
    private KeyCode button2 = KeyCode.H;

    //Global variables
    private bool showGlobalVariables = true;
    private GameObject parentObject;
    private float radius = 1;
    private LayerMask layerMask = 307;

    //Placement
    private bool showPlacementVariables = false;
    private List<GameObject> prefabsToPlace = new List<GameObject>();
    private int density = 1;
    private int frequency = 60;
    private float minXRotation = 0;
    private float maxXRotation = 0;
    private float minYRotation = 0;
    private float maxYRotation = 0;
    private float minZRotation = 0;
    private float maxZRotation = 0;
    private float minXScale = 1;
    private float maxXScale = 1;
    private float minYScale = 1;
    private float maxYScale = 1;
    private float minZScale = 1;
    private float maxZScale = 1;

    //Removing
    private bool showDeletionVariables = false;

    //Statics
    private static ObjectPlacer _objectPlacer;
    private static Vector2 _mousePos;
    private static SettingsScriptableObject _settings;

    // Add menu named "My Window" to the Window menu
    [MenuItem("Window/Placement Window")]
    static void Init()
    {
        // Get existing open window or if none, make a new one:
        PlacementWindow window = (PlacementWindow)EditorWindow.GetWindow(typeof(PlacementWindow));
        window.Show();

        _objectPlacer = UnityEditor.SceneView.lastActiveSceneView.camera.gameObject.AddComponent<ObjectPlacer>();
        _settings = (SettingsScriptableObject)Resources.Load("PlacementSettings", typeof(SettingsScriptableObject));
        window.LoadValues();
    }

    void OnGUI()
    {
        GlobalVariables();
        PlacementVariables();
        RemoveVariables();
        Keymapping();

        ReInitialize();
        SetValues();

        if (!_hasLoadedSettings)
            LoadValues();
    }

    private void GlobalVariables()
    {
        showGlobalVariables = EditorGUILayout.BeginFoldoutHeaderGroup(showGlobalVariables, "Global Variables");

        if (showGlobalVariables)
        {
            parentObject = (GameObject)EditorGUILayout.ObjectField("Parent Object", parentObject, typeof(GameObject), true);
            radius = EditorGUILayout.Slider("Radius", radius, 0.1f, 10.0f);
            layerMask = InputControls.LayerMaskField("Layermask", layerMask);
        }

        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void PlacementVariables()
    {
        //Keymapping
        showPlacementVariables = EditorGUILayout.BeginFoldoutHeaderGroup(showPlacementVariables, "Placement Variables");

        if (showPlacementVariables)
        {
            //Prefabs
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Prefabs to place: " + prefabsToPlace.Count);
            GUILayout.FlexibleSpace();
            GUIStyle btnStyle = EditorStyles.miniButton;
            if (GUILayout.Button("+", btnStyle))
            {
                prefabsToPlace.Add(null);
            }
            if (GUILayout.Button("-", btnStyle) && prefabsToPlace.Count > 0)
            {
                prefabsToPlace.RemoveAt(prefabsToPlace.Count - 1);
            }
            EditorGUILayout.EndHorizontal();
            for (int i = 0; i < prefabsToPlace.Count; i++)
            {
                prefabsToPlace[i] = (GameObject)EditorGUILayout.ObjectField("Prefab " + i, prefabsToPlace[i], typeof(GameObject), false);
            }

            //Frequency
            EditorGUILayout.Separator();
            frequency = EditorGUILayout.IntSlider("Frequency", frequency, 0, 60);

            //Density
            density = EditorGUILayout.IntSlider("Density", density, 1, 10);

            //Randomized rotation
            EditorGUILayout.Separator();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Random rotation:");
            if (GUILayout.Button("Reset"))
            {
                minXRotation = 0;
                maxXRotation = 0;
                minYRotation = 0;
                maxYRotation = 0;
                minZRotation = 0;
                maxZRotation = 0;
            }
            EditorGUILayout.EndHorizontal();
            //X
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("X:");
            minXRotation = EditorGUILayout.FloatField(minXRotation);
            EditorGUILayout.MinMaxSlider(ref minXRotation, ref maxXRotation, 0, 360);
            maxXRotation = EditorGUILayout.FloatField(maxXRotation);
            EditorGUILayout.EndHorizontal();
            //Y
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("Y:");
            minYRotation = EditorGUILayout.FloatField(minYRotation);
            EditorGUILayout.MinMaxSlider(ref minYRotation, ref maxYRotation, 0, 360);
            maxYRotation = EditorGUILayout.FloatField(maxYRotation);
            EditorGUILayout.EndHorizontal();
            //Z
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("Z:");
            minZRotation = EditorGUILayout.FloatField(minZRotation);
            EditorGUILayout.MinMaxSlider(ref minZRotation, ref maxZRotation, 0, 360);
            maxZRotation = EditorGUILayout.FloatField(maxZRotation);
            EditorGUILayout.EndHorizontal();

            //Randomized scale
            EditorGUILayout.Separator();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Random scale:");
            if (GUILayout.Button("Reset"))
            {
                minXScale = 1;
                maxXScale = 1;
                minYScale = 1;
                maxYScale = 1;
                minZScale = 1;
                maxZScale = 1;
            }
            EditorGUILayout.EndHorizontal();
            //X
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("X:");
            minXScale = EditorGUILayout.FloatField(minXScale);
            EditorGUILayout.MinMaxSlider(ref minXScale, ref maxXScale, 0, 2);
            maxXScale = EditorGUILayout.FloatField(maxXScale);
            EditorGUILayout.EndHorizontal();
            //Y
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("Y:");
            minYScale = EditorGUILayout.FloatField(minYScale);
            EditorGUILayout.MinMaxSlider(ref minYScale, ref maxYScale, 0, 2);
            maxYScale = EditorGUILayout.FloatField(maxYScale);
            EditorGUILayout.EndHorizontal();
            //Z
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("Z:");
            minZScale = EditorGUILayout.FloatField(minZScale);
            EditorGUILayout.MinMaxSlider(ref minZScale, ref maxZScale, 0, 2);
            maxZScale = EditorGUILayout.FloatField(maxZScale);
            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void RemoveVariables()
    {
        showDeletionVariables = EditorGUILayout.BeginFoldoutHeaderGroup(showDeletionVariables, "Deletion Variables");

        if (showDeletionVariables)
        {

        }

        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void Keymapping()
    {
        //Keymapping
        showKeymappingVariables = EditorGUILayout.BeginFoldoutHeaderGroup(showKeymappingVariables, "Keymapping");

        if (showKeymappingVariables)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Placing", EditorStyles.label);
            GUILayout.FlexibleSpace();
            button1 = InputControls.KeyCodeFieldLayout(button1);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Removing", EditorStyles.label);
            GUILayout.FlexibleSpace();
            button2 = InputControls.KeyCodeFieldLayout(button2);
            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.EndFoldoutHeaderGroup();

        MouseHelper.button1Code = button1;
        MouseHelper.button2Code = button2;
    }

    private void ReInitialize()
    {
        if(UnityEditor.SceneView.lastActiveSceneView.camera.gameObject.GetComponent<ObjectPlacer>() == null)
        { 
            _objectPlacer = UnityEditor.SceneView.lastActiveSceneView.camera.gameObject.AddComponent<ObjectPlacer>();
        }
    }

    private void OnDestroy()
    {
        DestroyImmediate(UnityEditor.SceneView.lastActiveSceneView.camera.gameObject.GetComponent<ObjectPlacer>());
    }

    public void SetValues()
    {
        if (_objectPlacer)
        {
            _objectPlacer.SetRandomScales(minXScale, maxXScale, minYScale, maxYScale, minZScale, maxZScale);
            _objectPlacer.SetRandomRotations(minXRotation, maxXRotation, minYRotation, maxYRotation, minZRotation, maxZRotation);
            _objectPlacer.SetPrefabsToPlace(prefabsToPlace);
            _objectPlacer.SetLayerMask(layerMask);
            _objectPlacer.SetScale(radius);
            _objectPlacer.SetParentObject(parentObject);
            _objectPlacer.SetDensity(density);
            _objectPlacer.SetFrequency(frequency);

            SaveValues();
        }
    }

    private void SaveValues()
    {
        if(!_settings)
            _settings = (SettingsScriptableObject)Resources.Load("PlacementSettings", typeof(SettingsScriptableObject));

        //Keymapping
        _settings.button1 = button1;
        _settings.button2 = button2;

        //Global variables
        _settings.parentObject = parentObject;
        _settings.radius = radius;
        _settings.layerMask = layerMask;

        //Placement variables
        _settings.prefabsToPlace = new List<GameObject>(prefabsToPlace);
        _settings.density = density;
        _settings.frequency = frequency;
        _settings.minXRotation = minXRotation;
        _settings.maxXRotation = maxXRotation;
        _settings.minYRotation = minYRotation;
        _settings.maxYRotation = maxYRotation;
        _settings.minZRotation = minZRotation;
        _settings.maxZRotation = maxZRotation;
        _settings.minXScale = minXScale;
        _settings.maxXScale = maxXScale;
        _settings.minYScale = minYScale;
        _settings.maxYScale = maxYScale;
        _settings.minZScale = minZScale;
        _settings.maxZScale = maxZScale;
    }

    public void LoadValues()
    {
        //Keymapping
        button1 = _settings.button1;
        button2 = _settings.button2;

        //Global variables
        parentObject = _settings.parentObject;
        radius = _settings.radius;
        layerMask = _settings.layerMask;

        //Placement variables
        prefabsToPlace = new List<GameObject>(_settings.prefabsToPlace);
        density = _settings.density;
        frequency = _settings.frequency;
        minXRotation = _settings.minXRotation;
        maxXRotation = _settings.maxXRotation;
        minYRotation = _settings.minYRotation;
        maxYRotation = _settings.maxYRotation;
        minZRotation = _settings.minZRotation;
        maxZRotation = _settings.maxZRotation;
        minXScale = _settings.minXScale;
        maxXScale = _settings.maxXScale;
        minYScale = _settings.minYScale;
        maxYScale = _settings.maxYScale;
        minZScale = _settings.minZScale;
        maxZScale = _settings.maxZScale;

        _hasLoadedSettings = true;
    }
}
