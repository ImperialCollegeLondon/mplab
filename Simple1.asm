	#include p18f87k22.inc
	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100
	
start
	
	movlw	0xff		    ; all bits in
	movwf	TRISD, A	    ; Port D Direction Register
	bsf	PADCFG1,RDPU, A	    ; Turn on pull-ups for Port D
	
	movlw	0x00
	movwf	0x20, ACCESS
	
	movlw	0x00
	movwf	0x21, ACCESS
	
	movlw	0x04
	movwf	0x31, ACCESS ; two stored for the delay itself
	movwf	0x30, ACCESS ; two stored to update the loop counter
	
	;movlw	0x02
	;movwf	0x31, ACCESS
	

	
	movlw 	0x0
	movwf	TRISC, ACCESS	    ; Port C all outputs
	bra 	test
loop	movff 	0x06, PORTC
	call	delay
	incf 	0x06, W, ACCESS
	
test	movwf	0x06, ACCESS	     ; Test for end of loop condition
;	movlw 	0x63
	movf	PORTD, W, ACCESS    ;
	cpfsgt 	0x06, ACCESS
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start
	
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
