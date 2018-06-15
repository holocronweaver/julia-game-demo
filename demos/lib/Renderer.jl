module Renderer

import GLFW
using ModernGL
include("opengl-util.jl")

# Exit app control.
exitApp = false

# const printFpsFreqSecs = 10

struct Mesh
    vertices::Array{GLfloat}
    indices::Array{GLint}
    vbo::GLuint
    ibo::GLuint

    function Mesh(vertices, indices)
        vbo = glGenBuffer()
        glBindBuffer(GL_ARRAY_BUFFER, vbo)
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
        ibo = glGenBuffer()
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
        new(vertices, indices, vbo, ibo)
    end
end

struct Shader
    program

    function Shader(vertexFile, fragFile)
        # Compile shaders.
        vertexShader = Renderer.createShaderFromFile(vertexFile, GL_VERTEX_SHADER)
        fragmentShader = Renderer.createShaderFromFile(fragFile, GL_FRAGMENT_SHADER)
        program = Renderer.createShaderProgram(vertexShader, fragmentShader)
        new(program)
    end
end
function bind(shader::Shader)
    glUseProgram(shader.program)
end

function init()
    glEnable(GL_CULL_FACE)

    vao = glGenVertexArray()
    glBindVertexArray(vao)

    # GLFW.SwapInterval(0)
end

# OS X-specific GLFW hints to initialize the correct version of OpenGL.
function createWindow(title, height=600)
    GLFW.Init()

    # Create a windowed mode window and its OpenGL context.
    window = GLFW.CreateWindow(height, height, title)
    # Make the window's context current.
    GLFW.MakeContextCurrent(window)
    GLFW.ShowWindow(window)
    # Seems to be necessary to guarantee that window > 0.
    GLFW.SetWindowSize(window, height, height)
    glViewport(0, 0, height, height)
    println(createcontextinfo())

    window
end

function render(mesh::Mesh)
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ibo)
    glDrawElements(GL_TRIANGLES, length(mesh.indices), GL_UNSIGNED_INT, C_NULL)
end

function exit()
    global exitApp = true
end

end # module
