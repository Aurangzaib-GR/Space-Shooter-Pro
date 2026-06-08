Shader "UI/ImageBorderDetection"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        
        [Header(Border Detection)]
        _EdgeThreshold ("Edge Detection Threshold", Range(0.01, 0.5)) = 0.1
        _SampleDistance ("Sample Distance", Range(0.001, 0.05)) = 0.01
        
        [Header(Glow Settings)]
        _BorderColor ("Border Color", Color) = (0.3, 0.85, 1.0, 1.0)
        _GlowIntensity ("Glow Intensity", Range(0, 15)) = 8.0
        _GlowWidth ("Glow Width", Range(0.005, 0.1)) = 0.03
        _GlowFalloff ("Glow Falloff", Range(0.5, 4)) = 1.5
        
        [Header(Moving Light)]
        _LightIntensity ("Light Intensity", Range(0, 15)) = 8.0
        _LightWidth ("Light Width", Range(0.05, 0.5)) = 0.25
        _AnimationSpeed ("Animation Speed", Range(0, 3)) = 0.6
        _EnableAnimation ("Enable Animation", Float) = 1
        
        [Header(UI)]
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }
    
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
        
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
        
        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            
            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            fixed4 _Color;
            fixed4 _BorderColor;
            float _EdgeThreshold;
            float _SampleDistance;
            float _GlowIntensity;
            float _GlowWidth;
            float _GlowFalloff;
            float _LightIntensity;
            float _LightWidth;
            float _AnimationSpeed;
            float _EnableAnimation;
            float4 _ClipRect;
            
            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.color = v.color * _Color;
                return OUT;
            }
            
            float detectEdge(float2 uv)
            {
                float center = tex2D(_MainTex, uv).a;
                
                float2 offsets[8] = {
                    float2(-1, 0),  float2(1, 0),
                    float2(0, -1),  float2(0, 1),
                    float2(-0.707, -0.707), float2(0.707, 0.707),
                    float2(-0.707, 0.707),  float2(0.707, -0.707)
                };
                
                float maxDiff = 0.0;
                for(int i = 0; i < 8; i++)
                {
                    float2 sampleUV = uv + offsets[i] * _SampleDistance;
                    float sample = tex2D(_MainTex, sampleUV).a;
                    maxDiff = max(maxDiff, abs(center - sample));
                }
                
                return step(_EdgeThreshold, maxDiff);
            }
            
            float calculateGlow(float2 uv, float edgeValue)
            {
                if(edgeValue < 0.5) return 0.0;
                
                float glow = 0.0;
                int samples = 5;
                
                for(int i = 1; i <= samples; i++)
                {
                    float dist = float(i) / float(samples) * _GlowWidth;
                    
                    float2 offsets[8] = {
                        float2(-1, 0),  float2(1, 0),
                        float2(0, -1),  float2(0, 1),
                        float2(-0.707, -0.707), float2(0.707, 0.707),
                        float2(-0.707, 0.707),  float2(0.707, -0.707)
                    };
                    
                    for(int j = 0; j < 8; j++)
                    {
                        float2 sampleUV = uv + offsets[j] * dist;
                        float edge = detectEdge(sampleUV);
                        float falloff = pow(1.0 - (float(i) / float(samples)), _GlowFalloff);
                        glow += edge * falloff;
                    }
                }
                
                return glow / (float(samples) * 8.0);
            }
            
            float calculatePerimeter(float2 uv)
            {
                float2 centered = (uv - 0.5) * 2.0;
                float angle = atan2(centered.y, centered.x);
                float normalized = (angle / 3.14159265359 + 1.0) * 0.5;
                return normalized;
            }
            
            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 texColor = tex2D(_MainTex, IN.texcoord);
                fixed4 color = texColor * IN.color;
                
                float edge = detectEdge(IN.texcoord);
                float glow = calculateGlow(IN.texcoord, edge) * _GlowIntensity;
                
                float movingLight = 0.0;
                if(_EnableAnimation > 0.5)
                {
                    float perimeter = calculatePerimeter(IN.texcoord);
                    float time = frac(_Time.y * _AnimationSpeed);
                    float dist = abs(perimeter - time);
                    dist = min(dist, 1.0 - dist);
                    movingLight = smoothstep(_LightWidth, 0.0, dist) * _LightIntensity;
                }
                
                float totalGlow = (glow + movingLight * edge);
                fixed4 glowColor = _BorderColor * totalGlow;
                
                color.rgb += glowColor.rgb;
                color.a = saturate(color.a + glowColor.a);
                
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                
                return color;
            }
            ENDCG
        }
    }
}
