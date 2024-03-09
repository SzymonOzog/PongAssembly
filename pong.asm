bits 64
default rel

WIDTH equ 800
HEIGHT equ 600
WM_PAINT equ 0x000F
VK_J equ 0x4A
VK_K equ 0x4B
WM_KEYDOWN equ 0x100
WM_KEYUP equ 0x101
PLAYER_SIZE_X EQU 30
PLAYER_SIZE_Y EQU 100
BALL_SIZE EQU 15


segment .data
    format db "value %d", 0xd, 0xa, 0
    float_fm db "float %f", 0xd, 0xa, 0
    error db "error %d", 0xd, 0xa, 0
    window_name db "pong window", 0
    style dw 0x3
    hbr_background dw 0x5
    dw_style dd 0xcf0000
    handle dq 1
    player1_x dd 0
    player1_y dd HEIGHT/2 - PLAYER_SIZE_Y/2
    player2_x dd WIDTH - PLAYER_SIZE_X
    player2_y dd HEIGHT/2 - PLAYER_SIZE_Y/2
    ball_x dd WIDTH/2 - BALL_SIZE/2
    ball_y dd HEIGHT/2 - BALL_SIZE/2
    delta_time dd 0
    ball_speed_x dd 0.0001
    ball_speed_y dd 0.0001

segment .bss
    hInstance resb 8
    win_class resb 80
    buffer resb 4*WIDTH*HEIGHT
    rect resb 16
    paint_struct resb 72
    bitmap_info resb 44
    msg resb 48
    input_up resb 1
    input_down resb 1
    time resb 8

segment .text
    global main
    extern ExitProcess
    extern CreateWindowExA
    extern RegisterClassExA
    extern printf
    extern DefWindowProcA
    extern GetLastError
    extern ShowWindow
    extern GetWindowRect
    extern BeginPaint
    extern EndPaint
    extern SetDIBitsToDevice 
    extern GetWindowRect
    extern TranslateMessage
    extern DispatchMessageA
    extern IsWindow
    extern GetMessageA
    extern InvalidateRect
    extern GetSystemTimePreciseAsFileTime
    

main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32 + 16

    pxor xmm0,xmm0
    cvtsi2ss xmm0, dword[player1_y]
    movss [player1_y], xmm0
    cvtsi2ss xmm0, dword[player2_y]
    movss [player2_y], xmm0
    cvtsi2ss xmm0, dword[ball_x]
    movss [ball_x], xmm0
    cvtsi2ss xmm0, dword[ball_y]
    movss [ball_y], xmm0


    call    create_window

.MAIN_LOOP:
    lea rcx, [time]
    call GetSystemTimePreciseAsFileTime
    mov rax, qword[time]
    mov qword[rsp+32], rax

    
    call  clear_buffer
    call  draw_objects
    call redraw

    lea rcx, [msg]
    mov rdx, qword[handle]
    mov r8, 0
    mov r9, 0
    call GetMessageA
    lea rcx, [msg]
    call TranslateMessage
    lea rcx, [msg]
    call DispatchMessageA

    call read_input
    mov rcx, qword[handle]
    call IsWindow

    lea rcx, [time]
    call GetSystemTimePreciseAsFileTime
    mov rax, qword[time]
    sub rax, qword[rsp+32]
    mov qword[delta_time], rax
    
    cmp rax, 0
    jne .MAIN_LOOP
    xor     rax, rax
    call    ExitProcess

draw_objects:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov ecx, dword[player1_x]
    cvtss2si edx, dword[player1_y]
    mov r8d, PLAYER_SIZE_X
    mov r9d, PLAYER_SIZE_Y
    call draw_rect
    
    mov ecx, dword[player2_x]
    cvtss2si edx, dword[player2_y]
    mov r8d, PLAYER_SIZE_X
    mov r9d, PLAYER_SIZE_Y
    call draw_rect

    cvtss2si ecx, dword[ball_x]
    cvtss2si edx, dword[ball_y]
    mov r8d, BALL_SIZE
    mov r9d, BALL_SIZE
    call draw_rect

    mov ecx, WIDTH/2
    mov edx, 0
    mov r8d, 5
    mov r9d, HEIGHT
    call draw_rect

    leave 
    ret

draw_rect:
    push rbp
    mov rbp, rsp
    sub rsp, 32  + 7*4
    %define x rsp+32
    %define y rsp+36
    %define w rsp+40
    %define h rsp+44
    %define i rsp+48
    %define j rsp+52

    mov dword[x], ecx
    mov dword[y], edx
    mov dword[w], r8d
    mov dword[h], r9d

    mov eax, dword[y]
    mov dword[i], eax
.draw_outer:
    mov eax, dword[x]
    mov dword[j], eax
.draw_inner:
    xor rax, rax
    mov eax, dword[i]
    imul rax, WIDTH 
    add eax, dword[j]
    imul rax, 4 ; go from index to byte offset

    lea r10, [buffer]
    add r10, rax
    mov dword[r10], 0xFFFFFF

    add dword[j], 1

    mov eax, dword[j]
    sub eax, dword[x]
    cmp eax, dword[w]
    jl .draw_inner
    add dword[i], 1
    mov eax, dword[i]
    sub eax, dword[y]
    cmp eax, dword[h]
    jl .draw_outer
    leave
    ret

read_input:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    cmp dword[msg+8], WM_KEYDOWN
    jne .NOT_KEYDOWN
    cmp qword[msg+16], VK_J
    jne .NOT_J_DOWN
    mov byte[input_down], 1
    .NOT_J_DOWN:
    cmp qword[msg+16], VK_K
    jne .NOT_K_DOWN
    mov byte[input_up], 1
    .NOT_K_DOWN:
    .NOT_KEYDOWN:

    cmp dword[msg+8], WM_KEYUP
    jne .NOT_KEYUP
    cmp qword[msg+16], VK_J
    jne .NOT_J_UP
    mov byte[input_down], 0
    .NOT_J_UP:
    cmp qword[msg+16], VK_K
    jne .NOT_K_UP
    mov byte[input_up], 0
    .NOT_K_UP:
    .NOT_KEYUP:

    add rsp, 32
    leave
    ret


create_window:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32 + 8*8
    
    ; wndclassA
    mov dword[win_class], 80
    mov dword[win_class+4], 0x3
    lea rax, [window_proc]
    mov qword[win_class+8], rax 
    mov dword[win_class+16], 0
    mov dword[win_class+20], 0
    mov qword[win_class+24], 0
    mov qword[win_class+32], 0
    mov qword[win_class+40], 0
    mov qword[win_class+48], 0x5
    lea rax, [window_name]
    mov qword[win_class+56], rax
    lea rax, [window_name]
    mov qword[win_class+64], rax 
    mov qword[win_class+72], 0

    lea rcx, [win_class]
    call RegisterClassExA

    mov ecx, 0
    mov rdx, qword[win_class+56]
    mov r8, qword[win_class+64]
    mov r9, qword[dw_style]

    mov qword[rsp+4*8], 200
    mov qword[rsp+5*8], 200
    mov qword[rsp+6*8], 800
    mov qword[rsp+7*8], 600

    mov qword[rsp+8*8], 0
    mov qword[rsp+9*8], 0
    mov qword[rsp+10*8], 0
    mov qword[rsp+11*8], 0
    call CreateWindowExA

    cmp rax, 0
    jne .NO_ERROR
    call GetLastError
    lea rcx, [error]
    mov rdx, rax
    call printf
    call ExitProcess
    .NO_ERROR:
    mov qword[handle], rax
    mov    rcx, qword[handle] 
    mov    rdx, 10
    call   ShowWindow

    add rsp, 32 + 8*8
    leave
    ret

window_proc:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 4*8
    
    mov qword[rsp+4*8], rcx
    mov qword[rsp+5*8], rdx
    mov qword[rsp+6*8], r8
    mov qword[rsp+7*8], r9

    cmp qword[rsp+5*8], WM_PAINT
    jne .CONTINUE
    call draw_buffer
.CONTINUE:
    mov rcx, qword[rsp+4*8]
    mov rdx, qword[rsp+5*8]
    mov r8, qword[rsp+6*8]
    mov r9, qword[rsp+7*8]
    call DefWindowProcA
    leave 
    ret
clear_buffer:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov r10, 0
    lea r11, [buffer]
.LOOP:
    mov dword[r11], 0
    add r10, 1
    add r11, 4
    cmp r10, WIDTH*HEIGHT
    jl .LOOP
    leave
    ret

redraw:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov qword[rect], 0
    mov qword[rect+4], 0
    mov qword[rect+8], WIDTH
    mov qword[rect+12], HEIGHT

    mov rcx, qword[handle]
    lea rdx, [rect]
    mov r8, 0
    call InvalidateRect
    leave
    ret

draw_buffer:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8

    mov rcx, qword[handle]
    lea rdx, [rect]
    call GetWindowRect
    
    mov qword[paint_struct], 0
    mov dword[paint_struct+8], 1
    mov rax, qword[rect]
    mov qword[paint_struct+12], rax
    mov rax, qword[rect+8]
    mov qword[paint_struct+20], rax 
    mov dword[paint_struct+44], 0
    mov dword[paint_struct+48], 0
    
    mov rcx, qword[handle]
    lea rdx, [paint_struct]
    call BeginPaint

    mov qword[rsp+32], rax
    
    mov dword[bitmap_info], 40
    mov dword[bitmap_info+4], WIDTH 
    mov dword[bitmap_info+8], HEIGHT 
    mov word[bitmap_info+12], 1
    mov word[bitmap_info+14], 32
    mov dword[bitmap_info+16], 0
    mov dword[bitmap_info+20], 0
    mov qword[bitmap_info+24], 0
    mov qword[bitmap_info+28], 0
    mov qword[bitmap_info+32], 0
    mov dword[bitmap_info+36], 0
    mov dword[bitmap_info+40], 0

    mov rcx, qword[rsp+32] 
    mov rdx, 0
    mov r8, 0
    mov r9, WIDTH 
    sub rsp, 8*8
    mov qword[rsp+4*8], HEIGHT
    mov qword[rsp+5*8], 0
    mov qword[rsp+6*8], 0
    mov qword[rsp+7*8], 0
    mov qword[rsp+8*8], HEIGHT
    lea rax, [buffer]
    mov qword[rsp+9*8], rax
    lea rax, [bitmap_info]
    mov qword[rsp+10*8], rax
    mov qword[rsp+11*8], 0
    call SetDIBitsToDevice 

    mov rcx, qword[handle]
    lea rdx, [paint_struct]
    call EndPaint

    leave 
    ret

