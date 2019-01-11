-- Niblib
-- Biblioteca de API utilitária para o Nibble
-- https://github.com/pongboy/nibble

-- Apaga variáveis globais desnecessárias
time = os.time
clock = os.clock

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
local lang = require('frameworks/niblib/lang')

-- Exporta API da linguagem
instanceof = lang.instanceof
copy = lang.copy
zip = lang.zip

-- Exporta a API gráfica

-- Limpar a tela
clr = gpu.clr

-- Sprites
spr = gpu.spr
pspr = gpu.pspr

-- Cores
mask = gpu.mask
setcol = gpu.setcol
cppal = gpu.cppal
col = gpu.col
screen = gpu.screen

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

-- Clip
clip = gpu.clip

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
OP1 = audio.OP1
OP2 = audio.OP2
OP3 = audio.OP3
OP4 = audio.OP4
OUT = audio.OUT

CH1 = audio.CH1
CH2 = audio.CH2
CH3 = audio.CH3
CH4 = audio.CH4
CH5 = audio.CH5
CH6 = audio.CH6
CH7 = audio.CH7
CH8 = audio.CH8

encode = audio.encode
channel = audio.channel
envelope = audio.envelope
freqs = audio.freqs
reverb = audio.reverb
route = audio.route
noteon = audio.noteon
noteoff = audio.noteoff
