Shader "Hidden/VolumetricLights"
{
    Properties
    {
        [HideInInspector]
        _MainTex ("Texture", 2D) = "white" {}
        _Steps("Steps", Range(1, 512)) = 128
        _Intensity("Intensity", Range(0, 5)) = 1
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
            #pragma require 2darray

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 ray : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD1;
                float4 wpos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = v.ray;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            //float3 _SpotLightPos;
            //float3 _SpotLightEndPos;
            //float3 _SpotLightDir;
            //float3 _SpotLightUpDir;
            //float _SpotLightRange;
            //float _SpotLightRadius;
            //fixed4 _SpotLightColor;
            //sampler2D _SpotLightDepthTexture;

            float _Steps;
            float _Intensity;

         /*   material.SetInt("_NumLights", _numLights);
            material.SetVectorArray("_LightPositions", _lightPositions);
            material.SetVectorArray("_LightDirections", _lightDirections);
            material.SetVectorArray("_LightUpDirections", _lightUpDirections);
            material.SetVectorArray("_LightEndPositions", _lightEndPositions);
            material.SetFloatArray("_LightRanges", _lightRanges);
            material.SetFloatArray("_LightRadius", _lightRadius);
            material.SetColorArray("_LightColors", _lightColors);*/
            int _NumLights;
            float3 _LightPositions[16];
            float3 _LightDirections[16];
            float3 _LightUpDirections[16];
            float3 _LightEndPositions[16];
            float _LightRanges[16];
            float _LightRadius[16];
            float _LightIntensities[16];
            fixed4 _LightColors[16];
            UNITY_DECLARE_TEX2DARRAY(_LightDepthTextures);

            float rand(float3 co)
            {
                float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
                return val - floor(val);
            }

            float sdCappedCone(in float3 pos, in float3 conePos, float3 b, float radiusStart, float radiusEnd)
            {
                float3 a = float3(0, 0, 0);
                b = -b;

                float3 p = conePos - pos;
                float rba = radiusEnd - radiusStart;
                float baba = dot(b - a, b - a);
                float papa = dot(p - a, p - a);
                float paba = dot(p - a, b - a) / baba;

                float x = sqrt(papa - paba * paba * baba);

                float cax = max(0.0, x - ((paba < 0.5) ? radiusStart : radiusEnd));
                float cay = abs(paba - 0.5) - 0.5;

                float k = rba * rba + baba;
                float f = clamp((rba * (x - radiusStart) + paba * baba) / k, 0.0, 1.0);

                float cbx = x - radiusStart - f * rba;
                float cby = paba - f;

                float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;

                return s * sqrt(min(cax * cax + cay * cay * baba,
                    cbx * cbx + cby * cby * baba));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                //Sample depth
                float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float linearDepth = Linear01Depth(nonLinearDepth) * length(i.viewDir);


                float3 pos = _WorldSpaceCameraPos;
                float3 dir = normalize(i.viewDir.xyz);
                float totalDist = 0;

                int steps = round(_Steps);
               // float intensity = _Intensity / steps;
                float stepSize = 0;
                float4 volume = 0;

                int lightIndex = 0;

                for (int i = 0; i < steps; i++)
                {
                    float stepVal = 9999999;
                    float localStepSize = stepSize;

                    for (int i = 0; i < _NumLights; i++)
                    {
                        float newStep = sdCappedCone(pos, _LightPositions[i], _LightEndPositions[i], 0.0f, _LightRadius[i]);

                        float isSmaller = step(newStep, stepVal);// newStep < stepVal;
                        stepVal = lerp(stepVal, newStep, isSmaller);
                        lightIndex = lerp(lightIndex, i, isSmaller);
                        stepSize = lerp(stepSize, _LightRanges[i] / steps, isSmaller);
                    }

                    float intensity = _LightIntensities[lightIndex] / steps;

                    stepVal = sdCappedCone(pos, _LightPositions[lightIndex], _LightEndPositions[lightIndex], 0.0f, _LightRadius[lightIndex]);

                    if (stepVal < 0.0f && totalDist < linearDepth)
                    {
                        float grain = (rand(pos) * 2);

                        float distPerc = pow(1 - (distance(pos, _LightPositions[lightIndex]) / _LightRanges[lightIndex]), 1);

                        float distFromOrigin = distance(pos, _LightPositions[lightIndex]);
                        float distFromOriginMiddle = dot(pos - _LightPositions[lightIndex], _LightDirections[lightIndex]);
                        float distFromMiddle = sqrt((distFromOrigin * distFromOrigin) - (distFromOriginMiddle * distFromOriginMiddle));

                        float distFromMiddlePerc = pow(1 - (distFromMiddle / _LightRadius[lightIndex]), 2);

                        localStepSize *= grain;
                        //stepVal *= (rand(pos.zxy) * 2);

                        float3 diff = pos - _LightPositions[lightIndex];
                        float size = (distFromOriginMiddle / _LightRanges[lightIndex]) * _LightRadius[lightIndex];
                        float yUv = dot(diff, _LightUpDirections[lightIndex]);
                        float xUv = dot(diff, cross(_LightUpDirections[lightIndex], _LightDirections[lightIndex]));
                        float3 uvs = float3(float2(xUv + size, yUv + size) / float2(size * 2, size * 2), lightIndex);

                        float depth = UNITY_SAMPLE_TEX2DARRAY(_LightDepthTextures, uvs).r;
                        float shadowMask = depth* _LightRanges[lightIndex] > distFromOriginMiddle;

                        float4 base = float4(_LightColors[lightIndex].rgb * intensity, 0.0f);
                        volume += max(base * grain * distPerc * distFromMiddlePerc * shadowMask, 0);
                    }

                    totalDist += length(dir * max(stepVal, localStepSize));
                    pos += dir * max(stepVal, localStepSize);
                }
                
                col += volume;
                return col;
            }
            ENDCG
        }
    }
}
