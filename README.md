# O que é? 

Console Fantasia feito para funcionar em hardware real.

<div style="text-align:center"><img style="image-rendering: pixelated;" src ="https://github.com/pongboy/oort/raw/gpu/assets/screencaps/boot-demo.gif" width="640" height="480"/></div>

# Hierarquia do código

## Diretórios 

* **[src](src/)**: código fonte
* **[include](include/)**: cabeçalhos
* **[assets](assets/)**: ícones, imagens e áudio gerais para o projeto; assets de um cart específico tem sua própria pasta.
* **[extern](extern/)**: bibliotecas externas que são compiladas junto ao projeto
* **[src/kernel/drivers/](src/kernel/drivers/)**: implemenctação de dispositivos
* **[src/apps/](src/apps/)**: carts de aplicativos de sistema
* **[src/stdlib/](src/stdlib/)**: uma biblioteca acessível para todos os processos (em lua) que facilita o acesso ao kernel e adiciona uma API simples de usar

## Arquivos

* **[src/main.cpp](src/main.cpp)**: ponto de entrada
* **[src/kernel/Kernel.cpp](src/kernel/Kernel.cpp)**: controle de processos e memória; API para Lua
* **[include/kernel/Memory.hpp](include/kernel/Memory.hpp)**: dispositivos mapeados em memória implementam essa interface
* **[src/kernel/Process.cpp](src/kernel/Process.cpp)**: carrega e executa carts
* **[src/kernel/drivers/VideoMemory.cpp](src/kernel/drivers/VideoMemory.cpp)**: acesso direto a texturas que representam a memória e vídeo

# Compilando

## Linux

1. Baixe o projeto

        git clone https://github.com/pongboy/oort

2. Entre no diretório e crie um outro diretório chamado build

        cd oort
        git submodule update --init --recursive
        mkdir build

3. Entre no build e rode o cmake e make

        cd build
        cmake ..
        make

## Windows (Geral)

Baixe o código utilizando seu método preferido (GUI git, git bash etc). Lembre de inicializar
os submódulos com `git submodule update --init --recursive` ou o equivalente na sua plataforma.

Instale o cmake se não tiver.

Abra o `CMake GUI` e selecione o diretório do código baixado no primeiro campo de texto.

No segundo campo de texto, insira o mesmo caminho, mas com `\build` ao final.

### Windows (Code::Blocks)

Clique em `configure` e escolha o gerador `Code Blocks - MinGW Makefiles`.

Configure e gere o projeto.

Abra o projeto no Code::Blocks e compile. Para rodar selecione apenas "pongboy" como target no lugar de "all"
e mande rodar.

### Windows (Visual Studio)

Clique em `configure` e escolha o gerador de acordo com sua versão do VS.

Configure e gere o projeto.

Abra o projeto no VS e compile. Para rodar adicione a solução "pongboy" como ponto de entrada clicando com o botão direito.

## macOS (XCode)
