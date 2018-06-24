$(Renderer.get_glsl_version_string())

in vec3 vertPos;
out vec4 vertColor;

layout(std140) uniform Pawn {
    mat4 worldRot;
    //vec4 color;
    vec3 worldPos;
    vec3 worldScale;
} pawn;

layout(std140) uniform Camera {
    mat4 projection;
    mat4 orientationTransform;
    vec3 position;
} camera;

mat4 translate(vec3 translation) {
    return transpose(mat4(
        1, 0, 0, translation[0],
        0, 1, 0, translation[1],
        0, 0, 1, translation[2],
        0, 0, 0, 1
    ));
}

mat4 scale(vec3 scale) {
    return transpose(mat4(
        scale[0], 0, 0, 0,
        0, scale[1], 0, 0,
        0, 0, scale[2], 0,
        0, 0, 0, 1
    ));
}

void main()
{
    vertColor = vec4(
        1.8 * vec3(vertPos.x + 0.1, vertPos.y + 0.1, vertPos.z + 0.1),
        1
    );

    mat4 world = translate(pawn.worldPos) * pawn.worldRot * scale(pawn.worldScale);
    mat4 view = camera.orientationTransform * translate(camera.position);
    gl_Position = camera.projection * view * world * vec4(vertPos, 1);
}
