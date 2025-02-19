.agc

.include "agc/agc.inc"
.include "lcd/ssd1331.inc"
.include "test/extra_io.inc"

load_start    equ 100
load_end      equ 101
memcpy_source equ 102
lm_x          equ 103
lm_y          equ 104
counter       equ 105
temp          equ 106
save_q        equ 107
velocity_x    equ 108
velocity_y    equ 109
lm_fixed_x    equ 110
lm_fixed_y    equ 111
lm_int_x      equ 112
lm_int_y      equ 113

;; The image of the lunar lander and erased lunar lander is between
;; 120 to 148.
;; The square is 11 words long.
lm_ram_data_start  equ 120
lm_ram_data_end    equ 131
lm_ram_erase_start equ 131
lm_ram_erase_end   equ 142

.org 02000

lcd_init_data:
  .dc16 SSD1331_DISPLAY_OFF
  .dc16 SSD1331_SET_REMAP
  .dc16 0x72
  .dc16 SSD1331_START_LINE
  .dc16 0x00
  .dc16 SSD1331_DISPLAY_OFFSET
  .dc16 0x00
  .dc16 SSD1331_DISPLAY_NORMAL
  .dc16 SSD1331_SET_MULTIPLEX
  .dc16 0x3f
  .dc16 SSD1331_SET_MASTER
  .dc16 0x8e
  .dc16 SSD1331_POWER_MODE
  .dc16 SSD1331_PRECHARGE
  .dc16 0x31
  .dc16 SSD1331_CLOCKDIV
  .dc16 0xf0
  .dc16 SSD1331_PRECHARGE_A
  .dc16 0x64
  .dc16 SSD1331_PRECHARGE_B
  .dc16 0x78
  .dc16 SSD1331_PRECHARGE_C
  .dc16 0x64
  .dc16 SSD1331_PRECHARGE_LEVEL
  .dc16 0x3a
  .dc16 SSD1331_VCOMH
  .dc16 0x3e
  .dc16 SSD1331_MASTER_CURRENT
  .dc16 0x06
  .dc16 SSD1331_CONTRAST_A
  .dc16 0x91
  .dc16 SSD1331_CONTRAST_B
  .dc16 0x50
  .dc16 SSD1331_CONTRAST_C
  .dc16 0x7d
  .dc16 SSD1331_DISPLAY_ON
  .dc16 SSD1331_FILL_ENABLE
  .dc16 0x01, 0x00
lcd_init_data_end:

;; OLED display is 96x64.
;; Coordinate data is: x0, y0, x1, y1.

horizon_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16    0,   21,   95,  63
  .dc16 0x00, 0x00, 0x00
  .dc16 0x00, 0x00, 0x00
horizon_data_end:

ground_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16    0,    0,   95,  20
  .dc16 0x10, 0x10, 0x10
  .dc16 0x10, 0x10, 0x10
ground_data_end:

landing_pad_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   40,   10,   56,  20
  .dc16 0x00, 0x00, 0xff
  .dc16 0x00, 0x00, 0xff
landing_pad_data_end:

landing_pad_crash_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   40,   10,   56,  20
  .dc16 0xff, 0x00, 0x00
  .dc16 0xff, 0x00, 0x00
landing_pad_crash_data_end:

landing_pad_safe_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   40,   10,   56,  20
  .dc16 0x00, 0xff, 0x00
  .dc16 0x00, 0xff, 0x00
landing_pad_safe_data_end:

;; horizon is (0, 21) - (95,  63)
lm_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   30,   50,   37,  57
  .dc16 0xff, 0xff, 0xff
  .dc16 0xff, 0xff, 0xff
lm_data_end:

lm_erase_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   30,   50,   37,  57
  .dc16 0x00, 0x00, 0x00
  .dc16 0x00, 0x00, 0x00
lm_erase_data_end:

spi_idle:
  .dc16 0x07
spi_command:
  .dc16 0x01
const_1:
  .dc16 0x0001
const_2:
  .dc16 0x0002
const_8:
  .dc16 0x0008
const_7:
  .dc16 7
const_neg_1:
  .dc16 0x7ffe
;const_64:
;  .dc16 64
delay_length_short:
  .dc16 0x7ff0
delay_length_200ms:
  .dc16 0x7feb
marker_0:
  .dc16 0x1234
marker_1:
  .dc16 0x9876
marker_2:
  .dc16 0x1122
lm_x_start:
  .dc16 88 << 4
lm_y_start:
  .dc16 54 << 4
offset_x0:
  .dc16 1
offset_y0:
  .dc16 2
offset_x1:
  .dc16 3
offset_y1:
  .dc16 4

landing_pad_x0:
  .dc16 39
landing_pad_x1:
  .dc16 56 - 8

lcd_init_start:
  .dc16 lcd_init_data
lcd_init_end:
  .dc16 lcd_init_data_end - 1
horizon_start:
  .dc16 horizon_data
horizon_end:
  .dc16 horizon_data_end - 1
ground_start:
  .dc16 ground_data
ground_end:
  .dc16 ground_data_end - 1
landing_pad_start:
  .dc16 landing_pad_data
landing_pad_end:
  .dc16 landing_pad_data_end - 1
landing_pad_crash_start:
  .dc16 landing_pad_crash_data
landing_pad_crash_end:
  .dc16 landing_pad_crash_data_end - 1
landing_pad_safe_start:
  .dc16 landing_pad_safe_data
landing_pad_safe_end:
  .dc16 landing_pad_safe_data_end - 1
lm_start:
  .dc16 lm_ram_data_start
lm_end:
  .dc16 lm_ram_data_end - 1
lm_erase_start:
  .dc16 lm_ram_erase_start
lm_erase_end:
  .dc16 lm_ram_erase_end - 1
lm_rom_start:
  .dc16 lm_data
ground_y0:
  .dc16 21
;debug_velocity:
;  .dc16 0x7ffc

.if 0
gravity_start:
  .dc16 gravity_table
gravity_end:
  .dc16 gravity_table_end - 1
.endif

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca spi_idle
  write IO_DATA_1

  ;; Init LCD display.
  ca lcd_init_start
  ts load_start
  ca lcd_init_end
  ts load_end
  tc lcd_load

  ca delay_length_short
  tc delay

  ;; Draw the horizon.
  ca horizon_start
  ts load_start
  ca horizon_end
  ts load_end
  tc lcd_load

  ca delay_length_short
  tc delay

  ;; Draw the ground.
  ca ground_start
  ts load_start
  ca ground_end
  ts load_end
  tc lcd_load

  ca delay_length_short
  tc delay

  ;; Draw the landing pad.
  ca landing_pad_start
  ts load_start
  ca landing_pad_end
  ts load_end
  tc lcd_load

  ;; Copy LEM and erase LEM to RAM.
  ca lm_rom_start
  ts memcpy_source
  ca lm_start
  ts load_start
  ca lm_erase_end
  ts load_end
  tc memcpy

  ca lm_x_start
  ts lm_x
  ca lm_y_start
  ts lm_y

  ca marker_0
  write DISPLAY_DATA
  tc wait_display

  ca ZERO
  ts velocity_x
  ts velocity_y

game_loop:
  tc lm_move

  ;; delay 200ms.
  ca delay_length_200ms
  tc delay

  ;; Joystick:
  ;; bit 0 = right.
  ;; bit 1 = left.
  ;; bit 2 = down.
  ;; bit 3 = up.
  ;; bit 4 = fire.

  ;; If joystick isn't up, increase velocity by 1.
  ;; If joystick is up, decrease velocity by 1.
  ca const_8
  rand JOYSTICK
  ;write DISPLAY_DATA
  bzf game_loop_joystick_up
  ca const_neg_1
  ads velocity_y
  tcf game_loop_joystick_up_done
game_loop_joystick_up:
  ca const_1
  ads velocity_y
game_loop_joystick_up_done:

  ;; If joystick is left move velocity left by 1.
  ca const_2
  rand JOYSTICK
  bzf game_loop_joystick_left
  tcf game_loop_joystick_left_done
game_loop_joystick_left:
  ca const_1
  ads velocity_x
game_loop_joystick_left_done:

  ;; If joystick is right move velocity right by 1.
  ca const_1
  rand JOYSTICK
  bzf game_loop_joystick_right
  tcf game_loop_joystick_right_done
game_loop_joystick_right:
  ca const_neg_1
  ads velocity_x
game_loop_joystick_right_done:

  ;; Using velocity, move lundar lander.
  index velocity_y
  ca gravity_velocity_0
  ads lm_y

  index velocity_x
  ca gravity_velocity_0
  ads lm_x

  ;; If lunar lander is past ground, crash it. If it's equal to the
  ;; ground, make it safe.
  ca horizon_data + 2
  ts temp
  ca lm_int_y
  su temp
  bzf game_loop_safe
  bzmf game_loop_crash

  tc game_loop

game_loop_safe:
  ;; Check to make sure the lander is on the landing pad before
  ;; declaring it safe.
  ca landing_pad_x0
  ts temp
  ca lm_int_x
  su temp
  bzmf game_loop_crash

  ca landing_pad_x1
  su lm_int_x
  bzmf game_loop_crash

  ca marker_1
  write DISPLAY_DATA
  tc wait_display

  ;; Draw the green landing pad.
  ca landing_pad_safe_start
  ts load_start
  ca landing_pad_safe_end
  ts load_end
  tc lcd_load

  edrupt 0

game_loop_crash:
  ca marker_2
  write DISPLAY_DATA
  tc wait_display

  ;; Draw the red landing pad.
  ca landing_pad_crash_start
  ts load_start
  ca landing_pad_crash_end
  ts load_end
  tc lcd_load

  edrupt 0

lm_move:
  qxch save_q

  ;; Erase the lander.
  ca lm_erase_start
  ts load_start
  ca lm_erase_end
  ts load_end
  tc lcd_load

  ;; Delay before redraw.
  ;ca delay_length_short
  ;tc delay

  ;; Draw the lander.
  ca lm_x
  ts SR
  ca SR
  ts SR
  ca SR
  ts SR
  ca SR
  ts SR
  ca SR
  ts lm_int_x
  index offset_x0
  ts lm_ram_data_start
  index offset_x0
  ts lm_ram_erase_start
  ad const_7
  index offset_x1
  ts lm_ram_data_start
  index offset_x1
  ts lm_ram_erase_start

  ca lm_y
  ts SR
  ca SR
  ts SR
  ca SR
  ts SR
  ca SR
  ts SR
  ca SR
  ts lm_int_y
  index offset_y0
  ts lm_ram_data_start
  index offset_y0
  ts lm_ram_erase_start
  ad const_7
  index offset_y1
  ts lm_ram_data_start
  index offset_y1
  ts lm_ram_erase_start

  ;; Draw the lander.
  ca lm_start
  ts load_start
  ca lm_end
  ts load_end
  tc lcd_load

  qxch save_q
  return

lcd_load:
  ;; Lower /CS and DC.
  ca spi_command
  write IO_DATA_1
lcd_load_next_byte:
  ;; Read next byte from data.
  index load_start
  ca 0
  write SPI_TX
  ;; ptr += 1;
  aug load_start
lcd_load_busy:
  ca const_1
  rand SPI_CTRL
  bzf lcd_load_busy
  ca load_start
  su load_end
  bzmf lcd_load_next_byte
  ca spi_idle
  write IO_DATA_1
  return

memcpy:
  index memcpy_source
  ca 0
  index load_start
  ts 0
  aug memcpy_source
  aug load_start
  ca load_start
  su load_end
  bzmf memcpy
  return

delay:
  ts counter
  ;ca marker_0
delay_outer_loop:
  ca TIME4
  ;ts temp
  ts REG_L
delay_loop:
  ca TIME4
  ;su temp
  rxor REG_L

;write DISPLAY_DATA
;edrupt 0

  bzf delay_loop
  incr counter
  ca counter
  bzmf delay_outer_loop
  return

wait_display:
  ;qxch temp
wait_display_busy:
  ca const_1
  rand DISPLAY_CTRL
  bzf wait_busy_exit
  tcf wait_display_busy
wait_busy_exit:
  ;qxch temp
  return

gravity_table:
  .dc16 0x7fc6, 0x7fc7, 0x7fc8, 0x7fc9, 0x7fca, 0x7fcb, 0x7fcc, 0x7fcd
  .dc16 0x7fce, 0x7fcf, 0x7fcf, 0x7fd0, 0x7fd1, 0x7fd2, 0x7fd3, 0x7fd4
  .dc16 0x7fd5, 0x7fd6, 0x7fd7, 0x7fd8, 0x7fd8, 0x7fd9, 0x7fda, 0x7fdb
  .dc16 0x7fdc, 0x7fdd, 0x7fde, 0x7fdf, 0x7fe0, 0x7fe1, 0x7fe2, 0x7fe2
  .dc16 0x7fe3, 0x7fe4, 0x7fe5, 0x7fe6, 0x7fe7, 0x7fe8, 0x7fe9, 0x7fea
  .dc16 0x7feb, 0x7fec, 0x7fec, 0x7fed, 0x7fee, 0x7fef, 0x7ff0, 0x7ff1
  .dc16 0x7ff2, 0x7ff3, 0x7ff4, 0x7ff5, 0x7ff6, 0x7ff6, 0x7ff7, 0x7ff8
  .dc16 0x7ff9, 0x7ffa, 0x7ffb, 0x7ffc, 0x7ffd, 0x7ffe, 0x7fff
gravity_velocity_0:
  .dc16 0x0000
  .dc16 0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007
  .dc16 0x0008, 0x0009, 0x0009, 0x000a, 0x000b, 0x000c, 0x000d, 0x000e
  .dc16 0x000f, 0x0010, 0x0011, 0x0012, 0x0013, 0x0013, 0x0014, 0x0015
  .dc16 0x0016, 0x0017, 0x0018, 0x0019, 0x001a, 0x001b, 0x001c, 0x001d
  .dc16 0x001d, 0x001e, 0x001f, 0x0020, 0x0021, 0x0022, 0x0023, 0x0024
  .dc16 0x0025, 0x0026, 0x0027, 0x0027, 0x0028, 0x0029, 0x002a, 0x002b
  .dc16 0x002c, 0x002d, 0x002e, 0x002f, 0x0030, 0x0030, 0x0031, 0x0032
  .dc16 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039
gravity_table_end:

