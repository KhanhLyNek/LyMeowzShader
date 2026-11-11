#version 330 compatibility
// ============================================================================
//  Pass 2 - FOG
//  Distance haze above water. Under the surface: absorption, scattering and
//  caustics on everything below eye level.
// ============================================================================
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow_distort.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadow.glsl"
#include "/lib/waves.glsl"
#include "/lib/depth.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
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

    vec3 P = viewPosAt(texcoord, depth);
    float dist = length(P);

    mat3 toWorld = mat3(gbufferModelViewInverse);
    vec3 dirW = normalize(toWorld * normalize(P));
    vec3 sunDirW = normalize(toWorld * sunPosition);
    vec3 lightDirW = normalize(toWorld * shadowLightPosition);
    float day = dayFactor(sunDirW);
    float rain = rainStrength;

    if (isEyeInWater == 1)
    {
        float d = (depth >= 1.0) ? 96.0 : dist;
        float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;

#ifdef WATER_CAUSTICS
        // The surface height is unknown here, so treat everything below eye level as
        // submerged (it is: the eye itself is under water) and fade out above it.
        if (depth < 1.0)
        {
            vec3 feet = (gbufferModelViewInverse * vec4(P, 1.0)).xyz;   // camera-relative
            vec3 nW = toWorld * normalFromDepth(depthtex0, texcoord);

            float below = smoothstep(0.6, -0.6, feet.y);
            float vDepth = max(-feet.y, 0.0) + 1.0;
            float gate = day * (1.0 - rain) * smoothstep(0.5, 0.9, eyeSky)
                       * smoothstep(0.05, 0.30, lightDirW.y) * below
                       * (0.3 + 0.7 * saturate(nW.y)) * exp(-vDepth * 0.12);
            if (gate > 0.01)
            {
                gate *= shadowVisibility(feet, nW, max(dot(nW, lightDirW), 0.1), ign(gl_FragCoord.xy, 0));
                vec2 bp = feet.xz + cameraPosition.xz
                        - lightDirW.xz / max(lightDirW.y, 0.25) * vDepth * 0.6;
                color *= 1.0 + causticPattern(bp, frameTimeCounter) * 2.2 * WATER_CAUSTICS_STRENGTH * gate;
            }
        }
#endif

        // Everything is seen through the water column
        vec3 k = waterAbsorption() / WATER_CLARITY;
        vec3 transmit = exp(-d * k);
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
