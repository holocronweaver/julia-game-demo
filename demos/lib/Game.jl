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

    posLoc::GLuint
    scaleLoc::GLuint
    rotLoc::GLuint
    # colorLoc::GLuint

    function Pawn(item::Renderer.Item)
        shader = item.shader

        pos = zeros(GLfloat, 3)
        scale = ones(GLfloat, 3)
        rot = eye(GLfloat, 4)
        orientation = qrotation([1, 0, 0], 0)

        posLoc = glGetUniformLocation(shader.program, "worldPos")
        scaleLoc = glGetUniformLocation(shader.program, "worldScale")
        rotLoc = glGetUniformLocation(shader.program, "worldRot")
        # colorLoc = glGetUniformLocation(shader.program, "color")

        pawn = new(item,
                   pos, scale, rot, orientation,
                   posLoc, scaleLoc, rotLoc)

        updateGpuBuffers(pawn)

        pawn
    end
end
function updateGpuBuffers(pawn::Pawn)
    glUseProgram(pawn.item.shader.program)

    #TODO: Find way to map game objects to their GPU data.
    # Preferably using OpenGL mapping, then delete this method.
    glUniform3fv(pawn.posLoc, 1, pawn.pos)
    glUniform3fv(pawn.scaleLoc, 1, pawn.scale)
    glUniformMatrix4fv(pawn.rotLoc, 1, false, pawn.rot)
    # glUniform4fv(pawn.colorLoc, 1, pawn.color)

    glUseProgram(0)
end

function Renderer.render(pawn::Pawn)
    updateGpuBuffers(pawn)
    Renderer.render(pawn.item)
end

end # module
