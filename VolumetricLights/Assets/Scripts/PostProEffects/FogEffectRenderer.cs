using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

public sealed class FogEffectRenderer : PostProcessEffectRenderer<FogEffect>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/FogEffect"));

        sheet.properties.SetColor("_Color1", settings.color1);
        sheet.properties.SetColor("_Color2", settings.color2);
        sheet.properties.SetFloat("_Color1Start", settings.color1Start);
        sheet.properties.SetFloat("_Color1End", settings.color1End);
        sheet.properties.SetFloat("_Color2Start", settings.color2Start);
        sheet.properties.SetFloat("_Color2End", settings.color2End);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
