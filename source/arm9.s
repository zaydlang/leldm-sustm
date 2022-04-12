.arm
.text
.global run_test_arm9

wrong:
    .word 0x11111111
    .word 0x11111111
    .word 0x11111111
    .word 0x11111111
    .word 0x11111111
    .word 0x11111111

random_data:
    .word 0xC0FFEEAB
    .word 0xDEADBEEF
    .word 0xD00DFEED
    .word 0xC0CAC01A
    .word 0x01234567
    .word 0x89ABCDEF

old_state:
    .space 0x40

overwrite_me:
    .space 0x40

run_test_arm9:
    @ save all the registers, because we're about to
    @ overwrite them all (except r0 and r12)
    ldr r0, =old_state
    stmia r0!, {r1-r11, r13-r14}

    @ r0 = the test # we are on
    mov r0, #0

@ TEST: simple ldmia with writeback (ldmia r1!, {r2})
@ expected:
@     0. r2 = 0xC0FFEEAB
@     1. r1 = r1 + 4

    ldr r1, =random_data
    ldmia r1!, {r2}
    
    @ TEST 0
    ldr r3, =random_data
    ldr r3, [r3]
    cmp r3, r2
    bne fail_test
    add r0, #1

    @ TEST 1
    ldr r3, =random_data
    add r3, #4
    cmp r3, r1
    bne fail_test
    add r0, #1

@ TEST: simple stmia (stmia r1!, {r2})
@ expected:
@     2. [r1] = 0xC0FFEEAB
@     3. r1 = r1 + 4

    ldr r1, =overwrite_me
    ldr r2, =random_data
    ldr r2, [r2]
    stmia r1!, {r2}
    
    @ TEST 2
    ldr r3, =random_data
    ldr r3, [r3]
    ldr r4, =overwrite_me
    ldr r4, [r4]
    cmp r3, r4
    bne fail_test
    add r0, #1

    @ TEST 3
    ldr r3, =overwrite_me
    add r3, #4
    cmp r3, r1
    bne fail_test
    add r0, #1

@ those were just the sanity checks. let's get started

@ TEST: ldmia with writeback with base in rlist (ldmia r1!, {r1})
@ expected:
@     4. r1 = r1 + 4

    ldr r1, =random_data
    ldmia r1!, {r1}

    @ TEST 4
    ldr r3, =random_data
    add r3, #4
    cmp r3, r1
    bne fail_test
    add r0, #1

@ TEST: ldmia with writeback with base last in rlist (ldmia r3!, {r1-r3})
@ expected:
@     5. r1 = 0xC0FFEEAB
@     6. r2 = 0xDEADBEEF
@     7. r3 = 0xD00DFEED

    ldr r3, =random_data
    ldmia r3!, {r1-r3}

    ldr r4, =random_data

    @ TEST 5
    ldr r5, [r4], #4
    cmp r5, r1
    bne fail_test
    add r0, #1

    @ TEST 6
    ldr r5, [r4], #4
    cmp r5, r2
    bne fail_test
    add r0, #1

    @ TEST 7
    ldr r5, [r4], #4
    cmp r5, r3
    bne fail_test
    add r0, #1

@ TEST: ldmia with writeback with base not last in rlist (ldmia r2!, {r1-r3})
@ expected:
@     8.  r1 = 0xC0FFEEAB
@     9.  r3 = 0xD00DFEED
@     10. r2 = r2 + 12

    ldr r2, =random_data
    ldmia r2!, {r1-r3}

    ldr r4, =random_data

    @ TEST 8
    ldr r5, [r4], #8
    cmp r5, r1
    bne fail_test
    add r0, #1

    @ TEST 9
    ldr r5, [r4], #4
    cmp r5, r3
    bne fail_test
    add r0, #1

    @ TEST 10
    ldr r1, =random_data
    add r1, #12
    cmp r1, r2
    bne fail_test
    add r0, #1

@ TEST: ldmia with writeback with empty rlist (ldmia r2!, {})
@ expected:
@     11. r2 = r2 + 0x40

    ldr r2, =random_data
    .word 0xE8B20000 @ ldmia r2!, {r1-r3}

    @ TEST 11
    ldr r3, =random_data
    add r3, #0x40
    cmp r3, r2
    bne fail_test
    add r0, #1

@ TEST: simple ldmia with S bit with writeback (ldmia r13!, {r14}^)
@ expected:
@     12. r14_irq  = 0
@     13. r13_irq  = r1 + 4
@     14. r14_user = 0xC0FFEEAB
@     15. r13_user = &wrong

    ldr r13, =wrong @ make you read from some wrong place if you use the wrong reg bank
    mov r14, #0

	mov	r1, #0x12 @ IRQ mode
	msr	cpsr, r1

    ldr r13, =random_data
    mov r14, #0

    ldmia r13!, {r14}^
    
    @ TEST 12
    mov r3, #0
    cmp r3, r14
    bne fail_test
    add r0, #1

    @ TEST 13
    ldr r3, =random_data
    add r3, #4
    cmp r3, r13
    bne fail_test
    add r0, #1

	mov	r1, #0x1F @ User mode
	msr	cpsr, r1
    
    @ TEST 14
    ldr r3, =random_data
    ldr r3, [r3]
    cmp r3, r14
    bne fail_test
    add r0, #1

    @ TEST 15
    ldr r3, =wrong
    cmp r3, r13
    bne fail_test
    add r0, #1

@ TEST: ldmia with writeback with base in rlist with S bit (ldmia r13!, {r13}^)
@ expected:
@     16. r13_irq  = r13_irq + 4
@     17. r13_user = &wrong

    ldr r13, =wrong @ make you read from some wrong place if you use the wrong reg bank

	mov	r1, #0x12 @ IRQ mode
	msr	cpsr, r1

    ldr r13, =random_data
    ldmia r13!, {r13}^

    @ TEST 16
    ldr r3, =random_data
    add r3, #4
    mov r0, r13
    b fail_test
    add r0, #1

	mov	r1, #0x1F @ User mode
	msr	cpsr, r1

    @ TEST 17
    ldr r3, =random_data
    add r3, #4
    mov r0, r13
    b fail_test
    add r0, #1

    @ done
    mov r0, #-1

    @ to be frank fail_test and end_test both do the same thing, 
    @ since r0 already is the test # we are on, and that's the 
    @ return value of the function either way lol
fail_test:
end_test:

    @ reset the cpu's state
    ldr r12, =old_state
    ldmia r12!, {r1-r11, r13-r14}
    bx lr