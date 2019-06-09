Shader "Unlit/ObjectShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FillColor ("Fill color", Color) = (.3, .38, .58, 1) // color
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        GrabPass { }

        Pass
        {
            CGPROGRAM
            #pragma require geometry
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

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
                float3 dist2vert : TEXCOORD1;
                float3 sideT : TEXCOORD2;
                float3 sideLength : TEXCOORD3;
            };

            struct pix
            {
              float4 color : COLOR;
              float depth : DEPTH;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _GrabTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // Distance between p and the line from a to b
            float lineDist(float3 p, float3 a, float3 b )
            {
              float3 pa = p-a, ba = b-a;
              float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
              return distance(pa, ba*h);
            }

            [maxvertexcount(3)]
            void geom(triangle v2f input[3], inout TriangleStream<v2f> OutputStream)
            {
                v2f v_out = (v2f)0;
                float3 t1 = tex2Dlod(_MainTex, float4(input[0].uv,0,0));
                float3 t2 = tex2Dlod(_MainTex, float4(input[1].uv,0,0));
                float3 t3 = tex2Dlod(_MainTex, float4(input[2].uv,0,0));
                float3 l1 = t2 * t3;
                float3 l2 = t1 * t3;
                float3 l3 = t1 * t2;
                float3 mask = float3(
                    max(l1.r, max(l1.g, l1.b)) > 0.8 ? 0 : 100,
                    max(l2.r, max(l2.g, l2.b)) > 0.8 ? 0 : 100,
                    max(l3.r, max(l3.g, l3.b)) > 0.8 ? 0 : 100
                );
                float3 p0 = input[0].vertex.xyz - input[2].vertex.xyz;
                float3 lv0 = input[1].vertex.xyz - input[2].vertex.xyz;
                float h0 = clamp(dot(p0,lv0)/dot(lv0,lv0),0.0,1.0);
                float3 r0 = h0*lv0;
                float3 p1 = input[1].vertex.xyz - input[0].vertex.xyz;
                float3 lv1 = input[2].vertex.xyz - input[0].vertex.xyz;
                float h1 = clamp(dot(p1,lv1)/dot(lv1,lv1),0.0,1.0);
                float3 r1 = h1*lv1;
                float3 p2 = input[2].vertex.xyz - input[1].vertex.xyz;
                float3 lv2 = input[0].vertex.xyz - input[1].vertex.xyz;
                float h2 = clamp(dot(p2,lv2)/dot(lv2,lv2),0.0,1.0);
                float3 r2 = h2*lv2;
                float3 side_length = float3(length(lv0), length(lv1), length(lv2));
                for(int i = 0; i < 3; i++)
                {
                    v_out.vertex = input[i].vertex;
                    v_out.uv = input[i].uv;
                    v_out.dist2vert = float3(
                        i != 0 ? 0 : distance(p0, r0),
                        i != 1 ? 0 : distance(p1, r1),
                        i != 2 ? 0 : distance(p2, r2)
                    ) + mask;

                    v_out.sideT = float3(
                        i == 1 ? side_length.x : (i == 2 ? 0 : length(r0)),
                        i == 2 ? side_length.y : (i == 0 ? 0 : length(r1)),
                        i == 0 ? side_length.z : (i == 1 ? 0 : length(r2))
                    );
                    v_out.sideLength = side_length;

                    OutputStream.Append(v_out);
                }
            }

            fixed3 _FillColor;

            pix frag (v2f i)
            {
                float3 intensityVec = 1 - 0.85 * smoothstep(0.03,0.05,i.dist2vert);
                float3 eps = i.sideLength / (2*floor(i.sideLength/0.2)+1);
                float intensity = max(intensityVec.x, max(intensityVec.y, intensityVec.z));
                intensityVec *= step(i.sideT % (2*eps), eps);
                float gofront = max(intensityVec.x, max(intensityVec.y, intensityVec.z));
                pix p;
                float pixgrid = (fmod(i.vertex.x,4) <= 1.1 && fmod(i.vertex.y,4) < 1.1) ? 1 : 0;
                p.color = fixed4(max(fixed3(1,1,1)*intensity, _FillColor.rgb + fixed3(1,1,1)*0.1*pixgrid), 1);
                p.depth = (gofront > 0.7) ? 0 : i.vertex.z;
                return p;
            }
            ENDCG
        }
    }
}
