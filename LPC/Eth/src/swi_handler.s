;/*****************************************************************************
;*   swi_handler.s: SWI handler file for NXP LPC23xx Family Microprocessors
;*
;*   Copyright(C) 2006, NXP Semiconductor
;*   All rights reserved.
;*
;*   History
;*   2006.09.01  ver 1.00    Prelimnary version, first Release
;*
;*****************************************************************************/

	PRESERVE8
	
SWI_IRQ_DIS		EQU	0
SWI_IRQ_EN		EQU	1
SWI_FIQ_DIS		EQU	2
SWI_FIQ_EN		EQU	3

I_Bit			EQU	0x80
F_Bit			EQU	0x40
	
;The exported labels and functions
	EXPORT		SoftwareInterrupt    
	EXPORT		IntEnable
	EXPORT		IntDisable

	CODE32
	AREA		SWI_HANDLER,CODE,READONLY
	ENTRY
    
;********************************************************************
;*  SWI interrupt handler											*
;*  Function :	SoftwareInterrupt(SWI_Number)						*
;*		The SWI_Number is 0 through 3								*
;*		See below "SwiFunction" table below							*
;*  Parameters:    None												*
;*  input  :       SWI_Number										* 
;*  output :       None												*
;********************************************************************
SoftwareInterrupt			
	CMP		R0, #4
	LDRLO	PC, [PC, R0, LSL #2]
	MOVS	PC, LR
	
SwiFunction
	DCD	IRQDisable		;0
	DCD	IRQEnable		;1
	DCD	FIQDisable		;2
	DCD	FIQEnable		;3

IRQDisable
	MRS		R0, SPSR
	ORR		R0, R0, #I_Bit
	MSR		SPSR_c, R0
	MOVS	PC, LR

IRQEnable
	MRS		R0, SPSR
	BIC		R0, R0, #I_Bit	
	MSR		SPSR_c, R0
	MOVS	PC, LR

FIQDisable
	MRS		R0, SPSR
	ORR		R0, R0, #F_Bit
	MSR		SPSR_c, R0
	MOVS	PC, LR

FIQEnable
	MRS		R0, SPSR
	BIC		R0, R0, #F_Bit	
	MSR		SPSR_c, R0
	MOVS	PC, LR

;**********************************************************************
;*  Call SWI to enable IRQ                                            *
;*  Function : void IntEnable(void)                                   *
;*  Parameters:      None                                             *
;*  input  :         None                                             * 
;*  output :         None                                             *
;**********************************************************************
IntEnable
	SWI     SWI_IRQ_EN	
	BX      lr	
; end of IntEnable

;**********************************************************************
;*  Call SWI to disable IRQ                                           *
;*  Function : void IntDisable(void)                                  *
;*  Parameters     : None                                             *
;*  input          : None                                             * 
;*  output         : None                                             *
;**********************************************************************
IntDisable
	SWI     SWI_IRQ_DIS		
	BX      lr
; end of IntDisable

	END
;/*************************************************************************
;**                            End Of File
;**************************************************************************/

