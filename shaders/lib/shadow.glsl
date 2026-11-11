// Sun/moon shadow lookup. Fragment shaders only.
// Needs settings, common and shadow_distort included first.

uniform sampler2D shadowtex0;   // depth of everything, translucents included
uniform sampler2D shadowtex1;   // opaque-only depth: water and glass never block it
uniform sampler2D shadowcolor0; // white where opaque, glass colour where translucent
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// Light that reaches a point, as rgb: black = fully shadowed, white = fully lit, and tinted
// when the light has to pass through stained glass and similar translucent blocks.
//
// feetPos : camera-relative world position of the surface
// normalW : world-space surface normal
// NdotL   : cosine to the light (used for slope-scaled offset)
// noise   : 0..1 per-pixel random, rotates the sampling pattern
vec3 shadowLight(vec3 feetPos, vec3 normalW, float NdotL, float noise)
{
    // Size of one shadow texel in the world at this location (after distortion)
    vec4 clip0 = shadowProjection * (shadowModelView * vec4(feetPos, 1.0));
    float f = length(clip0.xy) * SHADOW_DISTORT + (1.0 - SHADOW_DISTORT);
    float texel = (2.0 * shadowDistance / float(shadowMapResolution)) * f * f / (1.0 - SHADOW_DISTORT);

    // Push the lookup point out along the normal to fight acne
    float offsetLen = clamp(texel * 1.4 * (1.2 - NdotL * 0.7) * SHADOW_NORMAL_OFFSET, 0.02, 0.6);
    vec3 pos = feetPos + normalW * offsetLen;

    vec4 clip = shadowProjection * (shadowModelView * vec4(pos, 1.0));
    vec3 ndc = clip.xyz / clip.w;
    ndc.xy = distortShadow(ndc.xy);
    vec3 sc = ndc * 0.5 + 0.5;

    if (sc.x < 0.0 || sc.x > 1.0 || sc.y < 0.0 || sc.y > 1.0 || sc.z >= 1.0 || sc.z < 0.0)
        return vec3(1.0);

    const int TAPS = 8;
    float radius = SHADOW_SOFTNESS * 1.6 / float(shadowMapResolution);

    vec3 sum = vec3(0.0);
    for (int i = 0; i < TAPS; i++)
    {
        float r = sqrt((float(i) + 0.5) / float(TAPS));
        float a = float(i) * 2.39996323 + noise * TAU;
        vec2 uv = sc.xy + vec2(cos(a), sin(a)) * r * radius;

        float litOpaque = step(sc.z - SHADOW_BIAS, texture(shadowtex1, uv).r);
#ifdef COLORED_SHADOWS
        // A translucent occluder is something that blocks shadowtex0 but not shadowtex1
        float litAll = step(sc.z - SHADOW_BIAS, texture(shadowtex0, uv).r);
        vec3 tint = mix(min(texture(shadowcolor0, uv).rgb, vec3(1.0)), vec3(1.0), litAll);
        sum += litOpaque * tint;
#else
        sum += vec3(litOpaque);
#endif
    }
    vec3 vis = sum / float(TAPS);

    // fade out towards the edge of the shadow map
    float edge = max(abs(ndc.x), abs(ndc.y));
    return mix(vec3(1.0), vis, 1.0 - smoothstep(0.85, 1.0, edge));
}

// Single-channel version for effects that only need "lit or not" (caustics)
float shadowVisibility(vec3 feetPos, vec3 normalW, float NdotL, float noise)
{
    vec3 v = shadowLight(feetPos, normalW, NdotL, noise);
    return dot(v, vec3(1.0 / 3.0));
}
