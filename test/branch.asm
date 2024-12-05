.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x1236
  .dc16 0x8765
  .dc16 0x4002

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02000
  ;ca 02002
  ;ca ZERO
  ;bzf do_branch
  bzmf do_branch

  write DISPLAY_DATA
  edrupt 0

do_branch:
  ca 02001
  write DISPLAY_DATA
  edrupt 0

