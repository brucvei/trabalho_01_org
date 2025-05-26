.data
msg_init:   .asciiz "Inicializando o simulador MIPS...\n"
msg_done:   .asciiz "Simulador inicializado com sucesso.\n"
msg_pc_sp:  .asciiz "PC: 0x%08X, SP: 0x%08X\n"
msg_load_text: .asciiz "Carregando instruções do arquivo binário...\n"
msg_load_data: .asciiz "Carregando dados do arquivo binário...\n"
filename_text: .asciiz "C:/Users/Bruna/Documents/organizacao-de-computadores/trabalho-01/ex-000-073.bin"
filename_data: .asciiz "C:/Users/Bruna/Documents/organizacao-de-computadores/trabalho-01/ex-000-073.dat"
err_file:   .asciiz "Erro ao abrir arquivo binário.\n"
err_open_text: .asciiz "ABRINDO TEXTO \n"
err_read_text: .asciiz "LENDO TEXTO \n"
err_open_data: .asciiz "ABRINDO DADOS \n"
err_read_data: .asciiz "LENDO DADOS \n"
err_close:     .asciiz "FECHANDO ARQUIVO \n"

        .text
        .globl main
        .ent main

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

        # Mostra o nome do arquivo que será aberto
        la $a0, filename_text
        li $v0, 4
        syscall

        la $a0, filename_text      # nome do arquivo
        li $a1, 0                  # modo leitura
        li $v0, 13                 # syscall open
        syscall
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

        # Loop de execução de instruções
exec_loop:
        # Busca: IR = mem_text[(PC - 0x00400000) >> 2]
        lw $t0, PC
        li $t1, 0x00400000
        subu $t2, $t0, $t1
        srl $t2, $t2, 2
        la $t3, mem_text
        sll $t4, $t2, 2
        addu $t3, $t3, $t4
        lw $t5, 0($t3)
        sw $t5, IR

        # Decodificação dos campos da instrução
        lw $t6, IR
        srl $t7, $t6, 26         # opcode = IR[31:26]
        andi $t7, $t7, 0x3F
        move $s3, $t7            # $s3 = opcode

        srl $t8, $t6, 21         # rs = IR[25:21]
        andi $t8, $t8, 0x1F
        move $s4, $t8            # $s4 = rs

        srl $t9, $t6, 16         # rt = IR[20:16]
        andi $t9, $t9, 0x1F
        move $s5, $t9            # $s5 = rt

        srl $a3, $t6, 11         # rd = IR[15:11]
        andi $a3, $a3, 0x1F
        move $s6, $a3            # $s6 = rd

        srl $a2, $t6, 6          # shamt = IR[10:6]
        andi $a2, $a2, 0x1F
        move $s7, $a2            # $s7 = shamt

        andi $a1, $t6, 0x3F      # funct = IR[5:0]
        move $t0, $a1            # $t0 = funct

        andi $a0, $t6, 0xFFFF    # immediate = IR[15:0]
        move $t1, $a0            # $t1 = immediate

        li $t3, 0x03FFFFFF       # address = IR[25:0]
        and $t2, $t6, $t3
        move $t2, $t2            # $t2 = address

        # Incrementa PC
        lw $t3, PC
        addiu $t3, $t3, 4
        sw $t3, PC

        # Decisão de instrução
        beqz $s3, tipoR          # opcode == 0 -> tipo R
        li $t4, 2
        beq $s3, $t4, tipoJ      # opcode == 2 -> j
        li $t4, 3
        beq $s3, $t4, tipoJ      # opcode == 3 -> jal (não implementado, só exemplo)
        li $t4, 4
        beq $s3, $t4, beq_inst   # opcode == 4 -> beq
        li $t4, 5
        beq $s3, $t4, bne_inst   # opcode == 5 -> bne
        li $t4, 8
        beq $s3, $t4, addi_inst  # opcode == 8 -> addi
        li $t4, 12
        beq $s3, $t4, andi_inst  # opcode == 12 -> andi
        li $t4, 13
        beq $s3, $t4, ori_inst   # opcode == 13 -> ori
        li $t4, 35
        beq $s3, $t4, lw_inst    # opcode == 35 -> lw
        li $t4, 43
        beq $s3, $t4, sw_inst    # opcode == 43 -> sw
        j exec_loop              # instrução não suportada, ignora

tipoR:
        # Funct: add=32, sub=34, and=36, or=37, sll=0, srl=2, syscall=12
        li $t4, 32
        beq $t0, $t4, add_inst
        li $t4, 34
        beq $t0, $t4, sub_inst
        li $t4, 36
        beq $t0, $t4, and_inst
        li $t4, 37
        beq $t0, $t4, or_inst
        li $t4, 0
        beq $t0, $t4, sll_inst
        li $t4, 2
        beq $t0, $t4, srl_inst
        li $t4, 12
        beq $t0, $t4, syscall_inst
        j exec_loop

add_inst:
        # reg[rd] = reg[rs] + reg[rt]
        la $t1, reg
        sll $t2, $s4, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)           # reg[rs]
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t5, 0($t3)           # reg[rt]
        add $t6, $t4, $t5
        sll $t2, $s6, 2
        addu $t3, $t1, $t2
        sw $t6, 0($t3)           # reg[rd]
        j exec_loop

sub_inst:
        # reg[rd] = reg[rs] - reg[rt]
        la $t1, reg
        sll $t2, $s4, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)           # reg[rs]
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t5, 0($t3)           # reg[rt]
        sub $t6, $t4, $t5
        sll $t2, $s6, 2
        addu $t3, $t1, $t2
        sw $t6, 0($t3)           # reg[rd]
        j exec_loop

and_inst:
        # reg[rd] = reg[rs] & reg[rt]
        la $t1, reg
        sll $t2, $s4, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t5, 0($t3)
        and $t6, $t4, $t5
        sll $t2, $s6, 2
        addu $t3, $t1, $t2
        sw $t6, 0($t3)
        j exec_loop

or_inst:
        # reg[rd] = reg[rs] | reg[rt]
        la $t1, reg
        sll $t2, $s4, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t5, 0($t3)
        or $t6, $t4, $t5
        sll $t2, $s6, 2
        addu $t3, $t1, $t2
        sw $t6, 0($t3)
        j exec_loop

sll_inst:
        # reg[rd] = reg[rt] << shamt
        la $t1, reg
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        sllv $t5, $t4, $s7
        sll $t2, $s6, 2
        addu $t3, $t1, $t2
        sw $t5, 0($t3)
        j exec_loop

srl_inst:
        # reg[rd] = reg[rt] >> shamt
        la $t1, reg
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        srlv $t5, $t4, $s7
        sll $t2, $s6, 2
        addu $t3, $t1, $t2
        sw $t5, 0($t3)
        j exec_loop

syscall_inst:
        # syscall: verifica código em reg[2] ($v0)
        la $t1, reg
        li $t2, 2
        sll $t2, $t2, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        li $t5, 1
        beq $t4, $t5, exit1      # exit (código 1)
        li $t5, 10
        beq $t4, $t5, exit2      # exit2 (código 10)
        j exec_loop

exit1:
        # Serviço de saída (exit)
        li $v0, 10
        syscall

exit2:
        # Serviço de saída (exit2)
        li $v0, 10
        syscall

tipoJ:
        # j address
        # PC = (PC & 0xF0000000) | (address << 2)
        lw $t0, PC
        li $t2, 0xF0000000
        and $t1, $t0, $t2
        sll $t2, $t2, 2
        or $t3, $t1, $t2
        sw $t3, PC
        j exec_loop

beq_inst:
        # if reg[rs] == reg[rt] PC += (immediate << 2)
        la $t1, reg
        sll $t2, $s4, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t5, 0($t3)
        bne $t4, $t5, exec_loop
        lw $t6, PC
        sll $t7, $t1, 2
        add $t6, $t6, $t7
        sw $t6, PC
        j exec_loop

bne_inst:
        # if reg[rs] != reg[rt] PC += (immediate << 2)
        la $t1, reg
        sll $t2, $s4, 2
        addu $t3, $t1, $t2
        lw $t4, 0($t3)
        sll $t2, $s5, 2
        addu $t3, $t1, $t2
        lw $t5, 0($t3)
        beq $t4, $t5, exec_loop
        lw $t6, PC
        sll $t7, $t1, 2
        add $t6, $t6, $t7
        sw $t6, PC
        j exec_loop

addi_inst:
		    # reg[rt] = reg[rs] + immediate (com sinal!)
		    la $t1, reg
		    sll $t2, $s4, 2         # rs offset
		    addu $t3, $t1, $t2
		    lw $t4, 0($t3)          # reg[rs]

		    sll $t2, $s5, 2         # rt offset
		    addu $t3, $t1, $t2

		    # Extensão de sinal para imediato
		    move $t7, $t1           # $t1 contém o imediato extraído
		    sll $t5, $t7, 16
		    sra $t5, $t5, 16        # $t5 = sign-extended immediate

		    add $t6, $t4, $t5       # reg[rs] + imediato
		    sw $t6, 0($t3)          # reg[rt] = resultado
		    j exec_loop



andi_inst:
		    # reg[rt] = reg[rs] & immediate (zero-extended)
		    la $t1, reg
		    sll $t2, $s4, 2
		    addu $t3, $t1, $t2
		    lw $t4, 0($t3)           # reg[rs]

		    sll $t2, $s5, 2
		    addu $t3, $t1, $t2
		    andi $t5, $t1, 0xFFFF    # zero-extensão automática
		    and $t6, $t4, $t5
		    sw $t6, 0($t3)
		    j exec_loop

ori_inst:
		    # reg[rt] = reg[rs] | immediate (zero-extended)
		    la $t1, reg
		    sll $t2, $s4, 2
		    addu $t3, $t1, $t2
		    lw $t4, 0($t3)

		    sll $t2, $s5, 2
		    addu $t3, $t1, $t2
		    ori $t5, $t1, 0xFFFF     # zero-extensão automática
		    or $t6, $t4, $t5
		    sw $t6, 0($t3)
		    j exec_loop

lw_inst:
        # reg[rt] = mem_data[reg[rs] + offset]
		    la $t1, reg
		    sll $t2, $s4, 2          # rs
		    addu $t3, $t1, $t2
		    lw $t4, 0($t3)           # base

		    sll $t5, $t1, 16
		    sra $t5, $t5, 16         # sign-extend immediate

		    add $t6, $t4, $t5        # endereço efetivo
		    la $t7, mem_data
		    subu $t6, $t6, 0x10010000  # ajustar base
		    addu $t7, $t7, $t6
		    lw $t8, 0($t7)

		    sll $t2, $s5, 2          # rt
		    addu $t3, $t1, $t2
		    sw $t8, 0($t3)
		    j exec_loop

sw_inst:
		    # mem_data[reg[rs] + offset] = reg[rt]
		    la $t1, reg
		    sll $t2, $s4, 2          # rs
		    addu $t3, $t1, $t2
		    lw $t4, 0($t3)

		    sll $t5, $t1, 16
		    sra $t5, $t5, 16         # sign-extend immediate

		    add $t6, $t4, $t5        # endereço efetivo

		    sll $t2, $s5, 2          # rt
		    addu $t3, $t1, $t2
		    lw $t7, 0($t3)           # valor a armazenar

		    la $t8, mem_data
		    subu $t6, $t6, 0x10010000
		    addu $t8, $t8, $t6
		    sw $t7, 0($t8)
		    j exec_loop

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
mem_text: .space 4096   # espaço para instruções
mem_data: .space 4096   # espaço para dados

.end main
