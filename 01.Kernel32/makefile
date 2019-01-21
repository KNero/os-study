all: VirtualOS.bin

VirtualOS.bin: Source/VirtualOS.asm
	nasm -o Temp/VirtualOS.bin Source/VirtualOS.asm

clean:
	rm -f Temp/VirtualOS.bin