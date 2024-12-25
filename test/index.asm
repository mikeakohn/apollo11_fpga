.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x7ffe ; 02000 (-4)
  .dc16 0x4765 ; 02001 (-3)
  .dc16 0x3000 ; 02002 (-2)
  .dc16 0x1000 ; 02003 (-1)
  .dc16 0x2929 ; 02004 (0)
  .dc16 0x2925 ; 02005 (1)
  .dc16 0x2926 ; 02006 (2)

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

