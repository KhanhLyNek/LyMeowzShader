// Sun/moon shadow lookup. Fragment shaders only.
// Needs settings, common and shadow_distort included first.

uniform sampler2D shadowtex1;   // opaque-only depth: water and glass never shadow
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// feetPos : camera-relative world position of the surface
// normalW : world-space surface normal
// NdotL   : cosine to the light (used for slope-scaled offset)
// noise   : 0..1 per-pixel random, rotates the sampling pattern
float shadowVisibility(vec3 feetPos, vec3 normalW, float NdotL, float noise)
{
    // Size of one shadow texel in the world at this location (after distortion)
    vec4 clip0 = shadowProjection * (shadowModelView * vec4(feetPos, 1.0));
    float f = length(clip0.xy) * SHADOW_DISTORT + (1.0 - SHADOW_DISTORT);
    float texel = (2.0 * shadowDistance / float(shadowMapResolution)) * f * f / (1.0 - SHADOW_DISTORT);

    // Push the lookup point out along the normal to fight acne
    float offsetLen = clamp(texel * 1.4 * (1.2 - NdotL * 0.7), 0.02, 0.45);
    vec3 pos = feetPos + normalW * offsetLen;

    vec4 clip = shadowProjection * (shadowModelView * vec4(pos, 1.0));
    vec3 ndc = clip.xyz / clip.w;
    ndc.xy = distortShadow(ndc.xy);
    vec3 sc = ndc * 0.5 + 0.5;

    if (sc.x < 0.0 || sc.x > 1.0 || sc.y < 0.0 || sc.y > 1.0 || sc.z >= 1.0 || sc.z < 0.0)
        return 1.0;

    const int TAPS = 8;
    float radius = SHADOW_SOFTNESS * 1.6 / float(shadowMapResolution);
    float bias = 0.0005;

    float sum = 0.0;
    for (int i = 0; i < TAPS; i++)
    {
        float r = sqrt((float(i) + 0.5) / float(TAPS));
        float a = float(i) * 2.39996323 + noise * TAU;
        vec2 o = vec2(cos(a), sin(a)) * r * radius;
        float d = texture(shadowtex1, sc.xy + o).r;
        sum += step(sc.z - bias, d);
    }
    float vis = sum / float(TAPS);

    // fade out towards the edge of the shadow map
    float edge = max(abs(ndc.x), abs(ndc.y));
    return mix(1.0, vis, 1.0 - smoothstep(0.85, 1.0, edge));
}
