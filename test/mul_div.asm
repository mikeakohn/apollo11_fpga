.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x0234
  .dc16 0x1234
  ;.dc16 0x6dcb

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02001
  ts 100

  ca 02000
  mp 100
  ;dv 100

  write DISPLAY_DATA

  edrupt 0

