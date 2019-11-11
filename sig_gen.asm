#include p18f87k22.inc
	
	
	global	DAC_setup, DAC_stop, DAC_setup_2
acs0	udata_acs   ; reserve data space in access ram
delay_count res 1   ; reserve one byte for counter in the delay routine
	
int_hi	code	0x0008 ; high vector, no low vector
	btfss	PIR1,TMR2IF ; check that this is timer2 interrupt
	retfie	FAST ; if not then return
	;movlw	0x10
	;addwf	LATD, 1, 0
	incf	LATD ; increment PORTD
	;movlw	0x00
	;movwf	PORTE
	;call	delay
	;movlw	0x01
	;movwf	PORTE
	;call	delay
	bcf	PIR1,TMR2IF ; clear timer2 interrupt flag
	retfie	FAST ; fast return from interrupt
    
DAC code
 
DAC_setup
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	0x10
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	return

DAC_setup_2
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	0x40
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	return

DAC_stop  
	bcf	T2CON, TMR2ON ; turn off timer 2
	;movlw	b'01001000' ; TURN TIMER0 OFF
	;movwf	T0CON 
	;bcf	INTCON,TMR0IE ; disable timer0 interrupt
	;bcf	INTCON,GIE ; disable all interrupts
	return
	
delay	decfsz	delay_count	; decrement until zero
	bra delay
	return

	end
