Shader "Hidden/CameraEffects"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Atmospheric scattering color", Color) = (1, 0.32, 0.2, 1)
        _Intensity ("Effect intensity", Range (0, 1)) = 0.3
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
            sampler2D _CameraDepthNormalsTexture;
            fixed3 _Color;
            float _Intensity;

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float depth;
                float3 normal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture,
                                        i.uv.xy),
                                  depth, normal);
                depth = smoothstep(0,0.017,depth);

                /* Atmospheric scattering */
                fixed3 brighter = max(col.xyz, _Color.xyz);

                return fixed4(lerp(col, brighter, _Intensity * depth), 1);
            }
            ENDCG
        }
    }
}
