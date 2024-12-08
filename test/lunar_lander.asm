.agc

.include "agc/agc.inc"
.include "lcd/ssd1331.inc"
.include "test/extra_io.inc"

load_start    equ 100
load_end      equ 101
memcpy_source equ 102
lem_x         equ 103
lem_y         equ 104
counter       equ 105
temp          equ 106
save_q        equ 107

lem_ram_data_start  equ 120
lem_ram_data_end    equ 134
lem_ram_erase_start equ 134
lem_ram_erase_end   equ 148

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
lcd_init_data_end:

;; OLED display is 96x64.
;; Coordinate data is: x0, y0, x1, y1.

horizon_data:
  .dc16 SSD1331_FILL_ENABLE
  .dc16 0x01, 0x00
  .dc16 SSD1331_DRAW_RECT
  .dc16    0,   21,   95,  63
  .dc16 0x00, 0x00, 0x00
  .dc16 0x00, 0x00, 0x00
horizon_data_end:

ground_data:
  .dc16 SSD1331_FILL_ENABLE
  .dc16 0x01, 0x00
  .dc16 SSD1331_DRAW_RECT
  .dc16    0,    0,   95,  20
  .dc16 0x10, 0x10, 0x10
  .dc16 0x10, 0x10, 0x10
ground_data_end:

landing_pad_data:
  .dc16 SSD1331_FILL_ENABLE
  .dc16 0x01, 0x00
  .dc16 SSD1331_DRAW_RECT
  .dc16   40,   10,   56,  20
  .dc16 0xff, 0x00, 0x00
  .dc16 0xff, 0x00, 0x00
landing_pad_data_end:

;; horizon is (0, 21) - (95,  63)
lem_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   30,   50,   37,  57
  .dc16 0xff, 0xff, 0xff
  .dc16 0xff, 0xff, 0xff
lem_data_end:

lem_erase_data:
  .dc16 SSD1331_DRAW_RECT
  .dc16   30,   50,   37,  57
  .dc16 0x00, 0x00, 0x00
  .dc16 0x00, 0x00, 0x00
lem_erase_data_end:

spi_idle:
  .dc16 0x07
spi_command:
  .dc16 0x01
const_1:
  .dc16 0x01
const_7:
  .dc16 7
;const_64:
;  .dc16 64
delay_length:
  .dc16 0x7f20
marker:
  .dc16 0x1234
lem_x_start:
  .dc16 80
lem_y_start:
  .dc16 50
offset_x0:
  .dc16 1
offset_y0:
  .dc16 2
offset_x1:
  .dc16 3
offset_y1:
  .dc16 4

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
lem_start:
  .dc16 lem_ram_data_start
lem_end:
  .dc16 lem_ram_data_end - 1
lem_erase_start:
  .dc16 lem_ram_erase_start
lem_erase_end:
  .dc16 lem_ram_erase_end - 1
lem_rom_start:
  .dc16 lem_data

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

  ;; Draw the horizon.
  ca horizon_start
  ts load_start
  ca horizon_end
  ts load_end
  tc lcd_load

  ;; Draw the ground.
  ca ground_start
  ts load_start
  ca ground_end
  ts load_end
  tc lcd_load

  ;; Draw the landing pad.
  ca landing_pad_start
  ts load_start
  ca landing_pad_end
  ts load_end
  tc lcd_load

  ;; Copy LEM and erase LEM to RAM.
  ca lem_rom_start
  ts memcpy_source
  ca lem_start
  ts load_start
  ca lem_erase_end
  ts load_end
  tc memcpy

  ca lem_x_start
  ts lem_x
  ca lem_y_start
  ts lem_y
  tc lem_move

  ca marker
  write DISPLAY_DATA
  edrupt 0

lem_move:
  qxch save_q

  ;; Erase the lander.
  ca lem_erase_start
  ts load_start
  ca lem_erase_end
  ts load_end
  tc lcd_load

  ca lem_x
  index offset_x0
  ts lem_ram_data_start
  index offset_x0
  ts lem_ram_erase_start
  ad const_7
  index offset_x1
  ts lem_ram_data_start
  index offset_x1
  ts lem_ram_erase_start

  ca lem_y
  index offset_y0
  ts lem_ram_data_start
  index offset_y0
  ts lem_ram_erase_start
  ad const_7
  index offset_y1
  ts lem_ram_data_start
  index offset_y1
  ts lem_ram_erase_start

  ;; Draw the lander.
  ca lem_start
  ts load_start
  ca lem_end
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
  ca delay_length
  ts counter
delay_outer_loop:
  ca TIME4
  ts temp
delay_loop:
  ca TIME4
  su temp
  bzf delay_loop
  incr counter
  ca counter
  bzmf delay_outer_loop
  return

