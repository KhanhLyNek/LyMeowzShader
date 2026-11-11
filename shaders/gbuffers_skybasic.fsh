#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/clouds.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform int renderStage;

in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main()
{
    mat3 toWorld = mat3(gbufferModelViewInverse);
    vec3 sunDirW = normalize(toWorld * sunPosition);

#ifdef MC_RENDER_STAGE_STARS
    if (renderStage == MC_RENDER_STAGE_STARS)
    {
        float night = 1.0 - dayFactor(sunDirW);
        outColor = vec4(glcolor.rgb * 3.0 * night * (1.0 - rainStrength), glcolor.a);
        return;
    }
#endif

    vec3 ndc = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0) * 2.0 - 1.0;
    vec4 vp = gbufferProjectionInverse * vec4(ndc, 1.0);
    vec3 dirW = normalize(toWorld * normalize(vp.xyz / vp.w));

    outColor = vec4(skyWithClouds(dirW, sunDirW, rainStrength, frameTimeCounter), 1.0);
}
