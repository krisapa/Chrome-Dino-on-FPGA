.data 0x10010000

.eqv W_KEY, 1
.eqv S_KEY, 2
.eqv RIGHT_BRACKET_KEY, 3

.eqv BACKGROUND, 0
.eqv BACKGROUND_RED, 1
.eqv DINO_TOP, 2
.eqv DINO_TOP_HIT, 3
.eqv DINO_BOTTOM_LEFT_FOOT_DOWN, 4
.eqv DINO_BOTTOM_RIGHT_FOOT_DOWN, 5
.eqv DINO_BOTTOM_NEUTRAL, 6
.eqv SHORT_CACTUS, 7
.eqv TALL_CACTUS_BOTTOM, 8
.eqv TALL_CACTUS_TOP, 9
.eqv BIRD, 10

.eqv SCREEN_HEIGHT, 30
.eqv SCREEN_WIDTH, 40
.eqv GAME_ROW, 14
.eqv PLAYER_COL, 5

.eqv MAX_OBSTACLES, 2
.eqv MIN_OBSTACLE_COOLDOWN, 52
.eqv MAX_OBSTACLE_COOLDOWN, 60

.eqv FRAME_DELAY, 40
.eqv GROUND_MOVE_DELAY, 40
.eqv MIN_GROUND_MOVE_DELAY, 16
.eqv BIRD_MOVE_DELAY, 35
.eqv MIN_BIRD_MOVE_DELAY, 15
.eqv SPEED_INCREASE_INTERVAL, 2000
.eqv GAME_OVER_SOUND, 1000000
.eqv SCORE_SOUND_INTERVAL, 15000
.eqv SCORE_SOUND_DELAY, 80

.eqv NUM_SCORE_SOUNDS, 3

.eqv time_mmio 0x1003001C


ground_sprites: .word 11, 12, 13, 14

jump_arr: .word -1, -1, -1, -1, 0, 0, 1, 1, 1, 1

score_sounds: .word 227273, 180180, 151515

obstacles: .space 24


current_ground_move_delay: .word GROUND_MOVE_DELAY
current_bird_move_delay: .word BIRD_MOVE_DELAY

num_obstacles: .word 0
obstacle_cooldown: .word MAX_OBSTACLE_COOLDOWN

player_row: .word GAME_ROW
new_player_row: .word GAME_ROW
is_ducking: .word 0
is_jumping: .word 0
jump_idx: .word 0
foot_state: .word 0

cheat: .word 0
lfsr: .word 0

.text 0x00400000
.globl main

# =============================================================
main:
    lui     $sp, 0x1001 
    ori     $sp, $sp, 0x1000      
    addi    $fp, $sp, -4    

    la      $t0, new_player_row
    li      $t1, GAME_ROW
    sw      $t1, 0($t0)
    li      $a0, 0
    jal     draw_player
    j       play_game
    
 
# =============================================================
get_current_time_ms:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    lw      $v0, time_mmio

    j return_from_proc
# =============================================================

# =============================================================
lfsr_rand: 
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4
    
    la      $t0, lfsr
    lw      $t1, 0($t0)
    
    srl     $t2, $t1, 31
    srl     $t3, $t1, 21       
    srl     $t4, $t1, 1    

    xor     $t6, $t2, $t3
    xor     $t6, $t6, $t4
    xor     $t6, $t6, $t1
    andi    $t6, $t6, 1
    sll     $t1, $t1, 1
    or      $t1, $t1, $t6
    sw      $t1, 0($t0)
    
    move    $v0, $t1

    j      return_from_proc
    
# =============================================================

# =============================================================
select_foot:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    la      $t0, is_jumping
    lw      $t1, 0($t0)

    beq     $t1, $zero, check_foot_state

    li      $v0, DINO_BOTTOM_NEUTRAL
    j       return_from_proc

check_foot_state:
    la      $t2, foot_state
    lw      $t3, 0($t2)

    beq     $t3, $zero, set_right_foot

    li      $v0, DINO_BOTTOM_LEFT_FOOT_DOWN
    j       toggle_foot_state

set_right_foot:
    li      $v0, DINO_BOTTOM_RIGHT_FOOT_DOWN
    j       toggle_foot_state

toggle_foot_state:
    xori   $t3, $t3, 1
    sw     $t3, 0($t2)
    j       return_from_proc

# =============================================================

# =============================================================
draw_player:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    beq     $a0, $zero, not_dead
    li      $t1, DINO_TOP_HIT
    j       set_top_sprite_done

not_dead:
    li      $t1, DINO_TOP

set_top_sprite_done:
    li      $a0, BACKGROUND
    li      $a1, PLAYER_COL
    la      $t2, player_row
    lw      $a2, 0($t2)
    jal     putChar_atXY

    li      $a0, BACKGROUND
    li      $a1, PLAYER_COL
    la      $t3, player_row
    lw      $a2, 0($t3)
    addi    $a2, $a2, -1
    jal     putChar_atXY

    la      $t4, is_ducking
    lw      $t5, 0($t4)
    beq     $t5, $zero, draw_top_sprite
    j       skip_draw_top_sprite

draw_top_sprite:
    move    $a0, $t1
    li      $a1, PLAYER_COL
    la      $t6, new_player_row
    lw      $a2, 0($t6)
    addi    $a2, $a2, -1
    jal     putChar_atXY

skip_draw_top_sprite:
    jal     select_foot
    move    $a0, $v0

    li      $a1, PLAYER_COL
    la      $t7, new_player_row
    lw      $a2, 0($t7)
    jal     putChar_atXY

    la      $t0, new_player_row
    lw      $t0, 0($t0)
    la      $t1, player_row
    sw      $t0, 0($t1)

    j      return_from_proc
# =============================================================

# =============================================================
handle_jump: 
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4


    li      $t1, W_KEY

    la      $t2, is_jumping
    lw      $t3, 0($t2)

    la      $t5, jump_idx    

    bne     $a0, $t1, check_is_jumping
    bne     $t3, $zero, check_is_jumping

    li      $t3, 1
    sw      $t3, 0($t2)

    sw      $zero, 0($t5)

check_is_jumping:
    beq     $t3, $zero, return_from_proc

    li      $t6, S_KEY
    bne     $a0, $t6, update_player_position

    li      $t3, 6
    la      $t5, jump_idx
    sw      $t3, 0($t5)

update_player_position:
    lw      $t3, 0($t5)

    la      $t0, jump_arr
    sll     $t4, $t3, 2
    add     $t0, $t0, $t4
    lw      $t0, 0($t0)

    la      $t1, new_player_row
    lw      $t4, 0($t1)
    add     $t4, $t4, $t0
    sw      $t4, 0($t1)

    addi    $t3, $t3, 1
    la      $t5, jump_idx    
    sw      $t3, 0($t5)

    li      $t0, GAME_ROW
    bne     $t4, $t0, return_from_proc

    sw      $zero, 0($t2)
    j       return_from_proc
# =============================================================

# =============================================================
handle_duck: 
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    la      $t0, is_jumping
    lw      $t0, 0($t0)
    la      $t1, is_ducking

    beq     $t0, $zero, check_key

    sw      $zero, 0($t1)
    j       return_from_proc

check_key:
    li      $t2, S_KEY
    bne     $a0, $t2, return_from_proc

    lw      $t2, 0($t1)
    bne     $t2, $zero, return_from_proc

    li      $t2, 1
    sw      $t2, 0($t1)
    j       return_from_proc
# =============================================================

# =============================================================
render_ground:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    li      $t1, SCREEN_WIDTH
    addi    $t1, $t1, -1

    li      $a2, GAME_ROW
    addi    $a2, $a2, 1

    li      $t0, 0
move_ground_loop_start:
    beq     $t0, $t1, move_ground_loop_end

    addi    $a1, $t0, 1
    jal     getChar_atXY
    move    $a0, $v0
    move    $a1, $t0
    jal     putChar_atXY

    addi    $t0, $t0, 1
    j       move_ground_loop_start

move_ground_loop_end:
    jal     lfsr_rand
    andi    $t0, $v0, 3

    la      $t2, ground_sprites
    sll     $t0, $t0, 2
    add     $t2, $t0, $t2
    lw      $a0, 0($t2)

    li      $t1, SCREEN_WIDTH
    addi    $t1, $t1, -1
    move    $a1, $t1
    jal     putChar_atXY
    j       return_from_proc
# =============================================================


# =============================================================
init_course_ground:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    li      $a2, GAME_ROW
    addi    $a2, $a2, 1

    li      $a1, 0
init_course_ground_loop:
    li      $t1, SCREEN_WIDTH
    beq     $a1, $t1, return_from_proc
    jal     lfsr_rand
    andi    $t3, $v0, 3

    sll     $t3, $t3, 2
    la      $t2, ground_sprites
    add     $t3, $t2, $t3
    lw      $a0, 0($t3)

    jal     putChar_atXY
    addi    $a1, $a1, 1

    j       init_course_ground_loop
# =============================================================

# =============================================================
draw_obstacle: 
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    la      $t0, obstacles
    sll     $t1, $a0, 2
    sll     $t2, $a0, 3
    add     $t1, $t1, $t2
    add     $t1, $t0, $t1

    lw      $a1, 0($t1)
    lw      $a2, 4($t1)
    lw      $a0, 8($t1)

    li      $t3, TALL_CACTUS_BOTTOM
    beq     $a0, $t3, draw_tall_cactus

    jal     putChar_atXY
    j       return_from_proc

draw_tall_cactus:
    jal     putChar_atXY

    li      $a0, TALL_CACTUS_TOP
    addi    $a2, $a2, -1
    jal     putChar_atXY
    j       return_from_proc
# =============================================================

# =============================================================
remove_obstacle:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    la      $t0, obstacles
    sll     $t1, $a0, 2
    sll     $t2, $a0, 3
    add     $t1, $t1, $t2
    add     $t1, $t0, $t1

    lw      $a1, 0($t1)
    lw      $a2, 4($t1)
    lw      $t3, 8($t1)

    li      $a0, BACKGROUND
    li      $t4, TALL_CACTUS_BOTTOM
    beq     $t3, $t4, remove_tall_cactus

    jal     putChar_atXY
    j       return_from_proc

remove_tall_cactus:
    jal     putChar_atXY

    addi    $a2, $a2, -1
    jal     putChar_atXY

    j       return_from_proc
# =============================================================

# =============================================================
remove_out_of_bounds_obstacle:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    la      $t0, num_obstacles
    lw      $t1, 0($t0)

    addi    $t2, $t1, -1

    la      $t3, obstacles
    sll     $t4, $t2, 2
    sll     $t2, $t2, 3
    add     $t2, $t4, $t2
    add     $t2, $t3, $t2

    lw      $t5, 0($t2)
    lw      $t6, 4($t2)
    lw      $t7, 8($t2)

    sll     $t2, $a0, 2
    sll     $t4, $a0, 3
    add     $t2, $t4, $t2
    add     $t2, $t3, $t2

    sw      $t5, 0($t2)
    sw      $t6, 4($t2)
    sw      $t7, 8($t2)

    addi    $t1, $t1, -1
    sw      $t1, 0($t0)
    
    j return_from_proc
# =============================================================

# =============================================================
move_obstacles:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    addi    $sp, $sp, -16
    sw      $s0, 12($sp)
    sw      $s1, 8($sp)
    sw      $s2, 4($sp)
    sw      $s3, 0($sp)

    move    $s1, $a0
    li      $s0, 0
move_obstacles_loop_start:
    la      $t0, num_obstacles
    lw      $t0, 0($t0)

    beq     $s0, $t0, move_obstacles_end

    la      $t1, obstacles
    sll     $t2, $s0, 2
    sll     $t3, $s0, 3
    add     $t2, $t2, $t3
    add     $s2, $t1, $t2

    lw      $t0, 0($s2)
    lw      $t1, 4($s2)
    lw      $t2, 8($s2)

    bne     $t2, $s1, move_obstacles_increment

    move    $a0, $s0
    jal     remove_obstacle

    lw      $t1, 0($s2)
    addi    $t1, $t1, -1
    sw      $t1, 0($s2)

    move    $a0, $s0
    blt     $t1, $zero, move_remove_out_of_bounds

    jal     draw_obstacle
    j       move_obstacles_increment

move_remove_out_of_bounds:
    jal     remove_out_of_bounds_obstacle

move_obstacles_increment:
    addi    $s0, $s0, 1
    j       move_obstacles_loop_start

move_obstacles_end:
    lw  $s0, 12($sp)
    lw  $s1, 8($sp)
    lw  $s2, 4($sp)
    lw  $s3, 0($sp)
    addi    $sp, $sp, 16
    j   return_from_proc
# =============================================================

# =============================================================
create_obstacle:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    jal     lfsr_rand

    la      $t0, obstacle_cooldown
    lw      $t1, 0($t0)
    ble     $t1, $zero, check_num_obstacles

    addi    $t1, $t1, -1
    sw      $t1, 0($t0)
    j       return_from_proc

check_num_obstacles:
    la      $t1, num_obstacles
    lw      $t2, 0($t1)
    li      $t3, MAX_OBSTACLES
    bge     $t2, $t3, return_from_proc 

    
    la      $t3, obstacles
    sll     $t4, $t2, 2
    sll     $t5, $t2, 3
    add     $t4, $t5, $t4
    add     $t4, $t3, $t4
    li      $t5, SCREEN_WIDTH
    addi    $t5, $t5, -1
    sw      $t5, 0($t4)

    andi    $t6, $v0, 3

    li      $t5, GAME_ROW

    li      $t7, 2 
    blt     $t6, $t7, set_tall_cactus_bottom
    beq     $t6, $t7, set_bird
    # just do short catcus case
    li      $t7, SHORT_CACTUS
    sw      $t7, 8($t4)
    sw      $t5, 4($t4)
    j       create_obstacle_continue

set_tall_cactus_bottom:
    li      $t7, TALL_CACTUS_BOTTOM
    sw      $t7, 8($t4)
    sw      $t5, 4($t4)
    j       create_obstacle_continue

set_bird:
    srl     $t6, $v0, 16
    andi    $t6, $t6, 7
    li      $t7, GAME_ROW
    sub     $t6, $t7, $t6
    sw      $t6, 4($t4)
    li      $t7, BIRD
    sw      $t7, 8($t4)

create_obstacle_continue:
    addi    $t2, $t2, 1
    sw      $t2, 0($t1)

    andi    $t6, $v0, 7
    addi    $t6, $t6, MIN_OBSTACLE_COOLDOWN
    sw      $t6, 0($t0)

    addi    $a0, $t2, -1
    jal     draw_obstacle
    j       return_from_proc

# =============================================================

# =============================================================
check_collision:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4


    li      $v0, 0
    li      $t0, 0

    la      $t1, num_obstacles
    lw      $t2, 0($t1)
check_collision_loop_start:
    beq     $t0, $t2, return_from_proc

    la      $t3, obstacles
    sll     $t4, $t0, 2
    sll     $t5, $t0, 3
    add     $t4, $t4, $t5
    add     $t4, $t3, $t4

    lw      $t5, 0($t4)

    li      $t6, PLAYER_COL
    bne     $t6, $t5, check_collision_increment

    lw      $t5, 8($t4)
    lw      $t7, 4($t4)
    la      $t3, player_row
    lw      $t3, 0($t3)

    beq     $t3, $t7, check_collision_found

    li      $t6, TALL_CACTUS_BOTTOM
    beq     $t5, $t6, check_tall_cactus

    li      $t6, BIRD
    beq     $t5, $t6, check_bird

    j      check_collision_increment

check_tall_cactus:
    addi    $t7, $t7, -1
    beq     $t3, $t7, check_collision_found
    j       check_collision_increment

check_bird:
    la      $t5, is_ducking
    lw      $t5, 0($t5)

    bne     $t5, $zero, check_collision_increment

    addi    $t3, $t3, -1
    bne     $t3, $t7, check_collision_increment

check_collision_found:
    li      $v0, 1
    j       return_from_proc

check_collision_increment:
    addi    $t0, $t0, 1
    j       check_collision_loop_start
# =============================================================

# =============================================================
reset_game:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    li      $t0, 0
reset_game_clear_obstacles_loop:
    la      $t1, num_obstacles
    lw      $t1, 0($t1)

    beq     $t0, $t1, reset_game_clear_obstacles_end

    move    $a0, $t0
    jal     remove_obstacle

    addi    $t0, $t0, 1
    j       reset_game_clear_obstacles_loop

reset_game_clear_obstacles_end:
    li      $a2, 0
    li      $t0, SCREEN_HEIGHT
    li      $t1, SCREEN_WIDTH
    li      $a0, BACKGROUND

reset_game_clear_screen_row_loop:
    beq     $a2, $t0, reset_game_clear_screen_end
    li      $a1, 0
reset_game_clear_screen_col_loop:
    beq     $a1, $t1, reset_game_clear_screen_row_increment
    jal     putChar_atXY
    addi    $a1, $a1, 1
    j       reset_game_clear_screen_col_loop
reset_game_clear_screen_row_increment:
    addi    $a2, $a2, 1
    j       reset_game_clear_screen_row_loop

reset_game_clear_screen_end:
    li      $t0, 0
    la      $t1, num_obstacles
    sw      $t0, 0($t1)

    la      $t1, is_jumping
    sw      $t0, 0($t1)

    la      $t1, is_ducking
    sw      $t0, 0($t1)

    li      $t0, MAX_OBSTACLE_COOLDOWN
    la      $t1, obstacle_cooldown
    sw      $t0, 0($t1)

    li      $t0, GAME_ROW
    la      $t1, new_player_row
    sw      $t0, 0($t1)

    li      $t0, GROUND_MOVE_DELAY
    la      $t1, current_ground_move_delay
    sw      $t0, 0($t1)

    li      $t0, BIRD_MOVE_DELAY
    la      $t1, current_bird_move_delay
    sw      $t0, 0($t1)

    j        return_from_proc
# =============================================================

# =============================================================
game_over:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    li      $a0, GAME_OVER_SOUND
    jal     put_sound

    li      $t0, 0
    la      $t1, is_ducking
    sw      $t0, 0($t1)

    li      $a0, 1
    jal     draw_player

    li      $t2, GAME_ROW
    addi    $t2, $t2, 2
    li      $t3, SCREEN_WIDTH
    li      $t4, 0
set_background_red_loop:
    beq     $t4, $t3, set_background_red_loop_end
    li      $a0, BACKGROUND_RED
    move    $a1, $t4
    move    $a2, $t2
    jal     putChar_atXY

    addi    $t4, $t4, 1
    j       set_background_red_loop

set_background_red_loop_end:
    li      $a0, 15
    jal     pause
    jal     sound_off
    j       return_from_proc
# =============================================================


# =============================================================
robot_key:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    addi    $fp, $sp, 4

    li      $v0, 0
    la      $t0, cheat
    lw      $t0, 0($t0)

    beq     $t0, $zero, call_get_key

    li      $t0, 0
    la      $t1, num_obstacles
    lw      $t1, 0($t1)
    la      $t2, obstacles
robot_loop_start:
    beq     $t0, $t1, return_from_proc

    sll     $t3, $t0, 2
    sll     $t4, $t0, 3
    add     $t3, $t3, $t4
    
    add     $t3, $t3, $t2

    
    lw      $t4, 0($t3)
    lw      $t6, 4($t3)
    lw      $t5, 8($t3)

    li      $t7, PLAYER_COL
    sub     $t4, $t4, $t7

    li      $t7, 1
    blt     $t4, $t7, robot_skip_obstacle
    li      $t7, 7
    bgt     $t4, $t7, robot_skip_obstacle

    la      $t4, player_row
    lw      $t4, 0($t4)

    li      $t7, BIRD
    beq     $t5, $t7, robot_case_bird

    j       return_W_KEY

robot_case_bird:
    la      $t4, player_row
    lw      $t4, 0($t4)
    beq     $t4, $t6, return_W_KEY

    addi    $t4, $t4, -1
    bne     $t4, $t6, robot_skip_obstacle

    la      $t4, is_ducking
    lw      $t4, 0($t4)
    bne     $t4, $zero, robot_skip_obstacle

    li      $v0, S_KEY
    j       return_from_proc

robot_skip_obstacle:
    addi    $t0, $t0, 1
    j       robot_loop_start

call_get_key:
    jal     get_key
    j       return_from_proc

return_W_KEY:
    li      $v0, W_KEY
    j       return_from_proc
# =============================================================

# =============================================================
play_game:
    li      $s0, 0
    la      $t0, cheat

    sw      $zero, 0($t0)
init_wait_loop:
    li      $a0, 10
    jal     pause_and_getkey
    move    $s0, $v0
    beq     $s0, $zero, init_wait_loop

    li      $t1, RIGHT_BRACKET_KEY
    bne     $s0, $t1, continue_init

    li      $t2, 1
    sw      $t2, 0($t0)

continue_init:
    la      $t3, lfsr
    jal     get_current_time_ms
    sw      $v0, 0($t3)

    jal     reset_game
    jal     init_course_ground
    jal     render_ground

    move    $a0, $s0
    jal     handle_jump
    move    $a0, $s0
    jal     handle_duck
    li      $a0, 0
    jal     draw_player

    li      $s1, 0
    li      $s2, 0
    li      $s3, 0
    li      $s4, 0
    li      $s5, 0
    jal     get_current_time_ms
    move    $s6, $v0
    li      $s7, 0

main_game_loop:
    jal     get_current_time_ms
    move    $s0, $v0

    sub     $t6, $s0, $s5
    li      $t7, SPEED_INCREASE_INTERVAL
    blt     $t6, $t7, skip_speed_increment

    la      $t5, current_ground_move_delay
    lw      $t6, 0($t5)
    li      $t7, MIN_GROUND_MOVE_DELAY
    beq     $t6, $t7, skip_ground_move_update
    addi    $t6, $t6, -1
    sw      $t6, 0($t5)

skip_ground_move_update:
    la      $t5, current_bird_move_delay
    lw      $t6, 0($t5)
    li      $t7, MIN_BIRD_MOVE_DELAY
    beq     $t6, $t7, skip_update_bird_delay
    addi    $t6, $t6, -1
    sw      $t6, 0($t5)

skip_update_bird_delay:
    move $s5, $s0

skip_speed_increment:
    sub     $t5, $s0, $s3
    la      $t6, current_ground_move_delay
    lw      $t6, 0($t6)
    blt     $t5, $t6, skip_ground_update

    li      $a0, SHORT_CACTUS
    jal     move_obstacles
    li      $a0, TALL_CACTUS_BOTTOM
    jal     move_obstacles

    jal     render_ground

    move $s3, $s0

    jal     create_obstacle

skip_ground_update:
    sub     $t5, $s0, $s4
    la      $t6, current_bird_move_delay
    lw      $t6, 0($t6)
    blt     $t5, $t6, skip_bird_update

    li      $a0, BIRD
    jal     move_obstacles

    move $s4, $s0

    jal     create_obstacle

    addi    $s1, $s1, 1

skip_bird_update:
    jal     check_collision
    bne     $v0, $zero, exit_game_loop
    
    sub     $t5, $s0, $s2
    li      $t6, FRAME_DELAY
    blt     $t5, $t6, skip_player_update

    jal     robot_key
    move    $a0, $v0

    jal     handle_jump
    jal     handle_duck

    li      $a0, 0
    jal     draw_player

    move    $s2, $s0

skip_player_update:
    sub     $t5, $s0, $s6
    li      $t6, SCORE_SOUND_INTERVAL
    blt     $t5, $t6, main_game_loop

    lw      $t7, NUM_SCORE_SOUNDS
    beq     $s7, $t7, reset_score_sound_idx

    la      $t5, score_sounds
    sll     $t6, $s7, 2
    add     $t6, $t6, $t5
    lw      $a0, 0($t6)
    jal     put_sound

    lw      $t6, SCORE_SOUND_DELAY
    add     $s6, $s6, $t6

    addi    $s7, $s7, 1
    j       main_game_loop

reset_score_sound_idx:
    jal     sound_off
    li      $s7, 0
    move    $s6, $s0
    j       main_game_loop

exit_game_loop:
    jal     game_over
    j       play_game
# =============================================================

return_from_proc:
    addi    $sp, $fp, 4
    lw      $ra, 0($fp)
    lw      $fp, -4($fp)
    jr      $ra


.include "procs_board.asm"

