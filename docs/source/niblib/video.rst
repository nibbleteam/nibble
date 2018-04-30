Niblib - Video
==============

.. note::

    [argumento] indica que *argumento* é opcional.

.. function:: clr([cor])

    Limpa a tela

    :param int cor: A cor a ser utilizada para limpar

.. function:: spr(x, y, sprx, spry, [pal])

    Desenha um sprite 16x16 na tela::

        spr(0, 0, 1, 1)

    irá desenhar no canto superior esquerdo da tela (0, 0) o sprite que na spritesheet se encontra em 16, 16.

    :param int x: Coordenada x na tela
    :param int y: Coordenada y na tela
    :param int sprx: Posição x do sprite na spritesheet
    :param int spry: Posição y do sprite na spritesheet
    :param int pal: Paleta a ser utilizada

    .. warning::

        A posição do sprite para essa função é dada em sprites 16x16, não em pixels,
        para pixels veja :func:`pspr`

.. function:: pspr(x, y, sx, sy, w, h, [pal])

    Desenha um sprite de qualquer tamanho na tela::

        pspr(0, 0, 0, 0, 32, 32)

    irá desenhar no canto superior esquerdo da tela (0, 0) um sprite de tamanho 32, 32 que se encontra na posição 0,0 da spritesheet.

    :param int x: Coordenada x na tela
    :param int y: Coordenada y na tela
    :param int sx: Coordenada x na spritesheet
    :param int sy: Coordenada y na spritesheet
    :param int pal: Paleta a ser utilizada
