$(get_glsl_version_string())

in vec3 vertPos;
out vec4 vertColor;
uniform vec3 worldPos;
uniform vec3 worldScale;
uniform mat4 worldRot;
//uniform vec4 color;

mat4 translate(vec3 translation) {
    return mat4(
        1, 0, 0, translation[0],
        0, 1, 0, translation[1],
        0, 0, 1, translation[2],
        0, 0, 0, 1
    );
}

mat4 scale(vec3 scale) {
    return mat4(
        scale[0], 0, 0, 0,
        0, scale[1], 0, 0,
        0, 0, scale[2], 0,
        0, 0, 0, 1
    );
}

void main()
{
    vertColor = vec4(
        1.8 * vec3(vertPos.x + 0.1, vertPos.y + 0.1, vertPos.z + 0.1),
        1
    );

    mat4 world = scale(worldScale) * worldRot * translate(worldPos);
    //const mat4 view;
    //const mat4 proj;
    gl_Position = vec4(vertPos, 1) * world;
}
