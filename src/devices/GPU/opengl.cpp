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

#define TEXTURE_PITCH 400
#define TEXTURE_W 100
#define TEXTURE_H 256

precision lowp float;

uniform sampler2D texture;

vec2 index_to_position(int i, int w, int h) {
    return vec2(
        (float(i%w)+0.5)/float(w),
        (float(i/w)+0.5)/float(h)
    );
}

int subpixel_value(vec4 pixel, int subpixel) {
    if (subpixel == 0) {
        return int(pixel.a*255.0);
    } else if (subpixel == 1) {
        return int(pixel.b*255.0);
    } else if (subpixel == 2) {
        return int(pixel.g*255.0);
    } else if (subpixel == 3) {
        return int(pixel.r*255.0);
    }
}

int subpixel_for_column(vec4 pixel, int column) {
    return subpixel_value(pixel, column%4);
}

int linear_access(sampler2D tex, int w, int h, int index) {
    vec2 position = index_to_position(index, w, h);
    vec4 pixel = texture2D(tex, position);

    return subpixel_value(pixel, int(position.x*w)%4);
}

int palette_colmap_2(int i) {
    return linear_access(texture, TEXTURE_PITCH, TEXTURE_H, TEXTURE_PITCH*240+640+i%TEXTURE_W);
}

void main() {
    int x = int(gl_TexCoord[0].x*TEXTURE_W);
    int y = int(gl_TexCoord[0].y*TEXTURE_H);

    vec2 pixel_position = vec2((float(x)+0.5)/TEXTURE_W, (float(y)+0.5)/TEXTURE_H);
    vec4 pixel = texture2D(texture, pixel_position);

    int raw_index = subpixel_for_column(pixel, int(gl_TexCoord[0].x*TEXTURE_PITCH));
    int paletted_index = palette_colmap_2(raw_index);

    vec2 color_position = index_to_position(TEXTURE_PITCH*240+4*paletted_index, TEXTURE_PITCH, TEXTURE_H);
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
