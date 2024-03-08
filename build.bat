@echo off
nasm -f win64 -gcv8 pong.asm 
gcc -o pong.exe pong.obj -lgdi32
if "%1" == "run" (pong.exe)
