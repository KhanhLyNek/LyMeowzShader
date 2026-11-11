// Procedural 2-D cloud layer, drawn into the sky and reflected by water.
// Needs settings, common and sky included first.

float cloudFbm(vec2 p)
{
    const mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    float f = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++)
    {
        f += a * vnoise(p);
        p = rot * p * 2.03 + 11.7;
        a *= 0.5;
    }
    return f / 0.9375;
}

// rgb = cloud colour, a = coverage. dir/sunDir are world-space.
vec4 cloudLayer(vec3 dir, vec3 sunDir, float rain, float time)
{
#ifdef PROCEDURAL_CLOUDS
    if (dir.y < 0.02) return vec4(0.0);

    vec2 uv = dir.xz / (dir.y + 0.15) * 0.6 + vec2(time * 0.010, time * 0.004);
    float n = cloudFbm(uv);

    float coverage = clamp(CLOUD_COVERAGE + rain * 0.25, 0.0, 0.95);
    float density = smoothstep(1.0 - coverage, 1.0 - coverage + 0.30, n);
    if (density <= 0.001) return vec4(0.0);

    // cheap self-shadowing: is the cloud thicker on the sun's side of this point?
    vec2 toSun = normalize(sunDir.xz + vec2(1e-4)) * 0.07;
    float n2 = cloudFbm(uv + toSun);
    float lit = saturate(0.65 - (n2 - n) * 2.4);

    float day = dayFactor(sunDir);
    vec3 ambient = mix(vec3(0.02, 0.03, 0.06), vec3(0.50, 0.58, 0.70), day);
    vec3 sunCol = sunLightColor(sunDir) * 1.2 + moonLightColor(sunDir) * 2.0;
    vec3 col = ambient + sunCol * lit * (1.0 - 0.45 * density);
    col *= 1.0 - 0.5 * rain;

    float fade = smoothstep(0.02, 0.22, dir.y);   // thin out towards the horizon
    return vec4(col, density * fade * 0.95);
#else
    return vec4(0.0);
#endif
}

vec3 skyWithClouds(vec3 dir, vec3 sunDir, float rain, float time)
{
    vec3 sky = skyColor(dir, sunDir, rain);
    vec4 c = cloudLayer(dir, sunDir, rain, time);
    return mix(sky, c.rgb, c.a);
}
