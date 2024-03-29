bits 64
default rel

WIDTH equ 800
HEIGHT equ 600
WM_PAINT equ 0x000F
VK_J equ 0x4A
VK_K equ 0x4B
VK_S equ 0x53
VK_W equ 0x57
WM_KEYDOWN equ 0x100
WM_KEYUP equ 0x101
PLAYER_SIZE_X EQU 30
PLAYER_SIZE_Y EQU 100
BALL_SIZE EQU 15
CS_HREDRAW EQU 0x2
CS_VREDRAW EQU 0x1
COLOR_WINDOW EQU 0x5
WS_OVERLAPPEDWINDOW EQU 0xCF0000
WS_MINIMIZEBOX EQU 0x20000
WS_SYSMENUL EQU 0x80000


segment .data
    format db "value %d", 0xd, 0xa, 0
    float_fm db "float %f", 0xd, 0xa, 0
    error db "error %d", 0xd, 0xa, 0
    window_name db "pong window", 0
    handle dq 1
    player1_x dd 0
    player1_y dd HEIGHT/2 - PLAYER_SIZE_Y/2
    player2_x dd WIDTH - PLAYER_SIZE_X
    player2_y dd HEIGHT/2 - PLAYER_SIZE_Y/2
    ball_x dd WIDTH/2 - BALL_SIZE/2
    ball_y dd HEIGHT/2 - BALL_SIZE/2
    delta_time dd 0
    ball_speed_x dd 0.00003
    ball_speed_y dd 0.00003
    player_speed dd 0.00005
    hit_move_scale dd 10000.0
    sign_invert dd 0x80000000

segment .bss
    hInstance resb 8
    win_class resb 80
    buffer resb 4*WIDTH*HEIGHT
    rect resb 16
    paint_struct resb 72
    bitmap_info resb 44
    msg resb 48
    input_up_1 resb 1
    input_down_1 resb 1
    input_up_2 resb 1
    input_down_2 resb 1
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
    call update_positions
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
    mov dword[delta_time], eax
    
    cmp rax, 0
    jne .MAIN_LOOP
    xor     rax, rax
    call    ExitProcess

update_positions:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    cmp byte[input_up_1], 1
    jne .NOT_PLAYER1_UP
    movss xmm0, dword[player_speed]
    cvtsi2ss xmm1, dword[delta_time]
    mulss xmm0, xmm1
    movss xmm1, dword[player1_y]
    addss xmm0, xmm1
    cvtss2si rax, xmm0
    cmp rax, HEIGHT - PLAYER_SIZE_Y
    jge .NOT_PLAYER1_UP
    movss [player1_y], xmm0
.NOT_PLAYER1_UP:
    cmp byte[input_down_1], 1
    jne .NOT_PLAYER1_DOWN
    movss xmm0, dword[player_speed]
    cvtsi2ss xmm1, dword[delta_time]
    mulss xmm0, xmm1
    movss xmm1, dword[player1_y]
    subss xmm1, xmm0
    cvtss2si rax, xmm1
    cmp rax, 0
    jle .NOT_PLAYER1_DOWN
    movss [player1_y], xmm1
.NOT_PLAYER1_DOWN:

    cmp byte[input_up_2], 1
    jne .NOT_PLAYER2_UP
    movss xmm0, dword[player_speed]
    cvtsi2ss xmm1, dword[delta_time]
    mulss xmm0, xmm1
    movss xmm1, dword[player2_y]
    addss xmm0, xmm1
    cvtss2si rax, xmm0
    cmp rax, HEIGHT - PLAYER_SIZE_Y
    jge .NOT_PLAYER2_UP
    movss [player2_y], xmm0
.NOT_PLAYER2_UP:
    cmp byte[input_down_2], 1
    jne .NOT_PLAYER2_DOWN
    movss xmm0, dword[player_speed]
    cvtsi2ss xmm1, dword[delta_time]
    mulss xmm0, xmm1
    movss xmm1, dword[player2_y]
    subss xmm1, xmm0
    cvtss2si rax, xmm1
    cmp rax, 0
    jle .NOT_PLAYER2_DOWN
    movss [player2_y], xmm1
.NOT_PLAYER2_DOWN:

    movss xmm0, dword[ball_speed_x]
    cvtsi2ss xmm1, dword[delta_time]
    mulss xmm0, xmm1
    movss xmm1, dword[ball_x]
    addss xmm0, xmm1
    movss [ball_x], xmm0

    movss xmm0, dword[ball_speed_y]
    cvtsi2ss xmm1, dword[delta_time]
    mulss xmm0, xmm1
    movss xmm1, dword[ball_y]
    addss xmm0, xmm1

    cvtss2si rax, xmm0
    cmp rax, HEIGHT - BALL_SIZE
    jge .CHANGE_VEL

    cvtss2si rax, xmm0
    cmp rax, 0
    JLE .CHANGE_VEL

    movss [ball_y], xmm0
    jmp .SKIP_CHANGE_Y

.CHANGE_VEL:
    movss xmm0, dword[ball_speed_y]
    movss xmm1, dword[sign_invert]
    xorps xmm0, xmm1
    movss [ball_speed_y], xmm0

.SKIP_CHANGE_Y:

    sub rsp, 8*4
    
    %define o1_x rsp+32
    %define o1_y rsp+36
    %define o1_h rsp+40
    %define o1_w rsp+44
    %define o2_x rsp+48
    %define o2_y rsp+52
    %define o2_h rsp+56
    %define o2_w rsp+60

    mov eax, dword[player1_x]
    mov dword[o1_x], eax
    cvtss2si eax, dword[player1_y]
    mov dword[o1_y], eax
    mov dword[o1_h], PLAYER_SIZE_Y
    mov dword[o1_w], PLAYER_SIZE_X

    cvtss2si eax, dword[ball_x]
    mov dword[o2_x], eax
    cvtss2si eax, dword[ball_y]
    mov dword[o2_y], eax
    mov dword[o2_h], BALL_SIZE
    mov dword[o2_w], BALL_SIZE
    call rectangle_collision
    cmp rax, 1
    je .CHANGE_VEL_X

    mov eax,dword[player2_x]
    mov dword[o1_x], eax
    cvtss2si eax,dword[player2_y]
    mov dword[o1_y], eax
    mov dword[o1_h], PLAYER_SIZE_Y
    mov dword[o1_w], PLAYER_SIZE_X

    cvtss2si eax,dword[ball_x]
    mov dword[o2_x], eax
    cvtss2si eax,[ball_y]
    mov dword[o2_y], eax
    mov dword[o2_h], BALL_SIZE
    mov dword[o2_w], BALL_SIZE
    call rectangle_collision
    cmp rax, 1
    jne .SKIP_CHANGE_X

.CHANGE_VEL_X:
    movss xmm0, dword[ball_speed_x]
    movss xmm1, dword[sign_invert]
    xorps xmm0, xmm1
    movss [ball_speed_x], xmm0

    movss xmm1, dword[ball_x]
    mulss xmm0, dword[hit_move_scale]
    addss xmm1, xmm0
    movss [ball_x], xmm1

.SKIP_CHANGE_X:
    add rsp, 8*4

    cvtss2si eax,dword[ball_x]
    cmp eax, 0
    jge .NOT_SCORED_1
    mov eax, WIDTH/2 - BALL_SIZE/2
    cvtsi2ss xmm0, eax
    movss dword[ball_x], xmm0

.NOT_SCORED_1:
    cmp eax, WIDTH - BALL_SIZE
    jle .NOT_SCORED_2
    mov eax, WIDTH/2 - BALL_SIZE/2
    cvtsi2ss xmm0, eax
    movss dword[ball_x], xmm0

.NOT_SCORED_2:
    add rsp, 32
    leave 
    ret

rectangle_collision:
    push rbp
    mov rbp, rsp

    %define o1_x rsp+32+16
    %define o1_y rsp+36+16
    %define o1_h rsp+40+16 
    %define o1_w rsp+44+16
    %define o2_x rsp+48+16
    %define o2_y rsp+52+16
    %define o2_h rsp+56+16
    %define o2_w rsp+60+16

    mov ecx, dword[o1_x]
    mov edx, dword[o2_x]
    add edx, dword[o2_w]
    cmp ecx, edx
    jge .ARE_NOT_COLLIDING

    mov ecx, dword[o1_y]
    mov edx, dword[o2_y]
    add edx, dword[o2_h]
    cmp ecx, edx
    jge .ARE_NOT_COLLIDING

    mov ecx, dword[o1_y]
    add ecx, dword[o1_h]
    mov edx, dword[o2_y]
    cmp ecx, edx
    jle .ARE_NOT_COLLIDING

    mov ecx, dword[o1_x]
    add ecx, dword[o1_w]
    mov edx, dword[o2_x]
    cmp ecx, edx
    jle .ARE_NOT_COLLIDING

    mov rax, 1
    leave
    ret
.ARE_NOT_COLLIDING:
    mov rax, 0
    leave
    ret

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
    mov byte[input_down_2], 1
    .NOT_J_DOWN:
    cmp qword[msg+16], VK_K
    jne .NOT_K_DOWN
    mov byte[input_up_2], 1
    .NOT_K_DOWN:
    cmp qword[msg+16], VK_W
    jne .NOT_W_DOWN
    mov byte[input_up_1], 1
    .NOT_W_DOWN:
    cmp qword[msg+16], VK_S
    jne .NOT_S_DOWN
    mov byte[input_down_1], 1
    .NOT_S_DOWN:
    .NOT_KEYDOWN:

    cmp dword[msg+8], WM_KEYUP
    jne .NOT_KEYUP
    cmp qword[msg+16], VK_J
    jne .NOT_J_UP
    mov byte[input_down_2], 0
    .NOT_J_UP:
    cmp qword[msg+16], VK_K
    jne .NOT_K_UP
    mov byte[input_up_2], 0
    .NOT_K_UP:
    cmp qword[msg+16], VK_W
    jne .NOT_W_UP
    mov byte[input_up_1], 0
    .NOT_W_UP:
    cmp qword[msg+16], VK_S
    jne .NOT_S_UP
    mov byte[input_down_1], 0
    .NOT_S_UP:
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
    mov dword[win_class+4], CS_HREDRAW | CS_VREDRAW
    lea rax, [window_proc]
    mov qword[win_class+8], rax 
    mov dword[win_class+16], 0
    mov dword[win_class+20], 0
    mov qword[win_class+24], 0
    mov qword[win_class+32], 0
    mov qword[win_class+40], 0
    mov qword[win_class+48], COLOR_WINDOW 
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
    mov r9, (WS_MINIMIZEBOX | WS_SYSMENUL)

    mov qword[rsp+4*8], 200
    mov qword[rsp+5*8], 200
    mov qword[rsp+6*8], WIDTH+4 
    mov qword[rsp+7*8], HEIGHT+23

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
