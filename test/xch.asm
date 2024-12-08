.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x1234
  .dc16 0x0234
  .dc16 0x1111
  .dc16 0x2222

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  tc test

  ca 02001
  ts 100
  ca 02000
  ts 101

  ;xch 100

  ;lxch 100
  ;xch REG_L
  ;ca REG_L
  ;qxch 100
  ;ca REG_Q

  ca 02003
  ts REG_L
  ca 02002
  dxch 100
  ca 101

  write DISPLAY_DATA

  edrupt 0

test:
  ca 02000
  ts QRUPT
  ;qxch QRUPT
  ;qxch QRUPT
  ;ca REG_Q
  ca QRUPT
  write DISPLAY_DATA
  edrupt 0

