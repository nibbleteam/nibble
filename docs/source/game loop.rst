.. _game_loop:

Inicialização e Game Loop
=========================

A incialiazção e o game loop são um conjunto de funções que precisam obrigatoriamente existir
em todo *cartridge*. Elas devem ser colocadas no arquivo `main.lua`.

A inicialização é apenas uma função::

    function init()
    end

essa função é chamada assim que o *cartridge* é carregado.

O game loop é um conjunto de duas funções::

    function draw()
    end

    function update(dt)
    end

na `draw()` é adicionado todo o código de renderização do seu cartridge. Na `update(dt)` vai o código de entrada e atualização do estado do jogo.
