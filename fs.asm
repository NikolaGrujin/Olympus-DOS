ORG 0x7E00
BITS 16
CPU 386

; Apollo - the god of knowledge and oracles
; Disk driver
; 
; Functions:
; 
; Init drive
; AH = 0x00
; DL = [drive number]
; returns
; AH = [disk status code]
; CF = [carry flag set on error]
;
; Read from drive
; AH = 0x01
; AL = [number of sectors to read]
; DX:BX = [LBA address]
; ES:DI	= [buffer address]
; returns
; [filled buffer at ES:DI]
; AH = [disk status code]
; CF = [carry flag set on error]
;
; Write to drive
; AH = 0x02
; AL = [number of sectors to read]
; DX:BX = [LBA address]
; ES:DI = [buffer address]
; returns
; [filled sectors at LBA in DX:BX]
; AH = [disk status code]
; CF = [carry flag set on error]

Apollo:
	cmp ah,0	; Check function code
	je init		; Init drive function
	cmp ah,1	; Check function code
	je readwrite	; Read from drive function
	cmp ah,2	; Check function code
	je readwrite	; Write to drive function
	ret		; If there is no function match, return

s_per_t dw 0		; Sectors per track
sectors db 0		; Sectors to read/write
head_ct	db 0		; Head count
drive_n db 0		; Drive number

; LBA to CHS convertor
lba2chs:
	div WORD [s_per_t]; LBA (DX:AX) / sectors per track
	inc dl		; Get sector number
	mov cl,dl	; Move sector number to CL
	div BYTE [head_ct]; (LBA / sectors per track) / num of heads
	mov dh,ah	; Move head number to DH
	mov ch,al	; Move cylinder number to CH
	ret		; Return

; Init drive
init:
	mov [drive_n],dl; Store drive number
	clc		; Clear carry flag
	int 0x13	; Call BIOS disk service, reset disk
	jnc pstrst	; If no error, continue init
	mov ah,0x0E
	mov al,'E'
	int 0x10
	mov al,'I'
	int 0x10
	ret		; Otherwise, return early

pstrst:
	cmp dl,0x80	; Check drive number
	jl flpgeo	; If floppy selected, skip getting geometry
	
	mov ah,0x08	; Get Drive Params function
	int 0x13	; Call BIOS disk service
	inc dh		; Increment head count, from 0 to 1-based
	mov [head_ct],dh; Store head count
	and cl,0x3F	; AND CL with 0011 1111
	mov [s_per_t],cl; Store sectors per track
	ret		; Return from Apollo

flpgeo:		; 1.44MB floppy geometry
	mov WORD [s_per_t],18; 18 sectors per track
	mov BYTE [head_ct],2; 2 heads
	ret		; Return from Apollo

; Read from/Write to drive
readwrite:
	inc ah		; Increment AH to get function code
	push ax		; Push AX to the stack
	mov ax,bx	; Move LBA low to AX
	mov bx,di	; Move buffer offset to BX
	call lba2chs	; Convert LBA to CHS
	pop ax		; Pop AX to set function and sector count
	mov dl,[drive_n]; Restore drive number
	int 0x13	; Call BIOS disk service
	ret		; Return from Apollo

	times 512-($-$$) db 0	; Padding and/or size constrainer

res_sec db 0xFF7

	times 1536-($-$$) db 0	; Padidng
