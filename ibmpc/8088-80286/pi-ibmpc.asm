;for fasm assembler
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


;N = 3500   ;1000 digits
N = 2800  ;800 digits

macro div32x16 { ;BX:AX = DX:AX/SI, DX = DX:AX%SI, used: cx
local .div32, .exitdiv
     cmp dx,si
     jc .div32

     mov cx,ax
     mov ax,dx
     xor dx,dx
     div si
     xchg ax,cx
     div si
     mov bx,cx
     jmp .exitdiv

.div32:
     div si
     xor BX,BX
.exitdiv:
}

         use16
         org 100h

start:
         ;cli         ;no interrupts
         mov dx,msg1
         mov ah,9
         int 21h

         call getnum
         mov dx,msg2
         mov ah,9
         int 21h

         mov ax,bp
         add ax,3
         and ax,0xfffc
         cmp ax,bp
         je .l7

         push ax
         mov cx,ax
         call PR0000
         mov dx,msg3
         mov ah,9
         int 21h
         pop ax

.l7:     shr ax,1
         mov bx,7
         mul bx
         mov [.m101+4],ax
         inc ax
         mov [.m100+1],ax

         xor ax,ax
         push ax
         pop es
         mov ax,[es:46ch]
         mov [time],ax
         mov ax,[es:46eh]
         mov [time+2],ax

         push ds
         pop es
.m100:   mov cx,N+1   ;fill r-array
         mov ax,2000
         mov di,ra
         rep stosw

         mov [cv],cx
.m101:   mov [kv],N

.l0:     xor bp,bp
         mov di,bp          ;d = BP:DI <- 0

         mov si,[kv]
         add si,si       ;i <-k*2
.l2:     mov ax,[si+ra]     ; r[i]
         mov cx,10000    ;r[i]*10000, mul16x16
         mul cx
         add ax,di
         mov di,ax
         adc dx,bp
         mov bp,dx

         dec si        ;b <- 2*i-1
         div32x16
         mov [si+ra+1],dx   ;r[i] <- d%b
         dec si      ;i <- i - 1
         je .l4

         sub di,dx
         sbb bp,0
         sub di,ax
         sbb bp,bx
         shr bp,1
         rcr di,1
         jmp .l2

.l4:     mov dx,bx
         mov si,10000
         div si
         add ax,[cv]  ;c + d/10000
         mov [cv],dx     ;c <- d%10000
         mov cx,ax
         call PR0000
         sub [kv],14      ;k <- k - 14
         ;je .l5        ;it is not for 80386!
         ;jmp .l0
         jne .l0

.l5:     mov dl,' '
         call PR0000.le

         xor ax,ax
         mov es,ax
         mov bx,[es:46ch]
         sub bx,[time]
         mov ax,[es:46eh]
         sbb ax,[time+2]
         mov di,10000
         mul di
         mov si,ax
         mov ax,bx
         mul di
         add dx,si
         mov si,1821
         div32x16
         shl dx,1
         cmp si,dx
         adc ax,0
         mov dx,bx
         mov di,string
         mov si,10
         div32x16
         mov [di],dl
         inc di
         mov dx,bx
         div si
         mov [di],dl
         inc di
         xor dx,dx
         mov byte [di],'.'-'0'
         inc di
.l12:    or ax,ax
         jz .l11

         div si
         mov [di],dl
         inc di
         xor dx,dx
         jmp .l12

.l11:    dec di
         mov dl,[di]
         call PR0000.l2
         cmp di,string
         jne .l11
         ;sti
         int 20h

PR0000:     ;prints cx
        mov bx,1000
	CALL .l0
        mov bx,100
	CALL .l0
        mov bx,10
	CALL .l0
	mov dl,cl
.l2:	add dl,'0'
.le:    mov ah,2
   	int 21h
        retn

.l0:    mov dl,0ffh
.l4:	inc dl
        mov bp,cx
	sub cx,bx
	jnc .l4

	mov cx,bp
	jmp .l2

getnum: xor cx,cx    ;length
        xor bp,bp    ;number
.l0:    xor ah,ah
        int 16h 
        cmp al,13
        je .l5

        cmp al,8
        je .l1

        cmp al,'0'
        jc .l0

        cmp al,'9'+1
        jnc .l0

        cmp cl,4
        je .l0

        push bp
        mov dl,al
        mov ah,2
        int 21h
        inc cx
        xor dh,dh
        sub dl,'0'
        mov bx,dx
        mov ax,10
        mul bp
        mov bp,ax
        add bp,bx
        jmp .l0

.l1:    jcxz .l0
        dec cx
        mov dx,del
        mov ah,9
        int 21h

        pop bp
        jmp .l0

.l5:    jcxz .l0

        cmp bp,9232+1
        jnc .l0

.l8:    pop ax
        loop .l8
        retn

string rb 6
msg1  db 'number ',227,' calculator v2',13,10
      db 'it may give 9000 digits in less than an hour with the first IBM PC of 1981!'
      db 13,10,'number of digits (up to 9232)? $'
msg3  db ' digits will be printed'
msg2  db 13,10,'$'
del   db 8,' ',8,'$'

        align 2
cv  dw 0
kv  dw 0
time dw 0,0
ra  dw 0
