
NAKEN_INCLUDE=../naken_asm/include
PROGRAM=agc
SOURCE= \
  src/$(PROGRAM).v \
  src/display_spi.v \
  src/memory.v \
  src/spi.v

default:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE)
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

program:
	iceFUNprog $(PROGRAM).bin

blink:
	naken_asm -l -type bin -o rom.bin test/blink.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

simple:
	naken_asm -l -type bin -o rom.bin test/simple.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

display:
	naken_asm -l -type bin -o rom.bin test/display.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

interrupts:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/interrupts.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

add:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/add.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

mul_div:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/mul_div.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

xch:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/xch.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

das:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/das.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

shift:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/shift.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

function:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/function.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

branch:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/branch.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

index:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/index.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

ccs:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/ccs.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

other:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/other.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst *.bin
	@echo "Clean!"

