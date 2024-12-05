.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x1235
  .dc16 0x8765

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02000
  ;ts CYR
  ;ca CYR
  ts SR
  ca SR

  ;ca 02001
  ;ts CYL
  ;ca CYL
  ;ts EDOP
  ;ca EDOP

  write DISPLAY_DATA

  edrupt 0

