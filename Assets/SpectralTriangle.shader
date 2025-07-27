Shader "Custom/SpectralTriangle"
{
    Properties
    {
        _ColorA ("Color A (Top)", Color) = (1,0,0,1)
        _ColorB ("Color B (Bottom Left)", Color) = (0,1,0,1)
        _ColorC ("Color C (Bottom Right)", Color) = (0,0,1,1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Packages/jp.keijiro.spectral-js-unity/Shaders/SpectralUnity.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            fixed4 _ColorA;
            fixed4 _ColorB;
            fixed4 _ColorC;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                
                // Calculate barycentric coordinates for the triangle
                // UV (0.5, 1) = top vertex (Color A)
                // UV (0, 0) = bottom left vertex (Color B)  
                // UV (1, 0) = bottom right vertex (Color C)
                
                float u = uv.x;
                float v = uv.y;
                
                // Barycentric coordinates
                float alpha = v;                    // Weight for Color A (top)
                float beta = (1.0 - v) * (1.0 - u); // Weight for Color B (bottom left)
                float gamma = (1.0 - v) * u;        // Weight for Color C (bottom right)
                
                // Normalize weights to ensure they sum to 1
                float total = alpha + beta + gamma;
                alpha /= total;
                beta /= total;
                gamma /= total;
                
                // Use SpectralMix for physically accurate color blending
                float3 result = SpectralMix(_ColorA.rgb, alpha, _ColorB.rgb, beta, _ColorC.rgb, gamma);
                
                return fixed4(result, 1.0);
            }
            ENDCG
        }
    }
    
    FallBack "Diffuse"
}