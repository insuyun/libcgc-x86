.macro sys_call n
	movl	$\n, %eax
.endm

.macro do_syscall
	int	$0x80
.endm

.macro syscall_arg_1
	pushl	%ebx
	movl	8(%esp), %ebx
	do_syscall
	popl	%ebx
	ret
.endm

.macro syscall_arg_2
	pushl	%ebx
	pushl	%ecx
	movl	12(%esp), %ebx
	movl	16(%esp), %ecx
	do_syscall
	popl	%ecx
	popl	%ebx
	ret
.endm

.macro syscall_arg_3
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	movl	16(%esp), %ebx
	movl	20(%esp), %ecx
	movl	24(%esp), %edx
	do_syscall
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
.endm

.macro syscall_arg_4
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
	movl	20(%esp), %ebx
	movl	24(%esp), %ecx
	movl	28(%esp), %edx
	movl	32(%esp), %esi
	do_syscall
	popl	%esi
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
.endm

.macro syscall_arg_5
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
	pushl	%edi
	movl	24(%esp), %ebx
	movl	28(%esp), %ecx
	movl	32(%esp), %edx
	movl	36(%esp), %esi
	movl	40(%esp), %edi
	do_syscall
	popl	%edi
	popl	%esi
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
.endm

.macro syscall_arg_6
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
  pushl   %edi
	pushl	%ebp
	movl	28(%esp), %ebx
	movl	32(%esp), %ecx
	movl	36(%esp), %edx
	movl	40(%esp), %esi
	movl	44(%esp), %edi
	movl	48(%esp), %ebp
	do_syscall
	popl	%ebp
	popl	%edi
	popl	%esi
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
.endm

.macro ENTER base
	.global \base
	.type \base, @function
\base:
.endm

.macro END base
	.size \base, . - \base
.endm

.macro zero_if_success
  cmp   $0, %ebx
  je    1f
  mov   %eax, (%ebx)
1:
  cmp   $0, %eax
  jge   2f
  cmp   $-1024, %eax
  jle   2f
  jmp   3f
2:
  mov   $0, %eax
3:
  
.endm

.macro tx_and_rx
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
	movl	20(%esp), %ebx
	movl	24(%esp), %ecx
	movl	28(%esp), %edx
	do_syscall
  mov   32(%esp), %ebx
  zero_if_success
	popl	%esi
	popl	%edx
	popl	%ecx
	popl	%ebx
  ret
.endm

ENTER	_start
	call main
	pushl %eax
	call _terminate
END	_start

ENTER	_terminate
	sys_call 1
	syscall_arg_1
END	_terminate

ENTER transmit
  sys_call 4
  tx_and_rx
END	transmit

ENTER	receive
	sys_call 3
  tx_and_rx
END	receive

ENTER	fdwait
  sys_call 142
  pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
	pushl	%edi
	movl	24(%esp), %ebx
	movl	28(%esp), %ecx
	movl	32(%esp), %edx
  movl  $0, %esi
	movl	36(%esp), %edi
	do_syscall
  movl  40(%esp), %ebx
  zero_if_success
	popl	%edi
	popl	%esi
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
END	fdwait

ENTER	allocate
  # mmap2
  sys_call 192
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
  pushl %edi
	pushl	%ebp

  # addr == NULL
  movl  $0, %ebx
  # length
  movl  28(%esp), %ecx
  # prot
  movl  $3, %edx
  cmp   $0, 32(%esp)
  jz   1f
  movl  $7, %edx 
1:
  # flags : MAP_ANON | MAP_PRIVATE
  movl  $34, %esi
  # fd : -1
  movl  $0xffffffff, %edi
  # offset : 0
  movl  $0, %ebp
	do_syscall
  movl  36(%esp), %ebx
  zero_if_success
	popl	%ebp
	popl	%edi
	popl	%esi
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
END	allocate

ENTER	deallocate
	sys_call 91
	syscall_arg_2
END	deallocate

ENTER	random
	pushl	%ebx
	pushl	%ecx
	pushl	%edx

  # open
  sys_call 5
	movl	$urandom, %ebx
	movl	$0, %ecx
	do_syscall

  # read
  movl  %eax, %ebx
  sys_call 3
	movl	16(%esp), %ecx
	movl	20(%esp), %edx
  do_syscall

  # save fd to edx
  movl  %ebx, %edx
  movl  24(%esp), %ebx
  zero_if_success
  movl  %eax, %edx

  # close
  movl  %edx, %ebx
  sys_call 6
  movl  %eax, %ebx
  do_syscall

  mov %edx, %eax
	popl	%edx
	popl	%ecx
	popl	%ebx
	ret
END	random

ENTER	setjmp
	movl	4(%esp), %ecx
	movl	0(%esp), %edx
	movl	%edx, 0(%ecx)
	movl	%ebx, 4(%ecx)
	movl	%esp, 8(%ecx)
	movl	%ebp, 12(%ecx)
	movl	%esi, 16(%ecx)
	movl	%edi, 20(%ecx)
	xorl	%eax, %eax
	ret
END	setjmp

ENTER	longjmp
	movl	4(%esp), %edx
	movl	8(%esp), %eax
	movl	0(%edx), %ecx
	movl	4(%edx), %ebx
	movl	8(%edx), %esp
	movl	12(%edx), %ebp
	movl	16(%edx), %esi
	movl	20(%edx), %edi
	testl	%eax, %eax
	jnz	1f
	incl	%eax
1:	movl	%ecx, 0(%esp)
	ret
END	longjmp

.data
urandom:
  .ascii "/dev/urandom\x00"

