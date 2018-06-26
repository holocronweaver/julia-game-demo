struct Pyramid
    pawn::Game.Pawn

    function Pyramid(shader::Renderer.Shader)
        const vertices = GLfloat[
            0.0  0.5  0.0
            0.5 -0.5  0.0
            -0.5 -0.5  0.0
            0.0  0.0  1.0
        ]
        const indices = GLuint[
            2, 1, 0,
            3, 0, 1,
            2, 0, 3,
            1, 2, 3,
        ]

        mesh = Renderer.Mesh(vertices, indices)
        item = Renderer.Item(shader, mesh)
        pawn = Game.Pawn(item)
        new(pawn)
    end
end
function simulate(pyramid::Pyramid, secsSinceUpdate)
    pawn = pyramid.pawn

    # Move the triangle and color.
    # pawn.pos = GLfloat[
    #     0,
    #     0,
    #     # sin(secsSinceUpdate) + 0.1 * sin(secsSinceUpdate / 2)
    #     # sin(secsSinceUpdate / 50) + 0.2 * cos(secsSinceUpdate / 5)
    #     4
    # ]
    # pawn.scale = GLfloat[1, 1, 1]
    pawn.orientation = qrotation([0, 1, 0], 5.0 * secsSinceUpdate) * pawn.orientation
    pawn.rot = eye(GLfloat, 4)
    pawn.rot[1:3, 1:3] = rotationmatrix(pawn.orientation)

    # pawn.color = GLfloat[0, 1, sin(i / 50), 1]

    # Pulse the background blue.
    # glClearColor(0.0, 0.0, 0.5 * (1 + sin(i * 0.02)), 1.0)
end

struct Plane
    pawn::Game.Pawn

    function Plane(shader::Renderer.Shader,
                   texture::Renderer.Texture)
        const vertices = GLfloat[
            0.0  0.0  0.0
            1.0  0.0  0.0
            1.0  0.0  1.0
            0.0  0.0  1.0
        ]
        const indices = GLuint[
            0, 1, 2,
            0, 2, 3,
        ]

        mesh = Renderer.Mesh(vertices, indices)
        item = Renderer.Item(shader, mesh, texture)
        pawn = Game.Pawn(item)
        new(pawn)
    end
end
function simulate(plane::Plane, secsSinceUpdate)
end
