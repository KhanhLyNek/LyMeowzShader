// Procedural sky. All directions are in WORLD space (y up).
// Needs lib/common.glsl.

float dayFactor(vec3 sunDir)
{
    return smoothstep(-0.12, 0.22, sunDir.y);
}

// Colour of direct sunlight; warm near the horizon, fades out below it.
vec3 sunLightColor(vec3 sunDir)
{
    float elev = sunDir.y;
    vec3 low  = vec3(1.00, 0.42, 0.16);
    vec3 high = vec3(1.00, 0.93, 0.80);
    return mix(low, high, smoothstep(0.0, 0.40, elev)) * smoothstep(-0.05, 0.12, elev);
}

// Cool, dim moonlight (the moon is opposite the sun).
vec3 moonLightColor(vec3 sunDir)
{
    return vec3(0.28, 0.38, 0.62) * 0.12 * smoothstep(-0.05, 0.12, -sunDir.y);
}

vec3 skyColor(vec3 dir, vec3 sunDir, float rain)
{
    float day = dayFactor(sunDir);
    float up = clamp(dir.y, -1.0, 1.0);
    float horizonK = pow(1.0 - max(up, 0.0), 4.0);

    vec3 zenithDay    = vec3(0.09, 0.26, 0.68);
    vec3 horizonDay   = vec3(0.50, 0.68, 0.90);
    vec3 zenithNight  = vec3(0.004, 0.008, 0.026);
    vec3 horizonNight = vec3(0.012, 0.020, 0.050);

    vec3 zenith  = mix(zenithNight, zenithDay, day);
    vec3 horizon = mix(horizonNight, horizonDay, day);
    vec3 col = mix(zenith, horizon, horizonK);

    // Twilight band, strongest on the sun's side of the horizon
    float twilight = exp(-pow(sunDir.y * 4.0, 2.0));
    vec2 hs = normalize(sunDir.xz + vec2(1e-5));
    vec2 hd = normalize(dir.xz + vec2(1e-5));
    float toward = 0.5 + 0.5 * dot(hs, hd);
    vec3 twilightCol = mix(vec3(0.80, 0.42, 0.55), vec3(1.00, 0.38, 0.14), toward);
    col += twilightCol * twilight * pow(horizonK, 1.4) * (0.15 + 1.25 * toward * toward);

    // Forward-scattering glow around the sun (Henyey-Greenstein)
    float cosS = dot(dir, sunDir);
    float g = 0.78;
    float hg = (1.0 - g * g) / (4.0 * PI * pow(1.0 + g * g - 2.0 * g * cosS, 1.5));
    col += sunLightColor(sunDir) * hg * 0.30;

    // Faint moon halo
    float cosM = max(dot(dir, -sunDir), 0.0);
    col += moonLightColor(sunDir) * pow(cosM, 48.0) * 1.5;

    // Below the horizon fades to a dim haze
    col = mix(col, horizon * 0.45, smoothstep(0.0, 0.25, -up));

    // Overcast
    col = mix(col, vec3(luma(col)) * 0.8, rain * 0.7);
    col *= 1.0 - 0.35 * rain;
    return col;
}

// Hemispherical ambient light for a surface with world normal n.
vec3 ambientLight(vec3 n, vec3 sunDir, float rain)
{
    vec3 up = skyColor(vec3(0.0, 1.0, 0.0), sunDir, rain);
    vec3 hz = skyColor(normalize(vec3(n.x, 0.05, n.z) + vec3(1e-4, 0.0, 0.0)), sunDir, rain);
    float k = n.y * 0.5 + 0.5;
    return mix(hz * 0.55, up, k) * 0.9;
}
