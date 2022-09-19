CFLAGS=-O2 -fomit-frame-pointer -m32
CC=gcc

all:
	nasm -f elf32 Main.asm -o Main.o
	gcc -m32 Main.o