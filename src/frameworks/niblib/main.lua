-- Niblib
-- Biblioteca de API utilitária para o Nibble
-- https://github.com/pongboy/nibble

-- Exporta a API de entrada

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
