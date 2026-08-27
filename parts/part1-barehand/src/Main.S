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
	
	
  
	adrp x0, _helloworld@PAGE
	add  x0, x0, _helloworld@PAGEOFF
  
	bl _printf

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