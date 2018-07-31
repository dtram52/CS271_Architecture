; Author: Du Tram
; Class-section: CS271-400 
; Email: tramd@oregonstate.edu
; Project ID: Programming Assignment #6A     Due Date: December 3, 2017
;--------------------------------------------------------------------------------------
; [Requirements]
;  1) User’s numeric input must be validated the hard way: Read the user's input as a 
;     string, and convert the string to numeric form. If the user enters non-digits or 
;     the number is too large for 32-bit registers, an error message should be displayed
;     and the number should be discarded.
;  2) Conversion routines must appropriately use the lodsb and/or stosb operators.
;  3) All procedure parameters must be passed on the system stack.
;  4) Addresses of prompts, identifying strings, and other memory locations should be 
;     passed by address to the macros.
;  5) Used registers must be saved and restored by the called procedures and macros. 
;  6) The stack must be “cleaned up” by the called procedure. 
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;NOTE: I referred to lecture slides and demos, stackoverflow in the code. 
;[Extra-credit options]
; 1. Number each line of user input and display a 
;    running subtotal of the user's numbers
; 2. Handle signed integers.
; 3. Make your ReadVal and WriteVal procedures recursive.
; 4. Implement procedures ReadVal and WriteVal for 
;    floating point values, using the FPU.
;--------------------------------------------------------------------------------------

INCLUDE Irvine32.inc

.data

;constants

MAX_STR		EQU		15
HI			EQU		4294967286	
ARR_SIZE	EQU		10				; Number of integers receiving from user
INPUT_SIZE	EQU		10
MAXASCII	EQU		57
MINASCII	EQU		48
EC_LOW		EQU		-2147483648
EC_HI		EQU		2147483647

title_intro				BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 0dh, 0ah
						BYTE			"Written by Du Tram", 0dh, 0ah, 0
description			BYTE    "Please provide 10 (un)signed decimal integers.", 0dh, 0ah
						BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0dh, 0ah
						BYTE	"After you have finished inputting the raw numbers I will display a list", 0dh, 0ah
						BYTE	"of the integers, their sum, and their average value.", 0dh, 0ah, 0
mesEC				BYTE	"**EC1: Number each line of user input and display a running subtotal of the user's numbers", 0dh, 0ah
						;Time doesnt allow almost
						;BYTE	"**EC2: Handle signed integers.", 0dh, 0ah
						BYTE	"**EC3: Make your ReadVal and WriteVal procedures recursive.", 0dh, 0ah, 0
instructPrompt		BYTE     ".Please enter an unsigned integer: ", 0
errMes				BYTE     "ERROR: You did not enter an unsigned number or your number was too big.", 0dh, 0ah, 0
						BYTE		 "Please enter again: ",0
comma				BYTE     ", ",0
ty					BYTE     "Thanks for playing!!",0
inputMes			BYTE     "You entered the following numbers: ", 0dh, 0ah, 0
subMes				BYTE	 "The running subtotal: ",0
sumMes				BYTE      0dh, 0ah,"The sum of these numbers is: ", 0
avgMes				BYTE     "The average is: ",0
input               BYTE    MAX_STR DUP(?)
current				BYTE	MAX_STR DUP(?)
arrSize				SDWORD	10
count				DWORD	1
arr					SDWORD   10 DUP(?)
subTotal			SDWORD	0
sumNum				SDWORD	0
avgNum				SDWORD	0

; ;--------------------------------------------------------------------------------------
;        MACRO getstring with Paramenters: strPrompt, strAddress
;			Description: display prompts and then read in a string (lecture 26)
; ;--------------------------------------------------------------------------------------
getString MACRO strPrompt, strAddress
    push       edx
    push       ecx

    mov        edx, strPrompt
    call       WriteString					; display instruction to input string
	
	mov		edx, strAddress					;move address of input into edx
	mov		ecx, MAX_STR					;set max size
	call	ReadString					;read user input (save to input)

    pop        ecx
    pop        edx

ENDM


; ;--------------------------------------------------------------------------------------
;		MACRO displayString with Parameter: strMessage
;			Description: takes buffer and put it into edx and then writeString to display
; ;--------------------------------------------------------------------------------------
displayString MACRO strMessage
    push       edx
    mov        edx, strMessage
    call       WriteString
    pop        edx

ENDM

.code
; ;--------------------------------------------------------------------------------------
;         Main Procedure
; ;--------------------------------------------------------------------------------------
 main PROC
	push	OFFSET	title_intro		;+12
	push	OFFSET	description		;+8
	push	OFFSET	mesEC			;+4
    call       introduction

	push	OFFSET subMes				;+32
	push	subTotal					;+28
	push	count						;+24
	push	arrSize						;+20
	push	OFFSET arr					;+16
	push	OFFSET errMes				;+12
	push	OFFSET input				;+8
	push	OFFSET instructPrompt		;+4
	call	readVal						;+0

	

	push	OFFSET current				;20
	push	OFFSET inputMes				;16
	push	OFFSET comma				;12
	push	LENGTHOF arr				;8
	push	OFFSET arr					;4
	call	writeVal					;0


	push	OFFSET current				;20
	push	OFFSET arr					;16
	push	OFFSET avgMes				;12	
	push	OFFSET sumMes				;8
	push	subTotal					;4	
	call	displaySumAvg					;0

	push	OFFSET ty
	call	farewell
	call CrLf
	exit
main ENDP


; ;--------------------------------------------------------------------------------------
;  Introduction Procedure
;  Description: Prints program title, introductions and descriptions
;  Receives: strings to introduction, instruction and EC
; Returns: none
; Registers Changed: none
; ;--------------------------------------------------------------------------------------
introduction PROC
 	push			ebp					;ebp, ret@+4, @mesEC+8, @description+12, @title+16
	mov				ebp, esp			
	push			edi					;edi is -4

	mov				edi, [ebp + 16]
	displayString	edi					;displays title

	mov				edi, [ebp + 12]
	displayString	edi					;displays description of program

	mov				edi, [ebp + 8]
	displayString	edi					;displays extra credit message (if time allows)


	call			CrLF
	call			CrLF
	pop				edi
	pop				ebp
	ret				12
introduction ENDP


; ;--------------------------------------------------------------------------------------
;  ReadVal Procedure
; referenced from https://stackoverflow.com/questions/13664778/converting-string-to-integer-in-masm-esi-difficulty
;	Description: Receives and validates integers from the user and
;                    transforms decimal values
; Receives: prompt for input, input, error message, array, array size
; Returns: none
; Registers Changed: edx, eax, ecx, ebx
; ;--------------------------------------------------------------------------------------
readVal	PROC
;gets stack ready
	push ebp
	mov ebp, esp
	pushad

jmp			beginrVal	;first prompt go to start for loop purposes
	
invalidrVal:
	displayString	[ebp+16]	;error message for all types of invalid inputs

beginrVal:
	mov			ebx, [ebp+24]		;Checks if it reaches base case (10 inputs) and end if it does
	cmp			ebx, 0
	je			endrVal			
	
	mov			eax, [ebp+28]		;line # for EC
	call		WriteDec
	getString	[ebp+8], [ebp+12]	;[string to promp for #], [user input]
	cmp			eax, INPUT_SIZE	
	jge			invalidrVal
	
	mov			ecx, eax			;sets string length
	mov			esi, [ebp+12]		;user input
	mov			edi, [ebp+20]		;array destination
	mov			ebx, 10				;set up to multiply with 10 for conversion purpose
	mov			edx, 0			;clears edx 
	cld								;sets flag to move forward from beginning


;start looping through string
strLoop:
	lodsb
	cmp			al, MAXASCII			;verify with ASCII of 9
	jg			invalidrVal				;jump to invalid warning
	cmp			al, MINASCII			;verify with ASCII of 0
	jl			invalidrVal
	sub			al, 48					;subtract 48 to convert into digits 
	movzx		eax, al					;extends to fill SDWORD
	add			eax, edx				;Adds in values (starts at 0)
	mul			ebx						;multiplies by 10 to move forward referenced from stackoverflow as mentioned above
	mov			edx, eax				;saves to add  in next interation 
	loop		strLoop

	mov			eax, edx				; mov to divide value by 10 
	mov			edx, 0
	div			ebx

	displayString [ebp+36]				;subtotal message string
	push		eax						
	add			[ebp+32], eax			;add value to subtotal
	mov			eax, [ebp+32]			; moves to reg
	mov			[ebp+32], eax			;moves subtotal out to memory
	call		WriteDec				;display subtotal
	call		Crlf					;clear
	pop			eax		
	
;this procedure call will help us store value into array
	push		eax						
	push		edi
	call		miniStoreVal			

	mov			ebx, [ebp+24]			
	dec			ebx
	mov		[ebp+24], ebx

	add			edi, 4					;moves to next element in array
	mov			eax, [ebp+28]			
	add			eax, 1					; increments line number
	MOV			[ebp+28], eax
;we are making readVal recursive so pushing it to get ready for next call
	push		[ebp+36]			
	push		[ebp+32]
	push		eax
	push		ebx
	push		edi
	push		[ebp+16]
	push		[ebp+12]
	push		[ebp+8]
	call		readVal

;done with readVal proc
endrVal:
	
	popad
	pop ebp
	ret 32
readVal	ENDP

;------------------------------------------------------
; miniStore procedure
;mini procedures to store value into array
;Receives: input, arr
;Returns: none
;Registers changed : edi, eax
;---------------------------------------------------------
miniStoreVal PROC
	push ebp
	mov ebp, esp
	pushad
;storing our int in the next array address
	mov		edi, [ebp+8]		
	mov		eax, [ebp+12]
	mov		[edi], eax			

	popad
	pop ebp
	ret 8
miniStoreVal ENDP

; ;--------------------------------------------------------------------------------------
;   WriteVal    Procedure (making it recursive for EC if time allows)
;       Description: uses display string 
;          Receives:    list: @array
;                    request: number of array elements
;           Returns: none
; Registers Changed: eax, ecx, ebx, edx
; ;--------------------------------------------------------------------------------------
writeVal PROC
    ; Get parameters from the stack
    push       ebp
    mov        ebp, esp
	pushad
;check first of recursive call
  mov		ebx, [ebp+12]	
  cmp		ebx, 10
  jl		beginwVal
	displayString	[ebp+20]

beginwVal:
	;clear registers
	mov		edi, 0
	mov		ebx, 0		

	mov		ecx, [ebp+12]	; array size to as count
	mov		esi, [ebp+8]	;next integer for string coversion
;temp string and disply
	push	[ebp+24]		
	push	[esi]			
	call	intToString		 
	;if last digit no comma needed
	cmp		ecx, 1			
	je		rArrayDone
	displayString	[ebp+16]
	add		esi,4			;next elem in arr

	mov		ecx, [ebp+12]
	dec		ecx
; push to prep for recursive call
	push	[ebp+24]	;outputs
	push	[ebp+20]	;inputMes
	push	[ebp+16]	;comma
	push	ecx			;LENGTHOF arr	+12
	push	esi			;arr		+8
	call	writeVal

rArrayDone:

	popad
	pop	ebp

    ret        20
writeVal ENDP


; ;--------------------------------------------------------------------------------------
; displaySumAvg Procedure
;       Description: Calculates and displays the average and sum of array
;          Receives: subtotal, sum and avg messages, arr and current
;           Returns: none
; Registers Changed: eax, ebx, ecx, edx, edi and ebp
; ;--------------------------------------------------------------------------------------
displaySumAvg PROC
    ; Get parameters from stack
     push       ebp
    mov        ebp, esp
	pushad
    ; Parameter holding list of input numbers
    displayString	[ebp + 12]	
    mov        eax, 10
    mov        edx, 0
    mov        ebx, 0
    mov			ecx, eax
	mov			eax, 0

    
	mov		edi, [ebp+20]			;arr


;loop to adds sum
getSum:
	add		eax, [edi]				;adds current
	add		edi, 4					;increments to next element in array
	loop	getSum					

	push	[ebp+24]				;sum
	push	eax
	call	intToString						
	
	Call	Crlf					

	displayString	[ebp+16]		
	mov 	ebx, 10					;gets average, discard decimal point
	div		ebx

	push	[ebp+24]				;average
	push	eax
	call	intToString				

	popad
    pop        ebp

    ret        8
displaySumAvg ENDP

; ;--------------------------------------------------------------------------------------
;  intToString Conversion procedures
;  Description: input is converted into string and will be written out
;  Referenced from source  https://stackoverflow.com/questions/13523530/printing-an-int-or-int-to-string
;			Receives: arr, current
;          Returns: none
; Registers Changed: eax, ebx, ecx, edx ,edi and ebp.
;---------------------------------------------------------------------------

intToString	PROC
	push	ebp
	mov		ebp, esp
	pushad
	mov		ecx, 0				;clears ecx
	mov		eax, [ebp+8]		;next int
	mov		edi, [ebp+12]	

goToEndDigit:
	mov		edx, 0			
	mov		ebx, 10
	div		ebx
	cmp		eax, 0
	je		endDigit			;last digit jump to place terminator
	add		ecx, 1
	jmp		goToEndDigit

endDigit:						
	add		ecx, 1				;Increments for our last digit and places null terminator
	add		edi, ecx
	std
	mov		eax, 0
	mov		al,	0				;terminates string with null
	stosb
	mov		eax, [ebp+8]		
digitString:
	mov		edx, 0				;clears
	div		ebx					;remaind to take next digit
	add		edx, 48				;adds 48 to set to ASCII
	push	eax					;saves value to use stosb
	mov		al, dl				
	stosb
	pop		eax					;pops for next digit
	loop	digitString

	displayString	[ebp+12]	

	popad
	pop ebp
	ret		8
intToString	ENDP

; ;--------------------------------------------------------------------------------------
;         Procedure: farewell not passing (optional anw)
;       Description: Prints farewell message.
;          Receives: message: string message
;           Returns: none
; Registers Changed: edx
; ;--------------------------------------------------------------------------------------
farewell PROC
    push       ebp
    mov        ebp, esp
    ; Parameter holding farewell message
    mov        edx, [ebp + 8]

    call       CrLf
    call       WriteString
    call       CrLf
    pop        ebp

    ret        4
farewell ENDP

END main