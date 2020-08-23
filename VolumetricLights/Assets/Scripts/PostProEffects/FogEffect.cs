using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(FogEffectRenderer), PostProcessEvent.AfterStack, "Custom/FogEffect")]
public sealed class FogEffect : PostProcessEffectSettings
{
    public ColorParameter color1 = new ColorParameter { value = Color.white };
    public ColorParameter color2 = new ColorParameter { value = Color.white };
    public FloatParameter color1Start = new FloatParameter { value = 0.0f };
    public FloatParameter color1End = new FloatParameter { value = 0.5f };
    public FloatParameter color2Start = new FloatParameter { value = 0.5f };
    public FloatParameter color2End = new FloatParameter { value = 1.0f };
}