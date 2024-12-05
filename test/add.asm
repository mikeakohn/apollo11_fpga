.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x5234
  .dc16 0x0234

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02001
  ts 100
  ts 101

  ca 02000
  ;ad 100

  ;ads 100
  ;ca 100

  su 100

  ;msu 100

  ;incr 101
  ;ca 101

  write DISPLAY_DATA

  edrupt 0

