include "m8c.inc"										; part specific constants and macros
include "memory.inc"									; Constants & macros for SMM/LMM and Compiler
include "PSoCAPI.inc"									; PSoC API definitions for all User Modules

export _main
export sound_state_mode
export _timer_s
export _timer_m
export _timer_h

sound_state_mode	blk 1
_timer_s			blk 1
_timer_m			blk 1
_timer_h			blk 1

_main:

	lcall LCD_1_Start									; replace with LCD_Start if using the LCD_Start incase lib file name is different
	
Declare_Interupts:
	M8C_EnableIntMask INT_MSK0, INT_MSK0_GPIO			; enables the GPIO Interrupt mask (mic and push button) - source: http://www.cypress.com/file/46516/download
	M8C_EnableIntMask INT_MSK1, INT_MSK1_DBB00			; enables the DBB00 Interrupt mask (timer and counter) - change 00 to any other block number - source: http://www.cypress.com/file/46516/download
	M8C_EnableGInt										; enables the Global Interrupt - source: http://www.cypress.com/file/46516/download

Declare_Variables:
	mov [sound_state_mode], 00h							; clears the variable - might not be needed
	mov [_timer_s], 00h									; clears the variable - might not be needed
	mov [_timer_m], 00h									; clears the variable - might not be needed
	mov [_timer_h], 00h									; clears the variable - might not be needed

Declare_Analog:
	mov A, [bits]										; sets up the variable to a specific set of bits (7 to 13 bits)
	lcall DUALADC_1_SetResolution						; call the Set Resolution function - remove the 1 in the middle if using DUALADC.asm
	
	mov A, [power]										; sets up the variable for a specific power level (0 to 3)
	lcall DUALADC_1_Start								; call the start mode for ADC - might not be needed
	
	mov A, 00h											; sets variable to 0 for sampling mode
	lcall DUALADC_1_GetSamples							; call the ADC sampling mode - might not be needed
	
loop:
	mov A, 00h											; sets the row to position 0
	mov X, [position]									; sets the column to position [position] - whatever the number of columns the LCD is
	lcall LCD_1_Position								; officially position the LCD to A and X variables

;=====SOUND MODE=====
; might have multiple 'states' in this mode
sound_mode:
	mov A, 00h											; sets the row to position 0
	mov X, 00h											; sets the column to position 0
	lcall LCD_1_Position								; officially position the LCD to A and X variables
	mov A <SOUND_MODE									; sets up the row for our literal
	mov X >SOUND_MODE									; sets up the column for our literal
	lcall LCD_1_PrCString								; prints the literal on our LCD
	
sound_start:
	mov [_timer_s], 00h									; clears the variable
	mov [_timer_m], 00h									; clears the variable
	mov [_timer_h], 00h									; clears the variable
	
	mov A, 00h											; sets the row to position 0
	mov X, 00h											; sets the column to position 0
	lcall LCD_1_Position								; officially position the LCD to A and X variables
	mov A <DEFAULT_TIME									; sets up the row for our literal
	mov X >DEFAULT_TIME									; sets up the column for our literal
	lcall LCD_1_PrCString								; prints the literal on our LCD
	
	; might have to do some more variable clearing for ADC - not sure how to do it
	
; polling for ADC Signal (microphone - start mode)
ADC_Check_Start:
	lcall DUALADC_1_fIsDataAvailable					; check if there is ADC data is available - replace with DUALADC_fIsDataAvailable or ADC_fIsDataAvailable
	jz ADC_Check_Start									; polling loop - ends with data being ready
	
	M8C_DisableGInt										; disables Global Interrupts in order to do get the data off the ADC buffer - source: http://www.cypress.com/file/46516/download
	lcall DUALADC_1_iGetData1							; gets the ADC Data - assume channel 1, otherwise use DUALADC_1_iGetData2 (remove the 1 in the middle if using DUALADC.asm)
	M8C_EnableGInt										; enables Global Interrupts once data buffer is complete - source: http://www.cypress.com/file/46516/download
	
	lcall DUALADC_1_ClearFlag							; clearing ADC ready flag - remove the 1 in the middle if using DUALADC.asm

	; might have to do some variable stuff for ADC - not sure how to do it
	
;polling for ADC Signal (microphone - stop mode)
ADC_Check_Stop:
	lcall DUALADC_1_fIsDataAvailable					; check if there is ADC data is available - replace with DUALADC_fIsDataAvailable or ADC_fIsDataAvailable
	jz ADC_Check_Start									; polling loop - ends with data being ready
	
	M8C_DisableGInt										; disables Global Interrupts in order to do get the data off the ADC buffer - source: http://www.cypress.com/file/46516/download
	lcall DUALADC_1_iGetData1							; gets the ADC Data - assume channel 1, otherwise use DUALADC_1_iGetData2 (remove the 1 in the middle if using DUALADC.asm)
	M8C_EnableGInt										; enables Global Interrupts once data buffer is complete - source: http://www.cypress.com/file/46516/download
	
	lcall DUALADC_1_ClearFlag							; clearing ADC ready flag - remove the 1 in the middle if using DUALADC.asm

	; might have to do some variable stuff for ADC - not sure how to do it
	
sound_end:
	mov A, 00h
	mov X, 00h
	lcall LCD_1_Position
	mov A <DEFAULT_LCD									; sets up the row for our literal
	mov X >DEFAULT_LCD									; sets up the column for our literal
	lcall LCD_1_PrCString								; prints the literal on our LCD

	ljmp loop											; back to our loop
	
;=====END MODE=====
.terminate:
	jmp .terminate
	
;=====LITERAL DATA=====
.LITERAL												; literal for sound mode descriptor for LCD - Source: http://www.cypress.com/file/72341/download
DEFAULT_LCD:
ds " "													; might need to add more spaces for LCD row after " "
db 00h
.ENDLITERAL

.LITERAL												; literal for sound mode descriptor for LCD - Source: http://www.cypress.com/file/72341/download
DEFAULT_TIME:
ds "00:00:00"										; might need to add more spaces for LCD row after "00:00:00"
db 00h
.ENDLITERAL

.LITERAL												; literal for sound mode descriptor for LCD - Source: http://www.cypress.com/file/72341/download
SOUND_MODE:
ds "SOUND MODE"											; might need to add more spaces for LCD row after "MODE"
db 00h
.ENDLITERAL