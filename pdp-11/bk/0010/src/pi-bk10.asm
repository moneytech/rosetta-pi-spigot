;for macro-11 assembler
;it calculates pi-number using the next C-algorithm
;https://crypto.stanford.edu/pbc/notes/pi/code.html

;#include <stdio.h>
;#define N 2800
;main() {
;   long r[N + 1], i, k, b, c;
;   c = 0;
;   for (i = 0; i < N; i++)
;      r[i] = 2000;
;   for (k = N; k > 0; k -= 14) {
;      d = 0;
;      i = k;
;      for(;;) {
;         d += r[i]*10000;
;         b = i*2 - 1;
;         r[i] = d%b;
;         d /= b;
;         i--;
;         if (i == 0) break;
;         d *= i;
;      }
;      printf("%.4d", (int)(c + d/10000));
;      c = d%10000;
;   }
;}

;the time of the calculation is quadratic, so if T is time to calculate N digits
;then 4*T is required to calculate 2*N digits

      .radix 10
      .dsabl gbl

HMUL = 0  ;hardware multiplication, 0 - no

;N = 10500   ;3000 digits
;N = 3500   ;1000 digits
N = 350   ;100 digits
;N = 2800  ;800 digits

kv = kvs + 2
 
timerport1 = ^O177706            ;$ffc6
timerport2 = ^O177710            ;$ffc8
timerport3 = ^O177712            ;$ffca

.macro div0 ?l0
     asl r2
     rol r3
     cmp r3,r1
     bcs l0

     sub r1,r3
     inc r2
l0:
     .endm

.macro div32x16 ?div32 ?exit ;R4:R2 = R3:R2/R1, R3 = R3:R2%R1, used: R0, R1 not changed
                             ;may work wrong if R1>$7fff
     cmp r3,r1
     bcc div32

     .rept 16
     div0
     .endm
     clr r4
     jmp @#exit

OPT = 3         ;use 3 if N<=14000, limits R3 to 0x1f'ff'ff'ff
div32:
     mov r2,r0

     .rept OPT
     asl r3
     .endm

     mov r3,r2
     clr r3

     .rept 16-OPT
     div0
     .endm

     mov r2,r4
     mov r0,r2

     .rept 16
     div0
     .endm
exit:
     .endm

         .asect
         .=512
start:   mov #12,r0    ;clear screen
         emt ^O16
         mov #21,r1
         clr r2
         emt ^O24
         mov #msg1,r1
         mov #127,r2
         emt ^O20

         mov #9,r1
         mov #1,r2
         emt ^O24
         mov #msg2,r1
         mov #127,r2
         emt ^O20
restart: call @#getnum
         mov #10,r0
         emt ^O16

         mov r2,r4
         add #3,r4
         bic #3,r4
         cmp r2,r4
         beq 7$

         mov r4,r2
         call @#PR0000
         mov #msg3,r1
         mov #127,r2
         emt ^O20

7$:      asr r4
         mov r4,r0
         asl r0
         add r0,r4
         asl r0
         add r0,r4   ;r4 <- r4/2*7
         mov r4,@#kv
         inc r4
         mov r4,@#100$+2

         clr @#time
         clr @#time+2
         mov #^B110010,@#timerport3    ;sets timer, /16
         mov @#timerport2,@#prevtime
         mtps #128
100$:    mov #N+1,r0   ;fill r-array
         mov #2000,r1
         mov #ra,r2
1$:      mov r1,(r2)+
         sob r0,1$

         clr @#cv
mloop:   clr r5       ;d <- 0
         clr sp

kvs:     mov #0,r1
         asl r1       ;i <- 2k
ivs:

.if eq HMUL
         mov ra(r1),r0     ;r[i]
         clr r4         ;r[i]*10000
         ror r0         ;check the previous CF!
         ror r4
         asr r0
         ror r4
         asr r0
         ror r4
         mov r4,r2
         mov r0,r3
         asr r0
         ror r4
         asr r0
         ror r4
         asr r0
         ror r4
         add r4,r2
         adc r3
         add r0,r3
         asr r0
         ror r4
         add r4,r2
         adc r3
         add r0,r3
         asr r0
         ror r4
         add r4,r2
         adc r3
         add r0,r3
         asr r0
         ror r4
         asr r0
         ror r4
         asr r0
         ror r4
         asr r0
         ror r4
         add r4,r2
         adc r3
         add r0,r3

         add r5,r2
         mov r2,r5
.iff
         mov #10000,r2
         mul ra(r1),r2
         add r3,r5
         mov r2,r3
         mov r5,r2
.endc
         adc r3
         add r3,sp
         mov sp,r3

         dec r1          ;b <- 2*i-1
         div32x16
         mov r3,ra+1(r1)      ;r[i] <- d%b
         dec r1        ;i <- i - 1
         beq 4$

         add r3,r2       ;d <- d/b*i
         adc r4
         sub r2,r5
         sbc sp
         sub r4,sp
         ror sp
         ror r5
         jmp @#ivs

4$:      mov #512,sp
         mov r4,r3
         mov #10000,r1
         call @#div32x16s
         add @#cv,r2     ;c + d/10000
         mov r3,@#cv     ;c <- d%10000
         call @#PR0000
         mov @#timerport2,r1
         mov @#prevtime,r3
         sub r1,r3
         mov r1,@#prevtime
         add r3,@#time
         adc @#time+2
         sub #14,@#kv      ;k <- k - 14
         beq 5$
         jmp @#mloop

5$:      mov #32,r0
         emt ^O16
         mov @#time,r2
         mov @#time+2,r3
         asl r2     ;*100
         rol r3
         asl r2
         rol r3
         add @#time,r2
         adc r3
         add @#time+2,r3
         mov r3,-(sp)
         mov r2,-(sp)
         asl r2
         rol r3
         asl r2
         rol r3
         add (sp)+,r2
         adc r3
         add (sp)+,r3
         asl r2
         rol r3
         asl r2
         rol r3

         mov #1465,r1             ;3 MHz,3000000/16/128
         call @#div32x16s
         call @#printsec
         mov #msg4,r1
         mov #127,r2
         emt ^O20
         mtps #0
         jmp @#restart

div32x16s: ;R1:R2 = R3:R2/R1, R3 = R3:R2%R1, used: R0,R4
           ;compact form - 64 bytes
                             ;may work wrong if R1>$7fff
     cmp r3,r1
     bcc 32$

     call @#3$
     clr r1
     return

32$: mov r2,r0
     mov r3,r2
     clr r3
     call @#3$
     mov r2,r4
     mov r0,r2
     call @#3$
     mov r4,r1
     return

3$:  call @#.+4
     call @#.+4
     call @#.+4
     call @#.+4
     asl r2
     rol r3
     cmp r3,r1
     bcs 0$

     sub r1,r3
     inc r2
0$:  return

PR0000:     ;prints r2
        mov #1000,r3
	CALL @#0$
        mov #100,r3
	CALL @#0$
        mov #10,r3
	CALL @#0$
	mov r2,r0
2$:	add #48,r0
   	emt ^O16
        return

0$:	mov #65535,r0
4$:	inc r0
	cmp r2,r3
	bcs 2$

	sub r3,r2
	br 4$

printsec:  ;prints R1:R2/100
        clr r4
        mov #1,r5 
        mov #34464,r3  ;100000-65536
        call @#0$
        clr r5 
        mov #10000,r3
        call @#0$
        mov #1000,r3
        call @#0$
        inc r4
        mov #100,r3
        call @#0$
        movb #'.,r0
        emt ^O16
        mov #10,r3
        call @#0$
        mov r2,r0
2$:     add #48,r0
        emt ^O16
        inc r4
5$:     return

7$:     tst r4
        bne 2$

        tst r0
        beq 5$

        inc r4
        br 2$

0$:     mov #65535,r0
4$:	inc r0
        cmp r1,r5
        bcs 7$
        bne 8$

	cmp r2,r3
	bcs 7$

8$:     sub r3,r2
        sbc r1
        sub r5,r1
	br 4$

getnum: clr r1    ;length
        clr r2    ;number
0$:     emt 6
        cmp #10,r0
        beq 5$

        cmp #24,r0
        beq 1$

        cmp #47,r0
        bcc 0$

        cmp #48+9,r0
        bcs 0$

        cmp #4,r1
        beq 0$

        mov r2,-(sp)
        emt ^O16
        inc r1
        sub #48,r0
        mov r2,r3
        asl r3
        asl r3
        add r3,r2
        asl r2
        add r0,r2
        br 0$

1$:     tst r1
        beq 0$

        dec r1
        emt ^O16

        mov (sp)+,r2
        br 0$

5$:     tst r1
        beq 0$

        cmp #2056,r2   ;(end of memory minus end of program)/7 and down to the multiple of 4
        bcs 0$

        mov r1,r3
8$:     mov (sp)+,r0
        sob r3,8$
        return

cv: .word 0
time: .word 0,0
prevtime: .word 0
msg1: .ascii "number "
      .byte 160
      .ascii " calculator v2"
      .byte 10,0
msg2: .ascii "  it may give 2000 digits in about an hour!"
msg4: .byte 10,10
      .asciz "number of digits (up to 2056)? "
msg3: .ascii " digits will be printed"
      .byte 10,0

ra: .word 0