#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow_distort.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadow.glsl"
#include "/lib/lighting.glsl"
#include "/lib/waves.glsl"

uniform sampler2D gtexture;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int frameCounter;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normalV;
in vec3 feetPos;
in float isWater;

// 0: colour (glass, ice, slime ...)  3: water normal + flag  4: water sky-light + flag
/* RENDERTARGETS: 0,3,4 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outWaterNormal;
layout(location = 2) out vec4 outWaterData;

void main()
{
    float noise = ign(gl_FragCoord.xy, frameCounter);

    // ---- Everything translucent that is not water: ordinary lit, blended -------
    if (isWater < 0.5)
    {
        vec4 col = texture(gtexture, texcoord) * glcolor;
        vec3 lit = lightSurface(toLinear(col.rgb), normalize(normalV), lmcoord, feetPos, noise);
        outColor = vec4(lit, col.a);
        outWaterNormal = vec4(0.0);
        outWaterData = vec4(0.0);
        return;
    }

    // ---- Water: only write the wave normal; shading happens in composite -------
    float t = frameTimeCounter;
    mat3 toWorld = mat3(gbufferModelViewInverse);

    vec3 viewDirW = normalize(feetPos);                 // camera -> surface
    vec3 baseNW = normalize(toWorld * normalize(normalV));
    vec2 p = feetPos.xz + cameraPosition.xz;
    float dist = length(feetPos);

#ifdef WATER_PARALLAX
    if (abs(baseNW.y) > 0.5 && viewDirW.y < 0.0)
        p = waveParallax(p, viewDirW, t);
#endif

    // Smaller waves would shimmer in the distance, so flatten them gradually
    float detailFade = 1.0 - 0.8 * smoothstep(24.0, 120.0, dist);
    vec2 grad = waveGradient(p, t) * detailFade;

#ifdef RAIN_RIPPLES
    float rippleAmount = rainStrength * smoothstep(0.85, 1.0, lmcoord.y);
    if (rippleAmount > 0.01)
        grad += rainRipples(p, t) * rippleAmount;
#endif

    vec3 nW = baseNW;
    if (abs(baseNW.y) > 0.5)
        nW = normalize(vec3(baseNW.x - grad.x, baseNW.y, baseNW.z - grad.y));

    // always face the viewer (matters when looking up from underwater)
    if (dot(nW, viewDirW) > 0.0) nW = -nW;

    vec3 nV = normalize(mat3(gbufferModelView) * nW);

    outColor = vec4(0.0);                       // alpha 0: leaves the scene untouched
    outWaterNormal = vec4(nV, 1.0);
    outWaterData = vec4(lmcoord.y, 0.0, 0.0, 1.0);
}
