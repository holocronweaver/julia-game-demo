struct Mesh
    vertices::Array{GLfloat, 2}
    indices::Array{GLuint, 1}
end

struct Shader
    program

    function Shader(vertexFile, fragFile)
        # Compile shaders.
        vertexShader = Renderer.createShaderFromFile(vertexFile, GL_VERTEX_SHADER)
        fragmentShader = Renderer.createShaderFromFile(fragFile, GL_FRAGMENT_SHADER)
        program = Renderer.createShaderProgram(vertexShader, fragmentShader)

        new(program)
    end
end

struct Color
    r::GLubyte
    g::GLubyte
    b::GLubyte
    a::GLubyte

    # function Color(value)
    #     new(value, value, value, value)
    # end

    # function Color(gray, alpha)
    #     new(gray, gray, gray, alpha)
    # end

    # function Color(red, green, blue, alpha)
    #     new(red, green, blue, alpha)
    # end
end

struct Texture
    glName::GLuint
    sampler::GLuint
    unit::GLuint
    data::Array

    function Texture(texturePath::String)
        texture = load(texturePath)
        Texture(texture)
    end

    function Texture(data::Array)
        global textureCount
        textureUnit = textureCount
        textureCount += 1

        # Create texture buffer and fill it with data.
        glName = glGenTexture()
        glBindTexture(GL_TEXTURE_2D, glName)

        setTexturePackingAlignment(data)
        # data = fill(Color(0, 0, 255, 1), (2, 2))
        glTexImage2D(GL_TEXTURE_2D,    # target
                     0,                # level
                     GL_RGB,           # storage format
                     size(data, 1),    # width
                     size(data, 2),    # height
                     0,                # border
                     GL_RGB,           # data format
                     GL_UNSIGNED_BYTE, # type
                     data)             # data
        dataCheck = zeros(GLubyte, 3 * length(data))
        # glGetTexImage(GL_TEXTURE_2D, 0, GL_RGB, GL_UNSIGNED_BYTE, dataCheck)
        # println("data check: ", dataCheck)
        # glCheckError("Setting up a texture")

        # Specify texture parameters.
        # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
        # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

        glBindTexture(GL_TEXTURE_2D, 0)

        # Create sampler and set its parameters.
        #TODO: Separate sampler from texture?
        sampler = glGenSampler()
        # glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        # glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glSamplerParameteri(sampler, GL_TEXTURE_WRAP_S, GL_REPEAT)
        glSamplerParameteri(sampler, GL_TEXTURE_WRAP_T, GL_REPEAT)
        # glSamplerParameteri(sampler, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        # glSamplerParameteri(sampler, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

        new(glName, sampler, textureUnit, data)
    end
end
function bind(texture::Texture, shader::Shader)
    # Bind texture, sampler, and sampler uniform to same texture unit.
    bind(texture)
    glBindSampler(texture.unit, texture.sampler)
    samplerLoc = glGetUniformLocation(shader.program, "texSampler")
    glProgramUniform1i(shader.program, samplerLoc, texture.unit)
    hasTextureLoc = glGetUniformLocation(shader.program, "hasTexture")
    glProgramUniform1ui(shader.program, hasTextureLoc, GLuint(true))
end
#TODO: If bindless textures aren't used, should probably store texture
# unit with texture, or else have a per-program texture->unit map.
function bind(texture::Texture)
    oglTextureUnit = getfield(Renderer, Symbol("GL_TEXTURE", texture.unit))
    glActiveTexture(oglTextureUnit)
    glBindTexture(GL_TEXTURE_2D, texture.glName)
end
function unbindTexture(shader::Shader)
    hasTextureLoc = glGetUniformLocation(shader.program, "hasTexture")
    glProgramUniform1ui(shader.program, hasTextureLoc, GLuint(false))
end
function setTexturePackingAlignment(a)
    #TODO: Specialize to array/ptr a.
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0)
    glPixelStorei(GL_UNPACK_SKIP_ROWS, 0)
end

struct Item
    shader::Shader
    mesh::Mesh
    texture::Nullable{Texture}

    vao::GLuint
    vbo::GLuint
    ibo::GLuint

    function Item(shader::Shader, mesh::Mesh,
                  texture::Nullable{Texture} = null)
        vao = glGenVertexArray()
        glBindVertexArray(vao)

        #TODO: Map variables? Structs?
        #TODO: Ideally OpenGL <-> Julia, unified structs. Unclear how
        # to best do that.

        vbo = glGenBuffer()
        glBindBuffer(GL_ARRAY_BUFFER, vbo)
        glBufferData(GL_ARRAY_BUFFER,
                     sizeof(mesh.vertices), mesh.vertices', GL_STATIC_DRAW)
        positionIndex = glGetAttribLocation(shader.program, "vertPos")
        glEnableVertexAttribArray(positionIndex)
        glVertexAttribPointer(positionIndex, 3, GL_FLOAT, false, 0, C_NULL)
        glBindBuffer(GL_ARRAY_BUFFER, 0)

        ibo = glGenBuffer()
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                     sizeof(mesh.indices), mesh.indices, GL_STATIC_DRAW)

        glBindVertexArray(0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

        new(shader, mesh, texture, vao, vbo, ibo)
    end
end
