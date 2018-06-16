module Game

using ModernGL
using Quaternions

import Renderer

mutable struct Pawn
    shader::Renderer.Shader
    mesh::Renderer.Mesh

    posLoc::GLuint
    scaleLoc::GLuint
    rotLoc::GLuint
    # colorLoc::GLuint

    pos::Array{GLfloat, 1}
    scale::Array{GLfloat, 1}
    rot::Array{GLfloat, 2}
    # color::Array{GLfloat, 1}

    orientation::Quaternion

    function Pawn(shader, mesh)
        # Get shader variable locations.
        #TODO: Map variables? Structs?
        positionAttribute = glGetAttribLocation(shader.program, "vertPos")
        posLoc = glGetUniformLocation(shader.program, "worldPos")
        scaleLoc = glGetUniformLocation(shader.program, "worldScale")
        rotLoc = glGetUniformLocation(shader.program, "worldRot")
        # colorLoc = glGetUniformLocation(shader.program, "color")
        pos = zeros(GLfloat, 3)
        scale = ones(GLfloat, 3)
        rot = eye(GLfloat, 4)
        orientation = qrotation([1, 0, 0], 0)

        glEnableVertexAttribArray(positionAttribute)
        glVertexAttribPointer(positionAttribute, 3, GL_FLOAT, false, 0, C_NULL)

        new(shader, mesh,
            posLoc, scaleLoc, rotLoc,
            pos, scale, rot, orientation)
    end
end
function update(pawn::Pawn)
    #TODO: Find way to map game objects to their GPU data.
    # Preferably using OpenGL mapping.
    glUniform3fv(pawn.posLoc, 1, pawn.pos)
    glUniform3fv(pawn.scaleLoc, 1, pawn.scale)
    glUniformMatrix4fv(pawn.rotLoc, 1, false, pawn.rot)
    # glUniform4fv(pawn.colorLoc, 1, pawn.color)
end
function render(pawn::Pawn)
    Renderer.bind(pawn.shader)
    Renderer.render(pawn.mesh)
end

end # module
