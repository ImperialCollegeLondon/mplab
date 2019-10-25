	#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Send_Byte_I, LCD_Move_Cursor, LCD_Second_String, LCD_First_String    ; external LCD subroutines

	extern	UART_Setup, UART_Transmit_Message   ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message	    ; external LCD subroutines
	extern	LCD_Write_Hex			    ; external LCD subroutines
	extern  ADC_Setup, ADC_Read		    ; external ADC routines

	
acs0	udata_acs   ; reserve data space in access ram
counter	    res 1   ; reserve one byte for a counter variable
delay_count res 1   ; reserve one byte for counter in the delay routine
 
acs_ovr	access_ovr
k1	res 1
k2	res 1
H1	res 1
L1	res 1
H2	res 1
L2	res 1
in1	res 1
in2	res 1
CB	res 1
x8_16_1	res 1
x8_16_2	res 1
x8_16_3	res 1

tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
myArray res 0x80    ; reserve 128 bytes for message data
myArray2
	res 0x80    ; reserve 128 bytes for message data

rst	code	0    ; reset vector
	goto	setup

pdata	code    ; a section of programme memory for storing data
	; ******* myTable, data in programme memory, and its length *****
myTable data	    "wake up neo"	; message, plus carriage return
	constant    myTable_l=.11	; length of data
   
myTable2
	data	    "follow rabbit"	; message, plus carriage return
	constant    myTable_2=.13	; length of data
	
main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	ADC_Setup	; setup ADC
	movlw	0x41
	movwf	k1, A
	movlw	0x8A
	movwf	k2, A
	movlw	0x00
	movwf	CB, A
	
	goto	start
	
	; ******* Main programme ****************************************
start 	lfsr	FSR0, myArray	; Load FSR0 with address in RAM
	movlw	upper(myTable)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter		; our counter register
loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; count down to zero
	bra	loop		; keep going until finished
	
	lfsr	FSR0, myArray2	; Load FSR0 with address in RAM
	movlw	upper(myTable2)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable2)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable2)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable_2	; bytes to read
	movwf 	counter		; our counter register
loop2 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; count down to zero
	bra	loop2		; keep going until finished
		
	;movlw	myTable_l	; output message to LCD (leave out "\n")
	;lfsr	FSR2, myArray
	;call	LCD_Write_Message
	
	;movlw	myTable_l	; output message to UART
	;lfsr	FSR2, myArray
	;call	UART_Transmit_Message
	;call	LCD_Move_Cursor
	;call	LCD_Second_String
	
	;movlw	myTable_2	; output message to LCD (leave out "\n")
	;lfsr	FSR2, myArray2
	;call	LCD_Write_Message
	
	;call	LCD_Clear

	;goto	$		; goto current line in code
	
measure_loop
	call	ADC_Read
	movf	ADRESH,W
	call	LCD_Write_Hex
	movf	ADRESL,W
	call	LCD_Write_Hex
	call	delay
	call	LCD_First_String
	;call	LCD_Clear
	goto	measure_loop		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
delay	decfsz	delay_count	; decrement until zero
	bra delay
	return
	
	
x8_by_16
	mulwf	in1
	movff	PRODH, H1
	movff	PRODL, L1
	
	mulwf	in2
	movff	PRODH, H2
	movff	PRODL, L2  
	
	movf	L1, W
	addwf	L2, 1, 0
	movff	L2, x8_16_1
	
	movf	H1, W
	addwfc	H2, 1, 0
	movff	H2, x8_16_2
	
	movlw	0x00
	addwfc	CB, 1, 0
	movff	CB, x8_16_3
	
	return

	
	
	end