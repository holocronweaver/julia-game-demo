#! /usr/bin/env julia
const profile = false

import GLFW
using ModernGL
using Quaternions
if profile using ProfileView end

#WARNING: Order of includes matters.
include(joinpath("lib", "Renderer.jl"))
include(joinpath("lib", "Game.jl"))
import Renderer
import Game

# Quantum of simulation fixed time step in seconds.
const chronon = 0.01

const targetFps = 60
const targetSecsPerFrame = 1 / targetFps
const vsync = true

# Exit app control.
exitApp = false

global nextUpdateQuantaMultiple = 0

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

function modernGLDemo()
    window = Renderer.createWindow("ModernGL Example")
    Renderer.init()

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

    pyramid = generatePyramid()
    pawns = [pyramid]

    scene = [pawn.item for pawn in pawns]

    # Loop until user closes the window.
    secsSinceLastSimUpdate = 0
    secsSinceLastFrame = 0
    while !exitApp
        secsPerFrame = 0
        if !vsync || secsSinceLastFrame >= targetSecsPerFrame
            tic()

            Renderer.render(scene, window)

            secsPerFrame = toq()

            Renderer.printFps(secsSinceLastFrame)

            secsSinceLastFrame = 0
        end

        tic()

        secsSinceLastSimUpdate += secsPerFrame
        secsSinceLastSimUpdate = simulate(pawns, secsSinceLastSimUpdate)

        secsPerUpdate = toq()
        secsSinceLastFrame += secsPerUpdate
    end

    GLFW.Terminate()
end

function exit()
    global exitApp = true
end

function simulate(pawns, secsSinceUpdate)
    tic()
    while secsSinceUpdate > chronon
        # Pulse the background blue.
        # glClearColor(0.0, 0.0, 0.5 * (1 + sin(i * 0.02)), 1.0)

        # Threads.@threads for pawn in pawns
        for pawn in pawns
            #TODO: generic update
            updatePyramid(pawn, chronon)
        end

        # Update OpenGL in thread that created context.
        for pawn in pawns
            Game.updateGpuBuffers(pawn)
        end

        secsSinceUpdate -= chronon
    end
    secsSinceUpdate + toq()
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
