#    pause:         pause in hundredths of second (busy looping)
#    putChar_atXY:  puts a character (X, Y) on screen
#    getChar_atXY:  reads the character from (X, Y) on screen
#    get_key:       reads keyboard and returns a match index from scancode arr
#    get_key2:      same as get_key but looks up a second array of scancodes (for player 2)
#    pause_and_getkey:  RESPONSIVE keyboard read + pause combined
#    pause_and_getkey_2player:  RESPONSIVE keyboard read + pause combined for 2 players
#    get_accel:     always returns 0 tilt value (i.e., 0x00FF00FF)
#    get_accelX:    always returns 0 X tilt value (i.e., 0x00FF)
#    get_accelY:    always returns 0 Y tilt value (i.e., 0x00FF)
#    put_sound:     sets the sound generator to a specified tone
#    sound_off:     dummy procedure; sound turns off on its own
#    put_leds:      dummy procedure



.text	
		
	#########################################
	# pause(N), N is hundredths of a second #
	# assuming 12.5 MHz clock.              #
	# N is placed in $a0.                   #
	#########################################

.globl pause
pause:
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$a0, 4($sp)
	sw	$v0, 0($sp)
	mul     $a0, $a0, 10		# $a0*10 (milliseconds)
	li	$v0, 32
	syscall				# sleep for $a0 milliseconds
		
	lw	$ra, 8($sp)
	lw	$a0, 4($sp)
	lw	$v0, 0($sp)
	addi	$sp, $sp, 12
	jr	$ra



	#####################################
	# proc check_display_counds         #
	# helper for put/getChar_atXY       #
	#                                   #
	#   $a0:  char                      #
	#   $a1:  x (col)                   #
	#   $a2:  y (row)                   #
	#                                   #
	# leaves $a0 unchanged              #
	# checks x is in [0..39]            #
	# checks y is in [0..29]            #
	# if x or y are out of bounds, pops #
	#   a dialog box and snaps them to  #
	#   closest boundary                #
	#                                   #
	# restores all other registers      #
	#   before returning                #
	#####################################
	

.data
__bounds_err_col: .asciiz "putChar_atXY called with out of bounds col = "
__bounds_err_row: .asciiz "putChar_atXY called with out of bounds row = "

.text
check_display_bounds:
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$a0, 8($sp)
	sw	$a1, 4($sp)
	sw	$a2, 0($sp)

__check_x_0:
	slt	$1, $a1, $0		# make sure X >= 0
	beq	$1, $0, __check_x_40
	# print error dialog
	li  $v0, 56
	sw	$a0, 8($sp)		# save $a0
	la  $a0, __bounds_err_col
	# move $a1, $a1
	syscall
	lw	$a0, 8($sp)		# restore $a0
	li	$a1, 0			# set X to 0
	j   __check_y_0
__check_x_40:
	slti $1, $a1, 40		# make sure X < 40
	bne	$1, $0, __check_y_0
	# print error dialog
	li  $v0, 56
	sw	$a0, 8($sp)		# save $a0
	la  $a0, __bounds_err_col
	# move $a1, $a1
	syscall
	lw	$a0, 8($sp)		# restore $a0
	li	$a1, 39			# set X to 39
__check_y_0:
	slt	$1, $a2, $0		# make sure Y >= 0
	beq	$1, $0, __check_y_30
	# print error dialog
	li  $v0, 56
	sw	$a0, 8($sp)		# save $a0
	sw	$a1, 4($sp)		# save $a1
	la  $a0, __bounds_err_row
	move $a1, $a2
	syscall
	lw	$a0, 8($sp)		# restore $a0
	lw	$a1, 4($sp)		# restore $a1
	li	$a2, 0			# else, set Y to 0
	j   __done_checking
__check_y_30:
	slti $1, $a2, 30		# make sure Y < 30
	bne	$1, $0, __done_checking
	# print error dialog
	li  $v0, 56
	sw	$a0, 8($sp)		# save $a0
	sw	$a1, 4($sp)		# save $a1
	la  $a0, __bounds_err_row
	move $a1, $a2
	syscall
	lw	$a0, 8($sp)		# restore $a0
	lw	$a1, 4($sp)		# restore $a1
	li	$a2, 29			# else, set Y to 29
__done_checking:


	lw	$ra, 12($sp)
	lw	$a0, 8($sp)
	lw	$a1, 4($sp)
	lw	$a2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra




	#####################################
	# proc putChar_atXY                 #
	# write one char to (x,y) on screen #
	#                                   #
	#   $a0:  char                      #
	#   $a1:  x (col)                   #
	#   $a2:  y (row)                   #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################


.eqv screen_ctl 0xFFFF0008 		# Control register in MARS for MMIO display tool
.eqv screen_transmit_data 0xFFFF000C 	# Data to transmit

.text
.globl putChar_atXY
putChar_atXY:	
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)

	jal check_display_bounds
	
	li	$t1, 1
	sw	$t1, screen_ctl($0)	# makes the transmit data register ready to send to display	
	sll	$t1, $a1, 20		# X goes in bit positions 20-31
	sll	$t2, $a2, 8		# Y goes in bit positions 8-19
	or	$t0, $t1, $t2		# OR these together
	ori	$t0, $t0, 7		# ASCII code 7 is for positioning
	sw	$t0, screen_transmit_data($0)
					# position cursor at (X, Y)
					 
	li	$t1, 1
	sw	$t1, screen_ctl($0)	# makes the transmit data register ready to send to display	
	addi 	$t0, $a0, '0'		# convert character code 0 to letter '0', etc.
	sw	$t0, screen_transmit_data($0)					# write at cursor location
	li	$t1, 1
	sw	$t1, screen_ctl($0)	# makes the transmit data register ready to send to display	
	
	
	la	$t0, smem    	# initialize to start address of screen memory's shadow copy
	
	sll	$t1, $a2, 5		# t1 = a2 << 5
	sll	$t2, $a2, 3		# t2 = a2 << 3
	add	$t1, $t1, $t2		# t1 = (a2 << 5) + (a2 << 3) = 40*row
	add	$t1, $t1, $a1		# t1 = 40*row + col
	sll	$t1, $t1, 2		# (40*row + col) * 4 for memory addressing
	add	$t0, $t0, $t1		# add offset to screen base address
	
	sw 	$a0, 0($t0) 		# store character in the shadow copy of screen memory
	
		
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc getChar_atXY                 #
	# read char from (x,y) on screen    #
	#                                   #
	#   $v0:  char read                 #
	#   $a1:  x (col)                   #
	#   $a2:  y (row)                   #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
getChar_atXY:	
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)
	
	jal check_display_bounds

	la	$t0, smem 	# initialize to start address of screen:  0x10020000
	
	sll	$t1, $a2, 5		# t1 = a2 << 5
	sll	$t2, $a2, 3		# t2 = a2 << 3
	add	$t1, $t1, $t2		# t1 = (a2 << 5) + (a2 << 3) = 40*row
	add	$t1, $t1, $a1		# t1 = 40*row + col
	sll	$t1, $t1, 2		# (40*row + col) * 4 for memory addressing
	add	$t0, $t0, $t1		# add offset to screen base address
	
	lw 	$v0, 0($t0) 		# read character from screen
	
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc get_key                      #
	# gets a key from the keyboard      #
	# returns:                                  #
	#   $v0= 0 if no valid key          #
	#      = index 1 to N if valid key  #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
.data
# key_array:	.word	'a', 'd', 'w', 's'
key_array: .word  'w', 's', ']'
key_array_end:

.eqv keyb_ctl 0xFFFF0000 		# Control register in MARS for MMIO display tool
.eqv keyb_receive_data 0xFFFF0004 	# Data to transmit

.text
.globl get_key
get_key:
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)

	lw	$v0, keyb_ctl($0)
	beq	$v0, $0, get_key_exit	# return 0 if no key available
	lw	$t1, keyb_receive_data($0)
	
	li	$v0, 0
	la  $t0, key_array
	la  $t2, key_array_end
	sub $t2, $t2, $t0

get_key_loop:				# iterate through key_array to find match
	lw	$t0, key_array($v0)
	addi	$v0, $v0, 4		# go to next array element
	beq	$t0, $t1, get_key_exit
	blt	$v0, $t2, get_key_loop
	li	$v0, 0			# key not found in key_array
	
get_key_exit:
	srl	$v0, $v0, 2		# index of key found = offset div by 4
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc get_key2                     #
	# gets a key from the kayboard      #
	#                                   #
	#   $v0: 0 if no valid key          #
	#      : index 1 to N if valid key  #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
.data
key_array2:	.word	'j', 'l', 'i', 'k'
key_array_end2:     # marks end of key array, so number of keys can be calculated

.text
.globl get_key2
get_key2:
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)

	lw	$v0, keyb_ctl($0)
	beq	$v0, $0, get_key_exit2	# return 0 if no key available
	lw	$t1, keyb_receive_data($0)
	
	li	$v0, 0
	la  $t0, key_array2
	la  $t2, key_array_end2
	sub $t2, $t2, $t0

get_key_loop2:				# iterate through key_array to find match
	lw	$t0, key_array2($v0)
	addi	$v0, $v0, 4		# go to next array element
	beq	$t0, $t1, get_key_exit2
	slt	$1, $v0, $t2
	bne	$1, $0, get_key_loop2
	li	$v0, 0			# key not found in key_array
	
get_key_exit2:
	srl	$v0, $v0, 2		# index of key found = offset div by 4
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra

	#########################################
	# pause_and_getkey(N),                  #
	# N is hundredths of a second           #
	# assuming 12.5 MHz clock.              #
	# N is placed in $a0.                   #
	#                                       #
	#   $v0: value returned by get_key      #
	#                                       #
	#   This is not an exact emulation of   #
	#   the same function defined for       #
	#   Nexys board implementation.         #
	#   Instead of a RESPONSIVE key read    #
	#   during a pause, this function       #
	#   simply pauses and then reads a key  #
	#   afterward.                          #
	#########################################

pause_and_getkey:
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$a0, 4($sp)
	sw  $s0, 0($sp)	
	
	jal pause
	jal get_key
	
	lw	$s0, 0($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra


	#########################################
	# pause_and_getkey_2player(N),          #
	# N is hundredths of a second           #
	# assuming 12.5 MHz clock.              #
	# N is placed in $a0.                   #
	# Returns 2 key values (for 2 players)  #
	#                                       #
	#   $v0: value returned by get_key      #
	#     if key != 0 at any time           #
    #     during the pause, the latest      #
    #     non-zero key value is returned;   #
    #     else, 0 is returned.              #
	#                                       #
	#   $v1: value returned by get_key2     #
	#     if key != 0 at any time           #
    #     during the pause, the latest      #
    #     non-zero key value is returned;   #
    #     else, 0 is returned.              #
	#########################################

pause_and_getkey_2player:
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$a0, 8($sp)
	sw  $s0, 4($sp)
	sw  $s1, 0($sp)
	li  $s0, 0
	li  $s1, 0

    jal pause
    
    lw	$v0, keyb_ctl($0)
	beq	$v0, $0, pgk2_done	# return 0 if no key available
	lw	$t1, keyb_receive_data($0)
	
	li	$v0, 0
	la  $t0, key_array
	la  $t2, key_array_end
	sub $t2, $t2, $t0

pgk2_key_loop:				# iterate through key_array to find match
	lw	$t0, key_array($v0)
	addi $v0, $v0, 4		# go to next array element
	beq	$t0, $t1, pgk2_key_loop_done
	slt	$1, $v0, $t2
	bne	$1, $0, pgk2_key_loop
	li	$v0, 0			# key not found in key_array
pgk2_key_loop_done:
	srl	$v0, $v0, 2		# index of key found = offset div by 4
	move $s0, $v0
    
	li	$v0, 0
	la  $t0, key_array2
	la  $t2, key_array_end2
	sub $t2, $t2, $t0

pgk2_key_loop2:				# iterate through key_array to find match
	lw	$t0, key_array2($v0)
	addi $v0, $v0, 4		# go to next array element
	beq	$t0, $t1, pgk2_key_loop_done2
	slt	$1, $v0, $t2
	bne	$1, $0, pgk2_key_loop2
	li	$v0, 0			# key not found in key_array
pgk2_key_loop_done2:
	srl	$v0, $v0, 2		# index of key found = offset div by 4
	move $s1, $v0
    
pgk2_done:
	move $v0, $s0
	move $v1, $s1
	
	lw	$s1, 0($sp)
	lw	$s0, 4($sp)
	lw	$a0, 8($sp)
	lw	$ra, 12($sp)
	addi	$sp, $sp, 16
	jr	$ra



	#####################################
	# proc get_accel                    #
	# gets value from accelerometer     #
	#                                   #
	#   Returns 0x00FF00FF in $v0       #
	#   These correspond to a perfectly #
	#   level accelerometer.            #
	#                                   #
	#####################################
	

.text
get_accel:
	li  $v0, 0x00FF00FF
	jr	$ra

get_accelX:
	li  $v0, 0x00FF
	jr	$ra

get_accelY:
	li  $v0, 0x00FF
	jr	$ra

	#####################################
	# proc put_sound                    #
	# generates a tone with a specified #
	#   period                          #
	#                                   #
	#                                   #
	#                                   #
	#####################################
	
.text
put_sound:
	addi $sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)
	sw  $a1, 8($sp)
	sw  $a2, 4($sp)
	sw  $a3, 0($sp)
	
	
	mul $a0, $a0, 12
	div $a0, $a0, 19000
	li  $v0, 84
	sub $a0, $v0, $a0
	
	li  $a1, 100
	li  $a2, 0
	li  $a3, 64
	li  $v0, 31
	syscall 
				
	lw	$a3, 0($sp)
	lw	$a2, 4($sp)
	lw	$a1, 8($sp)
	lw	$a0, 12($sp)
	lw	$ra, 16($sp)
	addi $sp, $sp, 20
	jr	$ra
	

# The procedure below does not do anything.  But it will help you compile
# a program that calls sound_off
#
sound_off:
	jr	$ra


	#####################################
	# proc put_leds                     #
	# lights up a pattern on the        #
	#   16 LEDs                         #
	#                                   #
	#   $a0: pattern (lower 16 bits)    #
	#                                   #
	#####################################

.text
# The procedure below does not do anything.  But it will help you compile
# a program that calls put_leds
#
put_leds:
	jr	$ra


.data 0x10012000                # Start "shadow" screen memory above data memory
smem: .space 4800