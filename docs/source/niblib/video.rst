Niblib - Video
==============

.. todo::

    Exemplo de código e imagem para cada função

Cores
-----

As cores no Nibble indicam um *índice* nas paletas de cores

A paleta padrão (ao ser iniciado) do nibble é a seguinte:

.. raw:: html

    <p>
        <table border="1" style="width: 100%; text-align: center;">
            <tr>
                <th>Índice</th>
                <th>Cor</th>
            </tr>
            <tr>
                <td>0</td>
                <td style="background: #140c1c !important; color: white">#140c1c</td>
            </tr>
            <tr>
                <td>1</td>
                <td style="background: #442434 !important; color: white">#442434</td>
            </tr>
            <tr>
                <td>2</td>
                <td style="background: #30346d !important; color: white">#30346d</td>
            </tr>
            <tr>
                <td>3</td>
                <td style="background: #4e4a4e !important; color: white">#4e4a4e</td>
            </tr>
            <tr>
                <td>4</td>
                <td style="background: #854c30 !important; color: white">#854c30</td>
            </tr>
            <tr>
                <td>5</td>
                <td style="background: #346524 !important; color: white">#346524</td>
            </tr>
            <tr>
                <td>6</td>
                <td style="background: #d04648 !important; color: white">#d04648</td>
            </tr>
            <tr>
                <td>7</td>
                <td style="background: #757161 !important; color: white">#757161</td>
            </tr>
            <tr>
                <td>8</td>
                <td style="background: #597dce !important; color: black">#597dce</td>
            </tr>
            <tr>
                <td>9</td>
                <td style="background: #d27d2c !important; color: black">#d27d2c</td>
            </tr>
            <tr>
                <td>10</td>
                <td style="background: #8595a1 !important; color: black">#8595a1</td>
            </tr>
            <tr>
                <td>11</td>
                <td style="background: #6daa2c !important; color: black">#6daa2c</td>
            </tr>
            <tr>
                <td>12</td>
                <td style="background: #d2aa99 !important; color: black">#d2aa99</td>
            </tr>
            <tr>
                <td>13</td>
                <td style="background: #6dc2ca !important; color: black">#6dc2ca</td>
            </tr>
            <tr>
                <td>14</td>
                <td style="background: #dad45e !important; color: black">#dad45e</td>
            </tr>
            <tr>
                <td>15</td>
                <td style="background: #deeed6 !important; color: black">#deeed6</td>
            </tr>
        </table>
    </p>

Essa paleta pode ser modificada escrevendo-se na área de memória reservada
para paletas.

Funções
-------

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
    :param int w: Comprimento do sprite
    :param int h: Altura do sprite
    :param int pal: Paleta a ser utilizada

.. function:: rectf(x, y, w, h, cor)

    Desenha um retângulo preenchido

    :param int x: Coordenada x na tela
    :param int y: Coordenada y na tela
    :param int w: Comprimento
    :param int h: Altura
    :param int cor: Cor do preenchimento

.. function:: quadf(x1, y1, x2, y2, x3, y3, x4, y4, cor)

    Desenha um quadrilátero preenchido nos pontos dados

.. function:: trif(x1, y1, x2, y2, x3, y3, cor)

    Desenha um triângulo preenchido nos pontos dados

.. function:: circf(x, y, r, cor)

    Desenha um círculo preenchido

    :param int x: Coordenada x na tela
    :param int y: Coordenada y na tela
    :param int r: Raio do círculo
    :param int cor: Cor do preenchimento

.. function:: line(x1, y1, x2, y2, cor)

    Desenha uma linha

    :param int x1: Coordenada x inicial
    :param int y1: Coordenada y incial
    :param int x2: Coordenada x final
    :param int y2: Coordenada y final
    :param int cor: Cor da linha

.. function:: rect(x, y, w, h, cor)

    Desenha um retângulo sem preenchimento, ver :func:`rectf` para os parâmetros.

.. function:: circ(x, y, r, cor)

    Desenha um círculo sem preenchimento, ver :func:`circf` para os parâmetros.

.. function:: tri(x1, y1, x2, y2, x3, y3, cor)

    Desenha um triângulo sem preenchimento, ver :func:`trif` para os parâmetros.

.. function:: quad(x1, y1, x2, y2, x3, y3, x4, y4, cor)

    Desenha um quadrilátero sem preenchimento, ver :func:`quadf` para os parâmetros.

.. function:: print(str, x, y, [pal])

    Escreve uma string na tela

    :param string str: Texto a ser escrito na tela
    :param int x: Coordenada x onde será escrito o texto
    :param int y: Coordenada y onde será escrito o texto
    :param int pal: Paleta a ser utilizada opcionalmente para desenhar o texto

    .. warning::

        Essa função só funciona se houver uma fonte na spritesheet!
