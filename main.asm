# Benjamin Goldberg
#
#
#
# Create the Chunk Availability Array and Malloc proc
#


.data
    variablePrompt: .asciiz "Enter variable name: "
    userInput: .space 22
    chunkArray: .space 128 # 128 bytes for chunk availability (0 is free, 1 is allocated)
    mallocFailMsg: .asciiz "Error: No free memory chunks available. \n"
    sizePrompt: .asciiz "Enter size (bytes to allocate): "

.text

main: 
     # Prompt user to enter variable name
    li $v0, 4
    la $a0, variablePrompt
    syscall

    # Store variable name
    li $v0, 8 # prepare to read string
    la $a0, userInput # load userInput variable address onto register
    li $a1, 22 # max characters = 22
    syscall

    li $v0, 4
    la $a0, userInput
    syscall

    # prompt user for allocation size
    li $v0, 4
    la $a0, sizePrompt
    syscall

    # read integral from user
    li $v0, 5
    syscall
    move $t1, $v0   # $s2 now holds bytes to allocate

    # save the original stack pointer in $s0
    move $s0, $sp
    li $t0, 0   # this will be the chunk index as it is allocated
    li $t4, 128 # total number of chunks to allocate


round_up:
    addi $t9, $t9, 1    
    jr $ra

malloc: 
    # Procedure handling memory allocation
    # Read user input -> Check Symbol Table -> Find available chunks -> write chunks
    # $t0 is where the chunk index is located
    
    # calculate number of chunks to allocate
    li   $t8, 32        # Chunk size
    move $t2, $t1       # Copy allocation size into $t2
    div  $t2, $t8       # Divide $t2 by $t8 → result in LO, remainder in HI
    mflo $t9            # Quotient = number of chunks needed
    mfhi $t10           # Remainder
    
    li $a0, 0   # store zero in $a0
    bgt $t10, $a0, round_up
    # Now $t9 will have how many chunks we need

    la $t2, chunkArray  # load address of the chunkArray into $t2
    li $t0, 0   # make sure $t0 is initilized at 0. Chunk Array Counter
    li $t6, 0   # consecutive free chunks counter, initilize to zero
    j malloc_loop

malloc_loop:
    lb $t3, 0($t2 + $t0)    # load chunkArray[$t0] into $t3
    beq $t3, $zero, free_chunk  # if chunk is free (0) jump to free_chunk
    addiu $t0, $t0, 1   # increment the chunk index
    bge $t0, $t4, malloc_fail # if loop gets through all chunks ($t0 >= 128), no free memory (jump to malloc_fail)
    j malloc_loop   # repeat until free chunk found or no chunks found

free_chunk: 
    beq $t6, 0, save_start # if this is the first free chunk we've found. Save the start of it
    addi $t6, $t6, 1    # increment consecutive chunk counter
    beq $t6, $t9, allocate_chunk
    j malloc_loop

save_start: 
    move $t7, $t0   # save the current chunk counter to $t7
    addi $t6, $t6, 1    # increment consecutive chunk counter
    jr $ra

allocate_chunk:
    li $t5, 1   # Just load 1 into $t5
    # store 1 into chunkarray[$t0]
    # result: $t0 holds the allocated chunk index

allocate_loop:
    move $t0, $t7 # reset chunk counter at start of consecutive chunks
    beq $t0, $t6, malloc_finish
    sb $t5, 0($t2 + $t0)

    j allocate_loop

malloc_finish: 
    move $a0, $t0
    li $v0, 1
    syscall

    # exit program
    li $v0, 10
    syscall

malloc_fail:
    li $v0, 4
    la $a0, mallocFailMsg
    syscall
    jr $ra

    # exit program
    li $v0, 10
    syscall
free: 
    # Procedure for handling memory deallocation
    # Read user input -> Check Symbol table -> Remove from symbol table