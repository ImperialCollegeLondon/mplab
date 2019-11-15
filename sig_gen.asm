#include p18f87k22.inc
	
	
	global	DAC_A, DAC_stop, DAC_F_s, DAC_D, DAC_E, TMR0_Op, TMR0_setup, TMR0_Nop, state_init, state_check, play, clr_seq, rec_on
acs0	udata_acs   ; reserve data space in access ram
delay_count 
	res 1   ; reserve one byte for counter in the delay routine
nc	res 1	; stores note code
oo	res 1	; stores on/off instruction
counter	res 1
dylen	res 1
dylen_cnt
	res 1
tmr0_cnt   
	res 1
state	res 1
chng	res 1
Command	res 1
TimeL	res 1
TimeH	res 1
TimeC	res 1
Note	res 1
	
tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
seq_array
	res 	    .120	;reserve 120 bytes
	constant    len_seq=.120 ; 1/3 of the array, because 3 bytes per command
	
int_hi	code	0x0008 ; high vector, no low vector
	btfsc	PIR1,TMR2IF ; check if that this is timer2 interrupt
	goto	tmr2
	btfsc	INTCON, TMR0IF ; check if that this is timer0 interrupt
	goto	tmr0
	retfie	FAST ; if not then return
tmr2	incf	LATD ; increment PORTD
	bcf	PIR1,TMR2IF ; clear timer2 interrupt flag
	retfie	FAST ; fast return from interrupt
tmr0	incf	tmr0_cnt
	bcf	INTCON, TMR0IF ;  clear tmr0 interrupt flag
	retfie	FAST
    
DAC code
 
TMR0_setup
	movlw	b'00000011' ; in 16 bit mode MUST read low first!!!
	movwf	T0CON ;timeroff, 8bit counter, int. clock low-to-high, supposedly 1:256 prescaler
	bsf	INTCON, TMR0IE ; enable interrupt timer0
	return

TMR0_Op
	btfsc	T0CON, TMR0ON ;if clear, needs to be turned on so skip line
	return
	bsf	T0CON, TMR0ON ; turn on timer0 if was off
	clrf	tmr0_cnt
	clrf	TMR0
	return

TMR0_Nop
	btfss	T0CON, TMR0ON ;if set, needs to be turned off so skip line
	return
	bcf	T0CON, TMR0ON ; turn off timer0
	clrf	TMR0
	clrf	tmr0_cnt
	movff	dylen_cnt, dylen
	return
	
	
rec_on
	btfsc	T0CON, TMR0ON ;if clear, needs to be turned on so skip line
	return
	call	TMR0_Op
	clrf	dylen_cnt
	call	state_init
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
	btfsc	chng, 7 ; if note B is on, do the thing
	call	DAC_B
	btfsc	chng, 6 ; if note A is on, do the thing
	call	DAC_A
	btfsc	chng, 5 ; if note G_s is on, do the thing
	call	DAC_G_s
	btfsc	chng, 4 ; if note F_s is on, do the thing
	call	DAC_F_s
	btfsc	chng, 3 ; if note F is on, do the thing
	call	DAC_F
	btfsc	chng, 2 ; if note E is on, do the thing
	call	DAC_E
	btfsc	chng, 1 ; if note D is on, do the thing
	call	DAC_D
	;btfsc	chng, 0 ; if 0 went on, play
	;call	play
	
	; state & ~portj
	comf	PORTJ, 0
	andwf	state, 0    ; should tell us which bits went 1->0
	movwf	chng
	btfsc	chng, 7 ; if note B is off, do the thing
	call	DAC_B_off
	btfsc	chng, 6 ; if note A is off, do the thing
	call	DAC_A_off
	btfsc	chng, 5 ; if note G_s is off, do the thing
	call	DAC_G_s_off
	btfsc	chng, 4 ; if note F_s is off, do the thing
	call	DAC_F_s_off
	btfsc	chng, 3 ; if note F is off, do the thing
	call	DAC_F_off
	btfsc	chng, 2 ; if note E is off, do the thing
	call	DAC_E_off
	btfsc	chng, 1 ; if note D is off, do the thing
	call	DAC_D_off
	
	call	state_init
	
	return
	
write_action
	;load 'note code' into 'nc', 'on/off' into 'oo' before calling
	;movf	oo, W
	;addwf	nc, f ; now temp_1 has upper nibble as 'on/off intruction' and lower nibble as 'note code'
	; load the array
	btfss	PORTE, RE0
	return
	movff	nc, POSTINC0
	movff	tmr0_cnt, POSTINC0
	movf	TMR0L, W
	;movff	TMR0L, POSTINC0
L1:	
	;disable global interrupts
	;copy TMR0H to temporary register (w)
	;copy counter 
	;check timer interrupt flag
	;if set: enable interrupt and goto L1
	
	;enable interripts
	
	
	movff	TMR0H, POSTINC0
	incf	dylen_cnt
	
	return

clr_seq
	lfsr	FSR0, seq_array
	movff	len_seq, counter
loop	clrf	POSTINC0
	decfsz	counter
	goto	loop
	lfsr	FSR0, seq_array ; point fsr- to the beginning of the seq_aray
	return

DAC_B
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.126 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	; at this point we want to write the time signature from tmr0 and the 
	; note info into the array seq_array
	; need a subroutine
	movlw	0xf1 ; suppose thats note code for B
	movwf	nc
	;movlw	0xf0
	;movwf	oo
	call	write_action
	return
	
DAC_B_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x01 ; suppose thats note code for B
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
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
	movlw	0xf2 ; suppose thats note code for A
	movwf	nc
	;movlw	0xf0
	;movwf	oo
	call	write_action
	return
	
DAC_A_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x02 ; suppose thats note code for A
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
	return

DAC_G_s
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.150 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	; at this point we want to write the time signature from tmr0 and the 
	; note info into the array seq_array
	; need a subroutine
	movlw	0xf3 ; suppose thats note code for G_s
	movwf	nc
	;movlw	0xf0
	;movwf	oo
	call	write_action
	return
	
DAC_G_s_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x03 ; suppose thats note code for G_s
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
	return

DAC_F_s
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.168 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	; at this point we want to write the time signature from tmr0 and the 
	; note info into the array seq_array
	; need a subroutine
	movlw	0xf4 ; suppose thats note code for F_s
	movwf	nc
	;movlw	0xf0
	;movwf	oo
	call	write_action
	return
	
DAC_F_s_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x04 ; suppose thats note code for F_s
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
	return
DAC_F
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.178 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	movlw	0xf5 ; suppose thats note code for F
	movwf	nc
	;movlw	0xF0
	;movwf	oo
	call	write_action
	return
	
DAC_F_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x05 ; suppose thats note code for F
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
	return
	
DAC_E
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.188 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	movlw	0xf6 ; suppose thats note code for E
	movwf	nc
	;movlw	0xf0
	;movwf	oo
	call	write_action
	return
	
DAC_E_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x06 ; suppose thats note code for E
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
	return
	
DAC_D
	clrf	TRISD ; Set PORTD as all outputs
	;clrf	TRISE
	clrf	LATD ; Clear PORTD outputs
	;clrf	PORTE ; Clear PORTE outputs -- dont need port e anymore
	movlw	b'00000100' ; Set timer2 to 8-bit, prescaler 1:1, postscaler 1:1
	movwf	T2CON ; = 500KHz clock rate, approx 1sec rollover
	movlw	.212 ;choose PR2 value 
	movwf	PR2
	bsf	PIE1,TMR2IE ; Enable timer2 interrupt
	bsf	INTCON,GIE ; Enable all interrupts
	bsf     INTCON,PEIE ; enable peripheral interrupts
	bsf	T2CON,TMR2ON      ; Start Timer2
	movlw	0xf7 ; suppose thats note code for D
	movwf	nc
	;movlw	0xf0
	;movwf	oo
	call	write_action
	return

DAC_D_off
	bcf	T2CON, TMR2ON ; turn off timer 2
	movlw	0x07 ; suppose thats note code for D
	movwf	nc
	;movlw	0x00
	;movwf	oo
	call	write_action
	return

DAC_stop  
	bcf	T2CON, TMR2ON ; turn off timer 2
	;movlw	b'01001000' ; TURN TIMER0 OFF
	;movwf	T0CON 
	;bcf	INTCON,TMR0IE ; disable timer0 interrupt
	;bcf	INTCON,GIE ; disable all interrupts
	return
	
;delay	decfsz	delay_count	; decrement until zero
;	bra delay
;	return

play	
	lfsr	FSR0, seq_array
	;movff	dylen, counter
lop:	movff	POSTINC0, Command ; has the form '0/F'(high nibble) + 'NC'(low nibble)
	movff	POSTINC0, TimeC
	;movff	POSTINC0, TimeL
	movff	POSTINC0, TimeH
	call	TMR0_Op
	
wai:	movf	TimeC, W
	cpfseq	tmr0_cnt
	goto	wai
	movf	TMR0L, W ; to buffer TMR0H
	;cpfsgt	TMR0L
	;goto	wai
	movf	TimeH, W
	cpfsgt	TMR0H
	goto	wai
	movff	Command, Note
	movlw	0x0F
	andwf	Note, 1 ; the actual note is now in Note, info on the note erased
	swapf	Command
	andwf	Command, 1
	
on:	cpfseq	Command
	goto	off
b:	movlw	0x01
	cpfseq	Note
	goto	a	
	call	DAC_B
a:	movlw	0x02
	cpfseq	Note
	goto	g_s
	call	DAC_A
g_s:	movlw	0x03
	cpfseq	Note
	goto	f_s
	call	DAC_G_s
f_s:	movlw	0x04
	cpfseq	Note
	goto	f
	call	DAC_F_s
f:	movlw	0x05
	cpfseq	Note
	goto	e
	call	DAC_F
e:	movlw	0x06
	cpfseq	Note
	goto	d
	call	DAC_E
d:	movlw	0x07
	cpfseq	Note
	goto	en1
	call	DAC_D
en1:	decfsz	dylen
	goto	lop
off:	
b_off:	movlw	0x01
	cpfseq	Note
	goto	a_off	
	call	DAC_B_off
a_off:movlw	0x02
	cpfseq	Note
	goto	g_s_off
	call	DAC_A_off
g_s_off:movlw	0x03
	cpfseq	Note
	goto	f_s_off
	call	DAC_G_s_off
f_s_off:movlw	0x04
	cpfseq	Note
	goto	f_off
	call	DAC_F_s_off
f_off:	movlw	0x05
	cpfseq	Note
	goto	e_off
	call	DAC_F_off
e_off:	movlw	0x06
	cpfseq	Note
	goto	d_off	
	call	DAC_E_off
d_off:	movlw	0x07
	cpfseq	Note
	goto	en
	call	DAC_D_off ;goto	lop
en:	decfsz	dylen
	goto	lop
	call	TMR0_Nop	
	return
	
	end
