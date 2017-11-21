# O que é? 

Console Fantasia feito para funcionar em hardware real.

# Hierarquia do código

* **[src][src/]**: código fonte
* **[include][include/]**: cabeçalhos

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
