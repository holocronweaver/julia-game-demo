#! /usr/bin/env julia
const profile = false
const targetFps = 60 + 5
const targetSecsPerFrame = 1 / targetFps
const vsync = false

import GLFW
using DataStructures
using ModernGL
using Quaternions
if profile using ProfileView end
include(joinpath("lib", "glfw-util.jl"))
include(joinpath("lib", "julia-util.jl"))
include(joinpath("lib", "opengl-util.jl"))
# include(joinpath("lib", "transform.jl"))

# Exit app control.
exitApp = false

function modernGLDemo()

    GLFW.Init()

    window = createWindow("ModernGL Example")

    # The data for our triangle.
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

    # Generate a vertex array and array buffer for our data.
    vao = glGenVertexArray()
    glBindVertexArray(vao)
    vbo = glGenBuffer()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    indexBuffer = glGenBuffer()
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
    glEnable(GL_CULL_FACE)
    # Create and initialize shaders.
    shadersDir = "shaders"
    vertexShader = createShaderFromFile(joinpath(shadersDir, "vert.glsl"), GL_VERTEX_SHADER)
    fragmentShader = createShaderFromFile(joinpath(shadersDir, "frag.glsl"), GL_FRAGMENT_SHADER)
    program = createShaderProgram(vertexShader, fragmentShader)
    glUseProgram(program)
    positionAttribute = glGetAttribLocation(program, "vertPos")
    glEnableVertexAttribArray(positionAttribute)
    glVertexAttribPointer(positionAttribute, 3, GL_FLOAT, false, 0, C_NULL)
    posLoc = glGetUniformLocation(program, "worldPos")
    scaleLoc = glGetUniformLocation(program, "worldScale")
    rotLoc = glGetUniformLocation(program, "worldRot")
    # colorLoc = glGetUniformLocation(program, "color")

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
    # Loop until the user closes the window.
    orientation = qrotation([1, 0, 0], 0)
    runningSecsPerFrame = CircularBuffer{Real}(120)
    const printFpsFreqSecs = 10
    secsSincePrintFps = 0

    GLFW.SwapInterval(0)

    const simUpdateQuantumSecs = 0.01
    secsSinceUpdate = simUpdateQuantumSecs

    const secsBetweenFpsUpdate = 2
    secsSinceFpsUpdate = 0

    while !exitApp
        tic()

        if secsSinceUpdate >= simUpdateQuantumSecs
            # Move the triangle and color.
            pos = GLfloat[
                # sin(secsSinceUpdate) + 0.1 * sin(secsSinceUpdate / 2)
                # sin(secsSinceUpdate / 50) + 0.2 * cos(secsSinceUpdate / 5)
                0
                0
                0
            ]
            scale = GLfloat[
                1
                1
                1
            ]
            orientation = qrotation([0, 1, 0], 5.0 * secsSinceUpdate) * orientation
            rot = eye(GLfloat, 4)
            rot[1:3, 1:3] = rotationmatrix(orientation)

            # color = GLfloat[0 1 sin(i / 50) 1]'

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

        glUniform3fv(posLoc, 1, pos)
        glUniform3fv(scaleLoc, 1, scale)
        glUniformMatrix4fv(rotLoc, 1, false, rot)
        # glUniform4fv(colorLoc, 1, color)

        glClear(GL_COLOR_BUFFER_BIT)

        # Draw our triangle.
        # glBindBuffer(GL_ARRAY_BUFFER, vbo)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer)
        glDrawElements(GL_TRIANGLES, length(indices), GL_UNSIGNED_INT, C_NULL)
        # Swap front and back buffers.
        GLFW.SwapBuffers(window)
        # Poll for and process events.
        GLFW.PollEvents()

        if exitApp
            println("Exiting")
            break
        end

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
