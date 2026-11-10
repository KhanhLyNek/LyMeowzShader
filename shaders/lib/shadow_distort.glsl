// Shadow-map space distortion: more resolution near the player.
// Used by shadow.vsh (writer) and lib/shadow.glsl (readers) - keep them identical.

vec2 distortShadow(vec2 xy)
{
    float f = length(xy) * SHADOW_DISTORT + (1.0 - SHADOW_DISTORT);
    return xy / f;
}
