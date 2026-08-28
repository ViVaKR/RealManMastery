.section __TEXT, __text, regular, pure_instructions

.global _main
.align 2

_main:
  
	stp x29, x30, [sp, #-96]!  // Pre-index
	mov x29, sp
  
	// x19 부터 x28 까지 16바이트 간격으로 풀 백업
	stp x19, x20, [sp, #16]  // Offset
	stp x21, x22, [sp, #32]
	stp x23, x24, [sp, #48]
	stp x25, x26, [sp, #64]
	stp x27, x28, [sp, #80]
	
	
	// ====================== //
	mov x1, #4095
	add x0, x1, #45
	
	// RISC 아키텍처 는 32비트(4바이트) 라는 고정된 틀 안에서 명령어 종류와 인자(피연산자)개수/타입에 따라. 비트 판을 쪼개 쓰는 방식
	// 6가지 표준 인코딩 그룹으로 수렴
	
	// (lldb) memory read 0x100000640
	// 0x100000640: 20 b4 00 91 (낮은 주소 -> 높은 주소)
	// 바이트 역순 정렬: 91 00 b4 20
	// 32 비트 Hex 명령어 0x9100b420
	// 2진수 표현
	// 1001 0001 0000 0000 1100 0010 0000
	// ARM64 ADD 32 비트 비트 필드 구조 분석
	// [sf] [op] [S] [ Opcode ] [ imm12 ] [ Rn ] [ Rd ]
	// 	1   0   0   1  0  0  0   0  0   0 0 0 0  0 0 1 0  1 1 0 1   0 0 0 0 1  0 0 0 0 0
	// -------------------------------------------------------------------------------
	// 1001 0001 | 0000 0000 | 0010 1100 | 0010 0000  =>  0x9100B420
	
	
	
	
	// bl _Regs

	// adrp x0, _helloworld@PAGE
	// add  x0, x0, _helloworld@PAGEOFF
	// bl _printf

	mov x0, #0
  
	ldp x19, x20, [sp, #16]
	ldp x21, x22, [sp, #32]
	ldp x23, x24, [sp, #48]
	ldp x25, x26, [sp, #64]
	ldp x27, x28, [sp, #80]
	ldp x29, x30, [sp], #96  // Post-index
  ret






// .include "section_macros.inc"

// // [코드 구역]
// // __TEXT,__text, regular, pure_instructions
// CODE_SECTION
// FUNC_START main, 32

// 	mov x19, #0x25
// 	mov x20, #0x43
// 	add x0, x19, x20
	
// 	bl _csharp_entry
// 	bl _calc
	
// 	mov x0, x19
// 	mov x1, x20
// 	bl  _add_i64
	
// 	mov x2, x0
// 	mov x0, x19
// 	mov x1, x20
	
// 	// i32 호출 시: w0, w1, w2 사용
// 	// i64 호출 시: x0, x1, x2 사용
// 	// f64 호출 시: d0, d1, d2 레지스터 사용
// 	bl _console_writeline_i64
	
// 	mov x0, #88
	
// 	bl _welcome_rust
	
// 	mov x0, #0
// FUNC_EXIT 32