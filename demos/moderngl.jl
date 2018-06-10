import GLFW
using ModernGL
include(joinpath("lib", "opengl-util.jl"))

GLFW.Init()
# OS X-specific GLFW hints to initialize the correct version of OpenGL
wh = 600
# Create a windowed mode window and its OpenGL context
window = GLFW.CreateWindow(wh, wh, "OpenGL Example")
# Make the window's context current
GLFW.MakeContextCurrent(window)
GLFW.ShowWindow(window)
GLFW.SetWindowSize(window, wh, wh) # Seems to be necessary to guarantee that window > 0

glViewport(0, 0, wh, wh)

println(createcontextinfo())

# The data for our triangle
data = GLfloat[
    0.0, 0.5,
    0.5, -0.5,
    -0.5,-0.5
]
# Generate a vertex array and array buffer for our data
vao = glGenVertexArray()
glBindVertexArray(vao)
vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)
# Create and initialize shaders
shadersDir = "shaders"
vertexShader = createShaderFromFile(joinpath(shadersDir, "vert.glsl"), GL_VERTEX_SHADER)
fragmentShader = createShaderFromFile(joinpath(shadersDir, "frag.glsl"), GL_FRAGMENT_SHADER)
program = createShaderProgram(vertexShader, fragmentShader)
glUseProgram(program)
positionAttribute = glGetAttribLocation(program, "position");
glEnableVertexAttribArray(positionAttribute)
glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 0, C_NULL)
glUniform2f(0, 0, 0)
glUniform4f(1, 0, 0, 1, 1)
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
# Loop until the user closes the window
for i in 0:600
    # Move the triangle and color.
    glUniform2f(0, sin(0.01 * i) + 0.1 * sin(i/2), sin(i/50) + 0.2 * cos(i/5))
    glUniform4f(1, 0, 1, sin(i / 50), 1)
    # Pulse the background blue
    # glClearColor(0.0, 0.0, 0.5 * (1 + sin(i * 0.02)), 1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    # Draw our triangle
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # Swap front and back buffers
    GLFW.SwapBuffers(window)
    # Poll for and process events
    GLFW.PollEvents()

    if exitApp
        println("Exiting")
        break
    end
end
GLFW.Terminate()
