import GLFW

# OS X-specific GLFW hints to initialize the correct version of OpenGL.
function createWindow(title, height=600)
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
