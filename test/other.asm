.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

.org 02000
  .dc16 0x1235
  .dc16 0x4765
  .dc16 0x3000
  .dc16 0x1000
  .dc16 0x2929
  .dc16 0x8000 | output_other
  .dc16 output_other

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ;dcs 02000
  ;dca 02000
  ;ca REG_L

  ;cs 02000
  ;ca 02000
  ;ts 100
  ;aug 100
  ;dim 100
  ;dim 100
  ;ca 100

  ;ca 02000
  ;mask 02001

  ca 02000
  write DISPLAY_DATA

wait_busy:
  ca 02000
  rand DISPLAY_CTRL
  bzf wait_busy_exit
  tc wait_busy
wait_busy_exit:

  ;; This causes a positive overflow.
  ca 02002
  ad 02003

  ;ca 02005
  ;tcaa

  ;ca 02005
  ca 02006
  ovsk
  aug REG_A
  ;noop

  ;; ovsk, aug REG_A is 3 words (puts output_other at 0x0813).
  ;noop
  ;noop
  ;noop

  write DISPLAY_DATA
  edrupt 0

output_other:
  ;ca 02002
  write DISPLAY_DATA
  edrupt 0

