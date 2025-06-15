[bits 16]
[cpu 8086]
[org 0x7C00]

%define GO_WEST  0x0
%define GO_EAST  0x1
%define GO_NORTH 0x2
%define GO_SOUTH 0x3

%define WEST    0b00001
%define EAST    0b00010
%define NORTH   0b00100
%define SOUTH   0b01000
%define VISITED 0b10000

%define CHAR_UNVISITED     0xDB
%define CHAR_VISITED_HORIZ 0xDC
%define CHAR_VISITED_VERT  0x20

%define MAZE_MEM_SEG 0x0050  ; Start of conventional memory.
%define MAZE_WIDTH   39
%define MAZE_HEIGHT  24

%define STACK_SEG     0x0600
%define STACK_TOP     0x1BFF
%define VIDEO_RAM_SEG 0xB800

; =============================================================================
;  Code
; =============================================================================

    cli

    ; Set up segments.
    mov ax, MAZE_MEM_SEG
    mov ds, ax
    mov es, ax

    ; Set stack segment and pointer.
    mov ax, STACK_SEG
    mov ss, ax
    mov sp, STACK_TOP

    ; Set video mode.
    mov ax, 0x0002  ; 80x25, text
    int 0x10

    ; Clear the memory
    xor ax, ax
    mov cx, (MAZE_WIDTH * MAZE_HEIGHT)
    rep stosb

    ; Set extra segment to video RAM.
    mov ax, VIDEO_RAM_SEG
    mov es, ax

    ; Set up the initial maze cell.
    mov al, VISITED       ; Cell status
    xor si, si            ; Cell index
    mov [ds:si], al
    push si
generate_maze:
    cmp sp, STACK_TOP
    jz draw              ; Stack is empty. Draw the maze.

.generate_continue:
    pop si
    xor bl, bl
.rnd_movement:
    ; Get direction to traverse.
    call rnd
    mov cl, al
    and cl, 0b11
    mov al, 1
    shl al, cl
    or bl, al

    ; See if moving would cause us to run into a border.
    mov ax, si
    mov dl, MAZE_WIDTH
    div dl

    cmp cl, 1
    js .border_check_west
    jz .border_check_east
    cmp cl, 2
    jz .border_check_north
    
.border_check_south:
    cmp al, (MAZE_HEIGHT - 1)
    jmp .border_check_jump

.border_check_east:
    cmp ah, (MAZE_WIDTH - 1)
    jmp .border_check_jump

.border_check_west:
    mov al, ah
.border_check_north:
    or al, al
.border_check_jump:
    jz .cell_at_border

.check_neighbor:
    call get_delta
    push si
    add si, dx
    mov al, [ds:si]
    test al, VISITED
    jnz .neighbor_visited

    ; Neighbor has *not* been visited. Update cells appropriately.
    or al, VISITED
    mov [ds:si], al

    ; Determine where to mark the exit.
    mov ah, 1
    shl ah, cl
    test cl, 1          ; We only care about east/south exits.
    jnz .flag_current   ; If we are moving east/south, flag the current cell.

    shl ah, 1           ; Otherwise, shift the register and flag the *neighbor*
    or al, ah           ; as having an east/south exit.
    mov [ds:si], al
    jmp .done_flagging

.flag_current:
    mov dx, si
    pop si
    mov al, [ds:si]
    or al, ah
    mov [ds:si], al
    push si
    mov si, dx

.done_flagging:
    push si             ; Push the neighbor onto the stack and process that cell.
    jmp generate_maze

.neighbor_visited:
    pop si
.cell_at_border:
    cmp bl, 0b1111      ; See if all directions have been tried.
    jnz .rnd_movement   ; If not, try a different direction.
.next_cell:             ; If so, move onto another cell.
    jmp generate_maze

draw:
    ; Draw a giant block.
    xor di, di
    mov ax, 0x07DB      ; Grey, solid block
    mov cx, 80 * 25
    rep stosw

draw_maze:
    ; Draw our beautiful maze.
    xor si, si
    mov di, 81 * 2      ; Second line, second character.

.draw_maze_new_cell:
    mov al, [ds:si]
    test al, EAST
    jz .draw_maze_check_south

    mov [es:di], byte CHAR_VISITED_HORIZ
    mov [es:di+2], byte CHAR_VISITED_HORIZ
    mov [es:di+4], byte CHAR_VISITED_HORIZ

.draw_maze_check_south:
    test al, SOUTH
    jz .draw_maze_next_cell

    mov [es:di], byte CHAR_VISITED_VERT
    mov [es:di+(80*2)], byte CHAR_VISITED_HORIZ

.draw_maze_next_cell:
    inc si
    cmp si, (MAZE_WIDTH * MAZE_HEIGHT)
    jz draw_exits

    ; Are we on the right edge?
    mov ax, si
    mov bl, MAZE_WIDTH
    div bl
    or ah, ah
    jz .draw_maze_next_line

    ; Nope. Advance two characters.
    add di, (2 * 2)
    jmp .draw_maze_new_cell

.draw_maze_next_line:
    ; Yep. Advance four characters.
    add di, (4 * 2)
    jmp .draw_maze_new_cell

    ; Draw the exits.
draw_exits:
    mov di, 80 * 2
    mov ax, 0x07DC
    mov [es:di], ax
    mov [es:di + (1918 * 2)], ax
    mov [es:di + (1919 * 2)], ax

    ; Draw the bar on the top of the screen.
    xor di, di
    mov ax, 0x07DC  ; Grey, solid block
    mov cx, 80
    rep stosw

done:
    hlt

rnd:
    ; Fast 8-bit PRNG
    ; https://www.stix.id.au/wiki/Fast_8-bit_pseudorandom_number_generator
    push si
    mov ax, rng
    mov si, ax

    ; ++x
    inc byte [cs:si]

    ; a = (a ^ c) ^ x
    mov al, [cs:si+1]
    xor al, [cs:si+3]
    xor al, [cs:si]
    mov [cs:si+1], al

    ; b = b + a
    add [cs:si+2], al

    ; c = (c + (b >> 1)) ^ a
    mov dl, [cs:si+2]
    shr dl, 1
    add [cs:si+3], dl
    xor [cs:si+3], al

    mov al, [cs:si+3]
    pop si
    ret

get_delta:
    mov dx, 1
    cmp cl, dl
    jg .delta_vert
    jnz .delta_neg
    ret
.delta_vert:
    mov dx, MAZE_WIDTH
    or cl, cl
    jpo .delta_neg
    ret
.delta_neg:
    neg dx
    ret


; =============================================================================
;  Data
; =============================================================================

rng: db 0, 12, 34, 56


; =============================================================================
;  Boot Signature
; =============================================================================

    times 510-($-$$) db 0  ; Padding
    dw 0xAA55
