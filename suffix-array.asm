; Calling-Convention:
;   calee-save RBX, RBP, R12-R15
;   rdi, rsi, rdx, rcx, r8, r9,
;   xmm0 - zmm7

section .text

extern calloc, free
extern printf

global buildSuffixArray
global findAllEntries

;; CONSTANTS

SZ      equ 4
DATA    equ 4

;; MACRO

%macro if 4
    cmp %1, %3
    j%+2 %4
%endmacro

%macro mpush 1-*
    %rep %0
        push %1
		%rotate 1
    %endrep
%endmacro

%macro mpop 1-*
    %rep %0
        %rotate -1
    	pop %1
    %endrep
%endmacro

%macro call_calloc 2
    mpush rdi, rsi
        mov rdi, %1
        mov rsi, %2
        call calloc
    mpop rdi, rsi
%endmacro

;; MAIN FUNCTIONS

buildSuffixArray:
    mpush r
