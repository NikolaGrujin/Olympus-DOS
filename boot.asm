ORG 0x7C00
BITS 16
CPU 386

	jmp boot	; Skip BPB and EBPB
	nop		; NOP for padding

BPB:
OEM_identif db "olympus",0
bytes_p_sec dw 512
sect_p_clus db 2
res_sectors dw 2
num_of_FATs db 1
root_entrys dw 1
total_sects dw 2880
media_descr db 0xF9
sects_p_fat dw 2
sec_p_track dw 18
drive_heads dw 2
hiddn_sects dd 0
lrg_sect_ct dd 2880

EBPB:
drive_numbr db 0
winnt_flags db 0
signature   db 0x28
volumeID    db "69696969"
volum_label db "Olympus   ",0
sys_identif db "FAT12  ",0

tries db 0
boot:
	clc		; Clear carry flag
	sti		; Enable interrupts	

	mov ax,0	; Clear AX
	mov es,ax	; Set buffer segment
	
	mov ss,ax	; Set stack segment
	mov sp,0x79FE	; Set stack pointer	

	mov ah,0x02	; Read Sectors from Drive function
	mov al,1	; Read 1 sector
	mov bx,0x7E00	; Set buffer offset
	mov ch,0	; Cylinder 0
	mov cl,2	; Sector 2
	mov dh,0	; Head 0
	mov dl,0	; Drive 0 / First floppy drive
	int 0x13	; Call BIOS disk service
	jc .error	; If errored, jump to error handler

	mov ah,0		; Init Drive function
	mov dl,0		; Drive number
	call 0x000:0x7E00	; Call Apollo
	
	mov ax,0		; Buffer segment in AX
	mov es,ax		; Buffer segment	
	mov ah,1		; Read from Drive function
	mov al,1		; Read 1 sector
	mov bx,2		; LBA 2 (Sector 3)
	mov dx,0		; Clear DX
	mov di,0x8000		; Buffer offset
	call 0x000:0x7E00	; Call Apollo
	
	hlt		; Wait for read to complete
	
	jmp 0x000:0x8000	; Jump to Zeus

.error:
	cmp BYTE [tries],5	; Check if retried 5 times
	je .fail		; If so, fail and halt
	inc BYTE [tries]	; Increment try counter
	
	mov cl,ah	; Store status
	mov al,cl	; Get status
	mov ah,0	; Clear AH
	mov bl,16	; Store divisor in BL
	div bl		; Divide AX by 16
	mov bx,0	; Clear BX
	add al,'0'	; AX / 16 + '0' = ASCII of first digit
	sub cl,ah	; status - AX % 16 = status - first digit
	mov ah,0x0E	; Teletype Print function
	int 0x10	; Call BIOS video service
	mov al,cl	; Get status
	mov ah,0	; Clear AH
	mov bl,16	; Store divisor in BL
	div bl		; Divide AX by 16
	mov bx,0	; Clear BX
	add al,'0'	; AX / 16 + '0' = ASCII of first digit
	mov ah,0x0E	; Teletype Print function
	int 0x10	; Call BIOS video service
	mov al,10	; New line
	int 0x10	; Call BIOS video service
	mov al,13	; Carriage return
	int 0x10	; Call BIOS video service
	
	clc		; Clear carry flag

	mov ah,0	; Reset Drive function
	int 0x13	; Call BIOS disk service
	jc .error	; If errored, jump to error handler
	
	jmp boot	; Retry boot
.fail:
	mov ah,0x0E	; Teletype Print function
	mov al,'F'	; 'F' for "Failed"
	int 0x10	; Call BIOS video service

	hlt		; Halt CPU
	
	jmp $		; Infinite loop
	
	times 510-($-$$) db 0	; Padding
	dw 0x55AA		; Magic number
