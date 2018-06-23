#! /usr/bin/env julia
const profile = false

using DataStructures
import GLFW
using ModernGL
using Quaternions
if profile using ProfileView end

#WARNING: Order of includes matters.
const libDir = joinpath("..", "lib")
include(joinpath(libDir, "Renderer.jl"))
include(joinpath(libDir, "Game.jl"))
import Renderer
import Game

# Quantum of simulation fixed time step in seconds.
const chronon = 0.01

const targetFps = 60
const targetSecsPerFrame = 1 / targetFps
const vsync = true

timeOfLastSimUpdate = Dates.now()

pastSecsPerUpdate = CircularBuffer{Real}(120)

updateCounter = 0

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

    const shadersDir = joinpath("..", "shaders")
    shader = Renderer.Shader(
        joinpath(shadersDir, "vert.glsl"),
        joinpath(shadersDir, "frag.glsl")
    )

    camera = Renderer.Camera(GLFW.GetWindowSize(window))
    Renderer.bind(camera, shader)

    pyramid = Pyramid(shader)
    actors = [pyramid]

    scene = [actor.pawn.item for actor in actors]

    # Loop until user closes the window.
    secsSinceLastFrame = 0
    timeOfLastFrame = Dates.now()
    while !exitApp
        secsSinceLastFrame = (Dates.now() - timeOfLastFrame).value / 1000
        if !vsync || secsSinceLastFrame >= targetSecsPerFrame
            tic()

            Renderer.render(scene, window)

            secsPerFrame = toq()

            timeOfLastFrame = Dates.now()

            Renderer.printFps(secsSinceLastFrame)
        end

        tic()
        simulate(actors)
        secsSpentSimulating = toq()

        GLFW.PollEvents()
    end

    GLFW.Terminate()
end

function simulate(actors)
    secsSinceUpdate = (Dates.now() - timeOfLastSimUpdate).value / 1000
    while secsSinceUpdate >= chronon
        # push!(pastSecsPerUpdate, )
        global updateCounter += 1
        if updateCounter == 5 / chronon
            println("Secs per update: ", secsSinceUpdate)
            global updateCounter = 0
        end

        # Threads.@threads for actor in actors
        for actor in actors
            #TODO: generic update
            simulate(actor, chronon)
        end

        # Update OpenGL in thread that created context.
        for actor in actors
            Game.updateGpuBuffers(actor.pawn)
        end

        secsSinceUpdate -= chronon

        global timeOfLastSimUpdate = Dates.now()
    end
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
