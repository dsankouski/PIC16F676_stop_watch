	include "p16f676.inc"	;include the defaults for the chip
	__config 0x3D14			;sets the configuration settings (oscillator type etc.)
							; HERE SET TO INTERNAL OSCILLATOR 4MHZ

	cblock 	0x20 			;start of general purpose registers
		count1 			;used in delay routine
		counta 			;used in delay routine 
		countb 			;used in delay routine
		counter
		;;;;;;;;;;;;;;;;;;; displayControllerConfiguration ;;;;;;;;;;;;;;;;;;;;;;
		displayConfiguration, configuration
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;; displayControllerData ;;;;;;;;;;;;;;;;;;;;;;
		displayControllerData, decodeConfigAndBank5, bank43, bank21
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		bit_index
		bit_count
		
	endc
	
	org	0x0000			;org sets the origin, 0x0000 for the 16F628,
						;this is where the program starts running	

	bcf 	STATUS,RP0 	;Bank 0
	clrf 	PORTA 		;Init PORTA
	bsf 	STATUS,RP1 	;Bank 1
	clrf	ANSEL 		;digital I/O

   	movlw 	b'00000000'	;set PortC all outputs
   	movwf 	TRISC
	movwf	TRISA		;set PortA all outputs
	bcf		STATUS,	RP0	;select bank 0
	
	;;;;;;;;;;;;;; Setting display controller data structures lengths ;;;;;;;;;;
	clrf	counter
	movlw	0x18
	movwf	displayControllerData
	movlw	0xf0
	movwf	decodeConfigAndBank5
	
	movlw	0x08
	movwf	displayConfiguration
	movlw	0x3f
	movwf	configuration
	
	
Loop	
	incf	bank21
	movlw	0xff
	movwf	PORTA			;set all bits on
	movwf	PORTC
	nop				;the nop's make up the time taken by the goto
	nop				;giving a square wave output
	
	movlw	displayControllerData
	call	WriteDataToSerialInterface
	
	call	Delay			;this waits for a while!
	movlw	0x00
	movwf	PORTA
	movwf	PORTC			;set all bits off
	call	Delay
	goto	Loop			;go back and do it again

Delay	movlw	d'250'			;delay 250 ms (4 MHz clock)
	movwf	count1
d1	movlw	0xC7
	movwf	counta
	movlw	0x01
	movwf	countb
Delay_0
	decfsz	counta, f
	goto	$+2
	decfsz	countb, f
	goto	Delay_0
	decfsz	count1	,f
	goto	d1
	retlw	0x00

WriteDataToSerialInterface
	movwf	FSR
	movfw	INDF
	movwf	bit_count
	clrf	bit_index
	bcf		PORTA,3
	
bit_send_loop	movlw	0x08
	andwf	bit_index,0
	btfsc	STATUS,Z
	incf	FSR
	bsf		PORTA,1
	btfss	INDF,W
	bsf		PORTA,2
	movfw	PORTA		;setting clock and data bits to zero
	andlw	0x39
	movwf	PORTA
	incf	bit_index
	movfw	bit_index
	subwf	bit_count
	btfss	STATUS,Z
	goto	bit_send_loop
	
	bsf		PORTA,3
	
	return

	end
