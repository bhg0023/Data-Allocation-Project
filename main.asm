# Julian Buendia
# April 11, 2025
# 
# The following code creates the symbol table for dynamic memory allocation

.data
    prompt: .asciiz "Enter variable name: "
    userInput: .space 22
.text
    main:
        # Prompt user to enter variable name
        li $v0, 4
        la $a0, prompt
        syscall

        # Store variable name
        li $v0, 8 # prepare to read string
        la $a0, userInput # load userInput variable address onto register
        li $a1, 22 # max characters = 22
        syscall

        li $v0, 4
        la $a0, userInput
        syscall

        # exit program
        li $v0, 10
        syscall