// Forward lighting used by all lit gbuffer programs (terrain, entities, hand, glass...).
// Include order: settings, common, shadow_distort, sky, shadow, lighting.

uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;   // sun by day, moon by night (view space)
uniform vec3 sunPosition;           // view space
uniform float rainStrength;

// albedo  : linear colour
// normalV : view-space normal
// lm      : (blocklight, skylight) in 0..1
// feetPos : camera-relative world position
// noise   : 0..1 per-pixel random
vec3 lightSurface(vec3 albedo, vec3 normalV, vec2 lm, vec3 feetPos, float noise)
{
    mat3 toWorld = mat3(gbufferModelViewInverse);
    vec3 sunDirW = normalize(toWorld * sunPosition);
    vec3 lightDirV = normalize(shadowLightPosition);
    vec3 normalW = normalize(toWorld * normalV);

    float NdotL = max(dot(normalV, lightDirV), 0.0);

    float skyGate = smoothstep(0.25, 0.85, lm.y);   // no sunlight leaking into caves
    float vis = 1.0;
#ifdef SHADOWS
    if (NdotL > 0.0 && skyGate > 0.0)
        vis = shadowVisibility(feetPos, normalW, NdotL, noise);
#endif
    vis *= skyGate;

    vec3 sunCol = sunLightColor(sunDirW) * (SUN_INTENSITY * 2.6) + moonLightColor(sunDirW);
    sunCol *= 1.0 - 0.85 * rainStrength;
    vec3 direct = sunCol * (NdotL * vis);

    vec3 ambient = ambientLight(normalW, sunDirW, rainStrength)
                 * (0.04 + 0.96 * pow(lm.y, 2.2)) * 0.8;
    ambient += vec3(MIN_LIGHT);

    float tl = max(lm.x - 0.06, 0.0) / 0.94;
    vec3 torch = vec3(1.0, 0.56, 0.26) * (tl * tl * tl) * (TORCH_INTENSITY * 2.2);

    return albedo * (direct + ambient + torch);
}
