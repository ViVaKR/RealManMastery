//-----------------------------------------------------
// ARM64 Assembly Template: for_loop.S
// Target OS: macOS  (심볼 접두사: '_' — Mach-O 관례)
//-----------------------------------------------------
.global _for_loop
.align 2

_for_loop:
	// --- Prologue ---
	stp x29, x30, [sp, #-32]!  // Frame pointer, Link register 저장
	mov x29, sp                // Frame pointer 설정
	stp x19, x20, [sp, #16]

	// --- Main Logic ---
	mov x19, #0  // 누적 합계
	mov x20, #1  // 루프 카우터
    
.L_loop:
	cmp  x20, #11
	b.ge .L_exit
    
	mov x0, x19
	mov x1, x20
    
	add x19, x19, x20  // 합계 누적
    
	mov x2, x19
	bl  _go_print_sum
    
	add x20, x20, #1
	b   .L_loop


.L_exit:
	mov x0, #0
	// --- Epilogue ---
	ldp x19, x20, [sp, #16]
	ldp x29, x30, [sp], #32  // Frame pointer, Link register 복원
	ret                      // Return