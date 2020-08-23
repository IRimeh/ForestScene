// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/TestingShader"
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
        _MainTex("Base (RGB) Alpha (A)", 2D) = "white" {}
        _ShadowStrength("Shadow Strength", Range(0, 1)) = 0
    }
        SubShader
    {

        Tags {"Queue" = "Geometry" "RenderType" = "Opaque"}
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4  pos         : SV_POSITION;
                float2  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal		: TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightColor0;
            float _ShadowStrength;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                o.lightDir = ObjSpaceLightDir(v.vertex);
                o.normal = v.normal;

                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= _Color;

                i.lightDir = normalize(i.lightDir);
                fixed atten = LIGHT_ATTENUATION(i);
                fixed dotVal = saturate(dot(i.normal, i.lightDir));

                fixed4 c;
                c.rgb = col.rgb * _ShadowStrength;
                c.rgb += (col.rgb * _LightColor0.rgb * dotVal) * (atten * 2);
                c.a = col.a + _LightColor0.a * atten;
                return c;
            }
            ENDCG
        }

        Pass {
            Tags {"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4  pos         : SV_POSITION;
                float2  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD2;
                float3 normal		: TEXCOORD1;
                LIGHTING_COORDS(3,4)
            };

            v2f vert(appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                o.lightDir = ObjSpaceLightDir(v.vertex);
                o.normal = v.normal;

                TRANSFER_VERTEX_TO_FRAGMENT(o); 
                return o;
            }

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _LightColor0;

            fixed4 frag(v2f i) : COLOR
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= _Color;

                i.lightDir = normalize(i.lightDir);
                fixed atten = LIGHT_ATTENUATION(i);
                fixed dotVal = saturate(dot(i.normal, i.lightDir));

                fixed4 c;
                c.rgb = (col.rgb * _LightColor0.rgb * dotVal) * (atten * 2);
                c.a = col.a;
                return c;
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}