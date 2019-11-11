#include p18f87k22.inc
	
	
	global	DAC_setup, DAC_stop
acs0	udata_acs   ; reserve data space in access ram
delay_count res 1   ; reserve one byte for counter in the delay routine
	
int_hi	code	0x0008 ; high vector, no low vector
	btfss	INTCON,TMR0IF ; check that this is timer0 interrupt
	retfie	FAST ; if not then return
	;movlw	0x10
	;addwf	LATD, 1, 0
	incf	LATD ; increment PORTD
	;incf	LATD ; increment PORTD
	;incf	LATD ; increment PORTD
	movlw	0x00
	movwf	PORTE
	;call	delay
	movlw	0x01
	movwf	PORTE
	;call	delay
	bcf	INTCON,TMR0IF ; clear interrupt flag
	retfie	FAST ; fast return from interrupt
    
DAC code
 
DAC_setup
	clrf	TRISD ; Set PORTD as all outputs
	clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	clrf	PORTE ; Clear PORTE outputs
	movlw	b'11001000' ; Set timer0 to 8-bit, Fosc/4/256
	movwf	T0CON ; = 500KHz clock rate, approx 1sec rollover
	bsf	INTCON,TMR0IE ; Enable timer0 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	return

DAC_stop    
	movlw	b'01001000' ; Set timer0 to 16-bit, Fosc/4/256
	movwf	T0CON ; = 500KHz clock rate, approx 1sec rollover
	bcf	INTCON,TMR0IE ; Enable timer0 interrupt
	bcf	INTCON,GIE ; Enable all interrupts
	return
	
delay	decfsz	delay_count	; decrement until zero
	bra delay
	return

	end