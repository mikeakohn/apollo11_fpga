.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

;; Banked at 02000, but based on FB=0, is physically location 0.
.org 02000
  .dc16 0x0001

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org BOOT
  tc main
.org T6RUPT
  tc interrupt_time
.org T5RUPT
  resume
.org T3RUPT
  resume
.org T4RUPT
  resume

.org 04054
main:
  ;; Set location 100 to 0 (Z=5).
  ca ZERO
  ts 100
  write IO_DATA

  ;; Testing to see if the busy flag on the display works.
  ca TIME1
  write DISPLAY_DATA

wait_busy:
  ca 02000
  rand DISPLAY_CTRL
  bzf wait_busy_exit
  tc wait_busy
wait_busy_exit:

  ca TIME4
  write DISPLAY_DATA

  relint
  ;inhint
  ;relint

while_1:
  ca ZERO
  write IO_DATA
  tc while_1

  edrupt 0

interrupt_time:
  ca 02000
  write IO_DATA

  aug 100
  ca 100
  ;ca ZRUPT
  ;ca BRUPT
  ;ca REG_Z
  ;ca TIME2
  ;read INTERRUPT_FLAGS
  write DISPLAY_DATA

  ;ca ZERO
  ;write IO_DATA
  resume

