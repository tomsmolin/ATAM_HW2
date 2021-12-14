.global	keyMixing, byteSubstitution, shiftRows, cipher

.section .data
sbox:	.byte	99,124,119,123,-14,107,111,-59,48,1,103,43,-2,-41,-85,118
		.byte	-54,-126,-55,125,-6,89,71,-16,-83,-44,-94,-81,-100,-92,114,-64
		.byte	-73,-3,-109,38,54,63,-9,-52,52,-91,-27,-15,113,-40,49,21
		.byte	4,-57,35,-61,24,-106,5,-102,7,18,-128,-30,-21,39,-78,117
		.byte	9,-125,44,26,27,110,90,-96,82,59,-42,-77,41,-29,47,-124
		.byte	83,-47,0,-19,32,-4,-79,91,106,-53,-66,57,74,76,88,-49
		.byte	-48,-17,-86,-5,67,77,51,-123,69,-7,2,127,80,60,-97,-88
		.byte	81,-93,64,-113,-110,-99,56,-11,-68,-74,-38,33,16,-1,-13,-46
		.byte	-51,12,19,-20,95,-105,68,23,-60,-89,126,61,100,93,25,115
		.byte	96,-127,79,-36,34,42,-112,-120,70,-18,-72,20,-34,94,11,-37
		.byte	-32,50,58,10,73,6,36,92,-62,-45,-84,98,-111,-107,-28,121
		.byte	-25,-56,55,109,-115,-43,78,-87,108,86,-12,-22,101,122,-82,8
		.byte	-70,120,37,46,28,-90,-76,-58,-24,-35,116,31,75,-67,-117,-118
		.byte	112,62,-75,102,72,3,-10,14,97,53,87,-71,-122,-63,29,-98
		.byte	-31,-8,-104,17,105,-39,-114,-108,-101,30,-121,-23,-50,85,40,-33
		.byte	-116,-95,-119,13,-65,-26,66,104,65,-103,45,15,-80,84,-69,22

.section	.text
 keyMixing:
 	pushq %rbx
	xorq %rax, %rax
	xorq %rbx, %rbx
	xorq %r10, %r10
	xorq %r11, %r11
	
	movq (%rdi), %rax
	movq 8(%rdi), %rbx
	movq (%rsi), %r10
	movq 8(%rsi), %r11

	xorq %r10, %rax
	xorq %r11, %rbx

	movq %rax, (%rdi)
	movq %rbx, 8(%rdi)
	popq %rbx
	ret
	
byteSubstitution:
  	movq $0, %rax
 	movq $0, %rcx
 	movq $0, %rdx
 	movq $0, %r9
    movq $0, %r8
    lea sbox(%rip), %r8
byte_loop:
 	cmpq $16, %r9
 	je end
 	movb (%rdi, %r9), %cl # cl have value of current byte in input
 	movb (%r8, %rcx),%al
 	movb %al, (%rdi, %r9)
 	inc %r9
 	jmp byte_loop
end:
 	ret

shiftRows:
    pushq %rbx
	xor %rax , %rax
	xor %rbx , %rbx
 	xor %rcx, %rcx
 	xor %rdx , %rdx
	# second row
	movb 4(%rdi), %al
	movw 5(%rdi), %bx
	movb 7(%rdi), %dl

	movw %bx, 4(%rdi)
	movb %dl, 6(%rdi)
	movb %al, 7(%rdi)

	# third row
	movb 8(%rdi), %al
	movb 9(%rdi), %bl
	movb 10(%rdi), %cl
	movb 11(%rdi), %dl

	movb %al, 10(%rdi)
	movb %bl, 11(%rdi)
	movb %cl, 8(%rdi)
	movb %dl, 9(%rdi)

	# fourth row
	movw 12(%rdi), %ax
	movb 14(%rdi), %cl
	movb 15(%rdi), %dl

	movb %dl, 12(%rdi)
	movw %ax, 13(%rdi)
	movb %cl, 15(%rdi)

	popq %rbx
	ret

cipher:
    # not using any of the callee saved registers \
	# Therefore no callee saves here			  \
	
traverse_array: 
		pushq %rdx	
		pushq %rdi
		pushq %rsi
 		call keyMixing # a
        popq %rsi
        popq %rdi
		popq %rdx

		xor %rcx, %rcx
		mov $10, %rcx
b_loop:
		pushq %rdx	
		pushq %rdi
		pushq %rsi
		pushq %rcx
		call byteSubstitution
        popq %rcx
		popq %rsi
        popq %rdi
		popq %rdx

		pushq %rdx	
		pushq %rdi
		pushq %rsi
		pushq %rcx
		call shiftRows
		popq %rcx
        popq %rsi
        popq %rdi
		popq %rdx
        
		pushq %rdx	
		pushq %rdi
		pushq %rsi
		pushq %rcx
		call mixColumns
		popq %rcx
        popq %rsi
        popq %rdi
		popq %rdx
        
		pushq %rdx	
		pushq %rdi
		pushq %rsi
		pushq %rcx
		call keyMixing
		popq %rcx
        popq %rsi
        popq %rdi
		popq %rdx
        
		dec %rcx
		cmpq $1, %rcx
		jne b_loop
# ====== END OF FIRST LOOP =======
		pushq %rdx	
		pushq %rdi
		pushq %rsi
		call byteSubstitution
		popq %rsi
        popq %rdi
		popq %rdx
        
		pushq %rdx	
		pushq %rdi
		pushq %rsi
		call shiftRows
        popq %rsi
        popq %rdi
		popq %rdx

		pushq %rdx	
		pushq %rdi
		pushq %rsi
		call keyMixing
        popq %rsi
        popq %rdi
		popq %rdx
        
		lea 16(%rdi), %rdi
		dec %rdx
		cmpq $0, %rdx
		jne traverse_array
	
	ret