Shader "Unlit/SkyboxShader"
{
    Properties
    {
        [HDR]_SkyDayColor("Day Sky Color", Color) = (1,1,1,1)
        [HDR]_SkyNightColor("Night Sky Color", Color) = (1,1,1,1)
    
        [Header(Sun)]
        [HDR]_SunColor("Sun Color", Color) = (1,1,1,1) 
        _SunSize("Sun Size", Range(0, 1)) = 0.5
        [HDR]_SunGlowColor("Sun Glow Color", Color) = (1,1,1,1)
        _SunGlowInnerEdge("Sun Glow Inner Edge", Range(0, 1)) = 0.5
        _SunGlowOuterEdge("Sun Glow Outer Edge", Range(0, 1)) = 0.1

        [Header(Gradient Sky Colors)]
        [HDR]_SkyDayGradient("Day Sky gradient", Color) = (0,0,0,1)
        [HDR]_SkySunsetColor("Sunset Sky Color", Color) = (1,1,1,1)
        [HDR]_SkyNightGradient("Sky night gradient", Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Background"
            "Queue"="Background"
            "PreviewType"="Skybox" 
        }
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _SkyDayColor;
            fixed4 _SkyNightColor;

            fixed4 _SunColor;
            float _SunSize;
            fixed4 _SunGlowColor;
            float _SunGlowInnerEdge;
            float _SunGlowOuterEdge;

            fixed4 _SkyDayGradient;
            fixed4 _SkySunsetColor;
            fixed4 _SkyNightGradient;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 pos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {        
                float3 viewDir = normalize(mul(unity_ObjectToWorld, i.pos) - _WorldSpaceCameraPos);   

                //Sun
                float4 sun = _SunColor;
                float sunSize = 1.05 - ( _SunSize * 0.1);
                float sunVal = smoothstep(sunSize * 0.95, sunSize, dot(viewDir, _WorldSpaceLightPos0));

                float outerEdge = (1 - _SunGlowOuterEdge);
                float innerEdge = max(outerEdge, 10 * (1 - _SunGlowInnerEdge));
                float sunglow = smoothstep(outerEdge, innerEdge, dot(viewDir, _WorldSpaceLightPos0));

                sun *= sunVal;
                sun += _SunGlowColor * sunglow;


                //Sky
                fixed4 sky = _SkyDayColor;
                float day = dot(float3(0,1,0), _WorldSpaceLightPos0);
                float night = dot(float3(0,-1,0), _WorldSpaceLightPos0);

                fixed4 colorBottom = lerp(_SkyDayGradient, _SkySunsetColor, min(1 - day, 1));
                fixed4 colorTop = lerp(_SkyDayColor, _SkyNightColor, clamp(1 - day, 0, 1));

                colorBottom = lerp(colorBottom, _SkyNightGradient, clamp((night), 0, 1));

                sky = lerp(colorBottom, colorTop, i.uv.y);

                float3 wpos = mul(unity_ObjectToWorld, i.pos).xyz;
                return sky + sun;
            }
            ENDCG
        }
    }
}
