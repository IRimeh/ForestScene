Shader "Hidden/Fog"
{
    Properties
    {
        _Color1("Fog Color 1", Color) = (1,1,1,1)
        _Color2("Fog Color 2", Color) = (1,1,1,1)
        _Color1Start("Color 1 Start", Range(0, 1)) = 0.0
        _Color1End("Color 1 End", Range(0, 1)) = 0.5
        _Color2Start("Color 2 Start", Range(0, 1)) = 0.5
        _Color2End("Color 2 End", Range(0, 1)) = 1.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            fixed4 _Color1;
            fixed4 _Color2;
            float _Color1Start;
            float _Color1End;
            float _Color2Start;
            float _Color2End;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));

                float fog1 = smoothstep(_Color1Start, _Color1End, depth);
                col = lerp(col, _Color1, fog1 * _Color1.a);

                float fog2 = smoothstep(_Color2Start, _Color2End, depth);
                col = lerp(col, _Color2, fog2 * _Color2.a);

                //col = lerp(col, _Color1, (depth / _FogMaxRange));

                return col;
            }
            ENDCG
        }
    }
}
