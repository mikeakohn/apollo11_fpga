.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x0234
  .dc16 0x3fff
  .dc16 3

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02000
  ts 100
  ca 02001
  ts 101

  ca 02002
  ts REG_L
  ca ZERO

  das 100

  ca 101

  write DISPLAY_DATA

  edrupt 0

