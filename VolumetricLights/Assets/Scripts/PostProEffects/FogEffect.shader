Shader "Hidden/Custom/FogEffect"
{
    HLSLINCLUDE

#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

    float4 _Color1;
    float4 _Color2;
    float _Color1Start;
    float _Color1End;
    float _Color2Start;
    float _Color2End;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
        float depth = Linear01Depth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord));

        float fog1 = smoothstep(_Color1Start, _Color1End, depth);
        col = lerp(col, _Color1, fog1 * _Color1.a);

        float fog2 = smoothstep(_Color2Start, _Color2End, depth);
        col = lerp(col, _Color2, fog2 * _Color2.a);
        return col;
    }

        ENDHLSL

        SubShader
    {
        Cull Off ZWrite Off ZTest Always

            Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment Frag

            ENDHLSL
        }
    }
}