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

include("pawns.jl")

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

function modernGLDemo()
    window = Renderer.createWindow("ModernGL Example")
    Renderer.init()

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

function simulate(pawns, secsSinceUpdate)
    tic()
    while secsSinceUpdate > chronon
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

if profile
    Profile.init(delay=0.01)
    Profile.clear()
    @profile modernGLDemo()
    ProfileView.view()
    sleep(20)
else
    modernGLDemo()
end
