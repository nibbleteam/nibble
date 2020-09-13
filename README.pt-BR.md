[English](README.md) [Português](README.pt-BR.md)

# Nibble

É um Console-Fantasia feito para funcionar em hardware de verdade e muito
foco em UX e design.

# Primeiros Passos

Primeiro, baixe o emulador e a SDK dá página de [releases](https://github.com/nibbleteam/nibble/releases).

Para rodar a versão de macOS provavelmente você vai precisar mexer em algo no sistema, porquê ela não é notarizada pela Apple.

Depois de extrair o `.zip` você pode rodar o executável `nibble`.

Você será recebido pela shell.

Você pode rodar qualquer programa digitando o nome dele.

<p align="center">
        <img style="image-rendering: pixelated;" src ="https://github.com/pongboy/nibble/raw/master/assets/screencaps/v0.2.0-cut.gif" width="800" height="480"/>
</p>

Dá uma olhada na [documentação](https://docs.nibble.world).

# Compilando 

O Nibble usa a ferramenta `CMake` para compilar o código. Há dois passos para executá-la.

1. criar uma pasta para compilar: `mkdir build && cd build`;
2. rodar cmake e make: `cmake .. && make`.

Esses dois passos vão gerar um executável `nibble` que pode ser rodado de dentro
do diretório `src` (isso é necessário porquê o OS do nibble está lá):

`cd ../src && ../build/nibble`
