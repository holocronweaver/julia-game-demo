mutable struct Camera
    position::Array{GLfloat, 1}
    orientation::Quaternion

    nearZ::GLfloat
    farZ::GLfloat
    fieldOfView::GLfloat # radians
    aspectRatio::GLfloat

    buffer::GLuint

    function Camera(; position=GLfloat[0,0,0],
                    orientation=qrotation([1, 0, 0], 0),
                    nearZ=0.1, farZ=100,
                    fieldOfView=deg2rad(30), aspectRatio=1920/1080)
        buffer = glGenBuffer()

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
