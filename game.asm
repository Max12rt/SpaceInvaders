use16
org 07C00h

sprites      equ 0FA00h
alien1       equ 0FA04h
alien2       equ 0FA08h
ship         equ 0FA08h
barrierArr   equ 0FA0Ch
alienArr     equ 0FA20h
playerX      equ 0FA24h
shotsArr     equ 0FA25h
alienY       equ 0FA2Dh
alienX       equ 0FA2Eh
num_aliens   equ 0FA2Fh
direction    equ 0FA30h
move_timer   equ 0FA31h
change_alien equ 0FA33h

SCREEN_WIDTH        equ 320
SCREEN_HEIGHT       equ 200
VIDEO_MEMORY        equ 0A000h
TIMER               equ 046Ch
BARRIERXY           equ 1655h
BARRIERX            equ 16h
BARRIERY            equ 55h
PLAYERY             equ 93
SPRITE_HEIGHT       equ 4
SPRITE_WIDTH        equ 8
SPRITE_WIDTH_PIXELS equ 16

ALIEN_COLOR         equ 03h
PLAYER_COLOR        equ 07h
BARRIER_COLOR       equ 28h
PLAYER_SHOT_COLOR   equ 0Bh
ALIEN_SHOT_COLOR    equ 0Eh

mov ax, 0013h
int 10h

push VIDEO_MEMORY
pop es

mov di, sprites
mov si, sprite_bitmaps
mov cl, 6
rep movsw

lodsd
mov cl, 5
rep stosd

mov cl, 5
rep movsb

xor ax, ax
mov cl, 4
rep stosw

mov cl, 7
rep movsb

push es
pop ds

game_loop:
    xor ax, ax
    xor di, di
    mov cx, SCREEN_WIDTH*SCREEN_HEIGHT
    rep stosb

    mov si, alienArr
    mov bl, ALIEN_COLOR
    mov ax, [si+13]
    cmp byte [si+19], cl
    mov cl, 4
    jg draw_next_alien_row
    add di, cx
    draw_next_alien_row:
        pusha
        mov cl, 8
        .check_next_alien:
            pusha
            dec cx
            bt [si], cx
            jnc .next_alien

            mov si, di
            call draw_sprite

            .next_alien:
                popa
                add ah, SPRITE_WIDTH+4
        loop .check_next_alien

        popa
        add al, SPRITE_HEIGHT+2
        inc si
    loop draw_next_alien_row

    lodsb
    push si
    mov si, ship
    mov ah, PLAYERY
    xchg ah, al
    mov bl, PLAYER_COLOR
    call draw_sprite

    mov bl, BARRIER_COLOR
    mov ax, BARRIERXY
    mov cl, 2
    draw_barrier_loop:
        pusha
        call draw_sprite
        popa
        add ah, 100
        add si, SPRITE_HEIGHT
    loop draw_barrier_loop

    pop si

    mov cl, 4
    get_next_shot:
        push cx
        lodsw
        cmp al, 0
        jnz check_shot

        next_shot:
            pop cx
    loop get_next_shot

    jmp create_alien_shots

    check_shot:
        call get_screen_position
        mov al, [di]

        cmp al, PLAYER_COLOR
        je game_over

        xor bx, bx

        cmp al, BARRIER_COLOR
        jne .check_hit_alien

        mov bx, barrierArr
        mov ah, BARRIERX+SPRITE_WIDTH
        .check_barrier_loop:
            cmp dh, ah
            ja .next_barrier

            sub ah, SPRITE_WIDTH
            sub dh, ah

            pusha
            sub dl, BARRIERY
            add bl, dl
            mov al, 7
            sub al, dh
            cbw
            btr [bx], ax
            mov byte [si-2], ah
            popa
            jmp next_shot

            .next_barrier:
                add ah, 25
                add bl, SPRITE_HEIGHT
        jmp .check_barrier_loop

        .check_hit_alien:
            cmp cl, 4
            jne draw_shot

            cmp al, ALIEN_COLOR
            jne draw_shot

            mov bx, alienArr
            mov ax, [bx+13]
            add al, SPRITE_HEIGHT
            .get_alien_row:
                cmp dl, al
                jg .next_row

                mov cl, 8
                add ah, SPRITE_WIDTH
                .get_alien:
                    dec cx
                    cmp dh, ah
                    ja .next_alien

                    btr [bx], cx
                    mov byte [si-2], 0
                    dec byte [si+8]
                    jz game_over
                    jmp next_shot

                    .next_alien:
                        add ah, SPRITE_WIDTH+4
                jmp .get_alien

                .next_row:
                    add al, SPRITE_HEIGHT+2
                    inc bx
            jmp .get_alien_row

    draw_shot:
        mov bh, PLAYER_SHOT_COLOR
        mov al, [si-2]
        dec ax
        cmp cl, 4
        je .draw

        mov bh, ALIEN_SHOT_COLOR
        inc ax
        inc ax
        cmp al, SCREEN_HEIGHT/2
        cmovge ax, bx

        .draw:
            mov byte [si-2], al

            mov bl, bh
            xchg ax, bx
            mov [di+SCREEN_WIDTH], ax
            stosw

        jmp next_shot

    create_alien_shots:
       sub si, 6
       mov cl, 3
       .check_shot:
            mov di, si
            lodsw
            cmp al, 0
            jg  .next_shot

            mov ax, [CS:TIMER]
            and ax, 0007h
            imul ax, ax, SPRITE_WIDTH+4
            xchg ah, al
            add ax, [alienY]
            stosw

            jmp move_aliens

            .next_shot:
        loop .check_shot

    move_aliens:
        mov di, alienX
        inc bp
        cmp bp, [di+3]
        jl get_input

        neg byte [di+5]
        xor bp, bp
        mov al, [di+2]

        add byte [di], al
        jg .check_right_side

        mov byte [di], cl
        jmp .move_down

        .check_right_side:
            mov al, 68
            cmp [di], al
            jle get_input
            stosb
            dec di

        .move_down:
            neg byte [di+2]
            dec di
            add byte [di], 5
            cmp byte [di], BARRIERY
            jg game_over
            dec byte [di+4]

    get_input:
        mov si, playerX
        mov ah, 02h
        int 16h
        test al, 1
        jz .check_left_shift
        add byte [si], ah

        .check_left_shift:
            test al, 2
            jz .check_alt
            sub byte [si], ah

        .check_alt:
            test al, 8
            jz delay_timer

            lodsb
            xchg ah, al

            add ax, 035Ah
            mov [si], ax

    delay_timer:
        mov ax, [CS:TIMER]
        inc ax
        .wait:
            cmp [CS:TIMER], ax
            jl .wait
jmp game_loop

game_over:
    xor ax, ax
    int 16h

    int 19h

draw_sprite:
    call get_screen_position
    mov cl, SPRITE_HEIGHT
    .next_line:
        push cx
        lodsb
        xchg ax, dx
        mov cl, SPRITE_WIDTH
        .next_pixel:
            xor ax, ax
            dec cx
            bt dx, cx
            cmovc ax, bx
            mov ah, al
            mov [di+SCREEN_WIDTH], ax
            stosw
        jnz .next_pixel

        add di, SCREEN_WIDTH*2-SPRITE_WIDTH_PIXELS
        pop cx
    loop .next_line

    ret

get_screen_position:
    mov dx, ax
    cbw
    imul di, ax, SCREEN_WIDTH*2
    mov al, dh
    shl ax, 1
    add di, ax

    ret

sprite_bitmaps:
    db 00111100b
    db 01111110b
    db 10100101b
    db 01011010b

    db 11000011b
    db 01100110b
    db 00111100b
    db 01011010b

    db 00011000b
    db 00111100b
    db 01111110b
    db 11011011b

    db 00111100b
    db 01000010b
    db 11000001b
    db 10000001b

    dw 0FFFFh
    dw 0FFFFh
    db 70
    dw 230Ah
    db 20h
    db 0FBh
    dw 18
    db 1

times 510-($-$$) db 0
dw 0AA55h
