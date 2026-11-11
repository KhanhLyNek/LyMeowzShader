// Depth helpers for composite passes.

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

vec3 viewPosAt(vec2 uv, float depth)
{
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 v = gbufferProjectionInverse * ndc;
    return v.xyz / v.w;
}

// View-space surface normal rebuilt from the depth buffer. For each axis it picks the
// neighbour with the smaller depth jump, which keeps edges from smearing the result.
// Uses explicit taps (not dFdx) so it is safe inside branches.
vec3 normalFromDepth(sampler2D depthTex, vec2 uv)
{
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 p0 = viewPosAt(uv, texture(depthTex, uv).r);

    vec2 uR = uv + vec2(texel.x, 0.0);
    vec2 uL = uv - vec2(texel.x, 0.0);
    vec2 uU = uv + vec2(0.0, texel.y);
    vec2 uD = uv - vec2(0.0, texel.y);
    vec3 pR = viewPosAt(uR, texture(depthTex, uR).r);
    vec3 pL = viewPosAt(uL, texture(depthTex, uL).r);
    vec3 pU = viewPosAt(uU, texture(depthTex, uU).r);
    vec3 pD = viewPosAt(uD, texture(depthTex, uD).r);

    vec3 dx = (abs(pR.z - p0.z) < abs(pL.z - p0.z)) ? (pR - p0) : (p0 - pL);
    vec3 dy = (abs(pU.z - p0.z) < abs(pD.z - p0.z)) ? (pU - p0) : (p0 - pD);

    vec3 n = normalize(cross(dx, dy) + vec3(0.0, 0.0, 1e-6));
    return (n.z > 0.0) ? n : -n;   // face the camera
}
