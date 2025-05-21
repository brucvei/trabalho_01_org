.data
msg_init:   .asciiz "Inicializando o simulador MIPS...\n"
msg_done:   .asciiz "Simulador inicializado com sucesso.\n"
msg_pc_sp:  .asciiz "PC: 0x%08X, SP: 0x%08X\n"
msg_load_text: .asciiz "Carregando instruções do arquivo binário...\n"
msg_load_data: .asciiz "Carregando dados do arquivo binário...\n"
filename_text: .asciiz "ex-000-073.bin"
filename_data: .asciiz "ex-000-073.dat"
err_file:   .asciiz "Erro ao abrir arquivo binário.\n"

        .text
        .globl main

main:
        # Imprime mensagem de inicialização
        la $a0, msg_init
        li $v0, 4
        syscall

        # Inicializa registradores
        la $t0, reg
        li $t1, 0
init_regs:
        sw $t1, 0($t0)
        addiu $t0, $t0, 4
        addiu $t1, $t1, 1
        li $t2, 32
        bne $t1, $t2, init_regs

        # Inicializa $sp (reg[29]) e PC
        la $t0, reg
        li $t1, 29
        sll $t1, $t1, 2
        add $t0, $t0, $t1
        li $t2, 0x7FFFEFFC
        sw $t2, 0($t0)

        li $t3, 0x00400000
        sw $t3, PC

        # Carrega arquivo binário de instruções em mem_text
        la $a0, msg_load_text
        li $v0, 4
        syscall

        la $a0, filename_text      # nome do arquivo
        li $a1, 0                  # modo leitura
        li $v0, 13                 # syscall open
        syscall
        bltz $v0, file_error
        move $s0, $v0              # descritor do arquivo

        la $a1, mem_text           # buffer destino
        li $a2, 4096               # lê até 4096 bytes (ajuste conforme necessário)
        li $v0, 14                 # syscall read
        syscall
        move $s1, $v0              # bytes lidos

        li $v0, 16                 # syscall close
        move $a0, $s0
        syscall

        # Carrega arquivo binário de dados em mem_data
        la $a0, msg_load_data
        li $v0, 4
        syscall

        la $a0, filename_data
        li $a1, 0
        li $v0, 13                 # syscall open
        syscall
        bltz $v0, file_error
        move $s0, $v0

        la $a1, mem_data
        li $a2, 4096
        li $v0, 14                 # syscall read
        syscall
        move $s2, $v0

        li $v0, 16                 # syscall close
        move $a0, $s0
        syscall

        # Imprime mensagem de sucesso
        la $a0, msg_done
        li $v0, 4
        syscall

        # Finaliza o programa
        li $v0, 10
        syscall

file_error:
        la $a0, err_file
        li $v0, 4
        syscall
        li $v0, 10
        syscall

        .align 2
reg:    .space 128  # 32 registradores de 4 bytes cada
PC:     .word 0     # Contador de programa
IR:     .word 0     # Registrador de instrução
mem_text: .space 4096   # espaço para instruções (ajuste conforme necessário)
mem_data: .space 4096   # espaço para dados (ajuste conforme necessário)
