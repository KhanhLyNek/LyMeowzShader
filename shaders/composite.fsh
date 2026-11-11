#version 330 compatibility
// ============================================================================
//  Pass 1 - WATER SHADING
//  Reads the wave normal written by gbuffers_water and builds the whole look:
//  refraction, depth absorption, caustics, Fresnel sky + screen-space
//  reflections, sun glitter and shoreline foam.
// ============================================================================
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow_distort.glsl"
#include "/lib/sky.glsl"
#include "/lib/clouds.glsl"
#include "/lib/shadow.glsl"
#include "/lib/waves.glsl"
#include "/lib/depth.glsl"

uniform sampler2D colortex0;   // lit scene (HDR)
uniform sampler2D colortex3;   // water: view-space normal, a = water flag
uniform sampler2D colortex4;   // water: r = sky light
uniform sampler2D depthtex0;   // depth including translucents
uniform sampler2D depthtex1;   // opaque-only depth

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int isEyeInWater;

in vec2 texcoord;

// Render-target formats. Iris reads these straight from the source text, so they live inside
// comments: the format names (RGBA16F ...) are not GLSL identifiers and must not be compiled.
/*const int colortex0Format = RGBA16F;*/
/*const int colortex3Format = RGBA16F;*/
/*const int colortex4Format = RGBA8;*/

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

// Screen-space reflection. origin/dir in view space. Returns (colour, confidence).
vec4 traceSSR(vec3 origin, vec3 dir, float jitter)
{
    const int N = WATER_SSR_STEPS;
    float prevDist = 0.0;

    for (int i = 0; i < N; i++)
    {
        // distances grow geometrically from 0.25 m to about 120 m
        float dist = 0.25 * pow(480.0, (float(i) + jitter) / float(N));
        vec3 p = origin + dir * dist;

        vec4 clip = gbufferProjection * vec4(p, 1.0);
        if (clip.w < 0.05) break;
        vec2 suv = clip.xy / clip.w * 0.5 + 0.5;
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) break;

        float sd = texture(depthtex1, suv).r;
        // skip sky, and anything that sits underneath another water surface
        if (sd < 1.0 && texture(colortex3, suv).a < 0.5)
        {
            float sceneZ = viewPosAt(suv, sd).z;
            float diff = sceneZ - p.z;   // > 0: the ray is now behind the surface
            if (diff > 0.0 && diff < (dist - prevDist) * 1.25 + 0.15)
            {
                // refine the hit with a few bisection steps
                float lo = prevDist;
                float hi = dist;
                for (int j = 0; j < 5; j++)
                {
                    float mid = 0.5 * (lo + hi);
                    vec3 pm = origin + dir * mid;
                    vec4 cm = gbufferProjection * vec4(pm, 1.0);
                    vec2 muv = cm.xy / cm.w * 0.5 + 0.5;
                    float msd = texture(depthtex1, muv).r;
                    float mz = viewPosAt(muv, msd).z;
                    if (msd < 1.0 && mz - pm.z > 0.0) hi = mid; else lo = mid;
                }
                vec3 ph = origin + dir * hi;
                vec4 ch = gbufferProjection * vec4(ph, 1.0);
                vec2 huv = clamp(ch.xy / ch.w * 0.5 + 0.5, vec2(0.0), vec2(1.0));

                float border = min(min(huv.x, 1.0 - huv.x), min(huv.y, 1.0 - huv.y));
                float fade = smoothstep(0.0, 0.08, border) * (1.0 - smoothstep(0.6, 1.0, hi / 120.0));
                return vec4(texture(colortex0, huv).rgb, fade);
            }
        }
        prevDist = dist;
    }
    return vec4(0.0);
}

void main()
{
    vec2 uv = texcoord;
    vec3 scene = texture(colortex0, uv).rgb;
    vec4 wn = texture(colortex3, uv);

    // Not water: nothing to do
    if (wn.a < 0.5)
    {
        outColor = vec4(scene, 1.0);
        return;
    }

    float depth0 = texture(depthtex0, uv).r;
    float depth1 = texture(depthtex1, uv).r;
    vec3 P = viewPosAt(uv, depth0);             // water surface
    vec3 V = normalize(-P);
    vec3 N = normalize(wn.xyz);
    float skylight = texture(colortex4, uv).r;

    mat3 toWorld = mat3(gbufferModelViewInverse);
    vec3 sunDirW = normalize(toWorld * sunPosition);
    vec3 lightDirW = normalize(toWorld * shadowLightPosition);
    float day = dayFactor(sunDirW);
    float rain = rainStrength;
    float noise = ign(gl_FragCoord.xy, 0);
    float t = frameTimeCounter;

    float lightAmt = (0.06 + 1.1 * day) * (0.2 + 0.8 * skylight);
    vec3 scatterCol = waterScatterColor() * lightAmt * 2.0;

    vec3 color;

    if (isEyeInWater == 1)
    {
        // ---- Water surface seen from below: Snell's window + total internal reflection
        float cosT = saturate(dot(N, V));
        vec3 refr = refract(-V, N, 1.33);
        vec3 under = scatterCol * 0.8;
        if (dot(refr, refr) < 0.001)
        {
            color = under;
        }
        else
        {
            vec3 skyCol = skyWithClouds(normalize(toWorld * refr), sunDirW, rain, t) * 0.9;
            float F = 0.02 + 0.98 * pow(1.0 - cosT, 5.0);
            color = mix(skyCol, under, saturate(F * 3.0));
        }
    }
    else
    {
        // ---- Water surface seen from above ---------------------------------------
        vec3 flatN = normalize(mat3(gbufferModelView) * vec3(0.0, 1.0, 0.0));
        vec3 bed0 = viewPosAt(uv, depth1);
        float wd0 = (depth1 >= 1.0) ? 24.0 : max(distance(bed0, P), 0.0);

        // Refraction: bend the lookup by how much the wave normal differs from flat water
        vec2 off = (N - flatN).xy;
        off *= 0.06 * WATER_REFRACTION * saturate(wd0 * 0.35 + 0.1) / (1.0 + 0.03 * length(P));
        vec2 ruv = clamp(uv + off, vec2(0.002), vec2(0.998));
        float d1r = texture(depthtex1, ruv).r;
        // never pull in something that is in front of the water, or sky behind a solid floor
        if ((d1r < 1.0 && viewPosAt(ruv, d1r).z > P.z + 0.02) || (d1r >= 1.0 && depth1 < 1.0))
        {
            ruv = uv;
            d1r = depth1;
        }

        vec3 bedP = viewPosAt(ruv, d1r);
        float pathLen = (d1r >= 1.0) ? 24.0 : max(distance(bedP, P), 0.0);
        vec3 bedColor = (d1r >= 1.0) ? vec3(0.0) : texture(colortex0, ruv).rgb;

        vec3 surfFeet = (gbufferModelViewInverse * vec4(P, 1.0)).xyz;

#ifdef WATER_CAUSTICS
        if (d1r < 1.0)
        {
            vec3 bedFeet = (gbufferModelViewInverse * vec4(bedP, 1.0)).xyz;
            float vDepth = max(surfFeet.y - bedFeet.y, 0.0);

            // floors catch caustics, walls much less
            vec3 bedN = toWorld * normalFromDepth(depthtex1, ruv);
            float gate = day * (1.0 - rain) * smoothstep(0.5, 0.9, skylight)
                       * smoothstep(0.05, 0.30, lightDirW.y) * exp(-vDepth * 0.18)
                       * (0.3 + 0.7 * saturate(bedN.y));
            if (gate > 0.01)
            {
                gate *= shadowVisibility(bedFeet, bedN, max(dot(bedN, lightDirW), 0.1), noise);
                // the pattern slides with depth because the light is refracted at an angle
                vec2 bp = bedFeet.xz + cameraPosition.xz
                        - lightDirW.xz / max(lightDirW.y, 0.25) * vDepth * 0.6;
                float c = causticPattern(bp, t);
                bedColor *= 1.0 + c * 2.2 * WATER_CAUSTICS_STRENGTH * gate;
            }
        }
#endif

        // Beer-Lambert absorption (red vanishes first) plus light scattered back to the eye
        vec3 k = waterAbsorption() / WATER_CLARITY;
        vec3 transmit = exp(-pathLen * k);
        float scat = 1.0 - exp(-pathLen * 0.28 / WATER_CLARITY);
        vec3 refracted = bedColor * transmit + scatterCol * scat;

        // Fresnel reflection: sky first, screen-space hits on top
        float NdotV = saturate(dot(N, V));
        float F = 0.02 + 0.98 * pow(1.0 - NdotV, 5.0);

        vec3 R = reflect(-V, N);
        vec3 Rw = toWorld * R;
        float skyGate = mix(0.06, 1.0, smoothstep(0.15, 0.85, skylight));
        vec3 reflCol = skyWithClouds(normalize(vec3(Rw.x, max(Rw.y, 0.01), Rw.z)), sunDirW, rain, t) * skyGate;

#ifdef WATER_REFLECTIONS
        if (Rw.y > 0.02)
        {
            vec4 ssr = traceSSR(P, R, noise);
            reflCol = mix(reflCol, ssr.rgb, ssr.a);
        }
#endif

        // Sun / moon glitter: GGX lobe on a very smooth surface
        vec3 L = normalize(shadowLightPosition);
        vec3 H = normalize(L + V);
        float NdotH = saturate(dot(N, H));
        float VdotH = saturate(dot(V, H));
        float a2 = 0.0025;
        float dd = NdotH * NdotH * (a2 - 1.0) + 1.0;
        float D = a2 / (PI * dd * dd);
        float Fh = 0.02 + 0.98 * pow(1.0 - VdotH, 5.0);
        float spec = min(D * Fh * 0.25 / max(NdotV, 0.05), 40.0);
        vec3 lightCol = (sunLightColor(sunDirW) * (SUN_INTENSITY * 2.6) + moonLightColor(sunDirW))
                      * (1.0 - 0.85 * rain);
        vec3 specCol = lightCol * spec * smoothstep(0.5, 0.9, skylight) * saturate(dot(N, L) * 4.0);

        color = refracted * (1.0 - F) + reflCol * F + specCol;

#ifdef WATER_FOAM
        // Shoreline foam: where the water is shallow, broken up by moving noise
        vec3 bed0Feet = (gbufferModelViewInverse * vec4(bed0, 1.0)).xyz;
        float vd0 = (depth1 >= 1.0) ? 10.0 : max(surfFeet.y - bed0Feet.y, 0.0);
        float foamZone = smoothstep(0.6, 0.0, vd0);
        if (foamZone > 0.001)
        {
            vec2 fp = surfFeet.xz + cameraPosition.xz;
            float fn = vnoise(fp * 2.4 + vec2(t * 0.22, -t * 0.17)) * 0.6
                     + vnoise(fp * 6.0 - vec2(t * 0.30, t * 0.10)) * 0.4;
            float foam = foamZone * smoothstep(0.38, 0.70, fn + foamZone * 0.4);
            vec3 foamCol = vec3(0.92, 0.95, 1.0) * (0.08 + 2.0 * day)
                         * (0.25 + 0.75 * skylight) * (1.0 - 0.5 * rain);
            color = mix(color, foamCol, foam * 0.8);
        }
#endif
    }

    outColor = vec4(color, 1.0);
}
