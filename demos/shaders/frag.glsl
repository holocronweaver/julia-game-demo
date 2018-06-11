$(get_glsl_version_string())

in vec4 vertColor;
out vec4 color;

void main()
{
    color = vertColor;
    //outColor = vec4(1, 1, 1, 1);
}
