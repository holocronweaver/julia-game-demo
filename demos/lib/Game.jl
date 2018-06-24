module Game

#TODO: Get rid of GL.
using ModernGL
using Quaternions
import Renderer

mutable struct Pawn
    item::Renderer.Item

    pos::Array{GLfloat, 1}
    scale::Array{GLfloat, 1}
    rot::Array{GLfloat, 2}
    # color::Array{GLfloat, 1}

    orientation::Quaternion

    buffer::GLuint

    function Pawn(item::Renderer.Item)
        shader = item.shader

        pos = zeros(GLfloat, 3)
        scale = ones(GLfloat, 3)
        rot = eye(GLfloat, 4)
        orientation = qrotation([1, 0, 0], 0)

        buffer = Renderer.glGenBuffer()
        bufferIndex = 0

        pawn = new(item,
                   pos, scale, rot, orientation,
                   buffer)

        glBindBuffer(GL_UNIFORM_BUFFER, buffer)
        bufferSize = (16 + 2 * 4) * sizeof(GLfloat)
        glBufferData(GL_UNIFORM_BUFFER, bufferSize, C_NULL, GL_STATIC_DRAW)
        glBindBuffer(GL_UNIFORM_BUFFER, 0)

        updateGpuBuffers(pawn)

        return pawn
    end
end
function updateGpuBuffers(pawn::Pawn)
    #TODO: Find way to map game objects to their GPU data.
    # Preferably using OpenGL mapping, then delete this method.
    glBindBuffer(GL_UNIFORM_BUFFER, pawn.buffer)

    offset = 0
    glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(pawn.rot), pawn.rot)
    offset += sizeof(pawn.rot)
    glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(pawn.pos), pawn.pos)
    offset += 4 * sizeof(GLfloat)
    glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(pawn.scale), pawn.scale)

    glBindBuffer(GL_UNIFORM_BUFFER, 0)
end
function Renderer.bind(pawn::Pawn, shader::Renderer.Shader)
    bufferIndex = 1

    uniformBlockIndex = glGetUniformBlockIndex(shader.program, "Pawn")
    glUniformBlockBinding(shader.program, uniformBlockIndex, bufferIndex)

    glBindBufferBase(GL_UNIFORM_BUFFER, bufferIndex, pawn.buffer)
    glBindBuffer(GL_UNIFORM_BUFFER, 0)
end

function Renderer.render(pawn::Pawn)
    updateGpuBuffers(pawn)
    Renderer.bind(pawn, pawn.item.shader)
    Renderer.render(pawn.item)
end

end # module
