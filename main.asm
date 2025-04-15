# Benjamin Goldberg
#
#
#
# Create the Chunk Availability Array
#


.data

.text

main: 
    # save the original stack pointer in $s0
    move $s0, $sp
    li $t0, 0   # this will be the chunk index as it is allocated
    li $t1, 128 # total number of chunks to allocate

allocate_chunk_array:
    beq $t0, t1, exit

    addi $sp, $sp, -32 