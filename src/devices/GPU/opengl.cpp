#include <devices/GPU/opengl.hpp>

#include <iostream>
#include <string>

using namespace std;

// Referência: https://github.com/AugustoRuiz/sdl2glsl/blob/master/src/main.cpp
PFNGLCREATESHADERPROC glCreateShader;
PFNGLSHADERSOURCEPROC glShaderSource;
PFNGLCOMPILESHADERPROC glCompileShader;
PFNGLGETSHADERIVPROC glGetShaderiv;
PFNGLGETSHADERINFOLOGPROC glGetShaderInfoLog;
PFNGLDELETESHADERPROC glDeleteShader;
PFNGLATTACHSHADERPROC glAttachShader;
PFNGLCREATEPROGRAMPROC glCreateProgram;
PFNGLLINKPROGRAMPROC glLinkProgram;
PFNGLVALIDATEPROGRAMPROC glValidateProgram;
PFNGLGETPROGRAMIVPROC glGetProgramiv;
PFNGLGETPROGRAMINFOLOGPROC glGetProgramInfoLog;
PFNGLUSEPROGRAMPROC glUseProgram;

const static string gl_default_vertex_shader = R"(
#version 130
// Shader padrão do SFML sem alterações
void main()
{
    // transform the vertex position
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    // transform the texture coordinates
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    // forward the vertex color
    gl_FrontColor = gl_Color;
}
)";

const static string gl_expand_colors_shader = R"(
#version 130
uniform sampler2D texture;

vec2 index_to_position(float i, float w, float h) {
    return vec2(
        (floor(mod(i, w))+0.5)/w,
        (floor(i/w)+0.5)/h
    );
}

float subpixel_value(vec4 pixel, int subpixel) {
    if (subpixel == 0) {
        return pixel.a*255.0;
    } else if (subpixel == 1) {
        return pixel.b*255.0;
    } else if (subpixel == 2) {
        return pixel.g*255.0;
    } else if (subpixel == 3) {
        return pixel.r*255.0;
    }
}

float subpixel_for_column(vec4 pixel, float column) {
    return subpixel_value(pixel, int(mod(column, 4.0)));
}

float linear_access(sampler2D tex, float w, float h, float index) {
    vec2 position = index_to_position(index, w, h);
    vec4 pixel = texture2D(tex, position);

    return subpixel_value(pixel, int(mod(position.x*w, 4.0)));
}

float palette_colmap_2(float i) {
    return linear_access(texture, 400.0, 256.0, 400.0*240.0+640.0+mod(i, 128.0));
}

void main() {
    int x = int(gl_TexCoord[0].x*100.0);
    int y = int(gl_TexCoord[0].y*256.0);

    vec2 pixel_position = vec2((float(x)+0.5)/100.0, (float(y)+0.5)/256.0);
    vec4 pixel = texture2D(texture, pixel_position);

    float raw_index = subpixel_for_column(pixel, floor(gl_TexCoord[0].x*400.0));
    float paletted_index = palette_colmap_2(raw_index);

    vec2 color_position = index_to_position(400.0*240.0+floor(paletted_index*4.0), 400.0, 256.0);
    vec4 color = texture2D(texture, color_position);

    gl_FragColor = vec4(color.a, color.b, color.g, color.r);
}
)";

SDL_Renderer* create_opengl_renderer(SDL_Window* window) {
  SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengl");

  return SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
}

void check_opengl() {
    // Inicializa extensões OpenGL
    // Referência: https://github.com/AugustoRuiz/sdl2glsl/blob/master/src/main.cpp
    glCreateShader = (PFNGLCREATESHADERPROC)SDL_GL_GetProcAddress("glCreateShader");
    glShaderSource = (PFNGLSHADERSOURCEPROC)SDL_GL_GetProcAddress("glShaderSource");
    glCompileShader = (PFNGLCOMPILESHADERPROC)SDL_GL_GetProcAddress("glCompileShader");
    glGetShaderiv = (PFNGLGETSHADERIVPROC)SDL_GL_GetProcAddress("glGetShaderiv");
    glGetShaderInfoLog = (PFNGLGETSHADERINFOLOGPROC)SDL_GL_GetProcAddress("glGetShaderInfoLog");
    glDeleteShader = (PFNGLDELETESHADERPROC)SDL_GL_GetProcAddress("glDeleteShader");
    glAttachShader = (PFNGLATTACHSHADERPROC)SDL_GL_GetProcAddress("glAttachShader");
    glCreateProgram = (PFNGLCREATEPROGRAMPROC)SDL_GL_GetProcAddress("glCreateProgram");
    glLinkProgram = (PFNGLLINKPROGRAMPROC)SDL_GL_GetProcAddress("glLinkProgram");
    glValidateProgram = (PFNGLVALIDATEPROGRAMPROC)SDL_GL_GetProcAddress("glValidateProgram");
    glGetProgramiv = (PFNGLGETPROGRAMIVPROC)SDL_GL_GetProcAddress("glGetProgramiv");
    glGetProgramInfoLog = (PFNGLGETPROGRAMINFOLOGPROC)SDL_GL_GetProcAddress("glGetProgramInfoLog");
    glUseProgram = (PFNGLUSEPROGRAMPROC)SDL_GL_GetProcAddress("glUseProgram");

    // Se alguma extensão não foi encontrada
    if (!(glCreateShader && glShaderSource &&
          glCompileShader && glGetShaderiv &&
          glGetShaderInfoLog && glDeleteShader &&
          glAttachShader && glCreateProgram &&
          glLinkProgram && glValidateProgram &&
          glGetProgramiv && glGetProgramInfoLog &&
          glUseProgram)) {
        cout << "Could not load the required GL Extensions!" << endl;
        cout << "Quitting." << endl;

        exit(1);
    }
}

void print_shader_errors(GLuint shader) {
    GLint log_len;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &log_len);

    if (log_len > 0) {
        auto log = new GLchar[log_len];

        glGetShaderInfoLog(shader, log_len, &log_len, log);

        cout << "Error while compiling shader: " << log << endl;

        delete log;
    }
}

GLuint compile_shader(const string &source, const GLuint type) {
    // C-string
    auto c_source = source.c_str();

    // Cria
    GLuint shader = glCreateShader(type);
    // Coloca o código fonte
    glShaderSource(shader, 1, &c_source, NULL);
    // Compila
    glCompileShader(shader);

    // Checa se houve erros
    GLint compiled = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if(compiled != GL_TRUE) {
        // Escreve os erros
        print_shader_errors(shader);

        glDeleteShader(shader);

        return 0;
    }

    // Retorna o shader
    return shader;
}

GLuint compile_glsl_program(const string &vertex_source, const string &fragment_source) {
    // Compila os shaders
    auto vertex_shader = compile_shader(vertex_source, GL_VERTEX_SHADER);
    auto fragment_shader = compile_shader(fragment_source, GL_FRAGMENT_SHADER);

    // Se tem erros nos shaders, sai
    if (!(vertex_shader || fragment_shader)) {
        return 0;
    }

    // Cria um programa com os shaders
    auto program = glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    // Checa o programa
    glValidateProgram(program);

    GLint link_status;
    glGetProgramiv(program, GL_LINK_STATUS, &link_status);

    if (link_status == GL_FALSE) {
        cout << "Shader program linking failed. Checking logs." << endl;

        // Escreve os erros, se algum
        GLint log_len;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &log_len);

        if(log_len > 0) {
            cout << "There are " << log_len << " characters of logs." << endl;

            auto log = new GLchar[log_len];

            glGetProgramInfoLog(program, log_len, &log_len, log);
            cout << "Error linking shader: " << log << endl;

            delete log;
        } else {
            cout << "No logs found." << endl;
        }

        glDeleteShader(vertex_shader);
        glDeleteShader(fragment_shader);

        return 0;
    }

    // Não precisamos mais dos shaders
    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);

    return program;
}

GLuint create_opengl_shader() {
  return compile_glsl_program(gl_default_vertex_shader, gl_expand_colors_shader);
}

void use_glsl_shader(GLuint shader) {
  glUseProgram(shader);
}
