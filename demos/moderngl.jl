import GLFW
using ModernGL
using Quaternions
include(joinpath("lib", "glfw-util.jl"))
include(joinpath("lib", "opengl-util.jl"))
# include(joinpath("lib", "transform.jl"))

GLFW.Init()

window = createWindow("ModernGL Example")

# The data for our triangle.
vertices = GLfloat[
     0.0  0.5  0.0
     0.5 -0.5  0.0
    -0.5 -0.5  0.0
     0.0  0.0  1.0
]'
indices = GLint[
    0, 1, 2,
    3, 0, 1,
    3, 0, 2,
    3, 1, 2,
]
# Generate a vertex array and array buffer for our data.
vao = glGenVertexArray()
glBindVertexArray(vao)
vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
indexBuffer = glGenBuffer()
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer)
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
# Create and initialize shaders.
shadersDir = "shaders"
vertexShader = createShaderFromFile(joinpath(shadersDir, "vert.glsl"), GL_VERTEX_SHADER)
fragmentShader = createShaderFromFile(joinpath(shadersDir, "frag.glsl"), GL_FRAGMENT_SHADER)
program = createShaderProgram(vertexShader, fragmentShader)
glUseProgram(program)
positionAttribute = glGetAttribLocation(program, "vertPos")
glEnableVertexAttribArray(positionAttribute)
glVertexAttribPointer(positionAttribute, 3, GL_FLOAT, false, 0, C_NULL)
posLoc = glGetUniformLocation(program, "worldPos")
scaleLoc = glGetUniformLocation(program, "worldScale")
rotLoc = glGetUniformLocation(program, "worldRot")
# colorLoc = glGetUniformLocation(program, "color")
# Exit app control.
exitApp = false
# Setup input key handler.
function handleKey(key, scancode, action)
    name = GLFW.GetKeyName(key, scancode)
    if name == nothing
        println("scancode $scancode ", action)
    else
        println("key $name ", action)
    end
    # if key != nothing
    if key == GLFW.KEY_SPACE
        global exitApp = true
    end
end
GLFW.SetKeyCallback(
    window,
    (_, key, scancode, action, mods) -> handleKey(key, scancode, action)
)
# Loop until the user closes the window.
orientation = qrotation([1, 0, 0], 0)
const fps = 60
secsPerFrame = 1 / fps
for i in 0:600
    tic()

    # Move the triangle and color.
    pos = GLfloat[
        # sin(0.01 * i) + 0.1 * sin(i / 2)
        # sin(i / 50) + 0.2 * cos(i / 5)
        0
        0
        0
    ]
    scale = GLfloat[
        1
        1
        1
    ]
    angle = 0
    orientation = qrotation([0, 1, 0], 0.05) * orientation
    rot = eye(GLfloat, 4)
    rot[1:3, 1:3] = rotationmatrix(orientation)

    glUniform3fv(posLoc, 1, pos)
    glUniform3fv(scaleLoc, 1, scale)
    glUniformMatrix4fv(rotLoc, 1, false, rot)

    # color = GLfloat[0 1 sin(i / 50) 1]'
    # glUniform4fv(colorLoc, 1, color)
    # Pulse the background blue.
    # glClearColor(0.0, 0.0, 0.5 * (1 + sin(i * 0.02)), 1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    # Draw our triangle.
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer)
    glDrawElements(GL_TRIANGLES, length(indices), GL_UNSIGNED_INT, C_NULL)
    # Swap front and back buffers.
    GLFW.SwapBuffers(window)
    # Poll for and process events.
    GLFW.PollEvents()

    if exitApp
        println("Exiting")
        break
    end

    # frametime = toq()
    # secsTilNextFrame = secsPerFrame - frametime
    # if secsTilNextFrame >= 0
    #     sleep(secsTilNextFrame)
    # else
    #     println(frametime)
    #     println("Behind $secsPerFrame secs per frame target by $(abs(secsTilNextFrame)) secs.")
    # end
end
GLFW.Terminate()
