// Procedural water: wave height field, parallax, rain ripples, caustics, colours.
// Original implementation for LyMeowz Shader. Needs lib/settings.glsl + lib/common.glsl.

#define WAVE_SLOPE 0.28            // how steep the normal-map slopes are
#define WAVE_PARALLAX_METERS 0.12  // apparent wave height used for parallax

// ---- Height field --------------------------------------------------------------
// p = world xz (metres), t = seconds. Returns a unit-less height of roughly -0.2..0.4.
// Layered drifting ridged noise with domain warping: broad swells + choppy detail.
float waveHeight(vec2 p, float t)
{
    p *= WATER_WAVE_SCALE;
    t *= WATER_WAVE_SPEED;

    const mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    float h = 0.0;
    float amp = 0.5;
    float freq = 0.35;
    vec2 q = p;

    for (int i = 0; i < WATER_WAVE_DETAIL; i++)
    {
        float fi = float(i);
        vec2 dir = vec2(cos(fi * 1.9 + 0.4), sin(fi * 1.9 + 0.4));
        float n = vnoise(q * freq + dir * t * (0.35 + 0.12 * fi));
        float ridge = 1.0 - abs(2.0 * n - 1.0);
        h += (ridge * ridge - 0.35) * amp;
        q = rot * q + vec2(h * 0.6, -h * 0.4);
        freq *= 2.05;
        amp *= 0.5;
    }
    return h * WATER_WAVE_HEIGHT;
}

// dh/dx, dh/dz of the height field (forward differences), already scaled to slopes.
vec2 waveGradient(vec2 p, float t)
{
    const float e = 0.05;
    float h0 = waveHeight(p, t);
    float hx = waveHeight(p + vec2(e, 0.0), t);
    float hz = waveHeight(p + vec2(0.0, e), t);
    return vec2(hx - h0, hz - h0) * (WAVE_SLOPE / e);
}

// Parallax: where does the view ray actually meet the displaced surface?
// viewDirW points from the camera to the surface (y < 0 when looking down).
vec2 waveParallax(vec2 p, vec3 viewDirW, float t)
{
    float vy = min(viewDirW.y, -0.12);
    vec2 shift = viewDirW.xz / vy;
    vec2 q = p;
    for (int i = 0; i < 3; i++)
        q = p + shift * (waveHeight(q, t) * WAVE_PARALLAX_METERS);
    return q;
}

// ---- Rain ripples ---------------------------------------------------------------
// Expanding rings spawned at random points inside a grid. Returns a slope offset.
vec2 rainRipples(vec2 p, float t)
{
    vec2 grad = vec2(0.0);
    for (int layer = 0; layer < 2; layer++)
    {
        float fl = float(layer);
        vec2 pp = p * (2.2 + fl * 1.4) + fl * 17.0;
        vec2 cell = floor(pp);
        vec2 f = fract(pp);

        float seed = hash12(cell + fl * 31.0);
        float tt = t * (1.1 + 0.4 * fl) + seed * 11.0;
        float life = fract(tt);
        float cycle = floor(tt);

        vec2 c = vec2(hash12(cell + cycle * 7.13), hash12(cell * 1.37 + cycle * 3.71 + 5.0));
        c = 0.35 + 0.30 * c;

        vec2 d = f - c;
        float r = length(d) + 1e-4;
        float w = r - life * 0.34;

        float env = (1.0 - life);
        env *= env;
        float g = exp(-w * w * 320.0);
        float dprof = (-42.0 * sin(w * 42.0) - 640.0 * w * cos(w * 42.0)) * g;
        grad += (d / r) * dprof * env * 0.010;
    }
    return grad;
}

// ---- Caustics -------------------------------------------------------------------
// F2-F1 of an animated cellular pattern gives the classic bright network of lines.
float worleyEdge(vec2 p, float t)
{
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float d1 = 8.0;
    float d2 = 8.0;
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            vec2 g = vec2(float(x), float(y));
            vec2 o = hash22(ip + g);
            o = 0.5 + 0.45 * sin(t + TAU * o);
            vec2 r = g + o - fp;
            float d = dot(r, r);
            if (d < d1) { d2 = d1; d1 = d; }
            else if (d < d2) { d2 = d; }
        }
    }
    return sqrt(d2) - sqrt(d1);
}

// p = world xz of the sea floor (already shifted for depth by the caller)
float causticPattern(vec2 p, float t)
{
    // warp the lookup with the real wave field so the pattern follows the surface
    p += waveGradient(p, t) * 0.8;

    float a = worleyEdge(p * 0.85 + vec2(t * 0.06, -t * 0.04), t * 0.7);
    float b = worleyEdge(p * 1.45 - vec2(t * 0.05, t * 0.07), t * 0.9 + 3.0);
    float la = pow(1.0 - clamp(a * 2.4, 0.0, 1.0), 5.0);
    float lb = pow(1.0 - clamp(b * 2.4, 0.0, 1.0), 5.0);
    return (la + lb) * 0.55 + min(la, lb) * 0.8;
}

// ---- Water colour presets ---------------------------------------------------------
// Absorption in 1/metre (red dies first), and the colour of light scattered back.
vec3 waterAbsorption()
{
#if WATER_COLOR == 1
    return vec3(0.55, 0.045, 0.05);   // tropical turquoise
#elif WATER_COLOR == 2
    return vec3(0.30, 0.10, 0.34);    // swamp green
#elif WATER_COLOR == 3
    return vec3(0.50, 0.10, 0.06);    // deep ocean
#else
    return vec3(0.40, 0.065, 0.035);  // clear blue
#endif
}

vec3 waterScatterColor()
{
#if WATER_COLOR == 1
    return vec3(0.010, 0.200, 0.200);
#elif WATER_COLOR == 2
    return vec3(0.050, 0.140, 0.060);
#elif WATER_COLOR == 3
    return vec3(0.010, 0.070, 0.160);
#else
    return vec3(0.020, 0.140, 0.260);
#endif
}
