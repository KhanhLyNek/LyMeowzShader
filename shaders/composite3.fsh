#version 330 compatibility
// ============================================================================
//  Bloom 2/4 - vertical blur (narrow). Keeps a copy of the narrow glow in
//  colortex6 for the final pass.
// ============================================================================
#include "/lib/settings.glsl"

uniform sampler2D colortex5;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 5,6 */
layout(location = 0) out vec4 outWide;
layout(location = 1) out vec4 outNarrow;

void main()
{
#ifdef BLOOM
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec2 stepVec = vec2(0.0, texel.y) * max(viewHeight / 1080.0, 1.0);

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++)
    {
        float w = exp(-float(i * i) / 18.0);
        sum += texture(colortex5, texcoord + stepVec * float(i)).rgb * w;
        wsum += w;
    }
    vec4 blurred = vec4(sum / wsum, 1.0);
    outWide = blurred;
    outNarrow = blurred;
#else
    outWide = vec4(0.0);
    outNarrow = vec4(0.0);
#endif
}
