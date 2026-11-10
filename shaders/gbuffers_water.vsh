#version 330 compatibility

in vec4 mc_Entity;

uniform mat4 gbufferModelViewInverse;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normalV;
out vec3 feetPos;
out float isWater;

void main()
{
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    feetPos = (gbufferModelViewInverse * viewPos).xyz;
    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec2 lm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = clamp((lm - 0.03125) * 1.0666667, 0.0, 1.0);

    glcolor = gl_Color;
    normalV = normalize(gl_NormalMatrix * gl_Normal);

    // block.properties maps minecraft:water to id 10001
    isWater = (mc_Entity.x == 10001.0) ? 1.0 : 0.0;
}
