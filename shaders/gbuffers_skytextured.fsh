#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform int renderStage;
uniform float rainStrength;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main()
{
    vec4 c = texture(gtexture, texcoord) * glcolor;
    vec3 col = toLinear(c.rgb);

    // Sun and moon sprites are drawn in HDR so they bloom out of the sky
    float boost = 3.0;
#ifdef MC_RENDER_STAGE_SUN
    boost = (renderStage == MC_RENDER_STAGE_SUN) ? 7.0 : 1.6;
#endif
    outColor = vec4(col * boost * (1.0 - 0.7 * rainStrength), c.a);
}
