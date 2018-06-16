#! /usr/bin/env julia
const profile = false
const targetFps = 60 + 5
const targetSecsPerFrame = 1 / targetFps
const vsync = false

const simUpdateQuantumSecs = 0.01
const secsBetweenFpsUpdate = 2

using DataStructures
import GLFW
using ModernGL
using Quaternions
if profile using ProfileView end

#WARNING: Order of includes matters.
include(joinpath("lib", "Renderer.jl"))
include(joinpath("lib", "Game.jl"))
import Renderer
import Game

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

    const shadersDir = "shaders"
    pyramid = Game.Pawn(
        Renderer.Shader(
            joinpath(shadersDir, "vert.glsl"),
            joinpath(shadersDir, "frag.glsl")
        ),
        Renderer.Mesh(vertices, indices)
    )
    pyramid
end

function modernGLDemo()

    window = Renderer.createWindow("ModernGL Example")
    Renderer.init()

    pyramid = generatePyramid()

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
            Renderer.exit()
        end
    end
    GLFW.SetKeyCallback(
        window,
        (_, key, scancode, action, mods) -> handleKey(key, scancode, action)
    )

    # Loop until user closes the window.
    runningSecsPerFrame = CircularBuffer{Real}(120)
    secsSincePrintFps = 0

    secsSinceUpdate = simUpdateQuantumSecs

    secsSinceFpsUpdate = 0

    while !Renderer.exitApp
        tic()

        if secsSinceUpdate >= simUpdateQuantumSecs
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

            # pyramid.color = GLfloat[0 1 sin(i / 50) 1]'

            # Pulse the background blue.
            # glClearColor(0.0, 0.0, 0.5 * (1 + sin(i * 0.02)), 1.0)

            secsSinceFpsUpdate += secsSinceUpdate

            if secsSinceFpsUpdate >= secsBetweenFpsUpdate
                avgFps = 1 / mean(secsPerFrame)
                println("FPS: ", avgFps)
                secsSinceFpsUpdate = 0
            end

            secsSinceUpdate = 0
        end

        Game.update(pyramid)

        glClear(GL_COLOR_BUFFER_BIT)

        Game.render(pyramid)

        # Swap front and back buffers.
        GLFW.SwapBuffers(window)
        # Poll for and process events.
        GLFW.PollEvents()

        # Update time.
        secsPerFrame = toq()

        # Limit frame rate.
        if vsync
            tic()
            secsTilNextFrame = targetSecsPerFrame - secsPerFrame
            # println("secsPerFrame: ", secsPerFrame)
            # println("secsSinceUpdate: ", secsSinceUpdate)
            # println("secsTilNextFrame: ", secsTilNextFrame)
            if secsTilNextFrame >= 0
                sleep(secsTilNextFrame)
            else
                println("Behind $targetSecsPerFrame secs per frame target by $(abs(secsTilNextFrame)) secs.")
            end
            secsPerFrame += toq()
        end

        push!(runningSecsPerFrame, secsPerFrame)
        secsSinceUpdate += secsPerFrame
    end
    GLFW.Terminate()
end


if profile
    Profile.init(delay=0.01)
    Profile.clear()
    @profile modernGLDemo()
    ProfileView.view()
    sleep(20)
else
    modernGLDemo()
end
