.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

;; Banked at 02000, but based on FB=0, is physically location 0.
.org 02000
  .dc16 0xcafe

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:

wait_busy:
  ca 02000
  rand DISPLAY_CTRL
  bzf wait_busy_exit
  tc wait_busy
wait_busy_exit:

  ca 02000
  write DISPLAY_DATA

  edrupt 0

