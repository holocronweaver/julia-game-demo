module Renderer

using DataStructures
import GLFW
using ModernGL
using Quaternions

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
    position::Array{GLfloat, 1}
    orientation::Quaternion

    nearZ::GLfloat
    farZ::GLfloat
    fieldOfView::GLfloat # radians
    aspectRatio::GLfloat

    buffer::GLuint

    function Camera(; position=GLfloat[0,0,0], orientation=qrotation([1, 0, 0], 0),
                    nearZ=0.1, farZ=100,
                    fieldOfView=deg2rad(30), aspectRatio=1920/1080)
        buffer = glGenBuffer()
        bufferIndex = 0

        camera = new(position, orientation, nearZ, farZ, fieldOfView, aspectRatio, buffer)

        glBindBuffer(GL_UNIFORM_BUFFER, buffer)
        bufferSize = (2 * 16 + 3) * sizeof(GLfloat)
        glBufferData(GL_UNIFORM_BUFFER, bufferSize, C_NULL, GL_STATIC_DRAW)
        glBindBuffer(GL_UNIFORM_BUFFER, 0)

        updateGpuBuffers(camera)

        camera
    end

    function Camera(screenResolution)
        aspectRatio = screenResolution[1] / screenResolution[2]
        Camera(aspectRatio=aspectRatio)
    end
end
function updateGpuBuffers(cam::Camera)
    glBindBuffer(GL_UNIFORM_BUFFER, cam.buffer)

    offset = 0
    proj = projection(cam)
    glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(proj), proj)
    offset += sizeof(proj)
    orientationTrans = orientationTransform(cam)
    glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(orientationTrans), orientationTrans)
    offset += sizeof(orientationTrans)
    glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(cam.position), cam.position)

    glBindBuffer(GL_UNIFORM_BUFFER, 0)
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
# After moving the coordinate origin to camera position, this
# transform projects coordinates to the camera orientation axes.
function orientationTransform(cam::Camera)
    rot = rotationmatrix(cam.orientation)
    pitch = rot * GLfloat[1, 0, 0]
    yaw = rot * GLfloat[0, 1, 0]
    roll = rot * GLfloat[0, 0, 1]

    view = GLfloat[
        pitch[1] pitch[2] pitch[3] 0
        yaw[1] yaw[2] yaw[3] 0
        roll[1] roll[2] roll[3] 0
        0 0 0 1
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

function createWindow(title; width=0, height=0, monitorIndex=0)
    GLFW.Init()

    monitor = monitorIndex == 0 ? GLFW.GetPrimaryMonitor() : GLFW.GetMonitors()[monitorIndex]
    mode = GLFW.GetVideoMode(monitor)

    GLFW.WindowHint(GLFW.RED_BITS, mode.redbits)
    GLFW.WindowHint(GLFW.GREEN_BITS, mode.greenbits)
    GLFW.WindowHint(GLFW.BLUE_BITS, mode.bluebits)
    GLFW.WindowHint(GLFW.REFRESH_RATE, mode.refreshrate)
    if width == 0 || height == 0
        width = mode.width
        height = mode.height
    end

    # Create a windowed mode window and its OpenGL context.
    window = GLFW.CreateWindow(width, height, title)
    monitorPos = GLFW.GetMonitorPos(monitor)
    GLFW.SetWindowPos(window, monitorPos[1], monitorPos[2])
    # Make the window's context current.
    GLFW.MakeContextCurrent(window)
    GLFW.ShowWindow(window)
    # Seems to be necessary to guarantee that window > 0.
    GLFW.SetWindowSize(window, width, height)
    glViewport(0, 0, width, height)
    println(createcontextinfo())

    glEnable(GL_DEPTH_TEST)

    return window
end

function render(item::Item)
    glUseProgram(item.shader.program)
    glBindVertexArray(item.vao)

    glDrawElements(GL_TRIANGLES, length(item.mesh.indices), GL_UNSIGNED_INT, C_NULL)

    glBindVertexArray(0)
    glUseProgram(0)
end

function render(scene, window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

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
