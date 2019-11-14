#include p18f87k22.inc
	
	
	global	DAC_A, DAC_stop, DAC_F_s, DAC_D, DAC_E, TMR0_Op, TMR0_setup, TMR0_Nop, state_init, state_check
acs0	udata_acs   ; reserve data space in access ram
delay_count 
	res 1   ; reserve one byte for counter in the delay routine
nc	res 1	; stores note code
oo	res 1	; stores on/off instruction
counter	res 1
state	res 1
chng	res 1
	
tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
seq_array
	res 	    .80	;reserve 80 bytes
	constant    len_seq=.80
	
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
 
TMR0_setup
	movlw	b'01001000'
	movwf	T0CON ;timeroff, 8bit counter, int. clock low-to-high, no prescaler
	bcf	INTCON, TMR0IE ; disable interrupt timer0
	return

TMR0_Op
	bsf	T0CON, TMR0ON ; turn on timer0
	lfsr	FSR0, seq_array ; point fsr- to the beginning of the seq_aray
	return

TMR0_Nop
	bcf	T0CON, TMR0ON ; turn off timer0
	clrf	TMR0
	return

	
state_init
	movff	PORTJ, state
	return
	
state_check
	movf	PORTJ, W
	cpfseq	state ;compares values of PORTJ (current state) to state (most recent state)
	goto	neq ;if values not equal go to neq to investigate
	return
	
neq	; IF THERE WAS A CHANGE OF STATE
	; ~state & portj
	comf	state, 0 ; NOT state is now in W
	andwf	PORTJ, 0 ; should tell us which bits went 0->1	
	movwf	chng
	btfsc	chng, 7 ; if note A is on, do the thing
	call	DAC_A
	btfsc	chng, 6 ; if note F_s is on, do the thing
	call	DAC_F_s
	btfsc	chng, 5 ; if note E is on, do the thing
	call	DAC_E
	btfsc	chng, 4 ; if note D is on, do the thing
	call	DAC_D
	
	; state & ~portj
	comf	PORTJ, 0
	andwf	state, 0    ; should tell us which bits went 1->0
	movwf	chng
	btfsc	chng, 7 ; if note A is off, do the thing
	call	DAC_A_off
	btfsc	chng, 6 ; if note F_s is off, do the thing
	call	DAC_F_s_off
	btfsc	chng, 5 ; if note E is off, do the thing
	call	DAC_E_off
	btfsc	chng, 4 ; if note D is off, do the thing
	call	DAC_D_off
	
	call	state_init
	
	return
	
write_action
	;load 'note code' into 'nc', 'on/off' into 'oo' before calling
	movf	oo, W
	addwf	nc, f ; now temp_1 has upper nibble as 'on intruction' and lower nibble as 'note code'
	; load the array
	movff	nc, POSTINC0
	movff	TMR0, POSTINC0
	return

clr_seq
	lfsr	FSR0, seq_array
	movff	len_seq, counter
loop	clrf	POSTINC0
	decfsz	counter
	goto	loop
	return
	
DAC_A
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.141 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	; at this point we want to write the time signature from tmr0 and the 
	; note info into the array seq_array
	; need a subroutine
	movlw	0x01 ; suppose thats note code for A
	movwf	nc
	movlw	0xf0
	movwf	oo
	call	write_action
	return
	
DAC_A_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x01 ; suppose thats note code for A
	movwf	nc
	movlw	0x00
	movwf	oo
	call	write_action
	return

DAC_F_s
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.169 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	movlw	0x02 ; suppose thats note code for F_s
	movwf	nc
	movlw	0xf0
	movwf	oo
	call	write_action
	return
	
DAC_F_s_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x02 ; suppose thats note code for A
	movwf	nc
	movlw	0x00
	movwf	oo
	call	write_action
	return
	
DAC_E
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.190 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	movlw	0x03 ; suppose thats note code for F_s
	movwf	nc
	movlw	0xf0
	movwf	oo
	call	write_action
	return
	
DAC_E_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x03 ; suppose thats note code for A
	movwf	nc
	movlw	0x00
	movwf	oo
	call	write_action
	return
	
DAC_D
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.213 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	movlw	0x04 ; suppose thats note code for F_s
	movwf	nc
	movlw	0xf0
	movwf	oo
	call	write_action
	return

DAC_D_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x04 ; suppose thats note code for A
	movwf	nc
	movlw	0x00
	movwf	oo
	call	write_action
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
