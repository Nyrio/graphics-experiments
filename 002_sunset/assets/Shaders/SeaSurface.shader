Shader "Unlit/SeaSurface"
{
    Properties
    {
        _Color ("Diffuse color", Color) = (0, 0.01, 0.12, 1)
        _SunColor ("Sun color", Color) = (1, 0.5, 0.25, 1)
        _SkyColor ("Sky color", Color) = (0.76, 0.38, 0.12, 1)
        _SunRadius ("Sun radius", Range (0, 2)) = 1
        _SunPosAngle ("Sun position angle", Range (0, 45)) = 17
        _SunRadiusAngle ("Sun radius angle", Range(0, 60)) = 36
    }
    SubShader
    {
      Tags { "RenderType"="Opaque"
             "Queue"="Transparent-1"}
        ZWrite On
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/Shaders/util.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 worldv : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.worldv = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, o.worldv);
                return o;
            }

            fixed4 _Color;
            fixed4 _SunColor;
            fixed4 _SkyColor;
            float _SunRadius;
            float _SunPosAngle;
            float _SunRadiusAngle;

            float height(float x, float z) {
              return 0.03 * (0.2 * sin(5*z+0.3*_Time.y)
                             + 0.1*simplexNoise(float3(3*x, 10*z + 0.4*_Time.y, 0.4*_Time.y))       // micro
                             + 0.4*simplexNoise(float3(x, 3.5*z + 0.6*_Time.y, 0.2*_Time.y))       // medium
                             + 0.6*simplexNoise(float3(0.5*x, 1.5*z + 0.6*_Time.y, 0.2*_Time.y))); // macro
            }

            /* Symmetric of the camera position c in relation to the normal
             * vector n at the fragment p */
            float3 symmetric(float3 c, float3 p, float3 n) {
              float3 pc = c - p;
              /* Projection of c on n */
              float3 pp = p + (dot(pc, n) / dot(n, n)) * n;
              /* Symmetric of c w.r.t pp */
              return 2 * pp - c;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 wv = i.worldv;

                const float chouilla = 0.001;
                float h = height(wv.x, wv.z);
                float3 t1 = float3(chouilla, height(wv.x + chouilla, wv.z) -h, 0);
                float3 t2 = float3(0, height(wv.x, wv.z - chouilla) - h, -chouilla);
                float3 normal = normalize(cross(t1, t2));

                fixed4 diffuse = _Color;

                float3 pcc = symmetric(_WorldSpaceCameraPos, wv, normal) - wv;

                float angle_v = degrees(atan2(pcc.y, pcc.z));

                float3 sun_spec = (1 - smoothstep(0, _SunRadius, abs(wv.x)))
                                 * (1 - smoothstep(0, _SunRadiusAngle, abs(angle_v - _SunPosAngle)))
                                 * smoothstep(-0.05, 0.2, normal.z)
                                 * _SunColor.rgb;
                sun_spec += (1 - smoothstep(0, _SunRadius, abs(wv.x)))
                            * (1 - smoothstep(0, 30, abs(angle_v - _SunPosAngle)))
                            * smoothstep(0.05, 0.2, normal.z);
                float3 sky_spec = 1.7 * smoothstep(-0.4, 1, normal.z)
                                  * (1 - 0.7*smoothstep(2, 10, abs(wv.x)))
                                  * _SkyColor.rgb;
                float3 specular = sun_spec + sky_spec;

                float alpha = 1 - smoothstep(4.5, 6.3, wv.z);

                return fixed4(diffuse + specular, alpha);
            }
            ENDCG
        }
    }
}
