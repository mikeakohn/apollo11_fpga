.agc

.org 02000
  .dc16 0x1234
  .dc16 0x5678
  .dc16 0x1abc

;; Due to the way memory is banked, the address written as 04000 but
;; physically it's location 06000 (bank 2).
.org 04000
main:
  ca 02002
  ts 100
  aug 100

  ca 02000
  ads 100

  ca 100

  edrupt 0

