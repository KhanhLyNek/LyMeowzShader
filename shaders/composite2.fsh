#version 330 compatibility
// ============================================================================
//  Bloom 1/4 - bright pass + horizontal blur (narrow)
//  Only HDR values above BLOOM_THRESHOLD glow: sun glitter on water, the sun,
//  lava, torches in the dark.
// ============================================================================
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 outColor;

vec3 brightPass(vec3 c)
{
    float l = luma(c);
    float k = max(l - BLOOM_THRESHOLD, 0.0) / max(l, 1e-4);
    return min(c * k, vec3(30.0));
}

void main()
{
#ifdef BLOOM
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec2 stepVec = vec2(texel.x, 0.0) * max(viewHeight / 1080.0, 1.0);

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++)
    {
        float w = exp(-float(i * i) / 18.0);
        sum += brightPass(texture(colortex0, texcoord + stepVec * float(i)).rgb) * w;
        wsum += w;
    }
    outColor = vec4(sum / wsum, 1.0);
#else
    outColor = vec4(0.0);
#endif
}
