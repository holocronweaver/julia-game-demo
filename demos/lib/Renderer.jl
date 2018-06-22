module Renderer

using DataStructures
import GLFW
using ModernGL

include("opengl-util.jl")

# FPS tracking.
const secsBetweenFpsPrint = 2
secsPerFrameHistory = CircularBuffer{Real}(120)
timeOfLastFpsPrint = Dates.now()

struct Mesh
    vertices::Array{GLfloat, 2}
    indices::Array{GLuint, 1}
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

struct Item
    shader::Shader
    mesh::Mesh

    vao::GLuint
    vbo::GLuint
    ibo::GLuint

    function Item(shader::Shader, mesh::Mesh)
        vao = glGenVertexArray()
        glBindVertexArray(vao)

        #TODO: Map variables? Structs?
        #TODO: Ideally OpenGL <-> Julia, unified structs. Unclear how
        # to best do that.

        # See https://www.khronos.org/opengl/wiki/Vertex_Specification#Vertex_Buffer_Object
        # Basically, unlike GL_ELEMENT_ARRAY_BUFFER, the
        # GL_ARRAY_BUFFER binding is not tracked by VAO. Instead
        # glVertexAttribPointer sets the current bound buffer to the
        # vertex attribute index, and it is this attrib pointer that
        # is tracked by VAO. Thus multiple GL_ARRAY_BUFFER can be used
        # for a single VAO, up to one unique buffer per attribute index.
        vbo = glGenBuffer()
        glBindBuffer(GL_ARRAY_BUFFER, vbo)
        glBufferData(GL_ARRAY_BUFFER,
                     sizeof(mesh.vertices), mesh.vertices, GL_STATIC_DRAW)
        positionIndex = glGetAttribLocation(shader.program, "vertPos")
        glEnableVertexAttribArray(positionIndex)
        glVertexAttribPointer(positionIndex, 3, GL_FLOAT, false, 0, C_NULL)
        glBindBuffer(GL_ARRAY_BUFFER, 0)

        ibo = glGenBuffer()
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                     sizeof(mesh.indices), mesh.indices, GL_STATIC_DRAW)

        glBindVertexArray(0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

        new(shader, mesh, vao, vbo, ibo)
    end
end
end

function init()
    glEnable(GL_CULL_FACE)

    # GLFW.SwapInterval(0)
end

function createWindow(title, width=600, height=600)
    GLFW.Init()

    # Create a windowed mode window and its OpenGL context.
    window = GLFW.CreateWindow(width, height, title)
    # Make the window's context current.
    GLFW.MakeContextCurrent(window)
    GLFW.ShowWindow(window)
    # Seems to be necessary to guarantee that window > 0.
    GLFW.SetWindowSize(window, width, height)
    glViewport(0, 0, width, height)
    println(createcontextinfo())

    window
end

function render(item::Item)
    glUseProgram(item.shader.program)
    glBindVertexArray(item.vao)

    glDrawElements(GL_TRIANGLES, length(item.mesh.indices), GL_UNSIGNED_INT, C_NULL)

    glBindVertexArray(0)
    glUseProgram(0)
end

function render(scene::Array{Item, 1}, window)
    glClear(GL_COLOR_BUFFER_BIT)

    for item in scene
        render(item)
    end

    # Swap front and back buffers.
    GLFW.SwapBuffers(window)
end

function printFps(secsPerFrame)
    secsSinceFpsPrint = (Dates.now() - timeOfLastFpsPrint).value / 1000

    push!(secsPerFrameHistory, secsPerFrame)

    if secsSinceFpsPrint >= secsBetweenFpsPrint
        avgFps = 1 / mean(secsPerFrameHistory)
        println("FPS: ", round(avgFps))
        global timeOfLastFpsPrint = Dates.now()
    end
end

end # module
