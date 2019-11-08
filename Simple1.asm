	#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Send_Byte_I, LCD_Move_Cursor, LCD_Second_String, LCD_First_String,  LCD_Send_Byte_D    ; external LCD subroutines

	extern	UART_Setup, UART_Transmit_Message   ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message	    ; external LCD subroutines
	extern	LCD_Write_Hex			    ; external LCD subroutines
	extern  ADC_Setup, ADC_Read		    ; external ADC routines
	extern	DAC_setup, DAC_stop

	
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
in3	res 1
CB	res 1
x8_16_1	res 1
x8_16_2	res 1
x8_16_3	res 1
	
N1	res 1
N2	res 1
temp1	res 1
temp2	res 1
temp3	res 1
x16_16_1 
	res 1
x16_16_2
	res 1
x16_16_3	
	res 1
x16_16_4
	res 1

x24_8_1
	res 1
x24_8_2
	res 1
x24_8_3	
	res 1
x24_8_4
	res 1
hx_1	res 1
hx_2	res 1

dec_1	res 1
dec_2	res 1
dec_3	res 1
dec_4	res 1
	
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
	movwf	k2, A
	movlw	0x8A
	movwf	k1, A
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

	
	movlw	0x17
	movwf	in1
	movlw	0x03
	movwf	in2
	movlw	0x10
	movwf	in3
	movlw	0x56
	movwf	N1
	movlw	0x03
	movwf	N2
	movlw	0x21
	movwf	hx_1
	movlw	0x05
	movwf	hx_2
	
	;call	hex_dec
	call	DAC_setup
	goto	$
	; sacking the next bit, it is supposed to play sound upon pressing a button
	
	movlw	b'10000000'
	movwf	TRISE
	banksel PADCFG1 ; PADCFG1 is not in Access Bank!!
	bsf	PADCFG1,REPU, BANKED ; Turn on pull-ups for Port D
	movlb	0x00 ; set BSR back to Bank 0

	
Button_Check
	btfsc	PORTE, RE7
	call	DAC_setup
	btfss	PORTE, RE7
	call	DAC_stop
	goto	Button_Check
	
measure_loop
	call	ADC_Read
	movff	ADRESH, hx_2
	movff	ADRESL, hx_1
	call	hex_dec
	call	LCD_dec
	;call	LCD_Write_Hex
	;movf	ADRESL,W
	;call	LCD_Write_Hex
	call	delay
	call	LCD_First_String
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

	movff	L1, x8_16_1
	
	movf	H1, W
	addwf	L2, 1, 0
	movff	L2, x8_16_2
	
	movlw	0x00
	addwfc	H2, 1, 0
	movff	H2, x8_16_3
	
	return
	
x16_by_16
	movf	N1, W
	call	x8_by_16
	movff	x8_16_1, temp1
	movff	x8_16_2, temp2
	movff	x8_16_3, temp3
	
	movf	N2, W
	call	x8_by_16
	
	movff	temp1, x16_16_1
	
	movf	x8_16_1, W
	addwf	temp2, 1, 0
	movff	temp2, x16_16_2
	
	movf	x8_16_2, W
	addwfc	temp3, 1, 0
	movff	temp3, x16_16_3
	
	movlw	0x00
	addwfc	x8_16_3, 1, 0
	movff	x8_16_3, x16_16_4
	
	return
	
x24_by_8
	movf	N1, W
	call	x8_by_16
	
	movff	x8_16_1, x24_8_1
	movff	x8_16_2, x24_8_2
	
	movf	N1, W
	mulwf	in3
	
	movf	PRODL, W
	addwf	x8_16_3, 1, 0
	movff	x8_16_3, x24_8_3
	
	movlw	0x00
	addwfc	PRODH, 0, 0
	movwf	x24_8_4
	
	return
	
hex_dec
	movff	k1, in1
	movff	k2, in2
	movff	hx_1, N1
	movff	hx_2, N2
	
	call	x16_by_16
	movff	x16_16_4, dec_4
	
	movlw	0x0A
	movwf	N1
	
	movff	x16_16_3, in3
	movff	x16_16_2, in2
	movff	x16_16_1, in1
	
	call	x24_by_8
	movff	x24_8_4, dec_3
	
	movff	x24_8_3, in3
	movff	x24_8_2, in2
	movff	x24_8_1, in1
	
	call	x24_by_8
	movff	x24_8_4, dec_2
	
	movff	x24_8_3, in3
	movff	x24_8_2, in2
	movff	x24_8_1, in1
	
	call	x24_by_8
	movff	x24_8_4, dec_1
	
	return

LCD_dec
	movlw	0x30
	addwf	dec_4, 0, 0
	call	LCD_Send_Byte_D
	movlw	0x30
	addwf	dec_3, 0, 0
	call	LCD_Send_Byte_D
	movlw	0x30
	addwf	dec_2, 0, 0
	call	LCD_Send_Byte_D
	movlw	0x30
	addwf	dec_1, 0, 0
	call	LCD_Send_Byte_D
	
	return
	
	
	
	

	
	
	end

