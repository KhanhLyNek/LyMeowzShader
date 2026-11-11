#version 330 compatibility
#include "/lib/settings.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 outColor;

void main()
{
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.1) discard;

#ifdef COLORED_SHADOWS
    // Opaque geometry stores white. Translucent geometry (stained glass, ice...) stores its own
    // colour and is blended over that white, which leaves exactly the tint of the light that
    // passes through it.
    outColor = (c.a > 0.99) ? vec4(1.0) : c;
#else
    outColor = c;
#endif
}
