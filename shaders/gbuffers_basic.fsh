#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main()
{
    outColor = vec4(toLinear(glcolor.rgb), glcolor.a);
}
