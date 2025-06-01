
// Specify the keys here that get_key() will look for,

int key_array[] = {'w', 's', ']'};

#define W_KEY 1
#define S_KEY 2
#define RIGHT_BRACKET_KEY 3

//  get_key2()

int key_array2[] = {};

/*
    { text character, foreground color, background color }
*/

// type definition for emulating sprites (see below)
typedef struct
{
    char char_to_display;
    int fg_color;
    int bg_color;
} sprite_attr;

enum colors
{
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white
};

sprite_attr sprite_attributes[] = {
    {' ', white, white},  // background
    {' ', red, red},      // red background
    {'V', black, green},  // dino top
    {'X', black, red},    // dino top hit
    {'U', black, green},  // dino bottom Left foot down
    {'V', black, green},  // dino bottom Right foot down
    {'M', black, green},  // dino bottom neutral feet
    {'i', black, yellow}, // short cactus
    {'I', black, yellow}, // tall cactus bottom
    {'i', black, yellow}, // tall cactus top
    {'^', blue, white},   // bird
    {'-', black, white},  // ground 1
    {'-', blue, white},   // ground 2
    {'-', cyan, white},   // ground 3
    {'-', red, white}     // ground 4
};

#define Nchars (sizeof sprite_attributes / sizeof sprite_attributes[0])

#define BACKGROUND 0
#define BACKGROUND_RED 1
#define DINO_TOP 2
#define DINO_TOP_HIT 3
#define DINO_BOTTOM_LEFT_FOOT_DOWN 4
#define DINO_BOTTOM_RIGHT_FOOT_DOWN 5
#define DINO_BOTTOM_NEUTRAL 6
#define SHORT_CACTUS 7
#define TALL_CACTUS_BOTTOM 8
#define TALL_CACTUS_TOP 9
#define BIRD 10

const int ground_sprites[] = {Nchars - 4, Nchars - 3, Nchars - 2, Nchars - 1};
#define NUM_GROUND_SPRITES (sizeof ground_sprites / sizeof ground_sprites[0])

// I/O Functions that are also availabile in MIPS

void my_pause(int N); // N is hundredths of a second

void putChar_atXY(int charcode, int col, int row);
// puts a character at screen location (X, Y)

int getChar_atXY(int col, int row);
// gets the character from screen location (X, Y)

int get_key();
// if a key has been pressed and it matches one of the
// characters specified in key_array[], return the
// index of the key in that array (starting with 1),
// else return 0 if no valid key was pressed.

int get_key2();
// similar to get_key(), but looks for key in
// key_array2[].

// not used due to timing of chrome dino
int pause_and_getkey(int N);

void pause_and_getkey_2player(int N, int *key1, int *key2);
// 2-player version of pause_and_getkey().

int get_accel();
// returns the accelerometer value:  accelX in bits [31:16], accelY in bits [15:0]
// to emulate accelerometer, use the four arrow keys

int get_accelX();
// returns X tilt value (increases back-to-front)

int get_accelY();
// returns Y tilt value (increases right-to-left)

void put_sound(int period);
// visually shows approximate sound tone generated
// you will not hear a sound, but see the tone highlighted on a sound bar

void sound_off();
// turns sound off

void put_leds(int pattern);
// put_leds: set the LED lights to a specified pattern
//   displays on row #31 (below the screen display)

void initialize_IO(char *smem_initfile);

#include <stdlib.h>
#include <time.h>
#include <stdio.h>

#define SCREEN_HEIGHT 30
#define SCREEN_WIDTH 40
#define GAME_ROW 14
#define PLAYER_COL 5

#define MAX_OBSTACLES 2
#define MIN_OBSTACLE_COOLDOWN 52
#define MAX_OBSTACLE_COOLDOWN 60

#define FRAME_DELAY 40
#define GROUND_MOVE_DELAY 40
#define MIN_GROUND_MOVE_DELAY 16
#define BIRD_MOVE_DELAY 35
#define MIN_BIRD_MOVE_DELAY 15
#define SPEED_INCREASE_INTERVAL 2000

#define GAME_OVER_SOUND_PERIOD 1000000

const unsigned int score_sounds[] = {
    227273,
    180180,
    151515};

#define NUM_SCORE_SOUNDS (sizeof score_sounds / sizeof score_sounds[0])
#define SCORE_SOUND_INTERVAL 25000
#define SCORE_SOUND_DELAY 80

int current_ground_move_delay, current_bird_move_delay;

int num_obstacles, obstacle_cooldown;
int obstacles[MAX_OBSTACLES][3];

int player_row, new_player_row;
int is_jumping, is_ducking;

const int jump_arr[] = {
    -1,
    -1,
    -1,
    -1,
    0,
    0,
    1,
    1,
    1,
    1};

int jump_idx;
int cheat;
unsigned int lfsr = 0;

unsigned int get_current_time_ms()
{
    struct timespec current;
    clock_gettime(CLOCK_MONOTONIC, &current);
    return (current.tv_sec * 1000) + (current.tv_nsec / 1000000);
}

unsigned int lfsr_rand()
{
    unsigned int bit;
    bit = ((lfsr >> 31) ^ (lfsr >> 21) ^ (lfsr >> 1) ^ (lfsr)) & 1;
    lfsr = (lfsr << 1) | bit;
    return lfsr;
}

int select_foot()
{
    if (is_jumping)
    {
        return DINO_BOTTOM_NEUTRAL;
    }
    int curr_foot = getChar_atXY(PLAYER_COL, player_row);
    if (curr_foot == BACKGROUND)
    {
        return DINO_BOTTOM_NEUTRAL;
    }
    if (curr_foot == DINO_BOTTOM_LEFT_FOOT_DOWN)
    {
        return DINO_BOTTOM_RIGHT_FOOT_DOWN;
    }
    return DINO_BOTTOM_LEFT_FOOT_DOWN;
}

void draw_player(int is_dead)
{
    int next_foot = select_foot();
    int top_sprite = is_dead ? DINO_TOP_HIT : DINO_TOP;
    putChar_atXY(BACKGROUND, PLAYER_COL, player_row);
    putChar_atXY(BACKGROUND, PLAYER_COL, player_row - 1);
    if (!is_ducking)
    {
        putChar_atXY(top_sprite, PLAYER_COL, new_player_row - 1);
    }
    putChar_atXY(next_foot, PLAYER_COL, new_player_row);
    player_row = new_player_row;
}

void handle_jump(int key)
{
    if (key == W_KEY && !is_jumping)
    {
        is_jumping = 1;
        jump_idx = 0;
    }
    if (is_jumping)
    {
        if (key == S_KEY)
        {
            jump_idx = 6;
        }

        new_player_row += jump_arr[jump_idx];
        jump_idx++;
        if (new_player_row == GAME_ROW)
        {
            is_jumping = 0;
        }
    }
}

void handle_duck(int key)
{
    if (is_jumping)
    {
        is_ducking = 0;
        return;
    }
    if (key == S_KEY)
    {
        is_ducking = !is_ducking;
    }
}

void render_ground()
{
    int ground_row = GAME_ROW + 1;
    for (int col = 0; col < SCREEN_WIDTH - 1; col++)
    {
        int next_ground = getChar_atXY(col + 1, ground_row);
        putChar_atXY(next_ground, col, ground_row);
    }
    int new_ground = ground_sprites[lfsr_rand() & 3];
    putChar_atXY(new_ground, SCREEN_WIDTH - 1, ground_row);
}

void init_course_ground()
{
    int ground_row = GAME_ROW + 1;
    for (int col = 0; col < SCREEN_WIDTH; col++)
    {
        int new_ground = ground_sprites[lfsr_rand() & 3];
        putChar_atXY(new_ground, col, ground_row);
    }
}

void draw_obstacle(int idx)
{
    if (obstacles[idx][0] < 0)
    {
        return;
    }
    switch (obstacles[idx][2])
    {
    case SHORT_CACTUS:
        putChar_atXY(SHORT_CACTUS, obstacles[idx][0], obstacles[idx][1]);
        break;
    case TALL_CACTUS_BOTTOM:
        putChar_atXY(TALL_CACTUS_BOTTOM, obstacles[idx][0], obstacles[idx][1]);
        putChar_atXY(TALL_CACTUS_TOP, obstacles[idx][0], obstacles[idx][1] - 1);
        break;
    case BIRD:
        putChar_atXY(BIRD, obstacles[idx][0], obstacles[idx][1]);
        break;
    }
}

void remove_obstacle(int idx)
{
    switch (obstacles[idx][2])
    {
    case SHORT_CACTUS:
        putChar_atXY(BACKGROUND, obstacles[idx][0], obstacles[idx][1]);
        break;
    case TALL_CACTUS_BOTTOM:
        putChar_atXY(BACKGROUND, obstacles[idx][0], obstacles[idx][1]);
        putChar_atXY(BACKGROUND, obstacles[idx][0], obstacles[idx][1] - 1);
        break;
    case BIRD:
        putChar_atXY(BACKGROUND, obstacles[idx][0], obstacles[idx][1]);
        break;
    }
}

void remove_out_of_bounds_obstacle(int idx)
{
    int swap_idx = num_obstacles - 1;
    obstacles[idx][0] = obstacles[swap_idx][0];
    obstacles[idx][1] = obstacles[swap_idx][1];
    obstacles[idx][2] = obstacles[swap_idx][2];
    num_obstacles--;
}

void move_obstacles(int obstacle_type)
{
    for (int i = 0; i < num_obstacles; i++)
    {
        if (obstacles[i][2] == obstacle_type)
        {
            remove_obstacle(i);
            obstacles[i][0]--;
            if (obstacles[i][0] < 0)
            {
                remove_out_of_bounds_obstacle(i);
            }
            else
            {
                draw_obstacle(i);
            }
        }
    }
}

void create_obstacle()
{
    if (obstacle_cooldown <= 0 && num_obstacles < MAX_OBSTACLES)
    {
        obstacles[num_obstacles][0] = SCREEN_WIDTH - 1;
        unsigned int rand_val = lfsr_rand();
        switch (rand_val & 3)
        {
        case 0:
            obstacles[num_obstacles][2] = SHORT_CACTUS;
            obstacles[num_obstacles][1] = GAME_ROW;
            break;
        case 1:
        case 2:
            obstacles[num_obstacles][2] = TALL_CACTUS_BOTTOM;
            obstacles[num_obstacles][1] = GAME_ROW;
            break;
        case 3:
            obstacles[num_obstacles][2] = BIRD;
            obstacles[num_obstacles][1] = GAME_ROW - ((rand_val >> 16) & 7);
            break;
        }
        num_obstacles++;
        obstacle_cooldown = (rand_val & 7) + MIN_OBSTACLE_COOLDOWN;
        draw_obstacle(num_obstacles - 1);
    }
    else
    {
        obstacle_cooldown--;
    }
}

int check_collision()
{
    for (int i = 0; i < num_obstacles; i++)
    {
        if (obstacles[i][0] != PLAYER_COL)
        {
            continue;
        }
        switch (obstacles[i][2])
        {
        case TALL_CACTUS_BOTTOM:
            if (obstacles[i][1] == player_row || obstacles[i][1] - 1 == player_row)
            {
                return 1;
            }
            break;
        case BIRD:
            if (!is_ducking && obstacles[i][1] == player_row - 1)
            {
                return 1;
            }
        case SHORT_CACTUS:
            if (obstacles[i][1] == player_row)
            {
                return 1;
            }
        }
    }
    return 0;
}

void reset_game()
{
    for (int i = 0; i < num_obstacles; i++)
    {
        remove_obstacle(i);
    }
    for (int row = 0; row < SCREEN_HEIGHT; row++)
    {
        for (int col = 0; col < SCREEN_WIDTH; col++)
        {
            putChar_atXY(BACKGROUND, col, row);
        }
    }
    num_obstacles = 0;
    is_jumping = 0;
    is_ducking = 0;
    obstacle_cooldown = MAX_OBSTACLE_COOLDOWN;
    new_player_row = GAME_ROW;
    current_ground_move_delay = GROUND_MOVE_DELAY;
    current_bird_move_delay = BIRD_MOVE_DELAY;
}

void game_over()
{
    put_sound(GAME_OVER_SOUND_PERIOD);
    is_ducking = 0;
    draw_player(1);
    int start_row = GAME_ROW + 2;
    for (int row = start_row; row < SCREEN_HEIGHT; row++)
    {
        for (int col = 0; col < SCREEN_WIDTH; col++)
        {
            putChar_atXY(BACKGROUND_RED, col, row);
        }
    }
    my_pause(10);
    sound_off();
}

int robot_key()
{
    if (!cheat)
    {
        return get_key();
    }

    for (int i = 0; i < num_obstacles; i++)
    {
        int obstacle_col = obstacles[i][0];
        int obstacle_type = obstacles[i][2];
        int obstacle_row = obstacles[i][1];

        int distance = obstacles[i][0] - PLAYER_COL;
        if (distance >= 1 && distance <= 7)
        {
            switch (obstacle_type)
            {
            case BIRD:
                if (obstacle_row == player_row)
                {
                    return W_KEY;
                }
                if (obstacle_row == player_row - 1 && !is_ducking)
                {
                    return S_KEY;
                }
                break;
            case SHORT_CACTUS:
            case TALL_CACTUS_BOTTOM:
                return W_KEY;
            }
        }
    }
    return 0;
}

void play_game()
{
    int key = 0;
    cheat = 0;
    while (1)
    {
        key = pause_and_getkey(10);
        if (key)
        {
            break;
        }
    }
    if (key == RIGHT_BRACKET_KEY)
    {
        cheat = 1;
    }

    lfsr = get_current_time_ms();

    reset_game();
    init_course_ground();
    render_ground();

    handle_jump(key);
    handle_duck(key);
    draw_player(0);

    unsigned int score = 0;
    unsigned int last_player_update = 0;
    unsigned int last_ground_update = 0;
    unsigned int last_bird_update = 0;
    unsigned int last_speed_increment_time = 0;
    unsigned int score_sound_time = get_current_time_ms();
    unsigned int score_sound_idx = 0;
    while (1)
    {
        unsigned int curr_time = get_current_time_ms();
        if (curr_time - last_speed_increment_time >= SPEED_INCREASE_INTERVAL)
        {
            current_ground_move_delay =
                current_ground_move_delay > MIN_GROUND_MOVE_DELAY ? current_ground_move_delay - 1
                                                                  : MIN_GROUND_MOVE_DELAY;
            current_bird_move_delay =
                current_bird_move_delay > MIN_BIRD_MOVE_DELAY ? current_bird_move_delay - 1 : MIN_BIRD_MOVE_DELAY;
            last_speed_increment_time = curr_time;
        }

        if (curr_time - last_ground_update >= current_ground_move_delay)
        {
            move_obstacles(SHORT_CACTUS);
            move_obstacles(TALL_CACTUS_BOTTOM);
            render_ground();
            last_ground_update = curr_time;
            create_obstacle();
        }
        if (curr_time - last_bird_update >= current_bird_move_delay)
        {
            move_obstacles(BIRD);
            last_bird_update = curr_time;
            create_obstacle();
            score++;
        }
        if (check_collision())
        {
            break;
        }
        if (curr_time - last_player_update >= FRAME_DELAY)
        {
            int key = robot_key();
            handle_jump(key);
            handle_duck(key);
            draw_player(0);
            last_player_update = curr_time;
        }
        if (curr_time - score_sound_time >= SCORE_SOUND_INTERVAL)
        {
            if (score_sound_idx == NUM_SCORE_SOUNDS)
            {
                sound_off();
                score_sound_idx = 0;
                score_sound_time = curr_time;
            }
            else
            {
                put_sound(score_sounds[score_sound_idx]);
                score_sound_time += SCORE_SOUND_DELAY;
                score_sound_idx++;
            }
        }
    }
    game_over();
}

int main()
{
    initialize_IO("smem.mem");
    new_player_row = GAME_ROW;
    draw_player(0);
    while (1)
    {
        play_game();
    }
}

// The file below has the implementation of all of the helper functions
#include "procs.c"