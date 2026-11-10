#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/shadow_distort.glsl"

in vec4 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;

void main()
{
    gl_Position = ftransform();
    gl_Position.xy = distortShadow(gl_Position.xy);

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    // water never casts a shadow
    if (mc_Entity.x == 10001.0)
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
}
