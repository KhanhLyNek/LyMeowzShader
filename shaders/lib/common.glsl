// Shared helpers: maths, colour, hashing, noise.

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2  saturate(vec2 x)  { return clamp(x, vec2(0.0), vec2(1.0)); }
vec3  saturate(vec3 x)  { return clamp(x, vec3(0.0), vec3(1.0)); }

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

vec3 toLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
vec3 toGamma(vec3 c)  { return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2)); }

// ---- integer hashing (no sin(), stable at large world coordinates) -----------
uint pcgHash(uint v)
{
    uint state = v * 747796405u + 2891336453u;
    uint word  = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

float hash12(vec2 p)
{
    uvec2 q = uvec2(ivec2(floor(p)));
    uint h = pcgHash(q.x + pcgHash(q.y));
    return float(h) * (1.0 / 4294967295.0);
}

vec2 hash22(vec2 p)
{
    uvec2 q = uvec2(ivec2(floor(p)));
    uint h1 = pcgHash(q.x + pcgHash(q.y));
    uint h2 = pcgHash(h1 ^ 0x9E3779B9u);
    return vec2(float(h1), float(h2)) * (1.0 / 4294967295.0);
}

// Smooth value noise, 0..1
float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Interleaved gradient noise, animated per frame
float ign(vec2 fragCoord, int frame)
{
    vec2 p = fragCoord + 5.588238 * float(frame % 64);
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}
