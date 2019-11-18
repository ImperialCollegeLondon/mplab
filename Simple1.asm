	#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Send_Byte_I, LCD_Move_Cursor, LCD_Second_String, LCD_First_String,  LCD_Send_Byte_D, TMR0_Nop    ; external LCD subroutines

	extern	UART_Setup, UART_Transmit_Message   ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message	    ; external LCD subroutines
	extern	LCD_Write_Hex			    ; external LCD subroutines
	extern  ADC_Setup, ADC_Read, get_measurement		    ; external ADC routines
	extern	DAC_A, DAC_stop, DAC_F_s, DAC_D, DAC_E, TMR0_Op, TMR0_setup, state_init, state_check, play, clr_seq, rec_on, DAC_setup

	
acs0	udata_acs   ; reserve data space in access ram
counter	    res 1   ; reserve one byte for a counter variable
delay_count res 1   ; reserve one byte for counter in the delay routine
 
rst	code	0    ; reset vector
	goto	setup

;pdata	code    ; a section of programme memory for storing data
;	; ******* myTable, data in programme memory, and its length *****
	
main	code

setup	
	bsf	RCON, IPEN  ; interrupt priority
	;call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	ADC_Setup	; setup ADC
	call	DAC_setup	; setup	DAC
	call	state_init
	setf	TRISJ ; set portJ as all input
	setf	TRISE ; set portE as all input

	banksel PADCFG1 ; PADCFG1 is not in Access Bank!!
	bsf	PADCFG1, RJPU, BANKED ; Turn on pull-ups for Port J
	bsf	PADCFG1, REPU, BANKED ; Turn on pull-ups for Port E
	movlb	0x00 ; set BSR back to Bank 0
	call	TMR0_setup
	call	clr_seq
	goto	start
	
	; ******* Main programme ****************************************
start 	

Button_Check
	btfsc	PORTE, RE0  ;checks whether to turn on TMR0, i.e if button is held down
	call	rec_on ; TMR0_Op
	btfss	PORTE, RE0 ;checks whether to turn off TMR0, i.e. when tmer button is released
	call	TMR0_Nop
	call	state_check
	btfsc	PORTJ, RJ0 ;checks whether to play, i.e. when play button is held down
	call	play
	
	goto	Button_Check

	end

