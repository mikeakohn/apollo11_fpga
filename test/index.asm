.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x7ffe
  .dc16 0x4765
  .dc16 0x3000
  .dc16 0x1000
  .dc16 0x2929

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ;ca 02000
  ;ts 100
  ;index 100

  index 02000
  ca 02004
  write DISPLAY_DATA

  ;; This is indexing an instruction with an extra code.
  ;index 02000
  ;aug 100
  ;ca 102
  ;write DISPLAY_DATA

  edrupt 0

