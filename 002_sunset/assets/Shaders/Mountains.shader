Shader "Unlit/Mountains"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"
               "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float coeff(int i, int j) {
              float3 coeffs = float3(1,4,6);
              return coeffs[abs(i)] * coeffs[abs(j)];
            }

            fixed4 frag (v2f vdata) : SV_Target
            {
                fixed alpha = 0;
                float chouilla = 0.003;

                /* Opacity 5x5 gaussian blur */
                for(int i = -2; i <= 2; i++) {
                  for(int j = -2; j <= 2; j++) {
                    alpha += coeff(i, j) * tex2D(_MainTex, clamp(vdata.uv + chouilla * float2(i, j), 0, 1)).a;
                  }
                }
                alpha /= 256;

                fixed3 col = tex2D(_MainTex, vdata.uv).rgb;
                col += 0.01*fixed3(1,0.3,0) * simplexNoise(float3(float2(32,4)*vdata.uv, 0));

                return fixed4(col, clamp(alpha,0,1));
            }
            ENDCG
        }
    }
}
