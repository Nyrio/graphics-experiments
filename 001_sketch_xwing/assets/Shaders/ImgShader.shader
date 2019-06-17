// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/ImgShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Strokes ("Strokes", 2D) = "white" {}
        _Background ("Background", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _Strokes;
            sampler2D _Background;
            sampler2D _CameraDepthNormalsTexture;

            float2 rotate(float2 uv, float angle) {
              float ca = cos(angle), sa = sin(angle);
              return mul(float2x2(ca, -sa, sa, ca), uv);
            }

            float3 sampleStrokes(float intensity, float2 uv, float angle) {
              if(intensity > 0.8) return float3(1, 1, 1);
              float scaled = 1.25*intensity - fmod(1.25*intensity, 0.2);
              float2 uvr = float2(0.19, 1) * frac(rotate(4 * float2(1.778, 1) * uv,
                                                  angle));
              return tex2Dlod(_Strokes, float4(scaled+0.01 + uvr.x, uvr.y, 0, 0)).rgb;
            }

            //Fragment Shader
            fixed4 frag (v2f_img fg) : COLOR{
              // Calculate edges
              float depth, depthGradSum = 0;
              float3 normal, normalGradSum = 0;
              const float step = 0.001;
              for(float i = 0; i < 3; i++) {
                for(float j = 0; j < 3; j++) {
                  DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture,
                                          fg.uv.xy + step*(float2(j,i)-1)),
                                    depth, normal);

                  float fval = i == 1 && j == 1 ? 8 : -1;
                  depthGradSum += fval * depth;
                  normalGradSum += fval * normal;
                }
              }
              float normalGradNormSum = length(normalGradSum);

              float edge = 1 - clamp((smoothstep(3, 3.5, normalGradNormSum)
                                           + 1 * abs(depthGradSum)), 0, 1);

              // Lighting and shadows
              float4 mtex = tex2D(_MainTex, fg.uv.xy);
              float lighting = dot(fixed3(0.3,0.6,0.1), mtex.xyz);

              // float2 hv = normalize(abs(normal.gr));
              // float angle = atan2(hv.y, hv.x) * (1-abs(normal.b));

              float angle = depth > 0.99 ? 0 : -0.6;
              float3 bg = tex2Dlod(_Background, float4(fg.uv.xy, 0, 0)).rgb;

              float3 strokes = sampleStrokes(edge * lighting, fg.uv.xy, angle);

              return fixed4(bg * strokes, 1);
            }
            ENDCG
        }
    }
}
