CFLAGS=-O2 -fomit-frame-pointer -m32
CC=gcc

all:
	nasm -f elf32 Main.asm -o Main.o -l jqx86.lst
	nasm -f bin   test.asm -o test.bin
	gcc -m32 -g -fno-pie Main.o -o jqx86
	./jqx86 test.bin

clean:
	rm jqx86
	rm Main.o
	rm test.bin
