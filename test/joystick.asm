.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

;; Banked at 02000, but based on FB=0, is physically location 0.
.org 02000
  .dc16 0x0001
  .dc16 0x7f20

const_1f:
  .dc16 0x001f

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org BOOT
  tc main
.org T6RUPT
  qxch QRUPT
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

  ;ca TIME4
  ;write DISPLAY_DATA

  relint

  ca const_1f
  ts 105

while_1:
wait_busy:
  ca 02000
  rand DISPLAY_CTRL
  bzf wait_busy_exit
  tc wait_busy
wait_busy_exit:
  tc delay
  read JOYSTICK
  ts 104
  msu 105
  bzf while_1
  ca 104
  write DISPLAY_DATA
  tc while_1

  edrupt 0

delay:
  ca 02000
  write IO_DATA
  ca 02001
  ts 103
delay_outer_loop:
  ca TIME4
  ts 102
delay_loop:
  ca TIME4
  su 102
  bzf delay_loop
  incr 103
  ca 103
  bzmf delay_outer_loop
  ca ZERO
  write IO_DATA
  return

interrupt_time:
  xch ARUPT
  ca 02000
  write IO_DATA

  aug 100
  ca 100
  write DISPLAY_DATA
  xch ARUPT
  qxch QRUPT
  resume

