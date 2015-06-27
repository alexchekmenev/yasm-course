all: main

asm: suffix-array.asm
	yasm -felf64 -g dwarf2 suffix-array.asm

ar: asm
	ar rcs suffix-array.a suffix-array.o

main: ar main.cpp
	g++ -g -std=c++11 -w -O3 -o main main.cpp suffix-array.a

clean:
	rm suffix-array.a
	rm *.o
	rm main

