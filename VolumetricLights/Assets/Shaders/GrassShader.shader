Shader "Custom/GrassShader"
{
    Properties
    {
        _Color("Top Color", Color) = (1,1,1,1)
        _BotColor("Bottom Color", Color) = (0,0,0,1)
        _GroundColor("Ground Color", Color) = (1,1,1,1)
        _MainTex("Base (RGB) Alpha (A)", 2D) = "white" {}
        _ShadowStrength("Ambient Light", Range(0, 1)) = 0
        [Toggle(BASEMESH)]_BaseMesh("Enable Base Mesh", float) = 1
        _MaxDist("Max Dist", Range(0, 1000)) = 1000

        [Space(40)]
        [Header(Grass Variables)]
        _Quantity("Quantity", int) = 2
        _Subdivisions("Subdivisions", Range(1, 4)) = 5

        [Space(20)]
        _OffsetDistance("Offset Distance", float) = 0.1
        _GrassHeight("Grass Height", Range(0, 20)) = 3
        _GrassWidth("Grass Width", Range(0, 5)) = 0.2
        _GrassSizeRandomness("Grass Size Randomness", Range(0, 1)) = 0.5

        [Header(Wind)]
        _WindDirection("Wind Direction", Vector) = (0,0,-1,0)
        _WindTiling("Wind Tiling", Vector) = (0.25, 0.75, 0, 0)
        _WindSpeed("Wind Speed", float) = 1.0
    }
    SubShader
    {

        Tags {"Queue" = "Geometry" "RenderType" = "Opaque"}
        ZWrite On
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma shader_feature BASEMESH

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2g
            {
                float4  pos         : SV_POSITION;
                float2  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal      : TEXCOORD2;
                fixed4 color : COLOR;
                LIGHTING_COORDS(3,4)
            };

            struct g2f
            {
                float4  pos         : SV_POSITION;
                float3  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal		: TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _BotColor;
            fixed4 _GroundColor;
            fixed4 _LightColor0;
            float _ShadowStrength;

            int _Quantity;
            int _Subdivisions;

            float _OffsetDistance;
            float _GrassHeight;
            float _GrassWidth;
            float _GrassSizeRandomness;
            
            float3 _WindDirection;
            float3 _WindTiling;
            float _WindSpeed;
            float _MaxDist;

            float rand(float3 co)
            {
                float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
                return val - floor(val);
            }

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.vertex;
                o.uv = v.texcoord.xy;
                o.lightDir = ObjSpaceLightDir(v.vertex);
                o.normal = v.normal;
                o.color = v.color;

                return o;
            }

            void CreateOriginalMesh(g2f o, triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                for (int i = 0; i < 3; i++)
                {
                    o.pos = UnityObjectToClipPos(IN[i].pos);
                    o.uv = float3(IN[i].uv, 0);
                    o.lightDir = IN[i].lightDir;
                    o.normal = IN[i].normal;
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            #define MAX_SUBDIVISIONS 5
            void CreateGrassBlade(g2f o, inout TriangleStream<g2f> triStream, float3 pos, float3 upDir, float3 tanDir, float width, float height, int subdivisions, float3 wind)
            {
                subdivisions = clamp(subdivisions, 0, MAX_SUBDIVISIONS);
                float ratio = 1.0f / (subdivisions + 1);
                float ratio1 = 1.0f / subdivisions;

                float3 sideOffset;
                float3 upOffset;
                int j;

                //o.normal = cross(upDir, tanDir);
                for (int i = 0; i < subdivisions; i++)
                {
                    float3 offsetBot = wind * pow((i * ratio) , 1.5f);
                    float3 offsetTop = wind * pow((i + 1) * ratio, 1.5f);
                    float3 offsetBotBot = wind * pow(max(i - 1, 0) * ratio, 1.5f);
                    float3 offsetTopTop = wind * pow((i + 2) * ratio, 1.5f);

                    float3 posBot = pos + (upDir * ratio * i) + offsetBot;
                    float3 posTop = pos + (upDir * ratio * (i + 1)) + offsetTop;
                    float3 posBotBot = pos + (upDir * ratio * (i - 1)) + offsetBotBot;
                    float3 posTopTop = pos + (upDir * ratio * (i + 2)) + offsetTopTop;

                    float3 normBot = cross(normalize(posTop - posBotBot), normalize(tanDir));
                    float3 normTop = cross(normalize(posTopTop - posBot), normalize(tanDir));

                    j = subdivisions - i;

                    //Front side
                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = normBot;
                    o.uv = float3(0, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();


                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = normTop;
                    o.uv = float3(1, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();



                    //Back side
                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = -normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = -normBot;
                    o.uv = float3(0, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = -normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();


                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = -normTop;
                    o.uv = float3(1, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = -normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = -normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();
                }
            }

            [maxvertexcount(48)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;

#ifdef BASEMESH
                CreateOriginalMesh(o, IN, triStream);
#endif

                o.lightDir = IN[0].lightDir;
                float redVal = (IN[0].color.r + IN[1].color.r + IN[2].color.r) * 0.3333f;

                float dist = distance(mul(unity_ObjectToWorld, IN[0].pos), _WorldSpaceCameraPos);
                float inRange = step(dist, _MaxDist);

                
                for (float group = 0; group < _Quantity * redVal * inRange; group++)
                {
                    float rand1 = (rand(IN[0].pos.xyz * (1 + group * 21.532)) - 0.5f) * 2.0f;
                    float rand2 = (rand(IN[0].pos.xzy * (5 + group * 64.164)) - 0.5f) * 2.0f;
                    float xOffset = rand1;
                    float yOffset = rand2;

                    float randSize = rand(float3(rand1, rand2, rand1 + rand2));
                    float height = _GrassHeight * (1 - (randSize * _GrassSizeRandomness)) * IN[0].color.r;
                    float width = _GrassWidth * (1 - (randSize * _GrassSizeRandomness)) * IN[0].color.r;

                    float windMultiplier = sin((_Time.z * _WindSpeed) + rand1 * rand2 + (IN[0].pos.x * _WindTiling.x) + (IN[0].pos.z * _WindTiling.y));
                    windMultiplier = (windMultiplier + 1.0f) * 0.5f;
                    float3 wind = _WindDirection * windMultiplier;

                    CreateGrassBlade(o, triStream, IN[0].pos + float3(xOffset, 0, yOffset) * _OffsetDistance, IN[0].normal, cross(IN[0].normal, float3(rand1, rand1 * rand2, rand2)), width, height, _Subdivisions, wind);
                }
            }

            fixed4 frag(g2f i) : COLOR
            {
                fixed4 col = _GroundColor;
                float4 grassBladeCol = lerp(_BotColor, _Color, i.uv.y);
                col.rgb = lerp(col.rgb, grassBladeCol, i.uv.z);
                float mask = tex2D(_MainTex, i.uv.xy).r + (1- i.uv.z);

                i.lightDir = normalize(i.lightDir);
                fixed atten = LIGHT_ATTENUATION(i);
                fixed dotVal = saturate(dot(i.normal, i.lightDir));

                fixed4 c;
                c.rgb = col.rgb * _ShadowStrength;
                c.rgb += (col.rgb * _LightColor0.rgb * dotVal) * (atten * 2);
                c.a = col.a + _LightColor0.a * atten;

                if (mask < 0.5)
                    discard;
                return c;
            }
            ENDCG
        }











        /////////////////////////////
        //                         //
        //      SHADOW CASTER      //
        //                         //
        /////////////////////////////
        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
                "RenderType" = "Transparent"
                "Queue" = "AlphaTest"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma target 4.6
            #pragma multi_compile_shadowcaster
            #pragma shader_feature BASEMESH
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _BotColor;
            fixed4 _GroundColor;
            fixed4 _LightColor0;
            float _ShadowStrength;

            int _Quantity;
            int _Subdivisions;

            float _OffsetDistance;
            float _GrassHeight;
            float _GrassWidth;
            float _GrassSizeRandomness;

            float3 _WindDirection;
            float3 _WindTiling;
            float _WindSpeed;
            float _MaxDist;


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2g
            {
                float4  pos         : SV_POSITION;
                float2  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal		: TEXCOORD2;
                fixed4 color : COLOR;
            };

            struct g2f
            {
                float4  pos         : SV_POSITION;
                float3  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal		: TEXCOORD2;
            };

            float rand(float3 co)
            {
                float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
                return val - floor(val);
            }

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.vertex;
                o.uv = v.texcoord.xy;
                o.lightDir = ObjSpaceLightDir(v.vertex);
                o.normal = v.normal;
                o.color = v.color;

                return o;
            }

            void CreateOriginalMesh(g2f o, triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                for (int i = 0; i < 3; i++)
                {
                    o.pos = UnityObjectToClipPos(IN[i].pos);
                    o.uv = float3(IN[i].uv, 0);
                    o.lightDir = IN[i].lightDir;
                    o.normal = IN[i].normal;
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            #define MAX_SUBDIVISIONS 5
            void CreateGrassBlade(g2f o, inout TriangleStream<g2f> triStream, float3 pos, float3 upDir, float3 tanDir, float width, float height, int subdivisions, float3 wind, float3 lightDir)
            {
                subdivisions = clamp(subdivisions, 0, MAX_SUBDIVISIONS);
                float ratio = 1.0f / (subdivisions + 1);
                float ratio1 = 1.0f / subdivisions;

                float3 sideOffset;
                float3 upOffset;
                int j;

                //o.normal = cross(upDir, tanDir);
                o.lightDir = lightDir;
                for (int i = 0; i < subdivisions; i++)
                {
                    float3 offsetBot = wind * pow((i * ratio), 1.5f);
                    float3 offsetTop = wind * pow((i + 1) * ratio, 1.5f);
                    float3 offsetBotBot = wind * pow(max(i - 1, 0) * ratio, 1.5f);
                    float3 offsetTopTop = wind * pow((i + 2) * ratio, 1.5f);

                    float3 posBot = pos + (upDir * ratio * i) + offsetBot;
                    float3 posTop = pos + (upDir * ratio * (i + 1)) + offsetTop;
                    float3 posBotBot = pos + (upDir * ratio * (i - 1)) + offsetBotBot;
                    float3 posTopTop = pos + (upDir * ratio * (i + 2)) + offsetTopTop;

                    float3 normBot = cross(normalize(posTop - posBotBot), normalize(tanDir));
                    float3 normTop = cross(normalize(posTopTop - posBot), normalize(tanDir));

                    j = subdivisions - i;

                    //Front side
                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = normBot;
                    o.uv = float3(0, ratio1 * i, 1);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    triStream.Append(o);
                    triStream.RestartStrip();


                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = normTop;
                    o.uv = float3(1, ratio1 * (i + 1), 1);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    triStream.Append(o);
                    triStream.RestartStrip();



                    //Back side
                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = -normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = -normBot;
                    o.uv = float3(0, ratio1 * i, 1);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = -normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    triStream.Append(o);
                    triStream.RestartStrip();


                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = -normTop;
                    o.uv = float3(1, ratio1 * (i + 1), 1);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    o.normal = -normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    o.normal = -normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    triStream.Append(o);
                    triStream.RestartStrip();
                }
            }

            [maxvertexcount(48)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
#ifdef BASEMESH
                CreateOriginalMesh(o, IN, triStream);
#endif

                o.lightDir = IN[0].lightDir;
                float redVal = (IN[0].color.r + IN[1].color.r + IN[2].color.r) * 0.3333f;

                float dist = distance(mul(unity_ObjectToWorld, IN[0].pos), _WorldSpaceCameraPos);
                float inRange = step(dist, _MaxDist);

                for (float group = 0; group < _Quantity * redVal * inRange; group++)
                {
                    float rand1 = (rand(IN[0].pos.xyz * (1 + group * 21.532)) - 0.5f) * 2.0f;
                    float rand2 = (rand(IN[0].pos.xzy * (5 + group * 64.164)) - 0.5f) * 2.0f;
                    float xOffset = rand1;
                    float yOffset = rand2;

                    float randSize = rand(float3(rand1, rand2, rand1 + rand2));
                    float height = _GrassHeight * (1 - (randSize * _GrassSizeRandomness)) * IN[0].color.r;
                    float width = _GrassWidth * (1 - (randSize * _GrassSizeRandomness)) * IN[0].color.r;

                    float windMultiplier = sin((_Time.z * _WindSpeed) + rand1 * rand2 + (IN[0].pos.x * _WindTiling.x) + (IN[0].pos.z * _WindTiling.y));
                    windMultiplier = (windMultiplier + 1.0f) * 0.5f;
                    float3 wind = _WindDirection * windMultiplier;

                    CreateGrassBlade(o, triStream, IN[0].pos + float3(xOffset, 0, yOffset) * _OffsetDistance, IN[0].normal, cross(IN[0].normal, float3(rand1, rand1 * rand2, rand2)), width, height, _Subdivisions, wind, o.lightDir);
                }
            }

            fixed4 frag(g2f i) : COLOR
            {
                float mask = tex2D(_MainTex, i.uv.xy).r + (1 - i.uv.z);
                if (mask < 0.5)
                    discard;

                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

        ///////////////////////////
        //                       //
        //      FORWARD ADD      //
        //                       //
        ///////////////////////////
        Pass {
            Tags {"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature BASEMESH

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct lightData {
                float4 vertex : POSITION;
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2g
            {
                float4  pos         : SV_POSITION;
                float2  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal		: TEXCOORD2;
                fixed4 color : COLOR;
                //LIGHTING_COORDS(3, 4)
            };

            struct g2f
            {
                float4  pos         : SV_POSITION;
                float3  uv          : TEXCOORD0;
                float3  lightDir    : TEXCOORD1;
                float3  normal		: TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            int _Quantity;
            int _Subdivisions;

            float _OffsetDistance;
            float _GrassHeight;
            float _GrassWidth;
            float _GrassSizeRandomness;

            float3 _WindDirection;
            float3 _WindTiling;
            float _WindSpeed;
            float _MaxDist;

            float rand(float3 co)
            {
                float val = sin(dot(co.xyz, float3(12.9898, 78.233, 211.25312))) * 43758.5453;
                return val - floor(val);
            }

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.vertex;
                o.uv = v.texcoord.xy;
                o.lightDir = ObjSpaceLightDir(v.vertex);
                o.normal = v.normal;
                o.color = v.color;
                //TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            void CreateOriginalMesh(g2f o, triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                lightData v;
                for (int i = 0; i < 3; i++)
                {
                    o.pos = UnityObjectToClipPos(IN[i].pos);
                    v.vertex = IN[i].pos;
                    o.uv = float3(IN[i].uv, 0);
                    o.lightDir = IN[i].lightDir;
                    o.normal = IN[i].normal;
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            #define MAX_SUBDIVISIONS 5
            void CreateGrassBlade(g2f o, inout TriangleStream<g2f> triStream, float3 pos, float3 upDir, float3 tanDir, float width, float height, int subdivisions, float3 wind, float3 lightDir)
            {
                subdivisions = clamp(subdivisions, 0, MAX_SUBDIVISIONS);
                float ratio = 1.0f / (subdivisions + 1);
                float ratio1 = 1.0f / subdivisions;

                float3 sideOffset;
                float3 upOffset;
                int j;

                lightData v;
                o.lightDir = lightDir;

                //o.normal = cross(upDir, tanDir);
                for (int i = 0; i < subdivisions; i++)
                {
                    float3 offsetBot = wind * pow((i * ratio), 1.5f);
                    float3 offsetTop = wind * pow((i + 1) * ratio, 1.5f);
                    float3 offsetBotBot = wind * pow(max(i - 1, 0) * ratio, 1.5f);
                    float3 offsetTopTop = wind * pow((i + 2) * ratio, 1.5f);

                    float3 posBot = pos + (upDir * ratio * i) + offsetBot;
                    float3 posTop = pos + (upDir * ratio * (i + 1)) + offsetTop;
                    float3 posBotBot = pos + (upDir * ratio * (i - 1)) + offsetBotBot;
                    float3 posTopTop = pos + (upDir * ratio * (i + 2)) + offsetTopTop;

                    float3 normBot = cross(normalize(posTop - posBotBot), normalize(tanDir));
                    float3 normTop = cross(normalize(posTopTop - posBot), normalize(tanDir));

                    j = subdivisions - i;

                    //Front side
                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetBot, 1);
                    o.normal = normBot;
                    o.uv = float3(0, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetTop, 1);
                    o.normal = normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetBot, 1);
                    o.normal = normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();


                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetTop, 1);
                    o.normal = normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetTop, 1);
                    o.normal = normTop;
                    o.uv = float3(1, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetBot, 1);
                    o.normal = normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();



                    //Back side
                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetTop, 1);
                    o.normal = -normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetBot, 1);
                    o.normal = -normBot;
                    o.uv = float3(0, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetBot, 1);
                    o.normal = -normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();


                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetTop, 1);
                    o.normal = -normTop;
                    o.uv = float3(1, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * -width;
                    upOffset = upDir * height * ratio * (i + 1);
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetTop);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetTop, 1);
                    o.normal = -normTop;
                    o.uv = float3(0, ratio1 * (i + 1), 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);

                    sideOffset = tanDir * width;
                    upOffset = upDir * height * ratio * i;
                    o.pos = UnityObjectToClipPos(pos + sideOffset + upOffset + offsetBot);
                    v.vertex = float4(pos + sideOffset + upOffset + offsetBot, 1);
                    o.normal = -normBot;
                    o.uv = float3(1, ratio1 * i, 1);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    triStream.Append(o);
                    triStream.RestartStrip();
                }
            }

            [maxvertexcount(48)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
#ifdef BASEMESH
                CreateOriginalMesh(o, IN, triStream);
#endif

                o.lightDir = IN[0].lightDir;
                float redVal = (IN[0].color.r + IN[1].color.r + IN[2].color.r) * 0.3333f;

                float dist = distance(mul(unity_ObjectToWorld, IN[0].pos), _WorldSpaceCameraPos);
                float inRange = step(dist, _MaxDist);

                for (float group = 0; group < _Quantity * redVal * inRange; group++)
                {
                    float rand1 = (rand(IN[0].pos.xyz * (1 + group * 21.532)) - 0.5f) * 2.0f;
                    float rand2 = (rand(IN[0].pos.xzy * (5 + group * 64.164)) - 0.5f) * 2.0f;
                    float xOffset = rand1;
                    float yOffset = rand2;

                    float randSize = rand(float3(rand1, rand2, rand1 + rand2));
                    float height = _GrassHeight * (1 - (randSize * _GrassSizeRandomness)) * IN[0].color.r;
                    float width = _GrassWidth * (1 - (randSize * _GrassSizeRandomness)) * IN[0].color.r;

                    float windMultiplier = sin((_Time.z * _WindSpeed) + rand1 * rand2 + (IN[0].pos.x * _WindTiling.x) + (IN[0].pos.z * _WindTiling.y));
                    windMultiplier = (windMultiplier + 1.0f) * 0.5f;
                    float3 wind = _WindDirection * windMultiplier;

                    CreateGrassBlade(o, triStream, IN[0].pos + float3(xOffset, 0, yOffset) * _OffsetDistance, IN[0].normal, cross(IN[0].normal, float3(rand1, rand1 * rand2, rand2)), width, height, _Subdivisions, wind, IN[0].lightDir);
                }
            }


            fixed4 _LightColor0;

            fixed4 frag(g2f i) : COLOR
            {
                //fixed4 col = tex2D(_MainTex, i.uv);
                float mask = tex2D(_MainTex, i.uv.xy).r + (1 - i.uv.z);
                if (mask < 0.5)
                    discard;

                fixed4 col = 1;// _Color;

                i.lightDir = normalize(i.lightDir);
                fixed atten = LIGHT_ATTENUATION(i);
                float3 wpos = mul(unity_ObjectToWorld, i.pos);
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