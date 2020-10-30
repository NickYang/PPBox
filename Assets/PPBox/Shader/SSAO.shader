Shader "Hidden/SSAO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}

        _Radius("Raidus", float) = 2
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
                float4 viewPos: TEXTCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.viewPos.xyz = UnityObjectToViewPos(v.vertex);
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthNormalsTexture;
            sampler2D _NoiseTex;
            float _Radius;
            static const int SAMPLE_COUNT = 16;
            
             float3 sample_sphere[SAMPLE_COUNT] = {
                  float3( 0.5381, 0.1856,-0.4319), float3( 0.1379, 0.2486, 0.4430),
                  float3( 0.3371, 0.5679,-0.0057), float3(-0.6999,-0.0451,-0.0019),
                  float3( 0.0689,-0.1598,-0.8547), float3( 0.0560, 0.0069,-0.1843),
                  float3(-0.0146, 0.1402, 0.0762), float3( 0.0100,-0.1924,-0.0344),
                  float3(-0.3577,-0.5301,-0.4358), float3(-0.3169, 0.1063, 0.0158),
                  float3( 0.0103,-0.5869, 0.0046), float3(-0.0897,-0.4940, 0.3287),
                  float3( 0.7119,-0.0154,-0.0918), float3(-0.0533, 0.0596,-0.5411),
                  float3( 0.0352,-0.0631, 0.5460), float3(-0.4776, 0.2847,-0.0271)
              };

            float nrand(float2 uv, float dx, float dy)
            {
                uv += float2(dx, dy + _Time.x);
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            half HemisphereSample(half3 normal)
            {
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half depth;
                half3 normal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, normal);    

                //#if NOISE_ON
                float noiseSize = 2;
                // 对每个fragment做随机噪点增加相邻点的采样差异
                float3 randomVec = normalize(tex2D(_NoiseTex, i.uv).rgb);
                //#endif

                // TBN
                float3 tangent = normalize(randomVec - normal*dot(normal, randomVec));
                float3 bitangent = normalize(cross(tangent, normal));
                float3x3 TBN = float3x3(tangent, bitangent, normal);
                float finalOcc = 0;
                // 可以放在应用层先算好，也可以放在compute shader计算
                for(int cnt = 0; cnt < SAMPLE_COUNT; cnt++)
                {
                    //Normal-oriented Hemisphere
                    //float3 hemi_ray = HemisphereSample(normal, randomVec);

                    float3 samplePos_offset = mul(TBN, sample_sphere[cnt]);
                    float3 samplePos = i.viewPos.xyz + samplePos_offset*_Radius;
                    // view pos to screen pos
                    float4 clipPos = UnityViewToClipPos(samplePos);
                    float3 ndc = clipPos.xyz/clipPos.w;
                    float3 screenPos =  ndc*0.5 + 0.5;

                    half compareDepth;
                    half3 compareNormal;
                    DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, screenPos.xy), compareDepth, compareNormal);    
                    //float occ = samplePos.z <= LinearEyeDepth(compareDepth) ? 1.0 : 0.0;
                   // finalOcc  = finalOcc + occ;

                    float dist = samplePos.z - LinearEyeDepth(compareDepth);
      
                    finalOcc += (dist > 0.01 * _Radius);


                }

                  finalOcc = saturate(finalOcc  / SAMPLE_COUNT);
                fixed4 col = tex2D(_MainTex, i.uv);
                //col.xyz = 1.0 - col.xyz;
                //col.xyz = col.xyz + float3(finalOcc, finalOcc, finalOcc);
                col.xyz = float3(finalOcc, finalOcc, finalOcc);
                return col;
            }
            ENDCG
        }
    }
}
