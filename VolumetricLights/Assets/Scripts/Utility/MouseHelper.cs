using UnityEngine;
using UnityEditor;

namespace Utility
{
    /// <summary>
    /// This is used to find the mouse position when it's over a SceneView.
    /// Used by tools that are menu invoked.
    /// </summary>
    [InitializeOnLoad]
    public class MouseHelper : Editor
    {
        private static Vector2 position;
        private static bool button1Pressed;
        private static bool button2Pressed;

        public static KeyCode button1Code = KeyCode.G;
        public static KeyCode button2Code = KeyCode.H;

        public static Vector2 Position
        {
            get { return position; }
        }

        public static bool Button1Pressed
        {
            get { return button1Pressed; }
        }

        public static bool Button2Pressed
        {
            get { return button2Pressed; }
        }

        static MouseHelper()
        {
            SceneView.duringSceneGui += UpdateView;
        }

        private static void UpdateView(SceneView sceneView)
        {
            if (Event.current != null)
            {
                //Get mouse pos
                position = new Vector2(Event.current.mousePosition.x + sceneView.position.x, Event.current.mousePosition.y);

                //Get lmb pressed
                if (Event.current.type == EventType.KeyDown)
                {
                    if (Event.current.keyCode == button1Code)
                        button1Pressed = true;

                    //Get rmb pressed
                    if (Event.current.keyCode == button2Code)
                        button2Pressed = true;
                }

                if (Event.current.type == EventType.KeyUp)
                {
                    if (Event.current.keyCode == button1Code)
                        button1Pressed = false;

                    //Get rmb pressed
                    if (Event.current.keyCode == button2Code)
                        button2Pressed = false;
                }
            }
        }
    }
}