$(get_glsl_version_string())

in vec2 position;
uniform vec2 translation;

void main()
{
    gl_Position = vec4(position + translation, 0.0, 1.0);
}
