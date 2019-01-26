Apps
====

Todo jogo ou aplicativo do Nibble é um *app*, até mesmo os aplicativos de sistema.

Um *app* é uma pasta contendo todo o código, sprites e quaisquer outros dados
necessários para rodar jogo ou aplicativo.

O nome da pasta deve ser o nome do aplicativo finalizado com `.nib`, e ela deve conter no mínimo um arquivo `main.lua`, podendo também conter uma pasta `assets`::

    apps/demos/mixed-gpu-cpu.nib/
    ├── assets/
    └── main.lua

O arquivo `main.lua` contém o código do cartridge utilizando :ref:`game_loop` e as funções da :ref:`niblib` . Dentro da pasta `assets` encontram-se os arquivos gráficos, de áudio, de mapas e todos os outros dados do aplicativo.

O Nibble carrega automaticamente uma spritesheet de até 4096x1024 pixels para a memória de sprites se encontrada em `assets/sheet.png`::

    apps/shell/
    ├── assets/
    │   └── sheet.png
    └── main.lua

.. note::

    Para publicar um cartridge em um só arquivo, basta comprimir a pasta como .zip e remover a extensão, mantendo só o .nib.

.. warning::

    Ao publicar um arquivo .nib, `main.lua` e `assets` precisam estar na *raiz* do arquivo comprimido.
