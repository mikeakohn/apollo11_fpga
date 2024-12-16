.agc

.include "agc/agc.inc"
.include "test/extra_io.inc"

interrupt_counter equ 100
current_time      equ 102
delay_count       equ 103
joystick_value    equ 104
temp              equ 105

;; Banked at 02000, but based on FB=0, is physically location 0.
.org 02000
const_1:
  .dc16 0x0001
const_7ff0:
  .dc16 0x7ff0
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
  ts temp

while_1:
wait_busy:
  ca const_1
  rand DISPLAY_CTRL
  bzf wait_busy_exit
  tc wait_busy
wait_busy_exit:
  tc delay
  read JOYSTICK
  ts joystick_value
  ;; If joystick is 0x1f (no direction pushed), then don't display the value.
  su temp
  bzf while_1
  ca joystick_value
  write DISPLAY_DATA
  tc while_1

  edrupt 0

delay:
  ca const_1
  write IO_DATA
  ca const_7ff0
  ts delay_count
delay_outer_loop:
  ca TIME4
  ts current_time
delay_loop:
  ca TIME4
  su current_time
  bzf delay_loop
  incr delay_count
  ca delay_count
  bzmf delay_outer_loop
  ca ZERO
  write IO_DATA
  return

interrupt_time:
  xch ARUPT
  ca const_1
  write IO_DATA

  aug interrupt_counter
  ca interrupt_counter
  write DISPLAY_DATA
  xch ARUPT
  qxch QRUPT
  resume

