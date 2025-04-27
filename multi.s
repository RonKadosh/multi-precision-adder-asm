%macro print 1
    push eax
    lea eax, [%1]       
    push eax            
    call puts           
    add esp, 4
    pop eax         
%endmacro

section .data
    invalid_arg_msg db "Invalid Argument! exiting program.", 0
    debug_msg_1 db "IN LSFR", 0
    debug_msg_2 db "IN STDIN", 0
    debug_msg_3 db "HERE", 0
    strct_format db "%02hhx", 0
    line_feed db 0x0a, 0
    digit_format_debug db "%d", 0x0a, 0
    chat_format_debug db "%s" , 0x0a, 0
    x_struct: dw 5
    x_num: dw 0xaa, 1,2,0x44,0x4f
    y_struct: dw 6
    y_num: dw 0xaa, 1,2,3,0x44,0x4f
    STATE dw 0xF1BB        ; Initial non-zero state (16-bit)
    MASK  dw 0xB400        ; Fibonacci LFSR mask for 16 bits
    buffer db 256 dup(0)      ; Buffer to store input (128 bytes)
    debug_msg_invalid db "Invalid input!", 0


section .text
    global _start
    global get_maxmin
    global print_multi
    global add_multi
    global rand_num
    global PRmulti
    global read_hex_multi
    extern malloc
    extern printf
    extern puts
    extern stdin
    extern fgets


_start:
    ; check if argc == 2 jump to check arg
    mov eax, [esp]
    cmp eax, 2
    je check_arg

    ; no args, the program operates on numbers encoded by x_struct and y_struct
    push x_struct
    push y_struct
    call add_multi
    add esp, 8
    jmp exit_program

check_arg:
    mov eax, [esp + 8]
    mov esi, eax

    mov al, [esi]
    cmp al, '-'
    jne invalid_arg

    mov al, [esi + 2]
    cmp al, 0
    jne invalid_arg

    mov al, [esi + 1]
    cmp al, 'R'
    je input_from_lsfr

    cmp al, 'I'
    je input_from_stdin

    jmp invalid_arg

input_from_lsfr:
    call PRmulti
    push eax
    call PRmulti
    push eax
    call add_multi
    jmp exit_program

input_from_stdin:
    call read_hex_multi
    push eax
    call read_hex_multi
    push eax
    call add_multi
    add esp, 8
    jmp exit_program

invalid_arg:
    print invalid_arg_msg

exit_program:
    ; Exit the program
    mov eax, 1          ; syscall number for sys_exit
    xor ebx, ebx        ; exit code 0
    int 0x80            ; invoke syscall

print_multi:
 ; function prologue
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push esi
 ; struct pointer is pushed now the first arg, [ebp + 8]?
    mov esi, [ebp + 8]
    xor ebx, ebx
    mov bx, word [esi]  ; size is here
    lea esi, [esi + 2*ebx]  ; last word is here
 ; now print loop from the last word to the first word
 skip_zeros:
    xor eax, eax
    mov ax, word [esi]
    cmp eax, 0
    jnz print_multi_loop
    sub esi, 2
    dec bx
    jmp skip_zeros
print_multi_loop:
    xor eax, eax
    mov ax, word [esi]
    push eax
    push strct_format
    call printf
    add esp, 8
    sub esi, 2
 ; dec size and check if 0
    dec bx
    jnz print_multi_loop
 ; when condition isnt met, print line feed to flush the buffer
    push line_feed
    call printf
    add esp, 4
 ; function epilogue
    pop esi
    pop ebx
    pop eax
    mov esp, ebp
    pop ebp
    ret
    
get_maxmin:
 ; function prologue
    push ebp
    mov ebp, esp
 ; move the struct pointers to registers
    mov esi, [ebp + 8]
    mov edi, [ebp + 12]
 ; move the corresponding sizes to cx and dx
    xor ecx, ecx
    xor edx, edx
    mov cx, word [esi]
    mov dx, word [edi]
    cmp ecx, edx
    jge first_bigger
 ; second bigger
    mov eax, edi
    mov ebx, esi
    jmp second_bigger
first_bigger:
    mov eax, esi
    mov ebx, edi
second_bigger:
 ; function epilogue
    mov esp, ebp
    pop ebp
    ret

add_multi:
 ; function epiloge
   push ebp
   mov ebp, esp
 ; sort, move the operands to ebx, ecx and print them
   mov ecx, [ebp + 8]
   mov edx, [ebp + 12]

   push ecx
   push edx
   call get_maxmin

   mov esi, eax

   push esi
   call print_multi
   add esp, 4

    push ebx
    call print_multi
    add esp, 4
 
 ; alloc the new addition struct and set size
    xor ecx, ecx
    mov cx, word [eax]
    add ecx, 2
    shl ecx, 1
    push ecx
    call malloc
    pop ecx
    shr ecx, 1
    dec ecx
    mov word [eax], cx
    push eax

 ; now esi = bigger struct, ebx = smaller struct, eax = new struct
 ; calculate loops
    xor edx, edx
    mov dx, word [esi]  ; dx = big.size
    sub dx, word [ebx]  ; dx = dx - small.size
    mov edi, edx        ; edi = big.size - small.size (second loop)
    push edi            ; push second loop

    mov dx, word [ebx]
    mov edi, edx        ; edi = first loop
    xor edx, edx
addition_loop:  ; 2 bytes at a time
 ; calc offsets
    add eax, 2
    add esi, 2
    add ebx, 2
 ; make the first byte addition
    xor ecx, ecx
    mov cl, byte [esi]
    add cx, word [ebx] 
    add cx, dx
    mov byte [eax], cl
 ; calc the first byte carry
    mov dx, cx
    shr dx, 8
    and dx, 1
 ; inc loop
    dec edi
    jnz addition_loop
    pop edi
leftover_loop:
    cmp edi, 0
    je end_loop
    add eax, 2
    add esi, 2
    xor ecx, ecx
    mov cl, byte [esi]
    add cx, dx
    mov byte [eax], cl
    mov dx, cx
    shr dx, 8
    and dx, 1
    dec edi
    jmp leftover_loop
end_loop:
    mov byte [eax + 2], dl
    call print_multi
 ; function prologue
   mov esp, ebp
   pop ebp
   ret

rand_num:
; Function prologue
    push ebp
    mov ebp, esp
    xor ax, ax
    xor bx, bx

; Use the MASK to get just the relevant bits of the STATE variable
mov ax, [STATE]
mov bx, [MASK]
and ax, bx

; Compute the feedback bit by XORing relevant bits based on the mask
xor dx, dx        ; Clear DX to store feedback bit
xor cx, cx        ; Clear CX for loop counter

compute_feedback:
    test bx, 1    ; Check if the current bit of MASK is set
    jz skip_xor   ; If not set, skip XOR
    xor dx, ax    ; XOR the current bit of STATE into feedback

skip_xor:
    shr bx, 1     ; Shift MASK right by 1 bit
    shr ax, 1     ; Shift STATE right by 1 bit
    inc cx        ; Increment loop counter
    cmp cx, 16    ; Repeat until all 16 bits are processed
    jne compute_feedback

; DX now contains the feedback bit in the LSB

    test dx, 1        ; Check the feedback bit
    jz set_msb_zero   ; If feedback is zero, jump to set MSB to 0

set_msb_one:
    mov dx, 1
    jmp shift

set_msb_zero:
    mov dx, 0

shift:
    ; Shift the bits of the (non-masked) STATE variable one position to the right
    mov ax, [STATE]
    shr ax, 1
    shl dx, 15    ; Move feedback bit to MSB position
    or ax, dx     ; Insert feedback bit at MSB
    mov [STATE], ax

; Function epilogue
mov esp, ebp
pop ebp
ret

PRmulti:
    push ebp
    mov ebp, esp

generate_length:
    xor ecx, ecx
    call rand_num          ; Call PRNG to get a random 16-bit number
    movzx ecx, al          ; Use the lower 8 bits of EAX as length (ECX = n)
    test ecx, ecx          ; Check if length is zero
    jnz allocate_memory    ; If not zero, proceed to allocate memory
    jmp generate_length    ; Retry if length is zero

allocate_memory:
    add ecx, 1             ; Add 1 to ECX to account for the size field in the struct
    shl ecx, 1
    push ecx               ; Push total size (1 + n) as argument to malloc
    call malloc            ; Allocate memory on the heap
    pop ecx             ; Clean up stack after malloc
    mov esi, eax           ; Store the allocated memory pointer in ESI
    shr ecx, 1
    dec ecx
    ; Store the length in the size field of the struct
    mov word [esi], cx     ; Store length (n) in the first byte of the struct


generate_value:
    xor edi, edi           ; Clear EDI (counter for generated bytes)
    shl ecx, 1
generate_loop:
    push ecx
    call rand_num          ; Call PRNG to generate a 16-bit random number
    pop ecx
    mov [esi + edi + 2], ax ; Store the lower 8 bits of EAX in the num array
    add edi, 2                ; Increment byte counter
    cmp edi, ecx           ; Check if we've generated n bytes
    jl generate_loop       ; If not done, repeat
    
    mov eax, esi

    mov esp, ebp
    pop ebp
    ret


read_hex_multi:
    push ebp
    mov ebp, esp

 ; read input using fgets
    lea ebx, [buffer + 1]         
    push dword [stdin]        
    push dword 255            
    push ebx                  
    call fgets                
    add esp, 12               
 ; count the size of the struct
    xor ecx, ecx
count_loop:
    cmp byte [ebx + ecx], 0xa
    je end_count
    inc ecx
    jmp count_loop
end_count:
    test ecx, 1
    jz alloc_mem   ; if even
 ; else, need to fix the number to be even
    dec ebx
    mov byte [ebx], '0'
    inc ecx
    jmp alloc_mem

alloc_mem:
    add ebx, ecx
    sub ebx, 2
    inc ecx

    push ecx
    call malloc
    pop ecx
    dec ecx

    shr ecx, 1
    mov word [eax], cx

    mov esi, eax
    xor edi, edi
    xor eax, eax
    add esi, 2

parse_char_to_hex_loop:
    xor edx, edx
    xor eax, eax
    mov al, byte [ebx]
    call hex_to_nibble
    mov dh, al

    mov al, byte [ebx + 1]
    call hex_to_nibble
    shr edx, 4
    or al, dl
    mov word [esi + edi], ax
    inc edi
    inc edi
    sub ebx, 2
    dec ecx
    jz end_parse
    jmp parse_char_to_hex_loop

hex_to_nibble:
    cmp al, '0'
    jl invalid_hex            ; If less than '0', it's invalid
    cmp al, '9'
    jg check_alpha            ; If greater than '9', check if it's a letter
    sub al, '0'               ; Convert '0'-'9' to 0-9
    ret

check_alpha:
    cmp al, 'A'
    jl invalid_hex            ; If less than 'A', it's invalid
    cmp al, 'F'
    jg check_lowercase        ; If greater than 'F', check lowercase
    sub al, 'A' - 10          ; Convert 'A'-'F' to 10-15s
    ret

check_lowercase:
    cmp al, 'a'
    jl invalid_hex            ; If less than 'a', it's invalid
    cmp al, 'f'
    jg invalid_hex            ; If greater than 'f', it's invalid
    sub al, 'a' - 10          ; Convert 'a'-'f' to 10-15
    ret
invalid_hex:
    xor al, al                ; Return 0 on invalid input
    ret

end_parse:
    sub esi, 2
    mov eax, esi
    mov esp, ebp
    pop ebp 
    ret
