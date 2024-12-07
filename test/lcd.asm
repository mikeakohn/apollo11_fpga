.agc

.include "agc/agc.inc"
.include "lcd/ssd1331.inc"
.include "test/extra_io.inc"

lcd_count equ 100
lcd_data  equ 101

.org 02000

box_data:
  .dc16 SSD1331_FILL_ENABLE
  .dc16 0x01, 0x00
  .dc16 SSD1331_DRAW_RECT
  .dc16 0x10, 0x10, 0x40, 0x30
  .dc16 0x3e, 0x3f, 0x3e
  .dc16 0x00, 0x00, 40
box_data_end:

init_data:
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
init_data_end:

lcd_init_len:
  .dc16 init_data_end - init_data - 1
lcd_box_data_len:
  .dc16 init_data_end - box_data - 1
spi_idle:
  .dc16 0x07
spi_command:
  .dc16 0x01
one:
  .dc16 0x01
marker:
  .dc16 0x1234

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca spi_idle
  write IO_DATA_1

  tc init_lcd

  tc draw_box

  ca marker
  write DISPLAY_DATA
  edrupt 0

init_lcd:
  ;; Lower /CS and DC.
  ca spi_command
  write IO_DATA_1
  ca lcd_init_len
  ts 101
  ca ZERO
  ts 100
init_lcd_next_byte:
  ;; Read next byte from data.
  index 100
  ca init_data
  write SPI_TX
  ;; ptr += 1;
  aug 100
init_lcd_busy:
  ca one
  rand SPI_CTRL
  bzf init_lcd_busy
  ;; if ptr <= length - 1, continue.
  ca 100
  su 101
  bzmf init_lcd_next_byte
init_lcd_exit:
  ca spi_idle
  write IO_DATA_1
;ca one
;write DISPLAY_DATA
;edrupt 0
  return

draw_box:
  ;; Lower /CS and DC.
  ca spi_command
  write IO_DATA_1
  ca lcd_box_data_len
  ts 101
  ca ZERO
  ts 100
draw_box_next_byte:
  ;; Read next byte from data.
  index 100
  ca box_data
  write SPI_TX
  ;; ptr += 1;
  aug 100
draw_box_busy:
  ca one
  rand SPI_CTRL
  bzf draw_box_busy
  ;; count -= 1;
  ca 100
  su 101
  bzmf draw_box_next_byte
  ca spi_idle
  write IO_DATA_1
  return

