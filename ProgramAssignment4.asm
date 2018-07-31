TITLE PROGRAM 4
; Author: Du Tram
; Class-section: CS271-400 
; Email: tramd@oregonstate.edu
; Project ID: Programming Assignment #4     Due Date: November 5, 2017
; Description: 
; Write a program to calculate composite numbers. First, the user is instructed to enter the number of 
; composites to be displayed, and is prompted to enter an integer in the range [1 .. 400]. The user 
; enters a number, n, and the program verifies that 1 ≤ n ≤ 400. If n is out of range, the user is re-
; prompted until s/he enters a value in the specified range. The program then calculates and displays 
; all of the composite numbers up to and including the nth composite. The results should be displayed 
; 10 composites per line with at least 3 spaces between the numbers.  
; Extra-credit options:
; 1. Align the output columns. 
; 2. Display more composites, but show them one page at a time. The user can “Press any key to 
; continue …” to view the next page. Since length of the numbers will increase, it’s OK to 
; display fewer numbers per line. 
; 3.  Check against only prime divisors, which requires saving all of the primes found so far (numbers that fail the composite test)

INCLUDE Irvine32.inc

; (insert constant definitions here)
; constants - upper and lower limit
 

PER_ROW = 10
PER_PAGE = 100
UPPER = 400
LOWER = 1

.data
; Main strings
prog_intro			BYTE "Composite Numbers  Programmed by Du Tram", 0
prompt1				BYTE "Enter the number of composite numbers you would like to see. ",0
prompt2				BYTE "I’ll accept orders for up to 400 composites. ",0 
prompt_num			BYTE "Enter the number of composites to display [1 .. 400]: ", 0
goodBye				BYTE "Results certified by Du Tram. Goodbye.  ", 0
err_range			BYTE "Out of range. Try again.", 0
ecMes1				BYTE "** EC: Align the output columns.", 0
ecMes2				BYTE "** EC: Display more composites, but show them one page at a time (100 per page)", 0
space				BYTE "   ", 0 ; 3 spaces
morePage			BYTE "Press any key to continue...",0

; variables 


userNum			DWORD ?
current			DWORD ?
isComposite		DWORD 0
curr_row		DWORD 0
ec_page			DWORD 0

.code
main PROC
	call	introduction
	call	getUserData
	call	showComposites
	call	farewell

	exit	; exit to operating system
main ENDP


;Introduction Procedure
;Receives: none
;Returns: none
;Preconditions: none
;Registers changed: edx

introduction	PROC
	mov		edx, OFFSET prog_intro	;display program and author
	call	WriteString					
	call	CrLf

	mov		edx, OFFSET ecMes1
	call	WriteString
	call	CrLf
	
	mov		edx, OFFSET ecMes2
	call	WriteString
	call	CrLf
	call	CrLf

	mov		edx, OFFSET prompt			;prints instructions
	call	WriteString
	call	CrLf
	call	CrLf

	ret
introduction ENDP


;Procedure to say farewell
;receives: none
;returns: none
;preconditions: none
;registers changed: edx
farewell	 PROC
	mov		edx, OFFSET goodbye
	call	WriteString				;prints goodbye message
	call	CrLf
	call	CrLf

	ret
farewell ENDP


;Procedure to get values for number of composites to be printed from user
;receives: none
;returns: user input values for number of composites to be printed
;preconditions: none
;registers changed: eax, ebx, edx
getUserData		PROC
getNum:
	mov		edx, OFFSET prompt
	call	WriteString					;output instruction to get number
	call	ReadInt						;get an integer from user
	mov		userNum, eax
	call	validate					;validate it, in range [1-400]
	cmp		ebx, 1						;validate PROC returns 1 in ebx if valid, 0 if invalid
	je		haveNum						;jump to end if valid
	mov		edx, OFFSET invalid
	call	WriteString
	call	CrLf
	jmp		getNum						;otherwise, get another integer if invalid

haveNum:
	ret
getUserData		ENDP


;Procedure to validate user-gotten value for number of composites to be printed
;receives: userNum is a global variable
;returns: 0 in ebx if not valid, 1 in ebx if valid
;preconditions: none
;registers changed: eax, ebx
validate	PROC
	mov		eax, userNum		
	cmp		eax, 1				;check the user's integer with lower limit (1)
	jl		notValid			;if less, not valid
	cmp		eax, 400
	jg		notValid
	jmp		valid
notValid:
	mov		ebx, 0
	jmp		goBack	
valid:
	mov		ebx, 1
goBack:

	ret
validate		ENDP


;Procedure to print out composite numbers
;receives: userNum is a global variable
;returns: user-specified number of composite numbers to console
;preconditions: none
;registers changed: eax, ebx, ecx, edx
showComposites	PROC
	mov		composite, 0
	mov		eax, userNum
	dec		eax
	mov		userNumPU, eax
getComp:
	inc		composite				;start at 1
	call	isComposite				;check if it's composite
	cmp		eax, 0					;0 in eax = composite, 1 in eax = prime
	je		isComp					;if it is, print it out
	jmp		getComp					;if it isn't, try the next number
isComp:
	mov		eax, composite			;print it out
	call	WriteDec
	dec		spaceCount
	jmp		spaces
newLine:
	call	CrLf
	mov		eax, 10
	mov		spaceCount, eax
	jmp		continue
spaces:
	mov		eax, counter
	cmp		eax, userNumPU
	je		newLine
	mov		edx, OFFSET space
	call	WriteString
continue:
	inc		counter
	mov		eax, counter
	cmp		eax, userNum			;check if you have the user-specified number yet
	je		maxComp					;if you do, end
	jmp		getComp					;if you don't, keep going
maxComp:
	call	CrLf

	ret
showComposites	ENDP


;Procedure to check if a number is a composite number
;receives: composite is a global variable
;returns: 0 in eax if number is composite, 1 in eax if number is prime
;preconditions: composite must be given a value
;registers changed: eax, ebx, ecx, edx


isComposite	PROC
	mov		ebx, composite
	cmp		ebx, 2				;don't need to check numbers 2 or less
	jle		factorNo			;because they're obviously not composite
	mov		ecx, 2
checkDiv:
	mov		eax, ebx		;put the number to check in eax
	xor		edx, edx		;clear the edx register to hold remainder
	div		ecx				;divide it by (1 - number to check), not inclusive
	cmp		edx, 0			;if there is no remainder in edx, number was divisible
	je		factorYes		;so it's a composite, not a prime --> return 0
	inc		ecx				;if ecx = number to check,
	cmp		ecx, composite	;then you've checked all the numbers needed to be checked
	je		factorNo		;the number was not divisible by anything & is a prime --> return 1
	jmp		checkDiv

factorYes:
	mov		eax, 0
	jmp		compCheck
factorNo:
	mov		eax, 1
compCheck:
	ret
isComposite	ENDP



END main
