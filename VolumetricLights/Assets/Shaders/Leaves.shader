Shader "Custom/Leaves"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
            _CutOff("CutOff", Range(0, 1)) = 0.5
            _NormalMap("Normal Map", 2D) = "bump" {}

        [Header(Wind)]
        _WindDirection("Wind Direction", Vector) = (0,0,-1,0)
        _WindTiling("Wind Tiling", Vector) = (1,1,1,1)
        _WindSpeed("Wind Speed", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert alphatest:_CutOff addshadow 
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NormalMap;
        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float4 _WindDirection;
        float2 _WindTiling;
        float _WindSpeed;

        void vert(inout appdata_full v)
        {
            float4 wpos = mul(unity_ObjectToWorld, v.vertex);

            float windMultiplier = sin((_Time.z * _WindSpeed) + (wpos.x * _WindTiling.x) + (wpos.z * _WindTiling.y));
            windMultiplier = (windMultiplier + 1.0f) * 0.5f;
            float4 wind = _WindDirection * windMultiplier;

            float windMultiplier2 = sin((_Time.z * _WindSpeed * 0.0f) + (wpos.x * _WindTiling.x * 250.0f) + (wpos.z * _WindTiling.y * 250.0f));
            windMultiplier2 = (windMultiplier2 + 1.0f) * 0.5f;
            float4 wind2 = _WindDirection * windMultiplier2 * 0.05f;

            wpos += wind * v.texcoord.y + wind2 * v.texcoord.y;
            v.vertex = mul(unity_WorldToObject, wpos);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            float3 norm = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));

            o.Normal = norm;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
