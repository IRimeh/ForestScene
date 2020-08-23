using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public static class InputControls
{

    public static KeyCode KeyCodeField(Rect controlRect, KeyCode keyCode)
    {
        int controlID = GUIUtility.GetControlID(FocusType.Keyboard);

        KeyCode retVal = keyCode;

        Event evt = Event.current;

        switch (evt.GetTypeForControl(controlID))
        {
            case EventType.Repaint:
                {
                    GUIStyle style = GUI.skin.GetStyle("TextField");
                    if (style == GUIStyle.none)
                        break;
                    style.Draw(controlRect, new GUIContent(keyCode.ToString()), controlID);
                    break;
                }
            case EventType.MouseDown:
                {
                    if (controlRect.Contains(Event.current.mousePosition) && Event.current.button == 0 && GUIUtility.hotControl == 0)
                    {
                        GUIUtility.hotControl = controlID;
                        GUIUtility.keyboardControl = controlID;
                        evt.Use();
                    }
                    break;
                }
            case EventType.MouseUp:
                {
                    if (GUIUtility.hotControl == controlID)
                    {
                        GUIUtility.hotControl = 0;
                        evt.Use();
                    }
                    break;

                }
            case EventType.KeyDown:
                {
                    if (GUIUtility.keyboardControl == controlID)
                    {
                        retVal = Event.current.keyCode;
                        GUIUtility.hotControl = 0;
                        GUIUtility.keyboardControl = 0;
                        evt.Use();
                    }
                    break;
                }
            case EventType.KeyUp:
                {

                    break;
                }
        }
        return retVal;
    }

    public static KeyCode KeyCodeFieldLayout(KeyCode keyCode)
    {
        return KeyCodeField(EditorGUILayout.GetControlRect(), keyCode);
    }

    public static LayerMask LayerMaskField(string label, LayerMask layerMask)
    {
        List<string> layers = new List<string>();
        List<int> layerNumbers = new List<int>();

        for (int i = 0; i < 32; i++)
        {
            string layerName = LayerMask.LayerToName(i);
            if (layerName != "")
            {
                layers.Add(layerName);
                layerNumbers.Add(i);
            }
        }
        int maskWithoutEmpty = 0;
        for (int i = 0; i < layerNumbers.Count; i++)
        {
            if (((1 << layerNumbers[i]) & layerMask.value) > 0)
                maskWithoutEmpty |= (1 << i);
        }
        maskWithoutEmpty = EditorGUILayout.MaskField(label, maskWithoutEmpty, layers.ToArray());
        int mask = 0;
        for (int i = 0; i < layerNumbers.Count; i++)
        {
            if ((maskWithoutEmpty & (1 << i)) > 0)
                mask |= (1 << layerNumbers[i]);
        }
        layerMask.value = mask;
        return layerMask;
    }
}