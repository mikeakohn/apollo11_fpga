Apollo Guidance Computer
========================

This is an implmentation of the computer used in the luner lander and
command module during the Apollo space missions including Apollo 11
through 17 and the Apollo-Soyuz Test Project which an American spaceship
docked with a Russian Soyuz.

https://www.mikekohn.net/micro/apollo11_fpga.php

Details
=======

This is mostly just the CPU portion and other peripherals are either
omitted or replaced with other similar concepts.

Another difference is the the original AGC used 16 bit memory per address
where the upper 15 bits are real data and the lowest bit is a partity
bit. In this implentation, memory is 16 bit but the lower 15 bits are
data and the upper bit is almost always clear unless there is a functional
use for it.

Instruction timings are also different. The implementation here runs on
an iceFUN board (Lattice iCE40 HX8K FPGA) at 6 MHz. In this README,
the opcode descriptions have the original CPU timing of each instruction.
This implementation doesn't follow those guidelines, but could at a later
time. Since this will probably never run the original software, nor will
it land on the moon, it didn't seem that important.

Most of the information from this project came from:

https://www.ibiblio.org/apollo/assembly_language_manual.html#gsc.tab=0

The divide instruction implementation information came from:

http://www.righto.com/2019/09/a-computer-built-from-nor-gates-inside.html

The rest came from the Apollo Guidance, Navigation, and Control manual
which exists on the Internet as a PDF.

Opcodes
=======

            op  qc                   Mask         extra_code  original_timing
    tc      000 00 0000000000 - 111 00 0000000000 False         1 MCT (11.7us)
    xxalq   000 00 0000000000 - 111 11 1111111111 False         1 MCT (11.7us)
    xlq     000 00 0000000001 - 111 11 1111111111 False         1 MCT (11.7us)
    return  000 00 0000000010 - 111 11 1111111111 False         2 MCT (23.4us)
    relint  000 00 0000000011 - 111 11 1111111111 False         1 MCT (11.7us)
    inhint  000 00 0000000100 - 111 11 1111111111 False         1 MCT (11.7us)
    extend  000 00 0000000110 - 111 11 1111111111 False         1 MCT (11.7us)
    ccs     001 00 0000000000 - 111 00 0000000000 False         2 MCT (23.4us)
    tcf     001 00 0000000000 - 111 00 0000000000 False         1 MCT (11.7us)
    das     010 00 0000000001 - 111 11 0000000001 False         3 MCT (35.1us)
    lxch    010 01 0000000000 - 111 11 0000000000 False         2 MCT (23.4us)
    incr    010 10 0000000000 - 111 11 0000000001 False         2 MCT (24.4us)
    ads     010 11 0000000000 - 111 11 0000000000 False         2 MCT (23.4us)
    ca      011 00 0000000000 - 111 00 0000000000 False         2 MCT (23.4us)
    cs      100 00 0000000000 - 111 00 0000000000 False         2 MCT (23.4us)
    index   101 00 0000000000 - 111 11 0000000000 False         2 MCT (23.4us)
    resume  101 00 0000001111 - 111 11 1111111111 False         2 MCT (23.4us)
    dxch    101 01 0000000001 - 111 11 0000000001 False         3 MCT (23.4us)
    ts      101 10 0000000000 - 111 11 0000000000 False         2 MCT (23.4us)
    ovsk    101 10 0000000000 - 111 11 1111111111 False         2 MCT (23.4us)
    tcaa    101 10 0000000101 - 111 11 1111111111 False         2 MCT (23.4us)
    xch     101 11 0000000000 - 111 11 0000000000 False         2 NCT (23.4us)
    ad      110 00 0000000000 - 111 00 0000000000 False         2 MCT (23.4us)
    mask    111 00 0000000000 - 111 00 0000000000 False         2 MCT (23.4us)

    read    000 000 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    write   000 001 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    rand    000 010 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    wand    000 011 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    ror     000 100 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    wor     000 101 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    rxor    000 110 000000000 - 111 111 000000000 True          2 MCT (23.4us)
    edrupt  000 111 000000000 - 111 111 000000000 True          3 MCT (35.1us)
    bzf     001 000 000000000 - 111 000 000000000 True          1 MCT (35.1us)
    dv      001 000 000000000 - 111 110 000000000 True          6 MCT (70.2us)
    msu     010 000 000000000 - 111 110 000000000 True          2 MCT (23.4us)
    qxch    010 010 000000000 - 111 110 000000000 True          2 MCT (23.4us)
    aug     010 100 000000000 - 111 110 000000000 True          2 MCT (23.4us)
    dim     010 110 000000000 - 111 110 000000000 True          2 MCT (23.4us)
    dca     011 000 000000001 - 111 000 000000001 True          3 MCT (35.1us)
    dcs     100 000 000000001 - 111 000 000000001 True          3 MCT (35.1us)
    index   101 000 000000000 - 111 110 000000000 True          2 MCT (23.4us)
    bzmf    110 000 000000000 - 111 000 000000000 True          1 MCT (11.7us)
    su      110 000 000000000 - 111 110 000000000 True          2 MCT (23.4us)
    mp      111 000 000000000 - 111 000 000000000 True          3 MCT (23.4us)

Description
-----------

When doing math, data is considered single precision and 1's complement
where bit 14 is a sign bit and bits 13 to 0 represents x / 2^14. So:

      +0 is 0_00_0000_0000_0000
      -0 is 1_00_0000_0000_0000
     1/2 is 0_10_0000_0000_0000
    -1/2 is 1_01_1111_1111_1111
     1/4 is 0_01_0000_0000_0000
    -1/4 is 1_10_1111_1111_1111

There is also double precision that is used with instructions such as
"das". In that case A and L are combined into a single 29 bit register
where bit 28 (the sign bit) comes from A, the next 14 bits are lower
14 bits of A, and the last 14 bits (13 to 0) are the lower 14 bits of L.

There are a bunch of alias instructions. Some of them are listed here
and some of them were removed.

    Registers are:
    A - Accumulator                        (15 bit plus extra overflow bit).
    L - Lower product register             (15 bit).
    Q - Return address of called procedure (15 bit plus extra overflow).
    Z - Program counter                    (12 bit).

    tc      Transfer control: Z = K, Q = Z + 1
    xxalq   Transfer control: Z = A, Q = Z + 1
    xlq     Transfer control: Z = L, Q = Z + 1
    return  Transfer control: Z = Q, Q = Z + 1
    relint  Enable interrupts
    inhint  Disable interrupts
    extend  The next instruction is an extra code
    ccs     Compare, count, skip.
            [K]  >  0: Z = I + 1, A = [K] - 1
            [K] == +0: Z = I + 2, A = +0
            [K]  < -0: Z = I + 3, A = abs[K] - 1
            [K] == -0: Z = I + 4, A = +0
    tcf     Z = K
    das     [K, K + 1] = [K, K + 1] + [ A[14:0], L[13:0] ]
    ddoubl  Alias of: das a
    lxch    Exchange L and [K]
    zl      Alias of: lxch 7 (exchange L and hardcoded 0)
    incr    Increment memory: [K] = [K] + 1
    ads     Add accumulator to storage: [K] = A + [K]
    ca      Clear and add: A = [K]
    cae     Alias of: ca
    caf     Alias of: ca
    noop    Alias of: ca A
    cs      Clear and subtract: A = ~[K]
    com     Alias of: cs A 
    index   Add [K] to the K in the next instruction
    resume  Resume from interrupt:
    dxch    Double exchange: A = [K], L = [K+1], [K] = A, [K+1] = L
    dtcf    Alias of: dxch 5
    dtcb    Alias of: dxch 6
    ts      Transfer A to storage: [K] <= A
    ovsk    Skip next instruction if overflow is set.
    tcaa    Transfer A to Z: Z = A, if +overflow A -= 1, if -overflow A += 1
    xch     Exchange A and K: A = [K], [K] = A
    ad      Add memory to accumulator. A = A + [K]
    mask    Logical AND: A = A & [K]

These opcodes are excuted if the extra_code flag is set (by the extend
instruction). All instructions here clear extra_code except for index.

    read    Read  I/O: A    = [IO]
    write   Write I/O: [IO] = A
    rand    Read  I/O: A    = A & [IO]
    wand    Write I/O: [IO] = A & [IO]
    ror     Read  I/O: A    = A | [IO]
    wor     Write I/O: [IO] = A | [IO]
    rxor    Read  I/O: A    = A ^ [IO]
    edrupt  Unknown: HALT for now.
    bzf     Branch if A is 0: if A == +-0: Z = K
    dv      001 000 000000000 - 111 110 000000000 True
    msu     Subtract K from A (2's complement): A = A - [K]
    qxch    Exchange Q and K: Q = [K], [K] = Q
    zq      Alias for: qxch Zero
    aug     Augment  K: if [K] >= +0, [K] = [K] + 1; if [K] <= -0, [K] = [K] - 1;
    dim     Diminish K: if [K] >= +0, [K] = [K] - 1; if [K] <= -0, [K] = [K] + 1;
    dca     Copy  storage to AL: { A, L } =  { [K+1], [K] }
    dcs     Copy ~storage to AL: { A, L } = ~{ [K+1], [K] }
    dcom    Complement AL: { A, L } = ~{ A, L }
    index   Add [K] to the K in the next instruction
    bzmf    Branch if A <= 0: if A <= +-0: Z = K
    su      Subtract storage from accumulator: A = A - [K]
    mp      Multiply A * K: A,L = A * [K]

Memory Map
==========

All memory addresses are 15 bits wide.

AGC Erasable Memory (RAM)
-------------------------

There 8 banks of RAM each 256 words (512 bytes) in size
for a total of 2048 words (4096 bytes).

    00000 - 00377 (0x0000 - 0x00ff)  E0 Overlap
    00400 - 00777 (0x0100 - 0x01ff)  E1 Overlap
    01000 - 01377 (0x0200 - 0x02ff)  E2 Overlap
    01400 - 01777 (0x0300 - 0x03ff)  Depends on EB:
      EB = 0: Same as E0
      EB = 1: Same as E1
      EB = 2: Same as E2
      EB = 3: Bank 3 memory
      EB = 4: Bank 4 memory
      EB = 5: Bank 5 memory
      EB = 6: Bank 6 memory
      EB = 7: Bank 7 memory

AGC Fixed Memory (ROM)
----------------------

There are 36 banks of 1024 words (2048 bytes) in size for a total of
36874 words (73728 bytes). 32 banks are picked from FB and 5 extra
banks come from a super bank bit in I/O channel 7 (FEB).

    02000 - 03777 (0x0400 - 0x07ff) Bank 00 to 31 (FB/BB 00 to 31)
    04000 - 05777 (0x0800 - 0x0bff) Common-fixed mem (bank 02 overlap)
    06000 - 07777 (0x0c00 - 0x0fff) Common-fixed mem (bank 03 overlap)

This implementation maps fixed memory to 16 bit * 4096 addresses.

Peripherals
===========

    000 0x00 A           Accumulator
    001 0x01 L           Lower product register
    002 0x02 Q           Return address of called procedures
    003 0x03 EB          Erasable bank register 000 0EE E00 000 000
    004 0x04 FB          Fixed bank register    FFF FF0 000 000 000
    005 0x05 Z           Program counter
    006 0x06 BB          Both banks register    FFF FF0 000 000 EEE
    007 0x07 ZERO        Always zero.
    010 0x08 ARUPT       Save A during interrupt (not automatic)
    011 0x09 LRUPT       Save L during interrupt (not automatic)
    012 0x0a QRUPT       Save Q during interrupt (not automatic)
    013 0x0b SAMPTIME1   Store copy for TIME1 (automatic?)
    014 0x0c SAMPTIME2   Store copy for TIME2 (automatic?)
    015 0x0d ZRUPT       Return address for interrupt
    016 0x0e BBRUPT      Save BB during interrupt (not automatic)
    017 0x0f BRUPT       Copy of instruction pointed to by ZRUPT (automatic)
    020 0x10 CYR         Cycle right register
    021 0x11 SR          Shift right register
    022 0x12 CYL         Cycle left register
    023 0x13 EDOP        Shift right by 7 then clear upper 8 bits
    024 0x14 TIME2       14 bit / Inc on overflow of TIME1
    025 0x15 TIME1       15 bit / Inc every 10ms
    026 0x16 TIME3       15 bit / Inc every 10ms (T3RUPT)
    027 0x17 TIME4       15 bit / Inc every 10ms (T4RUPT / 7.5ms phase of TIME3)
    030 0x18 TIME5       15 bit / Inc every 10ms (T5RUPT / 5ms phase of TIME1)
    031 0x19 TIME6       15 bit / Updated 1/6000s DINC seq (T6RUPT)
    032 0x1a CDUX        Spacecraft orientation X counter
    033 0x1b CDUY        Spacecraft orientation Y counter
    034 0x1c CDUZ        Spacecraft orientation Z counter
    035 0x1d OPTY        Optics orientation X counter
    036 0x1e OPTX        Optics orientation Y counter
    037 0x1f PIPAX       Pulsed integrating pendulous acceleromter X
    040 0x20 PIPAY       Pulsed integrating pendulous acceleromter Y
    041 0x21 PIPAZ       Pulsed integrating pendulous acceleromter Z
    042 0x22 RHCP        LM only: rotational hand controller pitch
    043 0x23 RHCY        LM only: rotational hand controller yaw
    044 0x24 RHCR        LM only: rotational hand controller roll
    045 0x25 INLINK      Digital uplink data from ground station
    046 0x26 RNRAD       ?
    047 0x27 GRYOCTR     IMU fine alignment
    050 0x28 CDUXCMD     IMU course alignment X
    051 0x29 CDUYCMD     IMU course alignment Y
    052 0x2a CDUZCMD     IMU course alignment Z
    053 0x2b OPTYCMD     ?
    054 0x2c OPTXCMD     ?
    055 0x2d THRUST      LM only?
    056 0x2e LEMONM      LM only?
    057 0x2f OUTLINK     Not used?
    060 0x30 ALTM        LM only?

Vectors
-------

    04000 0x800 Boot
    04004 0x804 T6RUPT - TIME6 decremented to 0.
    04010 0x808 T5RUPT - TIME5 overflowed (digital autopilot thrust).
    04014 0x80c T3RUPT - TIME3 overflowed (autopilot).
    04020 0x810 T4RUPT - TIME4 overflowed (task scheduler).
    04024 0x814 KEYRUPT1 - Keystroke received from DSKY.
    04030 0x818 KEYRUPT2 - Keystroke received from secondary DSKY.
    04034 0x81c UPRUPT - Uplink word available in the INLINK register.
    04040 0x820 DOWNRUPT - Downlink shift register is ready for new data.
    04044 0x824 RADARRUPT - Triggered after pulse sequence sent to radars.
    04050 0x828 RUPT10 - Selectable from Trap 31A, 31B, 32.

I/O
===

These I/O ports are accessed with the read, write, rand, wand, etc
instructions.

    1: L
    2: Q
    3: hi_scaler
    4: lo_scaler
    5: pyjets
    6: rolljets
    7: superbnk

Not a part of the real AGC:

    12: IO data (bit 0: connected to LED)
    13: 4 x 7seg display
    14: display_ctrl - bit 0: display_busy
    15: interrupt flags
    16: interrupt clear
    17: IO data port 1 (3 bits used for SPI control for LCD)
    18: SPI transmit (8 bit)
    19: SPI receive (8 bit)
    20: SPI control - bit 0: SPI ready
    21: JOYSTICK - bits 4 to 0 are fire button and 4 axis of the stick

Interrupts
==========

There are several interrupts that can happen in the AGC. The ones
currently supported here are:

    T6RUPT - TIME6 decremented to 0.
    T5RUPT - TIME5 overflowed (digital autopilot thrust).
    T3RUPT - TIME3 overflowed (autopilot).
    T4RUPT - TIME4 overflowed (task scheduler).

When an interrupt flag goes high, an interrupt will happen at the
start of CPU instruction processing. Interrupts will not happen in
the middle of reading the second word of an instruction that is an
"extra code", in the middle of a "skip" instruction, and in the
middle of an index instruction. When an interrupt happens, the
following occurs:

1. Copy Z to ZRUPT.
2. The opcode instruction at location Z is copied to BRUPT.
3. Load Z with interrupt vector address.

On resume the following happens:

1. Copy ZRUPT to Z.
2. Copy BRUPT to next instruction to be decoded register.
3. Increment Z.

