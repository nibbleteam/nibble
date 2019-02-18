# Taskbar

A taskbar é exatamente o que o nome diz: uma
barra que gerencia as `tarefas`, ou seja, os
diferentes editores para cada tipo de arquivo.

De uma forma simples ela permite trocar entre
os editores de:

- música
- código
- sprites
- etc

# NOM

O primeiro passo é incluir o módulo do NOM,
que nos permite desenhar a UI da taskbar:

    local NOM = require 'nibui.NOM'

Em seguida, criar o NOM da taskbar:

    local taskbar = NOM:new(require 'taskbar') 

e também declarar variáveis para conter os processos
de cada um dos editores, o que vai nos permitir trocar
entre eles depois.

    pids = {
        music = 0,
        code = 0,
        sprite = 0,
    }

    running = {}

# Inicialização

O primeiro passo da inicialização é duplicar a paleta padrão
do nibble e mascarar a cor `0`, permitindo o uso de
transparência.

    function init_colors()
        cppal(0, 1)
        mask(0)
    end

Em seguida, rodamos (com `kernel.exec`) todos os editores:

    function init()
        init_colors()

        for editor, _ in pairs(pids) do 
            pids[editor], _ = kernel.exec('apps/user/creator/'..editor..'.nib', {})
        end

Deixa apenas um rodando:

        run('music')

        start_recording('Nibble Creator.gif')
    end

Após inicializar tudo, entramos em um loop que é apenas
atualizar e desenhar o NOM. Todo o restante do trabalho
é feito pelo NOM (de `taskbar.lua.md`).

    function update(dt)
        taskbar:update(dt)
    end

    function draw()
        taskbar:draw()
    end

    function run(target)
        for editor, _ in pairs(pids) do 
            if editor == target then
                kernel.send(pids[editor], {running=true})
                running[editor] = true
                taskbar:find('#'..editor):onenter()
            else
                kernel.send(pids[editor], {running=false})
                running[editor] = nil
                taskbar:find('#'..editor):onleave()
            end
        end
    end
