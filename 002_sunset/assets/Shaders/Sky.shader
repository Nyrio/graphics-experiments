Shader "Unlit/Sky"
{
    Properties
    {
      _SunColor ("Sun color", Color) = (1, 0.6, 0.2, 1)
      _SunHeight ("Sun height", Range (0, 5)) = 1.3
      _SunRadius ("Sun radius", Range (0, 3)) = 1
      _Color1 ("Color 1", Color) = (1, 0.32, 0.2, 1)
      _Color2 ("Color 2", Color) = (1, 0.52, 0.5, 1)
      _CloudColor ("Clouds color", Color) = (0.8, 0.3, 0.2, 1)
      _CloudIntensity ("Clouds intensity", Range (0, 1)) = 0.15
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        ZWrite On
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Assets/Shaders/util.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldv : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldv = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed3 _Color1, _Color2, _SunColor, _CloudColor;
            float _SunHeight, _SunRadius, _CloudIntensity;

            float fastincrease(float x, float lim) {
              float xm = x / lim;
              const float strength = 3;
              return - (((2-strength)*xm + 2*strength-3)*xm - strength)*xm;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 wv = i.worldv;

                /* Sky color */
                fixed3 col = lerp(_Color1, _Color2, i.worldv.y/5)
                             * (0.75 + 0.25 * smoothstep(0, 1, 42*(wv.y+0.7)
                                                               / (wv.x * wv.x)));

                /* Clouds */
                col = lerp(col, _CloudColor, _CloudIntensity*simplexNoise(float3(0.1*wv.x, 0.6*wv.y, 0)));

                /* Sun */
                float2 svec = wv.xy - float2(0, _SunHeight);
                float angle = atan2(svec.y, svec.x);
                float modifier = 0.9 + 0.03*simplexNoise(float3(wv.x, wv.y, 0.5*_Time.y));
                float inc = fastincrease(abs(abs(fmod(angle, PI/3)) - PI/6), PI/6);
                float dist = length(svec) * modifier;
                col = lerp(_SunColor, col, smoothstep(0.3, 2.5*_SunRadius, sqrt(dist)));
                col = lerp(float3(1,1,1), col, smoothstep(0.5*_SunRadius, 1.2*_SunRadius, dist));
                col = lerp(float3(1,1,1), col, 0.6+0.4*smoothstep(0.3, 1.5*_SunRadius, dist * (1 + 0.7*inc)));

                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
