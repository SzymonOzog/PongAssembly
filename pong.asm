bits 64
default rel

segment .data
    format db "%d", 0xd, 0xa, 0
    window_name db "pong window", 0
    style dw 0x3
    hbr_background dw 0x5
    dw_style dd 0xcf0000

segment .bss
    hInstance resb 8
    win_class resb 80

segment .text
    global main
    extern ExitProcess
    extern CreateWindowExA
    extern RegisterClassExA
    extern printf
    extern DefWindowProcA
    extern GetLastError
    extern ShowWindow

main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    call    create_window
    xor     rax, rax

create_window:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32 + 8*8
    
    ; wndclassA
    mov dword[win_class], 80
    mov dword[win_class+4], 0x3
    lea rax, [DefWindowProcA]
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
    lea rdx, [window_name]
    mov rdx, qword[win_class+56]
    mov r8, qword[win_class+64]
    mov r9, dw_style

    mov qword[rsp+4*8], 200
    mov qword[rsp+5*8], 200
    mov qword[rsp+6*8], 800
    mov qword[rsp+7*8], 600

    mov qword[rsp+8*8], 0
    mov qword[rsp+9*8], 0
    mov qword[rsp+10*8], 0
    mov qword[rsp+11*8], 0
    call CreateWindowExA

    mov    rcx, rax
    mov    rdx, 10
    call   ShowWindow
    leave
    ret

window_proc:
    push rbp
    mov rbp, rsp
