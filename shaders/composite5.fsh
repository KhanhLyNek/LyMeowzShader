#version 330 compatibility
// ============================================================================
//  Bloom 4/4 - vertical blur with a wide stride (soft halo)
// ============================================================================
#include "/lib/settings.glsl"

uniform sampler2D colortex5;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 outColor;

void main()
{
#ifdef BLOOM
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec2 stepVec = vec2(0.0, texel.y) * 3.0 * max(viewHeight / 1080.0, 1.0);

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++)
    {
        float w = exp(-float(i * i) / 18.0);
        sum += texture(colortex5, texcoord + stepVec * float(i)).rgb * w;
        wsum += w;
    }
    outColor = vec4(sum / wsum, 1.0);
#else
    outColor = vec4(0.0);
#endif
}
