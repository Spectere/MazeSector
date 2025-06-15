#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WIDTH (39)
#define HEIGHT (24)
#define SIZE (WIDTH * HEIGHT)
#define STACK_SIZE (SIZE * 2)

const char WALL = '#';
const char EMPTY = ' ';

enum STATE {
    NOT_VISITED = 0,
    VISITED = 1,
    EAST = 2,
    NORTH = 4
};

enum TRAVEL {
    CANNOT_TRAVEL = -1,
    GO_EAST,
    GO_SOUTH,
    GO_WEST,
    GO_NORTH
};

static char maze[SIZE];
static int stack[STACK_SIZE];
static int stack_ptr;

static uint8_t a, b, c, x;
uint8_t rnd() {
    ++x;
    a = (a ^ c) ^ x;
    b = b + a;
    c = (c + (b >> 1)) ^ a;
    return c;
}

void init_rng(uint8_t s1, uint8_t s2, uint8_t s3) {
    a ^= s1;
    b ^= s2;
    c ^= s3;
    rnd();
}

int max_stack = 0;
void push(int pos) {
    if(stack_ptr == STACK_SIZE) {
        puts("stack overflow");
        exit(1);
    }
    stack[stack_ptr++] = pos;
    if(stack_ptr > max_stack) max_stack = stack_ptr;
}

int pop() {
    if(stack_ptr == 0) {
        puts("stack underflow");
        exit(1);
    }
    return stack[--stack_ptr];
}

int get_target_cell(int cell, int direction) {
    /* Bounds checking. */
    if(((cell % WIDTH) == 0 && direction == GO_WEST)
    || (((cell % WIDTH) == WIDTH - 1) && direction == GO_EAST)
    || (cell < WIDTH && direction == GO_NORTH)
    || (cell >= (WIDTH * (HEIGHT - 1)) && direction == GO_SOUTH)) {
        return -1;
    }

    /* Result */
    switch(direction) {
        case GO_NORTH: return cell - WIDTH;
        case GO_EAST: return cell + 1;
        case GO_SOUTH: return cell + WIDTH;
        case GO_WEST: return cell - 1;
        default: {
            printf("get_target_cell: invalid direction %i\n", direction);
            exit(1);
        }
    }
}

int get_unvisited_cell_count(int cell) {
    int count = 0;

    int target = get_target_cell(cell, GO_NORTH);
    if(target >= 0 && maze[target] == NOT_VISITED) count++;

    target = get_target_cell(cell, GO_EAST);
    if(target >= 0 && maze[target] == NOT_VISITED) count++;

    target = get_target_cell(cell, GO_SOUTH);
    if(target >= 0 && maze[target] == NOT_VISITED) count++;

    target = get_target_cell(cell, GO_WEST);
    if(target >= 0 && maze[target] == NOT_VISITED) count++;

    return count;
}

void generate_maze() {
    /*
     * Iterative depth-search implementation.
    */

    /* Initialization */
    int maze_ptr = 0;
    maze[maze_ptr] |= VISITED;
    push(maze_ptr);

    /* Execution */
    while(stack_ptr > 0) {
        int cell = pop();

        if(!get_unvisited_cell_count(cell)) {
            continue;
        }

        push(cell);
        int target = -1;
        int direction = -1;
        while(target < 0) {
            /* Pretty naive and wasteful, but it should work well enough. */
            direction = rnd() & 3;  // 0 - 3
            target = get_target_cell(cell, direction);
        }

        switch(direction) {
            case GO_EAST: { maze[cell] |= EAST;
                            break; }

            case GO_NORTH: { maze[cell] |= NORTH;
                             break; }

            case GO_WEST: { maze[target] |= EAST;
                            break; }

            case GO_SOUTH: { maze[target] |= NORTH;
                             break; }
        }

        if(target > SIZE) {
            printf("generate_maze: invalid target %i\n", target);
            exit(1);
        }

        maze[target] |= VISITED;
        push(target);
    }
}

void draw_maze() {
    printf("\n  ");
    for(int x = 0; x < WIDTH * 2 + 1; ++x) {
        putchar(WALL);
    }
    printf("\n  ");

    int maze_ptr = 0;
    for(int maze_ptr = 0; maze_ptr < SIZE; ++maze_ptr) {
        if(maze_ptr % WIDTH == 0 && maze_ptr > 0) {
            printf("\n  ");

            putchar(WALL);
            for(int x = 0; x < WIDTH; ++x) {
                putchar((maze[maze_ptr + x] & NORTH) ? EMPTY : WALL);  /* Vertical exits */
                putchar(WALL);
            }

            printf("\n  ");
        }

        if(maze_ptr % WIDTH == 0) {
            /* Left edge. Create an opening for the maze entrance. */
            putchar(maze_ptr == 0 ? EMPTY : WALL);
        }

        /* Horizontal exits. Create an opening for the maze exit. */
        putchar(EMPTY);  /* Cell */
        putchar(((maze[maze_ptr] & EAST) || maze_ptr == (SIZE - 1)) ? EMPTY : WALL);  /* Wall */
    }

    printf("\n  ");
    for(int x = 0; x < WIDTH * 2 + 1; ++x) {
        putchar(WALL);
    }
}

int main(int argc, char **argv) {
    memset(&maze, NOT_VISITED, SIZE);
    stack_ptr = 0;
    init_rng(12, 34, 56);
    generate_maze();

    draw_maze();
    printf("\n\n  maximum stack entries: %i\n\n", max_stack);

    return 0;
}
