Shader "Hidden/ImgShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            float dist2hud(float2 pos) {
              float2 absPos = abs(pos);
              float time = _Time.y;
              float4 lvls = float4(
                0.37 + dot(float3(0.02, 0.02, 0.01),
                           sin(float3(2*time+.5, 3*time + .7, 4*time))),
                0.29 + dot(float3(0.017, 0.009, 0.005),
                           sin(float3(1.3*time+.2, 1.9*time + .6, 2.7*time))),
                0.4 + dot(float3(0.02, 0.012, 0.007),
                           sin(float3(1.5*time+.2, 2.5*time, 5*time))),
                0.34 + dot(float3(0.025, 0.015, 0.009),
                           sin(float3(1.9*time+.5, 3.5*time + .4, 3.7*time))));
              int whichlvl = 2. * (sign(pos.x)/2. + 0.5) + sign(pos.y)/2. + 0.5;
              float xDist = max(0.34 - absPos.x, absPos.x - 0.4);
              float yDist = max(0.04 - absPos.y, absPos.y - lvls[whichlvl]);
              return max(xDist, yDist);
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                float pixgrid = (fmod(i.pos.x,4) <= 1.1 && fmod(i.pos.y,4) < 1.1) ? 1 : 0;
                fixed3 fill = fixed3(.3, .38, .58) + fixed3(1,1,1)*0.1*pixgrid;
                fixed3 col = tex2D(_MainTex, i.uv).rgb;
                float2 pos = (i.uv.xy - float2(.5,.5));
                pos.x /= (1 - .5*pos.y*pos.y);
                float dist = dist2hud(pos);
                col = (dist < 0) ? lerp(fixed3(1,1,1), fill, smoothstep(0.0005,0.002, -dist))
                                 : lerp(fixed3(1,1,1), col, smoothstep(0.0005,0.002, dist));
                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
