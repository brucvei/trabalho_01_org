        .data
msg_init:   .asciiz "Inicializando o simulador MIPS...\n"
msg_done:   .asciiz "Simulador inicializado com sucesso.\n"
msg_pc_sp:  .asciiz "PC: 0x%08X, SP: 0x%08X\n"

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

        # Imprime mensagem de sucesso
        la $a0, msg_done
        li $v0, 4
        syscall

        # Finaliza o programa
        li $v0, 10
        syscall

        .align 2
reg:    .space 128  # 32 registradores de 4 bytes cada
PC:     .word 0     # Contador de programa
IR:     .word 0     # Registrador de instrução
