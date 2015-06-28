; Calling-Convention:
;   calee-save RBX, RBP, R12-R15
;   rdi, rsi, rdx, rcx, r8, r9,
;   xmm0 - zmm7

section .text

extern calloc
extern free
extern printf

global buildSuffixArray
global deleteSuffixArray
global length
global getPosition
global findAllEntries


;; CONSTANTS

CHAR_SZ     equ 1           ; 1-byte for every char in string
INT_SZ      equ 4           ; 4-byte for every value in SuffixArray
DATA        equ 4           ; 4-byte offset for SuffixArray length
ALPHABET    equ 256         ; ASCII

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
    mpush rdi, rsi, rdx, rcx
        mov rdi, %1
        mov rsi, %2
        call calloc
    mpop rdi, rsi, rdx, rcx
%endmacro

%macro call_free 1
    mpush rdi, rsi, rax, rbx, rcx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
        mov rdi, %1
        call free
    mpop rdi, rsi, rax, rbx, rcx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
%endmacro


%macro push_save_regs 0
    mpush rbx, r12, r13, r14, r15
%endmacro

%macro pop_save_regs 0
    mpop rbx, r12, r13, r14, r15
%endmacro


;; MAIN FUNCTIONS


; buildSuffixArray(const char* str, const int length)
;   Build suffix array for given string and certain length
;   Input:
;       rdi - address of string
;       rsi - length of string
;   Output:
;       rax - address pointing to SuffixArray object
buildSuffixArray:
    push_save_regs

    ; allocating memory for SuffixArray

    add rsi, 1
    call_calloc rsi, INT_SZ         ; calloc saves rdi & rsi
    sub rsi, 1

    mpush rax                       ; save address of SuffixArray

    mov [rax], esi                  ; set length of new SuffixArray

    mov rdx, rsi
    if rdx, ge, ALPHABET, .after_size_calc
;   {
        mov rdx, ALPHABET           ; rdx = size of every array
;   }

.after_size_calc:

    call_calloc rdx, INT_SZ
    mov r10, rax                    ; r10 = address to array `sum`
    call_calloc rdx, INT_SZ
    mov r11, rax                    ; r11 = address to array `h`
    call_calloc rdx, INT_SZ
    mov r12, rax                    ; r12 = address to array `c`
    call_calloc rdx, INT_SZ
    mov r13, rax                    ; r13 = address to array `c_n`
    call_calloc rsi, INT_SZ
    mov r14, rax                    ; r13 = address to array `p`
    call_calloc rsi, INT_SZ
    mov r15, rax                    ; r13 = address to array `p_n`

    mpop rax                        ; rax = address of SuffixArray

    xor r8, r8                      ; i = 0
.loop1:                             ; for(; i < n;)
    xor rcx, rcx
    mov cl, [rdi + r8 * CHAR_SZ]    ; rcx = s[i]
    mov [r12 + r8 * INT_SZ], ecx    ; c[i] = rcx

    mov r9d, [r10 + rcx * INT_SZ]   ; r9 = sum[c[i]]
    add r9, 1
    mov [r10 + rcx * INT_SZ], r9d   ; sum[c[i]]++

    add r8, 1                       ; i++
    if r8, l, rsi, .loop1           ; if i < n goto .loop1

    mov r8, 1                       ; i = 1
.loop2:                             ; for(; i < sz;)

    mov r9d, [r11 + (r8 - 1) * INT_SZ]  ; r9 = h[i - 1]
    mov ecx, [r10 + (r8 - 1) * INT_SZ]  ; rcx = sum[i - 1]
    add r9, rcx                         ; r9 += rcx -> r9 = h[i - 1] + sum[i - 1]
    mov [r11 + r8 * INT_SZ], r9d        ; h[i] = h[i - 1] + sum[i - 1]

    add r8, 1                       ; i++
    if r8, l, rdx, .loop2           ; if i < sz goto .loop2

;for(int i = 0; i < n; i++) {
;        p[h[c[i]]] = i;
;        h[c[i]]++;
;   }
    mov r8, 0                       ; i = 0
.loop3:                             ; for(; i < n; )

    mov ecx, [r12 + r8 * INT_SZ]    ; rcx = c[i]
    mov ecx, [r11 + rcx * INT_SZ]   ; rcx = h[c[i]]
    mov [r14 + rcx * INT_SZ], r8d   ; p[h[c[i]]] = i

    mov ecx, [r12 + r8 * INT_SZ]    ; rcx = c[i]
    mov r9d, [r11 + rcx * INT_SZ]   ; r9 = h[c[i]]
    add r9, 1                       ; r9++
    mov [r11 + rcx * INT_SZ], r9d   ; h[c[i]] = h[c[i]] + 1

    add r8, 1                       ; i++
    if r8, l, rsi, .loop3           ; if i < n goto .loop3

;    h[0] = 0;
;    c_n[p[0]] = 0;
;    for(int i = 1; i < n; i++) {
;        if (c[p[i]] != c[p[i - 1]]) {
;            c_n[p[i]] = c_n[p[i - 1]] + 1;
;            h[c_n[p[i]]] = i;
;        } else {
;            c_n[p[i]] = c_n[p[i - 1]];
;        }
;    }
;    c = c_n;
    mov r8, 0
    mov [r11 + 0 * INT_SZ], r8d     ; h[0] = 0
    mov ecx, [r14 + 0 * INT_SZ]     ; rcx = p[0]
    mov [r13 + rcx * INT_SZ], r8d   ; c_n[p[0]] = 0
    mov r8, 1                       ; i = 1
.loop4:                             ; for(; i < n;)

    mov ecx, [r14 + (r8 - 1) * INT_SZ]  ; rcx = p[i - 1]
    mov ecx, [r12 + rcx * INT_SZ]       ; rcx = c[p[i - 1]]
    mov r9d, [r14 + r8 * INT_SZ]        ; r9 = p[i]
    mov r9d, [r12 + r9 * INT_SZ]        ; r9 = c[p[i]]

    if rcx, e, r9, .loop4_else
        mov ecx, [r14 + (r8 - 1) * INT_SZ]  ; rcx = p[i - 1]
        mov ecx, [r13 + rcx * INT_SZ]       ; rcx = c_n[p[i - 1]]
        add rcx, 1                          ; rcx = c_n[p[i - 1]] + 1
        mov r9d, [r14 + r8 * INT_SZ]        ; r9 = p[i]
        mov [r13 + r9 * INT_SZ], ecx        ; c_n[p[i]] = c_n[p[i - 1]] + 1
        mov [r11 + rcx * INT_SZ], r8d       ; h[c_n[p[i]]] = i;
        jmp .loop4_after_if
    .loop4_else:
        mov ecx, [r14 + (r8 - 1) * INT_SZ]  ; rcx = p[i - 1]
        mov ecx, [r13 + rcx * INT_SZ]       ; rcx = c_n[p[i - 1]]
        mov r9d, [r14 + r8 * INT_SZ]        ; r9 = p[i]
        mov [r13 + r9 * INT_SZ], ecx        ; c_n[p[i]] = c_n[p[i - 1]]

    .loop4_after_if:

    add r8, 1                       ; i++
    if r8, l, rsi, .loop4           ; if i < n goto .loop4

    ; deallocation memory

    call_free r10
    call_free r11
    call_free r12
    call_free r13
    call_free r14
    call_free r15

    ; pop saved on top of stack regs

    pop_save_regs
    ret

deleteSuffixArray:
    call free
    ret

length:
    mov eax, [rdi]
    ret

getPosition:
    mov eax, [rdi + DATA + rsi * INT_SZ]
    ret
