; Calling-Convention:
;   calee-save RBX, RBP, R12-R15
;   rdi, rsi, rdx, rcx, r8, r9,
;   xmm0 - zmm7

section .data

ppstr db 'l = %d, r = %d',10,0

section .text

extern calloc
extern free
extern printf
extern memcpy
extern memmove

global buildSuffixArray
global deleteSuffixArray
global length
global getPosition
global findAllEntries
global getRangeFirst
global getRangeLast
global deleteRange

;; CONSTANTS

CHAR_SZ     equ 1           ; 1-byte for every char in string
INT_SZ      equ 4           ; 4-byte for every value in SuffixArray
LEN         equ 8           ; 4-byte for length of SuffixArray
DATA        equ 12          ; 12-byte offset for length and string address
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
    mpush rdi, rsi, rcx, rdx, r8, r9, r10, r11
        mov rdi, %1
        mov rsi, %2
        call calloc
    mpop rdi, rsi, rcx, rdx, r8, r9, r10, r11
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

    add rsi, 3
    call_calloc rsi, INT_SZ         ; calloc saves rdi & rsi
    sub rsi, 3

    mov r15, rax

    mpush rax                       ; save address of SuffixArray

    mov [rax + LEN], esi         ; set length of new SuffixArray
;===================================
    call_calloc rsi, CHAR_SZ        ; copying input string
    mov r12, rdi
    mov r13, rsi
    mpush rdi, rsi, rdx
        mov rdi, rax
        mov rsi, r12
        mov rdx, r13
        call memcpy
    mpop rdi, rsi, rdx

    mov [r15], rax                  ; set address of the copy of input string
;===================================
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

    ;jmp .finish1

;    for(int i = 0; i < n; i++) {
;        c[i] = s[i];
;        sum[c[i]]++;
;    }
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

;   for(int i = 1; i < sz; i++) {
;        h[i] = h[i - 1] + sum[i - 1];
;    }
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
    xor r8, r8                      ; i = 0
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
    xor r8, r8
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

    ; moving values of `c_n` to `c`

    mpush rax, rdi, rsi, rdx, r10, r11
        mov rdi, r12
        mov rsi, r13
        shl rdx, 2
        call memcpy
    mpop rax, rdi, rsi, rdx, r10, r11

    mov r9, 1                       ; l = 1

.calc_loop:
    mpush rdx                       ; save sz for using after .inner_loops

    ;   for(int i = 0; i < n; i++) {
    ;        p_n[i] = (n + p[i] - l) % n;
    ;    }
    xor r8, r8                                   ; i = 0
    .inner_loop1:
        mov ecx, [r14 + r8 * INT_SZ]            ; rcx = p[i]
        add rcx, rsi                            ; rcx = p[i] + n
        sub rcx, r9                             ; rcx = p[i] + n - l
        if rcx, l, rsi, .inner_loop1_after_mod  ; if rcx < n
            sub rcx, rsi                        ; rcx -= n
    .inner_loop1_after_mod:
        mov [r15 + r8 * INT_SZ], ecx            ; p_n[i] = (p[i] + n - l) % n

        add r8, 1                               ; i++
        if r8, l, rsi, .inner_loop1             ; if i < n goto .inner_loop1

    ;    for(int i = 0; i < n; i++) {
    ;        p[h[c[p_n[i]]]] = p_n[i];
    ;        h[c[p_n[i]]]++;
    ;    }

    xor r8, r8                                   ; i = 0
    .inner_loop2:

        xor rcx, rcx
        xor rdx, rdx

        mov edx, [r15 + r8 * INT_SZ]            ; rdx = p_n[i]
        mov ecx, [r12 + rdx * INT_SZ]           ; rcx = c[p_n[i]]
        mov ecx, [r11 + rcx * INT_SZ]           ; rcx = h[c[p_n[i]]]


        mov [r14 + rcx * INT_SZ], edx           ; p[h[c[p_n[i]]]] = p_n[i]
        add rcx, 1

        mov edx, [r15 + r8 * INT_SZ]            ; rdx = p_n[i]
        mov edx, [r12 + rdx * INT_SZ]           ; rdx = c[p_n[i]]
        mov [r11 + rdx * INT_SZ], ecx           ; h[c[p_n[i]]] = h[c[p_n[i]]] + 1

        add r8, 1                               ; i++
        if r8, l, rsi, .inner_loop2             ; if i < n goto .inner_loop2

    ;    c_n[p[0]] = 0;
    ;    h[0] = 0;
    ;    for(int i = 1; i < n; i++) {
    ;        int p1 = p[i], p2 = (p1 + l) % n;
    ;        int pr1 = p[i - 1], pr2 = (pr1 + l) % n;
    ;        if (c[pr1] != c[p1] || c[pr2] != c[p2]) {
    ;            c_n[p1] = c_n[pr1] + 1;
    ;            h[c_n[pr1] + 1] = i;
    ;        } else {
    ;            c_n[p1] = c_n[pr1];
    ;        }
    ;    }
    ;    c = c_n;
    mov rdx, 0
    mov ecx, [r14 + 0 * INT_SZ]                 ; rcx = p[0]
    mov [r13 + rcx * INT_SZ], edx               ; c_n[p[0]] = 0
    mov [r11 + 0 * INT_SZ], edx                 ; h[0] = 0
    mov r8, 1                                   ; i = 1
    .inner_loop3:                               ; for(;i < n;)

        mpush r8, r9, rbx
            mov rbx, r8                         ; rbx = i (save for the future)
            mov ecx, [r14 + r8 * INT_SZ]        ; p1 = p[i]
            mov edx, [r14 + (r8 - 1) * INT_SZ]  ; pr1 = p[i - 1]
            mov r8, rcx                         ; p2 = p1
            add r8, r9                          ; p2 += l
            add r9, rdx                         ; pr2 = pr1 + l

            if r8, l, rsi, .inner_loop3_if1     ; p2 % n
                sub r8, rsi

            .inner_loop3_if1:

            if r9, l, rsi, .inner_loop3_if2     ; pr2 % n
                sub r9, rsi

            .inner_loop3_if2:

            mpush rax, r10, r14, r15
                mov eax, [r12 + rcx * INT_SZ]   ; rax = c[p1]
                mov r10d, [r12 + rdx * INT_SZ]   ; r10 = c[pr1]
                mov r14d, [r12 + r8 * INT_SZ]  ; r14 = c[p2]
                mov r15d, [r12 + r9 * INT_SZ]   ; r15 = c[pr2]

                if rax, ne, r10, .inner_loop3_not_equal
                if r14, ne, r15, .inner_loop3_not_equal

                .inner_loop3_equal:
                    mpush r12
                        mov r12d, [r13 + rdx * INT_SZ]   ; r12 = c_n[pr1]
                        mov [r13 + rcx *  INT_SZ], r12d ; c_n[p1] = c_n[pr1]
                    mpop r12
                    jmp .inner_loop3_after_cmp

                .inner_loop3_not_equal:
                    mpush r12
                        mov r12d, [r13 + rdx * INT_SZ]   ; r12 = c_n[pr1]
                        add r12, 1
                        mov [r13 + rcx *  INT_SZ], r12d ; c_n[p1] = c_n[pr1] + 1
                        mov [r11 + r12 * INT_SZ], ebx   ; h[c_n[pr1] + 1] = i
                    mpop r12

                .inner_loop3_after_cmp:

            mpop rax, r10, r14, r15


        mpop r8, r9, rbx

        add r8, 1                               ; i++
        if r8, l, rsi, .inner_loop3             ; if i < n goto .inner_loop3

    mpop rdx

   ; moving values of `c_n` to `c`

    mpush rax, rdi, rsi, rdx, r8, r9, r10, r11
        mov rdi, r12
        mov rsi, r13
        shl rdx, 2
        call memmove
    mpop rax, rdi, rsi, rdx, r8, r9, r10, r11

    add r9, r9                      ; l *= 2
    if r9, l, rsi, .calc_loop       ; if l < n goto .calc_loop

    ; move values of `p` to SuffixArray object

    mpush rax, rdi, rsi, rdx, r9, r10, r11
        mov rdx, rsi
        shl rdx, 2

        mov rdi, rax
        add rdi, DATA

        mov rsi, r14

        call memcpy
    mpop rax, rdi, rsi, rdx, r9, r10, r11

    ; deallocation memory

.finish1:
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
    mov r12, rdi
    mov rdi, [rdi]
    call free       ; deallocating memory for input string

    mov rdi, r12
    call free       ; deallocating memory for object
    ret

length:
    mov eax, [rdi + LEN]
    ret

getPosition:
    mov eax, [rdi + DATA + rsi * INT_SZ]
    ret

%macro searchFirstEntry 3    ; SuffixArray, str address, str len
    mov r8, 0           ; l = 0
    mov r9d, [%1 + LEN] ; r = length
    mov rax, [%1]      ; SuffixArray.str
%%loop:
    mov r10, r8
    add r10, r9
    shr r10, 1          ; m = (l + r) / 2

    mpush r12

    mov r11, 0                              ; i = 0;
    mov r12d, [%1 + DATA + r10 * INT_SZ]     ; r12 = arr[m]
    %%inner_loop:
        mov cl, [rax + r12 * CHAR_SZ]       ; cl = SuffixArray.str[arr[m] + i]
        mov dl, [%2 + r11 * CHAR_SZ]        ; dl = str[i]

        cmp cl, dl
        jl %%comparator_true
        jne %%comparator_false

        add r11, 1                          ; i++
        add r12, CHAR_SZ                    ; r12 = arr[m] + 1
        if r11, l, %3, %%inner_loop          ; if i < str.len goto %%inner_loop

        %%comparator_false:
            mov r9, r10                     ; r = m
            jmp %%after_cmp
        %%comparator_true:
            add r10, 1                      ; m = m + 1
            mov r8, r10                     ; l = m + 1
    %%after_cmp:

    mpop r12

    if r8, l, r9, %%loop

    mov rax, r8                             ; rax = l

%endmacro

%macro searchLastEntry 3    ; SuffixArray, str address, str len
mov r8, 0           ; l = 0
    mov r9d, [%1 + LEN] ; r = length
    sub r9, 1           ; r = length - 1
    mov rax, [%1]      ; SuffixArray.str
%%loop:
    mov r10, r8
    add r10, r9
    shr r10, 1          ; m = (l + r) / 2

    mpush r12

    mov r11, 0                              ; i = 0;
    mov r12d, [%1 + DATA + r10 * INT_SZ]     ; r12 = arr[m]
    %%inner_loop:
        mov cl, [rax + r12 * CHAR_SZ]       ; cl = SuffixArray.str[arr[m] + i]
        mov dl, [%2 + r11 * CHAR_SZ]        ; dl = str[i]

        cmp cl, dl
        jl %%comparator_true
        jg %%comparator_false

        add r11, 1                          ; i++
        add r12, CHAR_SZ                    ; r12 = arr[m] + 1
        if r11, l, %3, %%inner_loop          ; if i < str.len goto %%inner_loop

        jmp %%comparator_true
        ; equal

        %%comparator_false:
            mov r9, r10                     ; r = m
            jmp %%after_cmp
        %%comparator_true:
            add r10, 1                      ; m = m + 1
            mov r8, r10                     ; l = m + 1
    %%after_cmp:

    mpop r12

    if r8, l, r9, %%loop

    mov rax, r8                             ; rax = l
%endmacro


findAllEntries:
    mpush r12, r13, r15
        mov r15, rdx

        searchFirstEntry rdi, rsi, rdx
        mov r12, rax


;=======================================
    mov r8, 0           ; l = 0
    mov r9d, [rdi + LEN] ; r = length
    mov rax, [rdi]      ; SuffixArray.str
.loop:
    mov r10, r8
    add r10, r9
    shr r10, 1          ; m = (l + r) / 2

    mpush r12

    mov r11, 0                              ; i = 0;
    mov r12d, [rdi + DATA + r10 * INT_SZ]   ; r12 = arr[m]
    .inner_loop:
        mov cl, [rax + r12 * CHAR_SZ]       ; cl = SuffixArray.str[arr[m] + i]
        mov dl, [rsi + r11 * CHAR_SZ]       ; dl = str[i]

        cmp cl, dl
        jne .after_inner_loop

        add r11, 1                          ; i++
        add r12, CHAR_SZ                    ; r12 = arr[m] + 1
        if r11, l, r15, .inner_loop         ; if i < str.len goto .inner_loop

        .after_inner_loop:                  ; equal
            if r11, e, r15, .comparator_true
            if cl, l, dl, .comparator_true
            if cl, g, dl, .comparator_false

        .comparator_false:
            mov r9, r10                     ; r = m
            jmp .after_cmp
        .comparator_true:
            add r10, 1                      ; m = m + 1
            mov r8, r10                     ; l = m + 1
    .after_cmp:

    mpop r12

    if r8, l, r9, .loop

    mov rax, r8                             ; rax = l
;=======================================
        mov r13, rax

        mov rdi, 2
        mov rsi, INT_SZ
        call calloc

        mov [rax], r12d
        mov [rax + INT_SZ], r13d

    mpop r12, r13, r15
    ret

getRangeFirst:
    mov eax, [rdi]
    ret

getRangeLast:
    mov eax, [rdi + INT_SZ]
    ret

deleteRange:
    call free
    ret
