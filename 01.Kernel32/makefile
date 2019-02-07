all: Kernel32.bin

Kernel32.bin: Source/EntryPoint.s
	nasm -o Temp/Kernel32.bin $<

clean:
	rm -f Temp/Kernel32.bin