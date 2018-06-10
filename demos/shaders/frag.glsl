$(get_glsl_version_string())

out vec4 outColor;
uniform vec4 color;

void main()
{
    outColor = color;
}
