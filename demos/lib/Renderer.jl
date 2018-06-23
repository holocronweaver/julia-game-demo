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

        vbo = glGenBuffer()
        glBindBuffer(GL_ARRAY_BUFFER, vbo)
        glBufferData(GL_ARRAY_BUFFER,
                     sizeof(mesh.vertices), mesh.vertices', GL_STATIC_DRAW)
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

mutable struct Camera
    nearZ::GLfloat
    farZ::GLfloat
    fieldOfView::GLfloat # radians
    aspectRatio::GLfloat

    buffer::GLuint

    function Camera(; nearZ=0.1, farZ=100,
                    fieldOfView=deg2rad(30), aspectRatio=1920/1080)
        buffer = glGenBuffer()
        bufferIndex = 0

        camera = new(nearZ, farZ, fieldOfView, aspectRatio, buffer)

        glBindBuffer(GL_UNIFORM_BUFFER, buffer)
        proj = projection(camera)
        glBufferData(GL_UNIFORM_BUFFER, sizeof(proj), proj, GL_STATIC_DRAW)
        glBindBuffer(GL_UNIFORM_BUFFER, 0)

        camera
    end

    function Camera(screenResolution)
        aspectRatio = screenResolution[1] / screenResolution[2]
        Camera(aspectRatio=aspectRatio)
    end
end
function projection(cam::Camera)
    tanfov = tan(cam.fieldOfView / 2)
    GLfloat[
        1 / (cam.aspectRatio * tanfov) 0 0 0
        0 1 / tanfov 0 0
        0 0 (-cam.nearZ - cam.farZ) / (cam.nearZ - cam.farZ) 2 * cam.farZ * cam.nearZ / (cam.nearZ - cam.farZ)
        0 0 1 0
    ]
end
function bind(camera::Camera, shader::Shader)
    #TODO: auto-map uniform buffer <-> buffer binding on shader creation.
    # Then all that has to be called is glBindBufferBase(GL_*, getBufferIndex(shader, "Camera"), camera.buffer) when switching cameras or shaders.
    bufferIndex = 0

    uniformBlockIndex = glGetUniformBlockIndex(shader.program, "Camera")
    glUniformBlockBinding(shader.program, uniformBlockIndex, bufferIndex)

    glBindBufferBase(GL_UNIFORM_BUFFER, bufferIndex, camera.buffer)
    glBindBuffer(GL_UNIFORM_BUFFER, 0)
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
