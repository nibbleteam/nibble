Inicialização e Game Loop
=========================

A incialiazção e o game loop são um conjunto de funções que precisam obrigatoriamente existir
em todo *cartridge*.

A inicialização é apenas uma função::

    function init()
    end

essa função é chamada assim que o *cartridge* é carregado.

O game loop é um conjunto de duas funções::

    function draw()
    end

    function update()
    end

na `draw()` é adicionado todo o código de renderização do seu cartridge. Na `update()` vai o código de entrada e atualização do estado do jogo.
