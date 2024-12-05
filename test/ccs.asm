.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x5fff
  .dc16 0x1001
  .dc16 0x2002
  .dc16 0x3003
  .dc16 0x4004

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02000
  ts 100

  ccs 100
  tc option_1  ; [K] > 0
  tc option_2  ; [K] == +0
  tc option_3  ; [K] < 0
  tc option_4  ; [K] == -0

  write DISPLAY_DATA
  edrupt 0

option_1:
  ca 02001
  write DISPLAY_DATA
  edrupt 0

option_2:
  ca 02002
  write DISPLAY_DATA
  edrupt 0

option_3:
  ca 02003
  write DISPLAY_DATA
  edrupt 0

option_4:
  ca 02004
  write DISPLAY_DATA
  edrupt 0

