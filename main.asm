# Program #8: Calculator
# Author: Lazlo F. Steele
# Due Date : Oct. 26, 2024 Course: CSC2025-2H1
# Created: Oct. 26, 2024
# Last Modified: Oct. 26, 2024
# Functional Description: Given a 16-bit numeric value provided by the user allow basic arithmetic operations
# Language/Architecture: MIPS 32 Assembly
####################################################################################################
# Algorithmic Description:
#	welcome user
#	get two string inputs from user
#	for each input
#		if input[0] = '-'
#			raise flag for negative
#		for each character in input:
#			if numeric:
#				multiply register value by 10
#				store in smallest digit in register
#			else:
#				invalid, try again
#		if negative flag true:
#			subtract the value of the register from zero and store in saved register
#		ensure value is not overflowing 16 bits
#		store value
#	seek user input for operation mode
#		if 1:
#			add the two integers
#		if 2:
#			subtract
#		if 3:
#			multiply (will not exceed the 32 bit LO register
#		if 4:
#			if divide by 0:
#				no you can't, try again
#			divide
#			store remainder
#		if 5:
#			exit program
#		else:
#			invalid input, try again
#	print formated output to show equation and result!
#	go again!
####################################################################################################
	.data
welcome_msg: 	.asciiz "\nGreetings. I am Calcutron. I will calculate."
decimal_prmpt:	.asciiz "\nPlease enter an integer between -32768 and 32767 > "
mode_msg:		.asciiz "	[1] Addition\n	[2] Subtraction\n	[3] Multiplication\n	[4] Division\n	[5] Exit"
mode_prmpt:		.asciiz "\nPlease select an option from the list above > "
repeat_msg: 	.asciiz "\nGo again? Y/N > "
invalid_msg: 	.asciiz "\nInvalid input. Try again!\n"
div_zero_err: 	.asciiz "\nCannot divide by 0. Try again!\n"
bye: 			.asciiz "\nToodles! ;)"
plus:			.asciiz " + "
minus:			.asciiz " - "
mult_by:		.asciiz " * "
div_by:			.asciiz " / "
equals:			.asciiz " = "
remainder:		.asciiz " r "
space: 			.ascii	" "
newline: 		.asciiz "\n"
				.align	2
min_signed:		.word	-32768
max_signed:		.word	32767
				.align	2
buffer:			.space	7
	.globl main
	
	.text
####################################################################################################
# function: main
# purpose: to control program flow
# registers used:
#	$s1 - operand 2
#	$s2 - operand 1
####################################################################################################
main:					#
	jal welcome			# welcome user
						#
	jal get_int			# get the first operand
						#
    move $s2, $s1		# move integer to $s2 to make room for second operand
	jal get_int			# get second operand
						#
	jal get_mode		# get operator or exit
						#
	jal print_result	# show result
						#
	j main				# go again!
						#
####################################################################################################
# function: get_int
# purpose: to receive, check, and convert user input string into signed 16 bit integer
# registers used:
#	$v0 - syscall codes
#	$a0 - arguments (addresses of buffers & messages)
#	$a1 - arguments (buffer lengths)
#	$s0 - storage of $ra
#	$s1 - operand
#	$t0 - working storage of the integer to be used as operand
#	$t1 - negative integer flag (0 = positive, 1 = negative)
#	$t2 - buffer address
#	$t3 - working character of buffer
#	$t4 - '-' for checking negative, minimum signed 16 bit integer value
#	$t5 - maximum signed 16 bit integer value
#	$zero - constant 0
#	$ra - return address
####################################################################################################
get_int:									#
	move $s0, $ra							# save return address for nesting
	la $a0, buffer							# load buffer address for clearing value
	li $a1, 7								# load buffer length
	jal reset_buffer						# reset buffer
	move $ra, $s0							# move return address back from saved value
											#
	la $a0, decimal_prmpt					# load prompt
	li $v0 4								# prepare to print string
	syscall									# print!
											#
	la $a0, buffer							# load buffer address
	li $a1, 7								# load 
	li $v0, 8								# prepare to read string
	syscall									# read!
											#
	li $t0, 0               	        	# $t0 will hold the final integer value
	li $t1, 0								# $t1 is a flag for sign (0 = positive, 1 = negative)
	la $t2, buffer							# $t2 points to the current character in buffer
	li $t4, '-'								# to check for negative
											#
	lb $t3, 0($t2)							# load the first character
	beq $t3, $t4, check_negative			# if it's '-', set negative flag
	j process_digits						# if no sign, process digits directly
											#
	check_negative:							#
		li $t1, 1							# set negative flag
		addi $t2, $t2, 1					# move to next character
		j process_digits					#
											#
	process_digits:							#
		lb $t3, 0($t2)                  	# load the next character
		beq $t3, 10, finalize_conversion	# end of string (null terminator)
		blt $t3, '0', invalid_integer		# if character is not a digit, go to error
		bgt $t3, '9', invalid_integer		# if character is not a digit, go to error
											#
		sub $t3, $t3, '0'					# $t3 = character - '0' to get integer value
		mul $t0, $t0, 10					# shift existing number left by one decimal place
		add $t0, $t0, $t3					# add the new digit to the result
											#
		addi $t2, $t2, 1					# move to next character
		j process_digits					#
											#
	finalize_conversion:					#
		beq $t1, 1, make_negative			# if flag raised, go to make_negative
		j check_overflow					# check if it's an overflow
											#
	make_negative:							#
		sub $t0, $zero, $t0					# negate $t0
											#
	check_overflow:							#
		lw $t4, min_signed					# minimum 16-bit signed integer value
		lw $t5, max_signed					# maximum 16-bit signed integer value
		blt $t0, $t4, invalid_integer		# check if result is too low
		bgt $t0, $t5, invalid_integer		# check if result is too high
											#
	move $s1, $t0							# store the final integer in $s1
	jr $ra									# return to caller
											#
	invalid_integer:						#
		la $a0, invalid_msg					#
		li $v0, 4							#
		syscall								#
											#
		j get_int							#
											#
####################################################################################################
# function: get_mode
# purpose: to control which operation is performed on the operands
# registers used:
#	$v0 - syscall codes
#	$a0 - arguments (addresses of messages)
#	$a1 - input length limit
#	$s1 - operand 2
#	$s2 - operand 1
#	$s3 - operator character
#	$s4 - result of equation
#	$s5 - remainder (if exists)
#	$t0 - stack pointer
#	$t1 - working storage for result
#	$t2 - remainder of division operation (initialized to 0 and used as a pseudoflag)
#	$sp - stack pointer
#	$ra - return address
####################################################################################################
get_mode:							#
	la $a0, mode_msg				# message to display options
	li $v0, 4						#
	syscall							#
									#
	la $a0, mode_prmpt				# prompt user
	li $v0, 4						#
	syscall							#
									#
	addi $sp, $sp, -2				# reserve 2 bytes
	li $t2, 0						# initialize division flag to false
									#
	move $a0, $sp					# point the input to the stack
	li $a1, 2						#
	li $v0, 8						# prepare to read string
	syscall							#
									#
	lb $t0, 0($sp)					# grab user input from stack
	beq $t0, 49, addition			# check user input and go to the relevant option
	beq $t0, 50, subtraction		#
	beq $t0, 51, multiplication		#
	beq $t0, 52, division			# 
	beq $t0, 53, end				#
									#
	error:							#
		la $a0, invalid_msg			# if not one of the listed options show error message
		li $v0, 4					#
		syscall						#
		j get_mode					# and try again!
	addition:						#
		add $t1, $s2, $s1			# add the values
		la $s3, plus				# load the operator character
		j calc_end					# and return
	subtraction:					#
		sub $t1, $s2, $s1			# same but with subtraction
		la $s3, minus				#
		j calc_end					#
	multiplication:					# same but with multiplication
		mult $s2, $s1				#
		mflo $t1					#
		la $s3, mult_by				#
		j calc_end					#
	division:						#
		beqz $s1, invalid_div		# if dividing by 0, don't
		div $s2, $s1				# divide the values
		mflo $t1					# store the quotient
		mfhi $t2					# store the remainder
		la $s3, div_by				# load the operator character
		j calc_end					# and return
		invalid_div:				#
			la $a0, div_zero_err	# don't divide by zero plz
			li $v0, 4				#
			syscall					#
			j get_mode				# if you did, pick a different operation
	calc_end:						#
		addi $sp, $sp, 2			# deallocate memory
		beqz $t2, store_result		# if no remainder then skip
		move $s5, $t2				# store the remainder in an caller saved register
		store_result:				#
			move $s4, $t1			# store the result of the equation in a caller saved register
		jr $ra						# return to caller
									#
####################################################################################################
# function: print_result
# purpose: to print a formatted output
# registers used:
#	$v0 - syscall codes
#	$a0 - arguments (addresses of messages, and integer values)
#	$s1 - operand 2
#	$s2 - operand 1
#	$s3 - operator character
#	$s4 - result of equation
#	$s5 - remainder (if exists)
#	$ra - return address
####################################################################################################							
print_result:			#
	la $a0, newline		# ensure the result is printed on a new line
	li $v0, 4			#
	syscall				#
						#
	move $a0, $s2		# print the first operand
	li $v0, 1			#
	syscall				#
						#
	li $s2, 0			# reinitialize the register for the next run
						#
	move $a0, $s3		# print the operator character
	li $v0, 4			#
	syscall				#
						#
	li $s3, 0			# reinitialize the register for the next run
						#
	move $a0, $s1		# print the second operand
	li $v0, 1			#
	syscall				#
						#
	li $s1, 0			# reinitialize the register for the next run
						#
	la $a0, equals		# print the equals sign character
	li $v0, 4			#
	syscall				#
						#	
	move $a0, $s4		# print the result of the equation
	li $v0, 1			#
	syscall				#
						#
	li $s4, 0			# reinitialize the register for the next run
						#	
	beqz $s5, done		# if no remainder then done
						#
	la $a0, remainder	# otherwise print " r "
	li $v0, 4			#
	syscall				#
						#
	move $a0, $s5		# and the remainder value
	li $v0, 1			#
	syscall				#
						#
	li $s5, 0			# reinitialize the register for the next run
						#
	done:				#
		jr $ra			# return to caller
####################################################################################################
# HELPER LAND!:
#	the following subroutines are helpers that keep some semblence of clean well scoped code in the
#	program specific tasks above.
####################################################################################################

####################################################################################################
# function: welcome
# purpose: to welcome the user to the program
# registers used:
#	$v0 - syscall codes
#	$a0 - message addresses
#	$ra - return address
####################################################################################################
welcome:					#
	la $a0, welcome_msg		# print the welcome message
	li $v0 4				#
	syscall					#
							# 
	jr $ra					# return to caller
####################################################################################################
# function: reset_buffer
# purpose: to reset the buffer for stability and security
# registers used:
#	$a0 - buffer address
#	$a1 - buffer length
#	$t2 - reset value (0)
#	$t3 - iterator
####################################################################################################	
reset_buffer:								#
	li $t2, 0								# to reset values in buffer
	li $t3, 0								# initialize iterator
	reset_buffer_loop:						#
		bge $t3, $a1, reset_buffer_return	#
		sw $t2, 0($a0)						# store a 0
		addi $a0, $a0, 4					# next word in buffer
		addi $t3, $t3, 1					# iterate it!
		j reset_buffer_loop 				# and loop!
	reset_buffer_return:					#
		jr $ra								#
####################################################################################################
# function: end
# purpose: to eloquently terminate the program
# registers used:
#	$v0 - syscall codes
#	$a0 - message address
####################################################################################################	
end: 					#
	la $a0, bye			#
	li $v0 4			# prepare to print string
	syscall				#	
						# print!
	li $v0, 10			# system call code for returning control to system
	syscall				# GOODBYE!
####################################################################################################
