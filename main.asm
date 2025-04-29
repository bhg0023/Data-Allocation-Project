# Benjamin Goldberg
#
#
#
# Create the Chunk Availability Array and Malloc proc
#


.data
    operationMsg: .asciiz "Do you wish to allocate (1) or deallocate (2) memory? (Type 1 or 2): "
    flagErr: .asciiz "Invalid entry!"
    variablePrompt: .asciiz "Enter variable name: "
    userInput: .space 22
    chunkArray: .space 64 # 64 bytes for chunk availability (0 is free, 1 is allocated)
    symbolTable: .space 250 # 10 entries * 25 bytes per entry
    mallocFailMsg: .asciiz "Error: No free memory chunks available. \n"
    noUsedSlots: .asciiz "Error: No used slots in symbol table \n"
    noFreeSlots: .asciiz "Error: No free slots in symbol table \n"
    nameUsed: .asciiz "Error: Variable name already in use \n"
    sizePrompt: .asciiz "Enter size (bytes to allocate): "
    newLine: .asciiz "\n"

.text

main: 
    la $t2, chunkArray  # load address of the chunkArray into $t2
    li $t0, 0   # make sure $t0 is initilized at 0. Chunk Array Counter
    li $t6, 0   # consecutive free chunks counter, initilize to zero
    li $s1, 0

init_chunk_array_loop:
    bge $s1, 64, prompt # if counter has reached 64, go to malloc
    add $a3, $t2, $s1   # store chunkArray[$t0] in $a3
    sb $zero, 0($a3)    # change chunkArray[$t0] to 0
    addi $s1, $s1, 1    # iterate the counter
    j init_chunk_array_loop

prompt:
    li $v0, 4
    la $a0, newLine
    syscall
    
    # Prompt user if malloc or dealloc
    li $v0, 4
    la $a0, operationMsg
    syscall

    # read from user
    li $v0, 5
    syscall
    move $s2, $v0

    beq $s2, 1, malloc
    beq $s2, 2, free

    li $v0, 4
    la $a0, flagErr
    syscall

    j prompt

malloc: 
    # Procedure handling memory allocation
    # Read user input -> Check Symbol Table -> Find available chunks -> write chunks
    # $t0 is where the chunk index is located

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

    move $s6, $a0

    # check if variable is in symbol table

    la $s0, symbolTable
    li $s2, 0

check_used_slot: 
    li $t7, 0   # init char index to 0
    li $s3, 25  # number of bytes in an entry
    li $t8, 10  # number of entries
    li $s7, 1 # for checking validity bit 1
    mul $s4, $s2, $s3   # offset = index * number of bytes in an entry
    add $s5, $s0, $s4   # $s5 contains symbolTable[$s4]
    lb $s4, 0($s5)  # load the validity bit into $s6
    beq $s4, $s7, check_name_loop   # if validity bit is 1, go to read name loop
    addi $s2, $s2, 1 # iterate symbolTable index
    blt $s2, $t8, check_used_slot
    j name_not_found

check_name_loop:
    lb $t1, 0($s6)  # store first bit of userInput in $t1
    addi $a3, $t7, 1    # read index with offset 1 (for validity bit)
    add $t9, $s5, $a3  # symbol table index + copy index with offset
    lb $t3, 0($t9)  # load char from symbol table into $t3
    bne $t1, $t3, check_next_slot  # check if char in userInput is the same as char in symbol table. If not equal, go back to find_used_slot
    beqz $t1, name_found  # if null char found, go to remove entry
    addi $s6, $s6, 1    # iterate to next char
    addi $t7, $t7, 1    # iterate copy Index
    j check_name_loop 

check_next_slot:
    addi $s2, $s2, 1
    blt $s2, $t8, check_used_slot

name_found:
    li $v0, 4
    la $a0, nameUsed
    syscall
    j prompt

name_not_found:
    # prompt user for allocation size
    li $v0, 4
    la $a0, sizePrompt
    syscall

    # read integer from user
    li $v0, 5
    syscall
    move $t1, $v0   # $t1 now holds bytes to allocate

    li $t0, 0   # this will be the chunk index as it is allocated
    li $t4, 64 # total number of chunks to allocate
    
    # calculate number of chunks to allocate
    li   $t8, 32         # chunk size
    move $t3, $t1        # copy requested size to $t2
    addi $t3, $t3, 31    # add chunk_size - 1 to round up
    divu $t3, $t8        # unsigned division (avoid negatives)
    mflo $t9             # get number of chunks

malloc_loop:
    bge $t0, $t4, malloc_fail # if loop gets through all chunks ($t0 >= 64), no free memory (jump to malloc_fail)
    add $a3, $t2, $t0
    lb $t3, 0($a3)    # load chunkArray[$t0] into $t3
    beqz $t3, free_chunk  # if chunk is free (0) jump to free_chunk
    li $t6, 0   # reset consecutive free chunk counter
    addi $t0, $t0, 1   # increment the chunk index  
    j malloc_loop   # repeat until free chunk found or no chunks found

free_chunk: 
    beq $t6, 0, save_start # if this is the first free chunk we've found. Save the start of it
    addi $t6, $t6, 1    # increment consecutive chunk counter
    beq $t6, $t9, allocate_chunk
    addi $t0, $t0, 1    # increment loop counter
    j malloc_loop

save_start: 
    move $t7, $t0   # save the current chunk counter to $t7
    li $t6, 1       # increment consecutive chunk counter
    beq $t6, $t9, allocate_chunk    # if we only need 1 chunk allocated, go to allocate_chunk
    addi $t0, $t0, 1    # increment counter
    j malloc_loop

allocate_chunk:
    li $t5, 1   # Just load 1 into $t5
    # store 1 into chunkarray[$t0]
    # result: $t0 holds the allocated chunk index
    move $t0, $t7 # reset chunk counter at start of consecutive chunks
    li $t6, 0

allocate_loop:
    beq $t9, $t6, malloc_finish
    add $a3, $t2, $t0
    sb $t5, 0($a3)
    addi $t0, $t0, 1
    addi $t6, $t6, 1
    j allocate_loop

malloc_finish: 
    move $v1, $t0   # save end index
    la $a0, newLine
    li $v0, 4   
    syscall

    li $t0, 0          # Start at index 0
    la $s0, symbolTable # load address of symbolTable into $s0
    li $s2, 0   # initilize symbolTable index to 0
    j find_free_slot

malloc_fail:
    li $v0, 4
    la $a0, mallocFailMsg
    syscall

    la $a0, newLine
    li $v0, 4
    syscall

    li $t0, 0          # Start at index 0
    j prompt

find_free_slot: 
    li $s3, 25  # number of bytes in an entry
    li $t8, 10  # number of entries
    mul $s4, $s2, $s3   # offset = index * number of bytes in an entry
    add $s5, $s0, $s4   # $s5 contains symbolTable[$s4]
    lb $s6, 0($s5)  # load the validity bit into $s6
    beqz $s6, write_entry   # if validity bit is zero, go to write_entry (found empty slot)
    add $s2, $s2, 1 # iterate symbolTable index
    blt $s2, $t8, find_free_slot

    # no free slots found on symbol table
    li $v0, 4
    la $a0, noFreeSlots
    syscall
    j prompt

write_entry:
    li $t9, 1
    sb $t9, 0($s5)  # write the validity bit as 1
    la $a0, userInput   # store address of userInput
    li $t3, 0   # char index init at 0

copy_name_loop:
    lb $t1, 0($a0)  # store first bit of userInput in $t1
    addi $t4, $t3, 1    # copy index with offset 1 (for validity bit)
    add $t9, $s5, $t4  # symbol table index + copy index with offset
    sb $t1, 0($t9)  # store first byte of userInput into symbol table index 
    beqz $t1, store_chunks  # if null char found, move to storing chunks
    addi $a0, $a0, 1    # iterate to next char
    addi $t3, $t3, 1    # iterate copy Index
    j copy_name_loop    

store_chunks:
    # store from_chunk (byte 23 in symbol table line)
    addi $t8, $s5, 23
    sb $t7, 0($t8)

    # store to_chunk (byte 24 in symbol table line)
    addi $t8, $s5, 24
    addi $t4, $v1, -1 # to_chunk = last allocated indexf
    sb $t4, 0($t8)

    j print_chunk_array

# Print the chunk array after allocation
print_chunk_array:
    la $t2, chunkArray
    li $t0, 0   # reinitilize counter

print_chunk_array_loop:
    bge $t0, 64, print_chunk_array_done # Exit when we've printed all 64 chunks
    add $a3, $t2, $t0 # Address of chunkArray[$t0]
    lb $a1, 0($a3)    # Load the value of the chunk
    li $v0, 1         # Prepare to print the chunk value
    move $a0, $a1     # Move the chunk value to $a0
    syscall           # Print the chunk value
    addi $t0, $t0, 1  # Move to the next chunk
    j print_chunk_array_loop

print_chunk_array_done:
    li $t0, 0
    li $t6, 0
    li $s1, 0
    j prompt

free: 
    # Procedure for handling memory deallocation
    # Read user input -> Check Symbol table -> Remove from symbol table

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

    la $s0, symbolTable # load address of symbol table into $s0
    li $s2, 0   # init symbol table index to 0

find_used_slot: 
    li $t7, 0   # init char index to 0
    li $s3, 25  # number of bytes in an entry
    li $t8, 10  # number of entries
    li $s7, 1 # for checking validity bit 1
    mul $s4, $s2, $s3   # offset = index * number of bytes in an entry
    add $s5, $s0, $s4   # $s5 contains symbolTable[$s4]
    lb $s6, 0($s5)  # load the validity bit into $s6
    beq $s6, $s7, read_name_loop   # if validity bit is 1, go to read name loop
    addi $s2, $s2, 1 # iterate symbolTable index
    blt $s2, $t8, find_used_slot

    # no full slots, go to fail message
    li $v0, 4
    la $a0, noUsedSlots
    syscall
    j prompt

read_name_loop:
    lb $t1, 0($a0)  # store first bit of userInput in $t1
    addi $a3, $t7, 1    # read index with offset 1 (for validity bit)
    add $t9, $s5, $a3  # symbol table index + copy index with offset
    lb $t3, 0($t9)  # load char from symbol table into $t3
    bne $t1, $t3, next_slot    # check if char in userInput is the same as char in symbol table. If not equal, go back to find_used_slot
    beqz $t1, remove_entry  # if null char found, go to remove entry
    addi $a0, $a0, 1    # iterate to next char
    addi $t7, $t7, 1    # iterate copy Index
    j read_name_loop  

next_slot:
    addi $s2, $s2, 1
    blt $s2, $t8, find_used_slot
    li $v0, 4
    la $a0, noUsedSlots
    syscall
    j prompt


remove_entry:
    li $t9, 0
    sb $t9, 0($s5)  # write the validity bit as zero
    la $a0, userInput   # store address of userInput
    li $t7, 0   # char index init at 0

    # read from_chunk (byte 23 in symbol table line)
    addi $t8, $s5, 23
    lb $t4, 0($t8)  # store from_chunk into $t5

    # read to_chunk (byte 24 in symbol table line)
    addi $t8, $s5, 24
    lb $t5, 0($t8) # store to_chunk into $t5

    la $t2, chunkArray  # load address of chunk array into $t2

    # free chunks in the chunk array
    move $t0, $t4   # start at from_chunk

free_chunks_loop:
    bgt $t0, $t5, free_done # if all chunks have been freed exit the loop
    add $a3, $t2, $t0   # address of curent chunk
    sb $zero, 0($a3)    # change current chunk to 0
    addi $t0, $t0, 1    # iterate chunk counter
    j free_chunks_loop  

free_done:
    li $t0, 0 # reset counter for printing
    j print_chunk_array