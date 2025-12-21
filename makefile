.PHONY: all

all:
	nasm -f bin game.asm -o invaders.bin
run:
	qemu-system-i386 -drive format=raw,file=invaders.bin -display cocoa