# CS 154 Winter 2019 lab 2
# Author: Eric Shen 3966363

.data
	A: .float 100000000000000000000000000000000000000.0
    B: .float 50000000000000000000000000000000000000.0
    C: .float 1.0

.text
main:

	# load the first float into $a0
	la $t0, A
    lw $a0, 0($t0)

	# load the second float into $a1
    la $t0, B
	lw $a1, 0($t0)
	 
	jal MYADD	# jump to MYADD

    move $a0, $v0

    # store the sum to C
    la $t0, C
    sw $v0, 0($t0)

	# exit the program
	li $v0, 10	# loading 10 into $v0
	syscall 	# calling syscall to exit

MYADD:
	# this function will take in two single precision 32 bit float values in $a0 and $a1
    # it will output the sum of these float values and output it in $v0
	
    # save the values of the $s registers, $s0 will store rs for $a0 and $s1 will store rs for $a1
	addi $sp, $sp, -8
	sw $s1, 4($sp)
	sw $s0, 0($sp)

    # initialize s registers to 0
    li $s0, 0
    li $s1, 0

    # extract sign, exponent and mantissa from $a0 and $a1
    # use $t0, $t1, $t2 for $a0 and use $t3, $t4, $t5 for $a1

    # copy $a0 and $a1 to $t0, $t3
    and $t0, $a0, 0xFFFFFFFF
    and $t3, $a1, 0xFFFFFFFF


    # extract the mantissa
    and $t2, $t0, 0x007FFFFF
    and $t5, $t3, 0x007FFFFF    

    # shift the values of $t0, $t3
    srl $t0, $t0, 23 
    srl $t3, $t3, 23

    # extract the exponenent components
    and $t1, $t0, 0x000000FF
    and $t4, $t3, 0x000000FF

    # check for zero cases
    beq $t1, $zero, zeros
    beq $t4, $zero, zeros

    # add the hidden 1 bit to the mantissa
    or $t2, $t2, 0x00800000
    or $t5, $t5, 0x00800000

    # shift $t0 and $t3 again, now what is left is the sign bits
    srl $t0, $t0, 8 
    srl $t3, $t3, 8



    # compare the exponents and proceed to the appropriate loop

    # check if the two exponents are already equal if they are no need to loop
    beq $t1, $t4, exit_loop
    # check if the exponent of $a0 is smaller than that of $a1
    slt $t6, $t4, $t1
    beq $t6, $zero, loop_a1_larger

# loop to shift fraction to left if necessary
loop_a0_larger:
    beq $t1, $t4, exit_loop
    
    # load the r and s bits
    and $t7, $t5, 1
    sll $t7, $t7, 1
    and $t6, $s1, 2
    srl $t6, $t6, 1
    or $s1, $t6, $s1
    or $s1, $s1, $t7

    # shift the fraction of $a1
    srl $t5, $t5, 1
    # increment the exponent
    addi $t4, $t4, 1

    j loop_a0_larger
loop_a1_larger:
    beq $t1, $t4, exit_loop

    # load the r and s bits
    and $t7, $t2, 1
    sll $t7, $t7, 1
    and $t6, $s0, 2
    srl $t6, $t6, 1
    or $s0, $t6, $s0
    or $s0, $s0, $t7

    # shift the fraction of $a0
    srl $t2, $t2, 1
    # increment the exponent
    addi $t1, $t1, 1

    j loop_a1_larger
exit_loop:
    # exponents now match add the mantissas
    # add the rs bits to the end of the mantissas make them 26 bits
    sll $t2, $t2, 2
    sll $t5, $t5, 2
    add $t2, $t2, $s0
    add $t5, $t5, $s1

    # check if signs are equal
    bne $t0, $t3, difference
    add $t6, $t2, $t5
    sll $t0, $t0, 31
    j normalization

difference:
    bne $t0, $zero, sub_first_elem
    # the second element is negative so perform $a0 - $a1

    # convert to 2s compliment
    nor $t5, $t5, 0
    addi $t5, $t5, 1 

    # add the 2s compliment numbers
    add $t6, $t5, $t2

    # get sign bit and check if sign bit is neg
    and $t0, $t6, 0x80000000
    beq $t0, $zero, normalization

    # if negative convert back to pos
    nor $t6, $t6, 0
    addi $t6, $t6, 1 
    j normalization
sub_first_elem:
    # the first element is negative so perform $a1-$a0
    # perform 2s compliment on the negative number 
    nor $t2, $t2, 0
    addi $t2, $t2, 1 

    # add the 2s compliment numbers
    add $t6, $t5, $t2

    # get the sign bit and check if neg
    and $t0, $t6, 0x80000000
    beq $t0, $zero, normalization

    # if negative convert back to pos
    nor $t6, $t6, 0
    addi $t6, $t6, 1 

normalization:
    # normalize the result 
    # get the r and s bits into $s0 and restore $t6 to a 24 bit 
    and $s0, $t6, 3
    srl $t6, $t6, 2

    and $t2, $t6, 0xFF00000
    blt $t6, 0x00800000, normalization_loop_decrease
    beq $t2, $zero, norm_loop_exit

normalization_loop_increase:
    # increase the exponent if the mantissa is too big
    # check if we can exit
    li $t7, 0x01000000
    blt $t6, $t7, norm_loop_exit


    # load the r and s bits
    and $t7, $t6, 1
    sll $t7, $t7, 1
    addi $t7, $t7, 1
    and $t3, $t6, 2
    srl $t3, $t3, 1
    or $s0, $t3, $s0
    and $s0, $s0, $t7

    # shift sum of fraction 
    srl $t6, $t6, 1

    # increase the exponent, let the final exponent be $t1
    li $t7, 0x000000FF
    addi $t1, $t1, 1
    beq $t1, $t7, overflow

    j normalization_loop_increase

normalization_loop_decrease:
    # decreases the exponent if the mantissa is too small
    # check if we can exit
    li $t7, 0x00800000
    bge $t6, $t7, norm_loop_exit

    # shift sum of fraction 
    sll $t6, $t6, 1

    # load in the r bit
    and $t3, $s0, 2
    and $s0, $s0, 1
    srl $t3, $t3, 1
    add $t6, $t6, $t3

    # decrease the exponent, let the final exponent be $t1
    addi $t1, $t1, -1
    beq $t1, $zero, underflow
    j normalization_loop_decrease

norm_loop_exit:
    # add one to mantissa if needed (rounding)
    li $t8, 3
    bne $s0, $t8, after_rounding
    addi $t6 $t6, 1
    li $t8, 0x01000000
    blt $t6, $t8, after_rounding
    srl $t6, $t6, 1
    addi $t1, $t1, 1
    li $t7, 0x000000FF
    beq $t1, $t7, overflow

after_rounding:
    # hide the hidden 1, return fration to 23 bits
    and $t6, $t6, 0xFF7FFFFF
    # shift the componenets into the proper positions
    sll $t1, $t1, 23 
    # put components back together, exponent is in $t1, mantissa is $t6, sign is $t0
    or $v0, $t1, $t6
    or $v0, $v0, $t0

    # restore s registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8

    # round
    li $s1, 3
    bne $s0, $s1, exit

    
exit:
	jr $ra 	# return to main

zeros:
    li $t0, 0
    beq $t1, $t4, underflow
    beq $t1, $zero, first_arg_zero

    move $v0, $a0
    jr $ra

first_arg_zero:
    move $v0, $a1
    jr $ra

overflow:
    li $v0, 0x7F800000
    or $v0, $v0, $t0

    # restore s registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8

    jr $ra
underflow:
    li $v0, 0
    or $v0, $v0, $t0

    # restore s registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
    
    jr $ra