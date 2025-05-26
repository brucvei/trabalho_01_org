###############################################################################
# .data - Definições de memória
###############################################################################
.data
instrucoes:      .space 256         # lista de instruções
registradores:   .space 128         # vetor de registradores
memoria:         .space 128         # vetor de memória (aumentado para 128 bytes)
pilha:           .space 128         # vetor de pilha

maskOpcode:      .word 0xFC000000   # máscara para extrair opcode
maskRs:          .word 0x03e00000   # máscara para extrair rs
maskRt:          .word 0x001f0000   # máscara para extrair rt
maskImm:         .word 0x0000ffff   # máscara para extrair o imediato
maskRd:          .word 0x0000f800   # máscara para extrair rd
maskFunct:       .word 0x0000003f   # máscara para extrair o funct
maskTarget:      .word 0x03ffffff   # máscara para extrair o target

localArquivoBin: .asciiz "C:/Users/Bruna/Documents/organizacao-de-computadores/trabalho-01/ex-000-073.bin"
localArquivoDat: .asciiz "C:/Users/Bruna/Documents/organizacao-de-computadores/trabalho-01/ex-000-073.dat"
msg_erro_mem:    .asciiz "ERRO: acesso inválido ao vetor memoria\n"
msg_fim:         .asciiz "\nSimulação concluída com sucesso!\n"
msg_leitura_ok:  .asciiz "Arquivos carregados com sucesso!\n"

###############################################################################
# .text - Código principal
###############################################################################
.text
.globl main       # Torna o símbolo 'main' global para referências externas

################################################################################
# $s0 = primeiro endereço do conteúdo do arquivo bin
# $s1 = primeiro endereço do conteudo do arquivo dat
# $s2 = primeiro endereço do vetor de registradores
# $s3 = hexadecimal atual
# $s4 = indice atual do conteúdo
################################################################################

################################################################################
# MAPA DE REGISTRADORES | INSTRUÇÕES
#							|TIPO R
#		| VETOR 	| BINÁRIO		|	OPCODE			  FUNCT
# 	$zero     0($s2)	  00000			|add	000000 rs rt rd 00000 	  100000
# 	$at	  4($s2)	  00001			|addu 	000000 rs rt rd 00000 	  100001
# 	$V0	  8($s2)	  00010			|jr	000000 rs 000000000000000 001000
# 	$v1	  12($s2)	  00011			|mul	011100 rs rt rd 00000 	  000010
# 	$a0	  16($s2)	  00100			|
# 	$a1	  20($s2)	  00101			|TIPO I
# 	$a2	  24($s2)	  00110			|	OPCODE
# 	$a3	  28($s2)	  00111			|addi	001000 rs rt imm
# 	$t0	  32($s2)	  01000			|addiu	001001 rs rt imm
# 	$t1	  36($s2)	  01001			|sw	101011 rs rt offset
# 	$t2	  40($s2)	  01010			|lw 	100011 rs rt offset
# 	$t3	  44($s2)	  01011			|bne 	000101 rs rt offset
# 	$t4	  48($s2)	  01100			|lui	001111 rs rt imm
# 	$t5	  52($s2)	  01101			|ori	001101 rs rt imm
# 	$t6	  56($s2)	  01110			|
# 	$t7	  60($s2)	  01111			|TIPO J
# 	$s0	  64($s2)	  10000			|	OPCODE
# 	$s1	  68($s2)	  10001			|jal	000011 target
# 	$s2	  72($s2)	  10010			|j	000010 target	
# 	$s3	  76($s2)	  10011			|
# 	$s4	  80($s2)	  10100			|
# 	$s5	  84($s2)	  10101			|OUTRAS
# 	$s6	  88($s2)	  10110			|
# 	$s7	  92($s2)	  10111			|syscall 000000 00000000000000000000 001100
# 	$t8	  96($s2)	  11000			|
# 	$t9	  100($s2)	  11001			|
# 	$k0	  104($s2)	  11010			|
# 	$k1	  108($s2)	  11011			|
# 	$gp	  112($s2)	  11100			|
# 	$sp	  116($s2)	  11101			|
# 	$fp	  120($s2)	  11110			|
# 	$ra	  124($s2)	  11111				|
################################################################################

main:
    # Prólogo
    la   $s2, registradores

    # Zerar registradores (exceto $sp)
    li   $t1, 0
    la   $t2, registradores
loop_zerar_regs:
    beq  $t1, 29, pula_sp
    sw   $zero, 0($t2)
    j    avanca_reg
pula_sp:
    # já setado antes
avanca_reg:
    addi $t2, $t2, 4
    addi $t1, $t1, 1
    blt  $t1, 32, loop_zerar_regs

    # Inicializa pilha
    lui  $t0, 0x7fff
    ori  $t0, $t0, 0xeffc
    add  $t0, $t0, 124
    sw   $t0, 116($s2)         # sp = &pilha[124]

    ############################################################################
    # Leitura do arquivo .bin
    ############################################################################
    addi $v0, $zero, 13        # solicita abertura de arquivo
    la   $a0, localArquivoBin  # endereço do arquivo em a0
    la   $a1, 0                # flag de leitura (0)
    syscall                    # descritor do arquivo em $v0

    move $t0, $v0              # copia descritor
    move $a0, $t0
    addi $v0, $zero, 14        # ler conteúdo do arquivo
    la   $a1, instrucoes
    addi $a2, $zero, 256
    syscall

    la   $s0, instrucoes

    # Fechar arquivo .bin
    addi $v0, $zero, 16
    move $a0, $t0
    syscall

    ############################################################################
    # Leitura do arquivo .dat
    ############################################################################
    addi $v0, $zero, 13
    la   $a0, localArquivoDat
    la   $a1, 0
    syscall

    move $t0, $v0
    move $a0, $t0
    addi $v0, $zero, 14
    la   $a1, memoria
    addi $a2, $zero, 128    # Alterado de 32 para 128 (ler todo o vetor memoria)
    syscall

    la   $s1, memoria

    # Fechar arquivo .dat
    addi $v0, $zero, 16
    move $a0, $t0
    syscall
    
    # Mostrar mensagem de sucesso da leitura
    li   $v0, 4
    la   $a0, msg_leitura_ok
    syscall

    ############################################################################
    # Loop de execução das instruções
    ############################################################################
    # Inicializa $s4 como zero (índice da primeira instrução)
    li   $s4, 0  # CORRIGIDO: $s4 deve ser um índice, não um endereço absoluto

loopInstrucoes:
    sll  $t0, $s4, 2        # multiplica índice por 4 (cada instrução = 4 bytes)
    add  $t0, $t0, $s0      # $t0 = endereço da instrução atual
    lw   $s3, 0($t0)        # carrega instrução
    beq  $s3, $zero, fim

    # Extração do opcode
    move $t0, $s3
    lw   $t2, maskOpcode
    and  $t0, $t0, $t2
    srl  $t0, $t0, 26

    # Decisão do tipo de instrução
    beq  $t0, $zero, tipo_R
    beq  $t0, 28, tipo_R
    beq  $t0, 3, tipo_J
    beq  $t0, 2, tipo_J

    # Tipo I
tipo_I:
    # Extrair rs
    lw   $t1, maskRs
    and  $t1, $t1, $s3
    srl  $t1, $t1, 21
    # Extrair rt
    lw   $t2, maskRt
    and  $t2, $t2, $s3
    srl  $t2, $t2, 16
    # Extrair imm
    lw   $t3, maskImm
    and  $t3, $t3, $s3

    # Função para encontrar os registradores da instrução
    jal  rs_rt_imm

    # Decisão da instrução tipo I
    beq  $t0, 8, _addi
    beq  $t0, 9, _addiu
    beq  $t0, 43, _sw
    beq  $t0, 35, _lw
    beq  $t0, 5, _bne
    beq  $t0, 15, _lui
    beq  $t0, 13, _ori
    beq  $t0, 4, _beq
    beq  $t0, 12, _andi

    # Execução das instruções tipo I
_addi:
    lw   $t1, ($t1)
    add  $t4, $t1, $t3
    sw   $t4, ($t2)
    j    avanca

_addiu:
    lw   $t1, ($t1)
    addu $t4, $t1, $t3
    sw   $t4, ($t2)
    j    avanca

_sw:
    lw   $t1, ($t1)        # Carrega o valor do registrador
    andi $t1, $t1, 0x1F    # Limita o índice entre 0-31
    add  $t1, $t1, $t3     # Adiciona o offset
    andi $t1, $t1, 0x1F    # Garante novamente que o índice está entre 0-31
    la   $t4, memoria
    sll  $t5, $t1, 2       # Multiplica por 4 (bytes por palavra)
    add  $t5, $t5, $t4     # Calcula endereço final
    lw   $t2, ($t2)        # Carrega valor do registrador
    sw   $t2, 0($t5)       # Armazena na memória
    j    avanca

_lw:
    lw   $t1, ($t1)        # Carrega o valor do registrador (pode ser qualquer valor)
    andi $t1, $t1, 0x1F    # Limita o índice entre 0-31 (força a estar no range válido)
    add  $t1, $t1, $t3     # Adiciona o offset
    andi $t1, $t1, 0x1F    # Garante novamente que o índice está entre 0-31
    la   $t4, memoria
    sll  $t5, $t1, 2       # Multiplica por 4 (bytes por palavra)
    add  $t5, $t5, $t4     # Calcula endereço final
    lw   $t6, 0($t5)       # Carrega da memória
    sw   $t6, 0($t2)       # Armazena no registrador
    j    avanca

erro_mem:
    # Imprime mensagem de erro e continua a execução
    li   $v0, 4
    la   $a0, msg_erro_mem
    syscall

_bne:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    beq  $t1, $t2, avanca
    sll  $t3, $t3, 2
    add  $s4, $s4, $t3       # adiciona offset ao PC quando condição é verdadeira
    j    loopInstrucoes      # Pula direto para loop, sem incrementar novamente

avanca:
    addi $s4, $s4, 4
    j    loopInstrucoes

_lui:
    sll  $t3, $t3, 16
    sw   $t3, ($t2)
    j    avanca

_ori:
    lw   $t1, ($t1)
    or   $t1, $t1, $t3
    sw   $t1, ($t2)
    j    avanca

###############################################################################
# Tipo R
###############################################################################
tipo_R:
    # Extrair rs
    lw   $t1, maskRs
    and  $t1, $t1, $s3
    srl  $t1, $t1, 21
    # Extrair rt
    lw   $t2, maskRt
    and  $t2, $t2, $s3
    srl  $t2, $t2, 16
    # Extrair rd
    lw   $t3, maskRd
    and  $t3, $t3, $s3
    srl  $t3, $t3, 11
    # Extrair funct
    lw   $t0, maskFunct
    and  $t0, $t0, $s3

    # Função para encontrar os registradores da instrução
    jal  rs_rt_rd

    # Decisão da instrução tipo R
    beq  $t0, 32, _add
    beq  $t0, 33, _addu
    beq  $t0, 8, _jr
    beq  $t0, 2, _mul
    beq  $t0, 12, _syscall
    beq  $t0, 34, _sub
    beq  $t0, 36, _and
    beq  $t0, 0, _sll
    beq  $t0, 2, _srl

    # Execução das instruções tipo R
_add:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    add  $t2, $t1, $t2
    sw   $t2, ($t3)
    j    avanca

_addu:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    addu $t2, $t1, $t2
    sw   $t2, ($t3)
    j    avanca


_jr:
    lw   $t1, ($t1)
    add  $s4, $zero, $t1
    j    loopInstrucoes

_mul:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    mul  $t1, $t1, $t2
    sw   $t1, ($t3)
    j    avanca


_syscall:
    lw   $a0, 16($s2)
    lui  $t9, 0x1001
    or   $t9, $t9, $a0
    bne  $t9, $a0, continua_s
    addi $a0, $a0, 0x0180
continua_s:
    lw   $v0, 8($s2)
    syscall
    j    avanca


###############################################################################
# Tipo J
###############################################################################
tipo_J:
    # Extrair target
    lw   $t1, maskTarget
    and  $t1, $s3, $t1

    # Decisão da instrução tipo J
    beq  $t0, 3, _jal
    beq  $t0, 2, _j

_jal:
    addi $t2, $s4, 4        # Próxima instrução como índice de retorno
    sw   $t2, 124($s2)      # Salva em $ra
    j    _j                 # Jump explícito para _j

_j:
    # O formato J do MIPS usa apenas os bits menos significativos
    # do campo target, mas o programa trabalha com índices
    andi $t1, $t1, 0x3F     # Limita o índice a 63 (valor seguro)
    move $s4, $t1           # Usa o target como índice em vez de sempre voltar para 0
    j    loopInstrucoes     

###############################################################################
# Funções auxiliares
###############################################################################
rs_rt:
    sll  $t1, $t1, 2
    add  $t1, $t1, $s2
    sll  $t2, $t2, 2
    add  $t2, $t2, $s2
    jr   $ra

rs_rt_rd:
    move $t9, $ra
    jal  rs_rt
    move $ra, $t9
    sll  $t3, $t3, 2
    add  $t3, $t3, $s2
    jr   $ra

rs_rt_imm:
    move $t9, $ra
    jal  rs_rt
    move $ra, $t9
    srl  $t4, $t3, 15
    bne  $t4, 1, fim_rs_rt_imm
    lui  $t4, 0xffff
    or   $t3, $t3, $t4
fim_rs_rt_imm:
    jr   $ra

_sub:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    sub  $t2, $t1, $t2
    sw   $t2, ($t3)
    j    avanca

_and:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    and  $t2, $t1, $t2
    sw   $t2, ($t3)
    j    avanca

_sll:
    lw   $t2, ($t2)
    andi $t4, $s3, 0x000007C0
    srl  $t4, $t4, 6
    sll  $t2, $t2, $t4
    sw   $t2, ($t3)
    j    avanca

_srl:
    lw   $t2, ($t2)
    andi $t4, $s3, 0x000007C0
    srl  $t4, $t4, 6
    srl  $t2, $t2, $t4
    sw   $t2, ($t3)
    j    avanca

_beq:
    lw   $t1, ($t1)
    lw   $t2, ($t2)
    bne  $t1, $t2, avanca
    sll  $t3, $t3, 2
    add  $s4, $s4, $t3       # adiciona offset ao PC quando condição é verdadeira
    j    loopInstrucoes      # Pula direto para loop, sem incrementar novamente

_andi:
    lw   $t1, ($t1)
    and  $t1, $t1, $t3
    sw   $t1, ($t2)
    j    avanca

###############################################################################
# Fim do programa
###############################################################################
fim:
    # Imprime mensagem de conclusão
    li   $v0, 4
    la   $a0, msg_fim
    syscall
    
    # Encerra o programa
    li   $v0, 10
    syscall
