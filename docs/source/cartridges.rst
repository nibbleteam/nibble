Cartridges
==========

.. todo::

    Quebrar em seções

Todo jogo ou aplicativo do Nibble é um *cartridge*, até mesmo os aplicativos de sistema.

Um *cartridge* é uma pasta contendo todo o código, sprites e quaisquer outros dados
necessários para rodar jogo ou aplicativo.

O nome da pasta deve ser o nome do aplicativo, e ela deve conter (no mínimo), uma pasta `assets` e um arquivo `main.lua`::

    apps/demos/mixed-gpu-cpu/
    ├── assets
    └── main.lua

O arquivo `main.lua` contém o código do cartridge utilizando :ref:`game_loop` e as funções da :ref:`niblib` . Dentro da pasta `assets` encontram-se os arquivos gráficos, de áudio, de mapas e todos os outros dados do aplicativo.

O Nibble carrega automaticamente uma spritesheet de até 4096x1024 pixels para a memória de sprites se encontrada em `assets/sheet.png`::

    apps/shell/
    ├── assets
    │   └── sheet.png
    └── main.lua

.. note::

    Para publicar um cartridge em um só arquivo, basta comprimir a pasta como .zip e renomear para .nib.

.. warning::

    Ao publicar um arquivo .nib, `main.lua` e `assets` precisam estar na *raiz* do arquivo comprimido.

