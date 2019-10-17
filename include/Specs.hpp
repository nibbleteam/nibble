/*
 * Nesse arquivos definimos todas
 * as especificações de hardware
 * do Nibble.
 */

// TODO: Exportar todas essas constantes para
// Lua automaticamente de forma que a niblib
// não precisa ser alterada

#ifndef SPECS_H
#define SPECS_H

#define VERSION_STRING          "0.1.0"

/*
 * GPU
 */

#define BOOT_CYCLES             8

#define GPU_PALETTE_DEPTH       4

#define GPU_PALETTE_LENGTH      16
#define GPU_PALETTE_AMOUNT      8
#define GPU_PALETTE_SIZE        (GPU_PALETTE_LENGTH*GPU_PALETTE_AMOUNT)

#define GPU_PALETTE_TBL1_SIZE   (GPU_PALETTE_SIZE) 
#define GPU_PALETTE_TBL2_SIZE   (GPU_PALETTE_SIZE) 

#define GPU_PALETTE_MEM_SIZE    (GPU_PALETTE_SIZE*GPU_PALETTE_DEPTH+\
                                 GPU_PALETTE_TBL1_SIZE+\
                                 GPU_PALETTE_TBL2_SIZE)

#define GPU_COMMAND_MEM_SIZE    32

#define GPU_VIDEO_WIDTH         320
#define GPU_VIDEO_HEIGHT        240
#define GPU_VIDEO_MEM_SIZE      (GPU_VIDEO_WIDTH*GPU_VIDEO_HEIGHT)

#define GPU_FRAMERATE           30
#define GPU_DEFAULT_SCALING     2

#define GPU_MEM_SIZE            (GPU_COMMAND_MEM_SIZE+\
                                 GPU_PALETTE_MEM_SIZE+\
                                 GPU_VIDEO_MEM_SIZE)

/*
 * Audio
 */

#define AUDIO_SAMPLE_RATE       44100
#define AUDIO_UPDATE_RATE       60

#define AUDIO_SAMPLE_AMOUNT     512
#define AUDIO_SAMPLE_LENGTH     sizeof(int16_t)
#define AUDIO_SAMPLE_MEM_SIZE   (AUDIO_SAMPLE_LENGTH*AUDIO_SAMPLE_AMOUNT)

#define AUDIO_DELAY_AMOUNT      64
#define AUDIO_DELAY_LENGTH      1470
#define AUDIO_DELAY_SIZE        (AUDIO_DELAY_AMOUNT*AUDIO_DELAY_LENGTH)
#define AUDIO_DELAY_MEM_SIZE    (AUDIO_DELAY_SIZE*AUDIO_SAMPLE_LENGTH)

#define AUDIO_CHANNEL_LENGTH    152
#define AUDIO_CHANNEL_AMOUNT    8
#define AUDIO_CHANNEL_MEM_SIZE  (AUDIO_CHANNEL_LENGTH*AUDIO_CHANNEL_AMOUNT)

#define AUDIO_CMD_AMOUNT        16
#define AUDIO_CMD_LENGTH        2
#define AUDIO_CMD_MEM_SIZE      (AUDIO_CMD_AMOUNT*AUDIO_CMD_LENGTH)

#define AUDIO_OPERATOR_AMOUNT   4

#define AUDIO_MEM_SIZE          (AUDIO_CHANNEL_MEM_SIZE+\
                                 AUDIO_SAMPLE_MEM_SIZE)

/*
 * Mouse
 */

#define MOUSE_COORDINATE_LENGTH 2
#define MOUSE_COORDINATE_AMOUNT 2

#define MOUSE_BUTTON_LENGTH     1
#define MOUSE_BUTTON_AMOUNT     2

#define MOUSE_MEM_SIZE          (MOUSE_COORDINATE_LENGTH*MOUSE_COORDINATE_AMOUNT+MOUSE_BUTTON_LENGTH*MOUSE_BUTTON_AMOUNT)

/*
 * Teclado
 */

#define KEYBOARD_QUEUE_SIZE     32

#define KEYBOARD_MEM_SIZE       (KEYBOARD_QUEUE_SIZE)

/*
 * Teclado MIDI
 */

#define MIDI_CONTROLLER_QUEUE_SIZE  1024
//#define NIBBLE_DISABLE_MIDI_CONTROLLER

/*
 * Controles
 */

#define CONTROLLER_AMOUNT       4
#define CONTROLLER_LENGTH_BITS  20
#define CONTROLLER_MEM_SIZE     (CONTROLLER_AMOUNT*CONTROLLER_LENGTH_BITS/8)

/*
 * General
 */

#define PROCESS_INFO_LENGTH     32

#define PROCESS_MEM_SIZE        (16*1024*1024)

#define NIBBLE_MEM_SIZE         (GPU_MEM_SIZE+\
                                 AUDIO_MEM_SIZE+\
                                 MOUSE_MEM_SIZE+\
                                 KEYBOARD_MEM_SIZE+\
                                 CONTROLLER_MEM_SIZE+\
                                 PROCESS_MEM_SIZE)

#endif /* SPECS_H */
