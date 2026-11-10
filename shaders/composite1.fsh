#version 330 compatibility
// ============================================================================
//  Pass 2 - FOG
//  Distance haze above water, absorption + scattering when the camera is
//  underneath the surface.
// ============================================================================
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/waves.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float far;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main()
{
    vec3 color = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).r;

    vec4 ndc = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 vp = gbufferProjectionInverse * ndc;
    vec3 P = vp.xyz / vp.w;
    float dist = length(P);

    mat3 toWorld = mat3(gbufferModelViewInverse);
    vec3 dirW = normalize(toWorld * normalize(P));
    vec3 sunDirW = normalize(toWorld * sunPosition);
    float day = dayFactor(sunDirW);
    float rain = rainStrength;

    if (isEyeInWater == 1)
    {
        // Everything is seen through the water column
        float d = (depth >= 1.0) ? 96.0 : dist;
        vec3 k = waterAbsorption() / WATER_CLARITY;
        vec3 transmit = exp(-d * k);

        float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;
        vec3 fogCol = waterScatterColor() * (0.06 + 1.1 * day) * (0.2 + 0.8 * eyeSky) * 2.0;
        float scat = 1.0 - exp(-d * 0.18 / WATER_CLARITY);

        color = color * transmit + fogCol * scat;
    }
    else if (depth < 1.0)
    {
        // Distance haze that melts terrain into the sky colour at the horizon
        float fd = dist / max(far, 64.0);
        float fog = max(smoothstep(0.6, 1.0, fd),
                        1.0 - exp(-dist * 0.0012 * (1.0 + 6.0 * rain)));
        vec3 fogCol = skyColor(normalize(vec3(dirW.x, 0.03, dirW.z)), sunDirW, rain);
        color = mix(color, fogCol, fog);
    }

    outColor = vec4(color, 1.0);
}
