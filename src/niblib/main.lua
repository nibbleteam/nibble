-- Niblib
-- Biblioteca de API utilitária para o Nibble
-- https://github.com/pongboy/nibble

-- Apaga variáveis globais desnecessárias
time = os.clock

os = nil
dprint = print

-- Importa implementação das funções
local gpu = require('niblib/gpu')
local input = require('niblib/input')
local vid = require('niblib/vid')
local audio = require('niblib/audio')

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
