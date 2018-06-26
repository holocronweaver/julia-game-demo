module Renderer

using DataStructures
using FileIO
import GLFW
using ModernGL
using Quaternions

include(joinpath("..", "julia-util.jl"))
include("opengl-util.jl")

rendererInitialized = false

include("Item.jl")
include("Camera.jl")

function init()
    global rendererInitialized
    if rendererInitialized return end

    reset()

    glEnable(GL_CULL_FACE)
    glEnable(GL_DEPTH_TEST)

    # GLFW.SwapInterval(0)

    rendererInitialized = true
end

function reset()
    global rendererInitialized = false
    # Allocating texture bind points.
    global textureCount = 0
    # FPS tracking.
    global const secsBetweenFpsPrint = 2
    global secsPerFrameHistory = CircularBuffer{Real}(120)
    global timeOfLastFpsPrint = Dates.now()
end

function shutdown()
    GLFW.Terminate()
    reset()
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

    if !rendererInitialized
        Renderer.init()
    end

    return window
end

function render(item::Item)
    glBindVertexArray(item.vao)

    if !(item.texture isa Null)
        bind(item.texture, item.shader)
    else
        unbindTexture(item.shader)
    end

    glDrawElements(GL_TRIANGLES, length(item.mesh.indices), GL_UNSIGNED_INT, C_NULL)

    glBindVertexArray(0)
end

"Render sets are renderable items that share the same set of shader
passes and thus can be batch rendered together."
function render(renderSet, window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    glUseProgram(renderSet[1].item.shader.program)
    for item in renderSet
        render(item)
    end
    glUseProgram(0)

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
