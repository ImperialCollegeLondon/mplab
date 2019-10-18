	#include p18f87k22.inc
	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100
	
start
	
	movlw	0x00
	movwf	0x20, ACCESS
	
	movlw	0x00
	movwf	0x21, ACCESS
	
	movlw	0xf0
	movwf	0x31, ACCESS ; num stored for the delay itself
	movwf	0x30, ACCESS ; num stored to update the loop counter
	
	call SPI_MasterInit
	
	movlw 0x07
	call SPI_MasterTransmit
	
	call delay
	
	movlw 0x01
	call SPI_MasterTransmit
	
endprogram
	nop
	bra endprogram
	
delay	call	sdelay
	decfsz	0x31 ; decrement until zero 
	bra	delay
	movff	0x30, 0x31.
	
	return
	
sdelay	call	ssdelay
	decfsz	0x21 ; decrement until zero 
	bra	sdelay
	return
	
ssdelay decfsz	0x20 ; decrement until zero 
	bra	ssdelay
	return
	
	

SPI_MasterInit ; Set Clock edge to negative
    bcf SSP2STAT, CKE
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP2CON1
    ; SDO2 output; SCK2 output
    bcf TRISD, SDO2
    bcf TRISD, SCK2
    return
    
SPI_MasterTransmit ; Start transmission of data (held in W)
    movwf SSP2BUF
    
Wait_Transmit ; Wait for transmission to complete
    btfss PIR2, SSP2IF
    bra Wait_Transmit
    bcf PIR2, SSP2IF ; clear interrupt flag
    return
	
    end
