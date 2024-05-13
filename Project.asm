; PIC16F877A Configuration Bit Settings and Assembly source line config statements

CONFIG FOSC = EXTRC ; Oscillator Selection bits (RC oscillator)
CONFIG WDTE = OFF ; Watchdog Timer Enable bit (WDT disabled)
CONFIG PWRTE = OFF ; Power-up Timer Enable bit (PWRT disabled)
CONFIG BOREN = OFF ; Brown-out Reset Enable bit (BOR disabled)
CONFIG LVP = OFF ; Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3 isdigital I/O, HV on MCLR must be used for programming)
CONFIG CPD = OFF ; Data EEPROM Memory Code Protection bit (Data EEPROM code protection off)
CONFIG WRT = OFF ; Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control)
CONFIG CP = OFF ; Flash Program Memory Code Protection bit (Code protection off)
    
#include <xc.inc>
    
;--------initialising-------------
PSECT start, CLASS = CODE, DELTA=2

start:
PAGESEL MAIN
GOTO MAIN
display_data equ 0x21 //store bits to display
use_delay equ 0x34 //store bits for delay

DS_config equ 0x35 //store bits to configure DS1302
DS_config1 equ 0x36

Max_config  equ 0x60 //Store outputs from DS1302
Max_config1 equ 0x61
Max_config2 equ 0x62
Max_config3 equ 0x63 

value1 equ 0x71  //store bits for looping purposes
value2 equ 0x72 
value3 equ 0x73 
value4 equ 0x74 
value5 equ 0x75

PSECT CODE, DELTA=2
;---------end initialising-------------


BANKSEL TRISB  //PORT B input
BCF PORTB,0  
BCF PORTB,1 
BANKSEL PORTB 
BCF PORTB,0
BCF PORTB,1 

Push:  //Push button function
 call MinandSec   ; Call subroutine to set seconds and minutes
 call DISPLAY	  ; Call subroutine to update display
 BTFSS PORTB,0
 goto Push1
 goto Push
 
Push1:
 call MinandSec       
 call DISPLAY	    
 BTFSS PORTB,0
 goto Push1
 goto Push2
 
Push2:
  call HoursandMin  ; Call subroutine to set hours and minutes
  call DISPLAY      
  BTFSS PORTB,0
  goto Push3
  goto Push2

Push3:
 call HoursandMin       
 call DISPLAY	     
 BTFSS PORTB,0
 goto Push3
 goto Push4 

Push4:
 call Year       ; Call subroutine year
 call DISPLAY	    
 BTFSS PORTB,0
 goto Push5
 goto Push4 

Push5:
 call Year       
 call DISPLAY	     
 BTFSS PORTB,0
 goto Push5
 goto Push6 

Push6:
 call MonthandDate  ; Call subroutine to set month and date
 call DISPLAY	      
 BTFSS PORTB,0
 goto Push7
 goto Push6 
 
Push7:
 call MonthandDate      
 call DISPLAY	      
 BTFSS PORTB,0
 goto Push7
 goto Push 


     
MinandSec: //configuration of requesting minutes and seconds
   
   MOVLW 0b10000001
   MOVWF DS_config
   
   MOVLW 0b10000011
   MOVWF DS_config1
   call Get_Data
   return
 
HoursandMin: //configuration of requesting hours and minutes
   
   MOVLW 0b10000011
   MOVWF DS_config
   
   MOVLW 0b10000101
   MOVWF DS_config1
   call Get_Data
   return

MonthandDate:   //configuration of requesting months and dates
   MOVLW 0b10000111
   MOVWF DS_config
   
   MOVLW 0b10001001
   MOVWF DS_config1
   call Get_Data
   return
    


Year:   //configuration of requesting year
   MOVLW 0b10001101
   MOVWF DS_config
   call Get_Data  
   MOVLW 0x32
   MOVWF Max_config3
   MOVLW 0x30
   MOVWF Max_config2
   return
       
 

Get_Data:    
    MOVLW 0X09
    MOVWF value1
    MOVLW 0X05
    MOVWF value3
    MOVLW 0X09
    MOVWF value5
    MOVLW 0X0f
    MOVWF use_delay
    
   //PORTD, 0 - RST
   //PORTD, 1 - SCLK
   //PORTD, 2 - Input/Output 
   BANKSEL TRISD  //setting pins output
   CLRF TRISD 
   BANKSEL PORTD
   CLRF PORTD 
 
 
 BCF PORTD,1
 call bit_delay    
 BSF PORTD,0
 call bit_delay  
 BCF PORTD,2
   

Loop_loop:
DECFSZ value1 ;decrement value, if value is zero, skip next line
goto Loop_sub1 // value1 not zero rotate data
goto END2
Loop_sub1:
BCF PORTD, 1 // CLK LOW
call bit_delay
BTFSS DS_config, 0 ;check bit value, if value is set, skip next line
goto zero3 // bit is zero after roration
;code for feeding address bits to DS1302 if the bits are set
 BSF PORTD,2
 call bit_delay
 BSF PORTD,1
 call bit_delay
 RRF DS_config
goto Loop_loop
zero3:
;code for feeding address bits to DS1302 if the bits are clear
 BCF PORTD,2
 call bit_delay
 BSF PORTD,1
 call bit_delay
 RRF DS_config
goto Loop_loop
 END2:
   MOVLW 0X09
   MOVWF value1 
   

   
   BANKSEL TRISD //Setting portD input
   BSF TRISD,2
   BANKSEL PORTD
   
   
   Loop_sub: //getting data from DS1302 and storing
   DECFSZ value3
   goto Loop_sub2
   goto END4
   Loop_sub2:
   BCF PORTD,1
   BTFSS PORTD,2
   goto zero 
   BSF Max_config ,0
   call bit_delay
   RRF Max_config 
   goto END3
    zero:
    BCF Max_config ,0
    call bit_delay
    RRF Max_config 
    END3:
    BSF PORTD,1
    goto Loop_sub
    END4:
    
    RRF Max_config 
    call bit_delay
    RRF Max_config 
    call bit_delay
    RRF Max_config 
    call bit_delay
    RRF Max_config 
    call bit_delay
    RRF Max_config 
    call bit_delay
    
    BCF Max_config ,7
    BCF Max_config ,6
    BSF Max_config ,5
    BSF Max_config ,4
    
   
  
   
    MOVLW 0X05
    MOVWF value3

   
   LOOP_sub4: //getting data from DS1302 and storing
   DECFSZ value3
   goto LOOP_sub3
   goto END_sub2
   LOOP_sub3:
   BCF PORTD,1
   BTFSS PORTD,2
   goto zero_1 
   BSF Max_config1 ,0
   call bit_delay
   RRF Max_config1
   goto END_sub
    zero_1:
    BCF Max_config1,0
    call bit_delay
    RRF Max_config1
    END_sub:
    BSF PORTD,1
    goto LOOP_sub4
    END_sub2:
    
    RRF Max_config1
    call bit_delay
    RRF Max_config1
    call bit_delay
    RRF Max_config1
    call bit_delay
    RRF Max_config1
    call bit_delay
    RRF Max_config1
    call bit_delay
    
    BCF Max_config1,7
    BCF Max_config1,6
    BSF Max_config1,5
    BSF Max_config1,4
    
    BCF PORTD,0
    call bit_delay
    
    
    MOVLW 0X09
    MOVWF value1
    MOVLW 0X05
    MOVWF value3
    
    BANKSEL TRISD
    CLRF TRISD ; Set port D as outputs
    BANKSEL PORTD
    CLRF PORTD ; Clear port D values
 
 BCF PORTD,1
 call bit_delay    
 BSF PORTD,0
 
 BCF PORTD,2
   
LOOP8:
DECFSZ value1 ;decrement value, if value is zero, skip next line
goto LOOP7 // value1 not zero rotate data
goto END7
LOOP7:
BCF PORTD, 1 // CLK LOW
call bit_delay
BTFSS DS_config1, 0 ;check bit value, if value is set, skip next line
goto zero5 // bit is zero after roration
;code for feeding address bits to DS1302 if the bits are set
 BSF PORTD,2
 call bit_delay
 BSF PORTD,1
 call bit_delay
 RRF DS_config1
goto LOOP8
zero5:
;code for feeding address bits to DS1302 if the bits are clear
 BCF PORTD,2
 call bit_delay
 BSF PORTD,1
 call bit_delay
 RRF DS_config1
goto LOOP8
 END7:
   MOVLW 0X09
   MOVWF value1 
   
   MOVLW 0X30
   MOVWF Max_config2
   
   MOVLW 0X30
   MOVWF Max_config3
   
   BANKSEL TRISD
   BSF TRISD,2
   BANKSEL PORTD
   
   
   LOOP10: //getting data from DS1302 and storing
   DECFSZ value3
   goto LOOP9
   goto END9
   LOOP9:
   BCF PORTD,1
   
   BTFSS PORTD,2
   goto zero6 
   BSF Max_config2,0
   call bit_delay
   RRF Max_config2
   goto END8
    zero6:
    BCF Max_config2,0
    call bit_delay
    RRF Max_config2
    END8:
    BSF PORTD,1
    goto LOOP10
    END9:
    
    RRF Max_config2
    call bit_delay
    RRF Max_config2
    call bit_delay
    RRF Max_config2
    call bit_delay
    RRF Max_config2
    call bit_delay
    RRF Max_config2
    call bit_delay
    
   
    
    MOVLW 0X05
    MOVWF value3

   
   LOOP4_2:  //getting data from DS1302 and storing
   DECFSZ value3
   goto LOOP3_2
   goto END4_2
   LOOP3_2:
   BCF PORTD,1
   BTFSS PORTD,2
   goto zero_2 
   BSF Max_config3,0
   call bit_delay
   RRF Max_config3
   goto END3_2
    zero_2:
    BCF Max_config3,0
    call bit_delay
    RRF Max_config3
    END3_2:
    BSF PORTD,1
    goto LOOP4_2
    END4_2:
    
    RRF Max_config3
    call bit_delay
    RRF Max_config3
    call bit_delay
    RRF Max_config3
    call bit_delay
    RRF Max_config3
    call bit_delay
    RRF Max_config3
    call bit_delay
    
    BCF Max_config3,7
    BCF Max_config3,6
    BSF Max_config3,5
    BSF Max_config3,4
    
    BCF PORTD,0
    return
    
DISPLAY: //Function to conig displays and send data in  
   
   //PORTC, 0 - Data Input
   //PORTC, 1 - Chip Select
   //PORTC, 2 - CLK    

BANKSEL TRISC //setting port c output
CLRF TRISC 
BANKSEL PORTC
CLRF PORTC 
   
; Storing register addresses and their data values for MAX6952
MOVLW 0X04 ; Address of Configuration register of MAX6952
MOVWF 0X22 ; Configuration address of MAX6952 stored at 0x22 file register of the PIC
MOVLW 0X81 ; Values of Data for Configuration register of MAX6952
MOVWF 0X23 ; Configuration data of MAX6952 stored at 0x23 file register of the PIC

MOVLW 0X01 ; Intensity 10
MOVWF 0X24 ; Intensity 10 address
MOVLW 0Xff ; Intensity 10 value
MOVWF 0X25 ; Intensity 10 data
    
MOVLW 0X02 ; Intensity 32
MOVWF 0X26 ; Intensity 32 address
MOVLW 0Xff ; Intensity 32 value
MOVWF 0X27 ; Intensity 32 data
 
MOVLW 0X07 ; Display test
MOVWF 0X28 ; Display test address
MOVLW 0X00 ; Display test value
MOVWF 0X29 ; Display test data     

; Display 4
MOVLW 0X20 ; Display 4
MOVWF 0X2A ; Display 4 address
MOVF Max_config3, W ; Display 0 value from Max_config3
MOVWF 0X2B ; Display 4 data
 
; Display 3
MOVLW 0X21 ; Display 3
MOVWF 0X2C ; Display 3 address
MOVF Max_config2, W ; Display 3 value from Max_config2
MOVWF 0X2D ; Display 3 data

; Display 2
MOVLW 0X22 ; Display 2
MOVWF 0X2E ; Display 2 address
MOVF Max_config1, W ; Display 2 value from Max_config1
MOVWF 0X2F ; Display 2 data

; Display 1
MOVLW 0X23 ; Display 1
MOVWF 0X30 ; Display 1 address
MOVF Max_config , W ; Display 1 value from Max_config 
MOVWF 0X31 ; Display 1 data

; Loading pointer value for accessing data
MOVLW 0X21
MOVWF FSR

; Loop for loading first 8 bits (15 to 8 bit loading)
first8bit_loop1:
    DECFSZ value5 ; Decrement value5 counter and skip if zero
    goto Main_sub ; Jump to Main_sub if value5 is not zero
    return  
    
Main_sub:    
    BSF PORTC, 1 ; CS (Chip Select) HIGH
    call bit_delay ; Call delay subroutine
    BCF PORTC, 2 ; CLK (Clock) LOW
    call bit_delay ; Call delay subroutine
    BCF PORTC, 1 ; CS LOW
    call bit_delay ; Call delay subroutine
    MOVLW 0X09 ; Load literal value 0x09
    MOVWF value2 ; Move value 0x09 to loop1 address (0x32)
    INCF FSR ; Increment FSR (File Select Register) to point to next address
    MOVF INDF, W ; Move data from address pointed by FSR to W register
    MOVWF display_data ; Store data into display_data (0x21)
    MOVLW 0X09 ; Load literal value 0x09
    MOVWF value4 ; Move value 0x09 to value4 address (0x33)

MAIN: ; Initializing 15 to 8 bit loading
    DECFSZ value2 ; Decrement loop1, skip next line if zero
    goto first_word_rotation ; Loop not zero, rotate data
    goto second8bit_loop2 ; First 8 bits done, proceed to next 8 bits

first_word_rotation:
    BCF PORTC, 2 ; CLK LOW
    call bit_delay ; Call delay subroutine
    BTFSS display_data, 7 ; Check if MSB (Most Significant Bit) is set
    goto zero1 ; If MSB is zero after rotation, jump to zero1

    ; Write code for feeding address bits to MAX6952 if the bits are set
    BSF PORTC, 0 ; Set address bit HIGH
    call bit_delay ; Call delay subroutine
    BSF PORTC, 2 ; CLK HIGH
    call bit_delay ; Call delay subroutine
    BCF PORTC, 2 ; CLK LOW
    RLF display_data ; Rotate left through carry in display_data
    goto MAIN ; repeat MAIN loop

zero1:
    ; Write code for feeding address bits to MAX6952 if the bits are clear
    BCF PORTC, 0 ; Set address bit LOW
    call bit_delay ; Call delay subroutine
    BSF PORTC, 2 ; CLK HIGH
    call bit_delay ; Call delay subroutine
    BCF PORTC, 2 ; CLK LOW
    RLF display_data ; Rotate left through carry in display_data
    goto MAIN ; repeat MAIN loop

second8bit_loop2: ; 7 to 0 bit loading
    MOVLW 0X09
    MOVWF value4 ; Initialize value4 (address 0x33)
    
    INCF FSR ; Increment FSR to point to next address
    MOVF INDF, W ; Move data from address pointed by FSR to W register
    MOVWF display_data ; Store data into display_data

MAIN2: ; Initializing 8 to 0 bit loading
    DECFSZ value4 ; Decrement value4, skip next line if zero
    goto second_word_rotation ; Loop not zero, rotate data
    goto first8bit_loop1 ; Second 8 bits done, go back to the next character address

second_word_rotation:
    BCF PORTC, 2 ; CLK LOW
    call bit_delay ; Call delay subroutine
    BTFSS display_data, 7 ; Check if MSB (Most Significant Bit) is set
    goto zero2 ; If MSB is zero after rotation, jump to zero2

    ; Write code for feeding data bits to MAX6952 if the bits are set
    BSF PORTC, 0 ; Set data bit HIGH
    call bit_delay ; Call delay subroutine
    BSF PORTC, 2 ; CLK HIGH
    call bit_delay ; Call delay subroutine
    BCF PORTC, 2 ; CLK LOW
    RLF display_data ; Rotate left through carry in display_data
    goto MAIN2 ; repeat MAIN2 loop

zero2:
    ; Write code for feeding data bits to MAX6952 if the bits are clear
    BCF PORTC, 0 ; Set data bit LOW
    call bit_delay ; Call delay subroutine
    BSF PORTC, 2 ; CLK HIGH
    call bit_delay ; Call delay subroutine
    BCF PORTC, 2 ; CLK LOW
    RLF display_data ; Rotate left through carry in display_data
    goto MAIN2 ; repeat MAIN2 loop
     
    
;Delay function
bit_delay:
DECFSZ use_delay ;decrement value, if value is zero, skip next line
goto bit_delay
MOVLW 0X0f
MOVWF use_delay
return

END start    
