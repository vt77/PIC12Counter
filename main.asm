;
;  Simple tick counter with i2c interface(slave)
;  Author: Daniel Marchasin
;  License: MIT
;  
;       PIC12F629/75 
;        -------          Pickit
;      -|VCC GND|-        1 -> RESET (GP3) 
;  CNT -|GP5 GP0|-        2 -> VCC
;  LED -|GP4 GP1|- SCL    3 -> GND
;  RST -|GP3 GP2|- SDA    4 -> ICSPDAT(GP0)  
;        -------          5 -> ICSPCLK(GP1)
;


#include <p12f629.inc>
__CONFIG(_INTRC_OSC_NOCLKOUT & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_ON & _CP_OFF & _CPD_OFF);
LIST P=12f675


#DEFINE    SDA    GP2 ;INT interrupt
#DEFINE    SCL    GP1 
#DEFINE    CNT    GP5 ;TMR1 clock    

#DEFINE    I2C_ADDRESS  0x15
#DEFINE    READ_MASK (I2C_ADDRESS << 1 | 1)

CBLOCK  0x20
             i
			 databyte
ENDC


;Reset vector
ORG    0x00			
     GOTO START

;Interrupt vector
INT    ORG    0x04  
     BTFSS   INTCON,INTF    ; if(!INTF) then exit
     GOTO    int_end
	 
	 ;Detect start bit SDA == 0 & SCL == 1
	 BTFSC   GPIO,SCL
	 CALL	 I2CPROCESS
	 BCF     INTCON,INTF	;Clear INTF
int_end        
     RETFIE

I2CPROCESS
	MOVLW   .8
	MOVWF   i 
read_next_bit

	BTFSC GPIO,SCL	;while(SCL)	
	GOTO $-1
	;If SDA changed since SCL is HIGH 
	;a) From Low to High - start
	;b) From High to Low - stop	
	;RETURN	

	BTFSS GPIO,SCL     ;while(!SCL)
	GOTO $-1

	MOVF  databyte,W
	ADDWF databyte
	BTFSC GPIO,SDA
	INCF  databyte
	;Check addr
    DECFSZ  i,F 
    GOTO read_next_bit
	MOVLW READ_MASK	  ;Check address if complete
	XORWF databyte,w
	BTFSS  STATUS,Z
	GOTO  i2cprocess_end     ;This is our address, send ACK
	
	;Send Ack
send_ack
	BTFSC GPIO,SCL  ;while(SCL)
	GOTO  $-1	
	BSF     STATUS,RP0
	BCF     TRISIO,SDA	
	BCF     STATUS,RP0
	BTFSS 	GPIO,SCL     ;while(!SCL)
	GOTO $-1
	BTFSC 	GPIO,SCL     ;while(SCL)
	GOTO $-1

	;BSF     STATUS,RP0   
	;BSF     TRISIO,SDA
	;BCF     STATUS,RP0
process_data

 	BCF 	T1CON,TMR1ON	;Stop timer
	MOVF    TMR1L,w
	MOVWF	databyte
	
	CALL    I2CSEND 
	
	BTFSS 	GPIO,SCL     ;while(!SCL)
	GOTO $-1

	BTFSC GPIO,SDA       ;Check master's ACK
	GOTO  i2cprocess_end

	MOVF    TMR1H,w
	MOVWF	databyte

	BTFSC 	GPIO,SCL     ;while(SCL)
	GOTO $-1

	CALL    I2CSEND
	
i2cprocess_end	
	BSF 	T1CON,TMR1ON	;Start timer
	RETURN

I2CSEND
	MOVLW   .8
	MOVWF   i

send_bit
	RLF		databyte
	BSF     STATUS,RP0
	BCF     TRISIO,SCL   ;!!! clock_stretching stop
	BTFSS	STATUS,C
	BCF     TRISIO,SDA
	BTFSC	STATUS,C
	BSF     TRISIO,SDA
	BSF     TRISIO,SCL   ;!!! Release clock
	BCF     STATUS,RP0

	BTFSS 	GPIO,SCL     ;while(!SCL)
	GOTO $-1
	BTFSC 	GPIO,SCL     ;while(SCL)
	GOTO $-1

    DECFSZ  i,F
    GOTO send_bit

	BSF     STATUS,RP0
	BSF     TRISIO,SDA
	BCF     STATUS,RP0
	
	RETURN 

START    ORG    0x50 
	MOVLW   0x07
	BSF     STATUS,RP0 	;select BANK 1 
	BSF     TRISIO,SDA  ;SDA Input
	BSF     TRISIO,SCL  ;SCL Input

    BCF   	OPTION_REG,INTEDG ;External INT Falling edge
	BSF     INTCON,INTE       ;Enable External Interrupt

	BCF     STATUS,RP0  ;select BANK 0
  
    ;MOVLW   TMR1ON|TMR1CS
    ;MOVWF   T1CON
	
	BSF 	T1CON,TMR1CS		;TMR1 External clock source
	BSF     T1CON,NOT_T1SYNC    ;Async mode
	CLRF	TMR1L
	MOVLW 	0xAA
	MOVWF	TMR1L 

	CLRF	TMR1H
	BSF 	T1CON,TMR1ON    	;TMR1 Start
	
	CLRF	GPIO				;Init latches
	MOVLW	0x07
	MOVWF   CMCON
	;CLRF    CMCON

	CLRF		GPIO			;Prepare for pull down

	BSF		INTCON,GIE  ;Enable interrupts

MAIN
     SLEEP
     GOTO    MAIN     
END
