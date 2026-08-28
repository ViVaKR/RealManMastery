//-----------------------------------------------------
// ARM64 Assembly Template: Regs.S
// Target OS: macOS  (심볼 접두사: '_' — Mach-O 관례)
// Mach-O(Mach Object File Format의 약자)는 
// 실행 파일, 목적 코드, 공유 라이브러리, 동적으로 로드되는 코드 및 코어 덤프를 위한 파일 형식이다. 
// a.out 형식을 대체하기 위해 개발되었다.
//-----------------------------------------------------

.global _Regs
.align 2

_Regs:
	// --- Prologue ---
	stp x29, x30, [sp, #-16]!  // Frame pointer, Link register 저장
	mov x29, sp                // Frame pointer 설정
    
	mov x0, #17
	mov x1, #20
	add x2, x0, x1

	// --- Main Logic ---
	mov w0, #0  // Return value (0)

	// --- Epilogue ---
	ldp x29, x30, [sp], #16  // Frame pointer, Link register 복원
	ret                      // Return