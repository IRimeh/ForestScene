using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "PlacementSettings", menuName = "ScriptableObjects/PlacementSettings", order = 1)]
public class SettingsScriptableObject : ScriptableObject
{
    //Keybinds
    public KeyCode button1 = KeyCode.G;
    public KeyCode button2 = KeyCode.H;

    //Global variables
    public GameObject parentObject;
    public float radius = 1;
    public LayerMask layerMask = 307;

    //Placement
    public List<GameObject> prefabsToPlace = new List<GameObject>();
    public int density = 1;
    public int frequency = 60;
    public float minXRotation = 0;
    public float maxXRotation = 0;
    public float minYRotation = 0;
    public float maxYRotation = 360;
    public float minZRotation = 0;
    public float maxZRotation = 0;
    public float minXScale = 1;
    public float maxXScale = 1;
    public float minYScale = 1;
    public float maxYScale = 1;
    public float minZScale = 1;
    public float maxZScale = 1;
}
