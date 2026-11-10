#version 330 compatibility
// ============================================================================
//  Final pass - tonemap, colour grade, vignette
// ============================================================================
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex0;
uniform int frameCounter;

in vec2 texcoord;

layout(location = 0) out vec4 outColor;

// Filmic curve: soft toe, gentle shoulder
vec3 filmic(vec3 x)
{
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main()
{
    vec3 c = texture(colortex0, texcoord).rgb;

    c *= 0.5 * EXPOSURE;
    c = filmic(c);
    c = toGamma(c);

    float l = luma(c);
    c = mix(vec3(l), c, SATURATION);

#ifdef VIGNETTE
    vec2 d = texcoord - 0.5;
    c *= 1.0 - dot(d, d) * 0.55;
#endif

    // a touch of dither to hide banding in the sky and water gradients
    c += (ign(gl_FragCoord.xy, frameCounter) - 0.5) / 255.0;

    outColor = vec4(c, 1.0);
}
