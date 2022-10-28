Shader "Custom/ColorGlitch"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        _SecondTex ("iChannel1", 2D) = "white" {}
        _ThirdTex ("iChannel2", 2D) = "white" {}
        _FourthTex ("iChannel3", 2D) = "white" {}
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
    }
    SubShader
    {
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
            };

            // Built-in properties
            sampler2D _MainTex;   float4 _MainTex_TexelSize;
            sampler2D _SecondTex; float4 _SecondTex_TexelSize;
            sampler2D _ThirdTex;  float4 _ThirdTex_TexelSize;
            sampler2D _FourthTex; float4 _FourthTex_TexelSize;
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define textureLod(ch, uv, lod) tex2Dlod(ch, float4(uv, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)
            #define iFrame (floor(_Time.y / 60))
            #define iChannelTime float4(_Time.y, _Time.y, _Time.y, _Time.y)
            #define iDate float4(2020, 6, 18, 30)
            #define iSampleRate (44100)
            #define iChannelResolution float4x4(                      \
                _MainTex_TexelSize.z,   _MainTex_TexelSize.w,   0, 0, \
                _SecondTex_TexelSize.z, _SecondTex_TexelSize.w, 0, 0, \
                _ThirdTex_TexelSize.z,  _ThirdTex_TexelSize.w,  0, 0, \
                _FourthTex_TexelSize.z, _FourthTex_TexelSize.w, 0, 0)

            // Global access to uv data
            static v2f vertex_output;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            float2 hash22(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return -1.+2.*frac(sin(p)*43758.547);
            }

            float perlin_noise(float2 p)
            {
                float2 pi = floor(p);
                float2 pf = p-pi;
                float2 w = pf*pf*(3.-2.*pf);
                return lerp(lerp(dot(hash22(pi+float2(0., 0.)), pf-float2(0., 0.)), dot(hash22(pi+float2(1., 0.)), pf-float2(1., 0.)), w.x), lerp(dot(hash22(pi+float2(0., 1.)), pf-float2(0., 1.)), dot(hash22(pi+float2(1., 1.)), pf-float2(1., 1.)), w.x), w.y);
            }

            float4 frag (v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                float4 fragColor = 0;
                float2 fragCoord = vertex_output.uv * _Resolution;
                float2 uv = fragCoord/iResolution.xy;
                float noiseScale = 0.05;
                float threshold = noiseScale*0.2;
                float frequency = 8.;
                float noiseX = noiseScale*perlin_noise(float2(_Time.y*frequency, 2));
                float noiseY = noiseScale*perlin_noise(float2(_Time.y*frequency, 3));
                float noiseZ = noiseScale*perlin_noise(float2(_Time.y*frequency, 4));
                float noiseW = noiseScale*perlin_noise(float2(_Time.y*frequency, 5));
                noiseX = noiseX>threshold ? noiseX : 0.;
                noiseY = noiseY>threshold ? noiseY : 0.;
                noiseZ = noiseZ>threshold ? noiseZ : 0.;
                noiseW = noiseW>threshold ? noiseW : 0.;
                float2 noise = float2(noiseX, noiseY);
                float2 shake = float2(noiseZ, noiseW);
                uv += shake;
                float r = tex2D(_MainTex, uv-noise).r;
                float g = tex2D(_MainTex, uv).g;
                float b = tex2D(_MainTex, uv+noise).b;
                fragColor = float4(r, g, b, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
