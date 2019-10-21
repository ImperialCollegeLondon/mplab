

	#include p18f87k22.inc
	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100
	
start
	banksel PADCFG1
	bsf	PADCFG1,REPU, BANKED	    ; Turn on pull-ups for Port E
	clrf	LATE
	
	call	sdelay
	
	movlw	0x0f	    ; R4-R7 high - inputd
	movwf	TRISE, A	    ; Port E Direction Register
	
	call	sdelay
	
	;movlw   0xf0
	;movwf   PORTE, A
	
delay	call	sdelay
	decfsz	0x31 ; decrement until zero 
	bra	delay
	movff	0x30, 0x31
	;movlw	0x02
	;movwf	0x31
	
	return
	
sdelay	call	ssdelay
	decfsz	0x21 ; decrement until zero 
	bra	sdelay
	return
	
ssdelay decfsz	0x20 ; decrement until zero 
	bra	ssdelay
	return	

	end