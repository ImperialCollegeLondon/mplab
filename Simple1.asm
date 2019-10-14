	#include p18f87k22.inc
	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100
	
start
	
	;movlw	0xff		    ; all bits in
	;movwf	TRISD, A	    ; Port D Direction Register
	;bsf	PADCFG1, RDPU, A	    ; Turn on pull-ups for Port D
	;Setting port D as outup only
	movlw 	0x0
	movwf	TRISD, ACCESS	    ; Port D all outputs
	
	clrf	TRISC
	clrf	TRISH
	
	banksel PADCFG1 ; PADCFG1 is not in Access Bank!! 
	bsf	PADCFG1, REPU, BANKED ; PortE pull-ups on 
	movlb	0x00 ; set BSR back to Bank 0 
	setf	TRISE ; Tri-state PortE

	movlw	0x00
	movwf	0x20, ACCESS
	
	movlw	0x00
	movwf	0x21, ACCESS
	
	movlw	0x04
	movwf	0x31, ACCESS ; num stored for the delay itself
	movwf	0x30, ACCESS ; num stored to update the loop counter
	
	movlw	0x01
	movwf	PORTD, ACCESS
	
	;call	write1
	call	read1
	
	;call	write2
	;call	read2
	
endprogram
	nop
	bra endprogram
	
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
	
write1	movlw	.17
	movwf	PORTD, ACCESS ; OE1 high, OE2 high, rest low
	clrf	TRISE
	movlw	.3 ;  just a number to write to 1
	movwf	PORTE, ACCESS
	call	sdelay
	movlw	.19 ; OE1 high, OE2 high, Clock1 high
	movwf	PORTD, ACCESS
	call	sdelay
	setf	TRISE
	
	return
	
read1	movlw	.16
	movwf	PORTD, ACCESS ; OE2 high, rest low
	setf	TRISE
	movf	PORTE, W
	movwf	PORTH
	call	sdelay
	
write2	movlw	.17
	movwf	PORTD, ACCESS ; OE1 high, OE2 high, rest low
	clrf	TRISE
	movlw	.13 ;  just a number to write to 2
	movwf	PORTE, ACCESS
	call	sdelay
	movlw	.25
	movwf	PORTD, ACCESS ; OE1 high, OE2 high, clock2 high
	call	sdelay
	movlw	.16
	movwf	PORTD, ACCESS ; OE2 high, rest low
	setf	TRISE
	
	return
	
read2	movlw	.1
	movwf	PORTD, ACCESS ; OE1 high, rest low
	setf	TRISE
	movf	PORTE, W
	movwf	PORTC
	call	sdelay
	
	return
	
	end
