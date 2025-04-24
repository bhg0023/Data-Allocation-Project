# Benjamin Goldberg
#
#
#
# Create the Chunk Availability Array and Malloc proc
#


.data
    variablePrompt: .asciiz "Enter variable name: "
    userInput: .space 22
    chunkArray: .space 64 # 64 bytes for chunk availability (0 is free, 1 is allocated)
    mallocFailMsg: .asciiz "Error: No free memory chunks available. \n"
    sizePrompt: .asciiz "Enter size (bytes to allocate): "
    newLine: .asciiz "\n"

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
    li $t4, 64 # total number of chunks to allocate

malloc: 
    # Procedure handling memory allocation
    # Read user input -> Check Symbol Table -> Find available chunks -> write chunks
    # $t0 is where the chunk index is located
    
    # calculate number of chunks to allocate
    li   $t8, 32         # chunk size
    move $t3, $t1        # copy requested size to $t2
    addi $t3, $t3, 31    # add chunk_size - 1 to round up
    divu $t3, $t8        # unsigned division (avoid negatives)
    mflo $t9             # get number of chunks

    la $t2, chunkArray  # load address of the chunkArray into $t2
    li $t0, 0   # make sure $t0 is initilized at 0. Chunk Array Counter
    li $t6, 0   # consecutive free chunks counter, initilize to zero
    li $s1, 0

init_chunk_array_loop:
    bge $s1, 64, malloc_loop # if counter has reached 64, go to malloc
    add $a3, $t2, $s1   # store chunkArray[$t0] in $a3
    sb $zero, 0($a3)    # change chunkArray[$t0] to 0
    addi $s1, $s1, 1    # iterate the counter
    j init_chunk_array_loop

malloc_loop:
    bge $t0, $t4, malloc_fail # if loop gets through all chunks ($t0 >= 64), no free memory (jump to malloc_fail)
    add $a3, $t2, $t0
    lb $t3, 0($a3)    # load chunkArray[$t0] into $t3
    beq $t3, $zero, free_chunk  # if chunk is free (0) jump to free_chunk
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
    move $a0, $t0
    li $v0, 1
    syscall

    la $a0, newLine
    li $v0, 4   
    syscall

    li $t0, 0          # Start at index 0
    j print_chunk_array
    # exit program
    # li $v0, 10
    # syscall

malloc_fail:
    li $v0, 4
    la $a0, mallocFailMsg
    syscall

    la $a0, newLine
    li $v0, 4
    syscall

    li $t0, 0          # Start at index 0
    j print_chunk_array
    # exit program
    # li $v0, 10
    # syscall

# Print the chunk array after allocation

print_chunk_array:
    bge $t0, 64, done # Exit when we've printed all 64 chunks
    add $a3, $t2, $t0 # Address of chunkArray[$t0]
    lb $a1, 0($a3)    # Load the value of the chunk
    li $v0, 1         # Prepare to print the chunk value
    move $a0, $a1     # Move the chunk value to $a0
    syscall           # Print the chunk value
    addi $t0, $t0, 1  # Move to the next chunk
    j print_chunk_array

done:
    # exit program
    li $v0, 10
    syscall
free: 
    # Procedure for handling memory deallocation
    # Read user input -> Check Symbol table -> Remove from symbol table