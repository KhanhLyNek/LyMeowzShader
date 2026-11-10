#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow_distort.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadow.glsl"
#include "/lib/lighting.glsl"

uniform sampler2D gtexture;
uniform vec4 entityColor;
uniform int frameCounter;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normalV;
in vec3 feetPos;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main()
{
    vec4 tex = texture(gtexture, texcoord);
    if (tex.a < 0.1) discard;
    vec4 col = tex * glcolor;

    vec3 albedo = toLinear(col.rgb);
    albedo = mix(albedo, toLinear(entityColor.rgb), entityColor.a);

    vec2 lm = lmcoord;
#ifdef FORCE_SKYLIGHT
    lm = vec2(0.0, 1.0);
#endif

    float noise = ign(gl_FragCoord.xy, frameCounter);
    vec3 lit = lightSurface(albedo, normalize(normalV), lm, feetPos, noise);

    float alpha = col.a;
#ifdef WEATHER
    alpha *= 0.55;
#endif
    outColor = vec4(lit, alpha);
}
