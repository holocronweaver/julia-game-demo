#version 450

in vec3 vertModelPos;
in vec4 vertColor;
out vec4 color;

uniform sampler2D texSampler;
uniform bool hasTexture;

void main()
{
    if (hasTexture) {
        vec4 texColor = texture2D(texSampler, 2 * vertModelPos.xz);
        //vec4 texColor = texelFetch(texSampler, ivec2(0, 0), 0);
        //vec4 texColor = textureGather(texSampler, vec2(0, 0), 0);
        color = texColor;
        //if (texColor.r == 1) {
        //   color = vec4(0, 1, 0, 1);
        //}
    } else {
        color = vertColor;
        //color = vec4(1, 1, 1, 1);
    }
}
