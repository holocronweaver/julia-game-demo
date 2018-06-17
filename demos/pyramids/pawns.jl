function generatePyramid()
    const vertices = GLfloat[
        0.0  0.5  0.0
        0.5 -0.5  0.0
        -0.5 -0.5  0.0
        0.0  0.0  1.0
    ]'
    const indices = GLint[
        2, 1, 0,
        3, 0, 1,
        2, 0, 3,
        3, 1, 2,
    ]

    const shadersDir = joinpath("..", "shaders")
    pyramid = Game.Pawn(
        Renderer.Item(
            Renderer.Shader(
                joinpath(shadersDir, "vert.glsl"),
                joinpath(shadersDir, "frag.glsl")
            ),
            Renderer.Mesh(vertices, indices)
        )
    )
    pyramid
end

function updatePyramid(pyramid::Game.Pawn, secsSinceUpdate)
    # Move the triangle and color.
    pyramid.pos = GLfloat[
        0,
        0,
        # sin(secsSinceUpdate) + 0.1 * sin(secsSinceUpdate / 2)
        # sin(secsSinceUpdate / 50) + 0.2 * cos(secsSinceUpdate / 5)
        0
    ]
    pyramid.scale = GLfloat[1, 1, 1]
    pyramid.orientation = qrotation([0, 1, 0], 5.0 * secsSinceUpdate) * pyramid.orientation
    pyramid.rot = eye(GLfloat, 4)
    pyramid.rot[1:3, 1:3] = rotationmatrix(pyramid.orientation)

    # pyramid.color = GLfloat[0, 1, sin(i / 50), 1]

    # Pulse the background blue.
    # glClearColor(0.0, 0.0, 0.5 * (1 + sin(i * 0.02)), 1.0)
end
