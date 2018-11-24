-- Niblib
-- Biblioteca de API utilitária para o Nibble
-- https://github.com/pongboy/nibble

-- Apaga variáveis globais desnecessárias
time = os.clock

os = nil
dprint = print

-- Cria esqueleto de funções
function init()
end

function update(dt)
end

function draw()
end

-- Importa implementação das funções
local gpu = require('frameworks/niblib/gpu')
local input = require('frameworks/niblib/input')
local vid = require('frameworks/niblib/vid')
local audio = require('frameworks/niblib/audio')
-- Helpers da linguagem
lang = require('frameworks/niblib/lang')


-- Exporta a API gráfica

-- Limpar a tela
clr = gpu.clr

-- Sprites
spr = gpu.spr
pspr = gpu.pspr

-- Cores
pal = gpu.pal
col = gpu.col
mix = gpu.mix

-- Formas
rectf = gpu.rectf
quadf = gpu.quadf
trif = gpu.trif
circf = gpu.circf
line = gpu.line
circ = gpu.circ
rect = gpu.rect
quad = gpu.quad
tri = gpu.tri
mask = gpu.mask
setcol = gpu.setcol
cppal = gpu.cppal
col = gpu.col
screen = gpu.screen

-- GIF
start_recording = gpu.start_recording
stop_recording = gpu.stop_recording

-- Print
print = gpu.print

-- Exporta a API de entrada
btd = function (b) return input.bt(b) == input.STDOWN; end
btu = function (b) return input.bt(b) == input.STUP; end
btp = function (b) return input.bt(b) == input.STPRESSED; end
btr = function (b) return input.bt(b) == input.STRELEASED; end

-- Manimulação direta da memória de vídeo
putp = vid.putp
getp = vid.getp

-- Acesso a memória
function read16(p)
    local data = kernel.read(p, 2)
    local value = data:byte(2)
    value = value+data:byte(1)*256
    return value
end

function read8(p)
    return kernel.read(p, 1):byte()
end

UP = input.UP
DOWN = input.DOWN
LEFT = input.LEFT
RIGHT = input.RIGHT

RED = input.RED
BLUE = input.BLUE

BLACK = input.BLACK
WHITE = input.WHITE

-- Áudio
snd = audio.snd
mksnd = audio.mksnd
note = audio.note
skip = audio.skip
rep = audio.rep
loop = audio.loop
stop = audio.stop
adsr = audio.adsr

