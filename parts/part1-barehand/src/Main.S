.include "section_macros.inc"

// [코드 구역]
// __TEXT,__text, regular, pure_instructions
CODE_SECTION
FUNC_START main, 32

	mov x19, #0x25
	mov x20, #0x43
	add x0, x19, x20
	
	bl _csharp_entry
	bl _calc
	
	mov x0, x19
	mov x1, x20
	bl  _add_i64
	
	mov x2, x0
	mov x0, x19
	mov x1, x20
	
	// i32 호출 시: w0, w1, w2 사용
	// i64 호출 시: x0, x1, x2 사용
	// f64 호출 시: d0, d1, d2 레지스터 사용
	bl _console_writeline_i64
	
	mov x0, #88
	
	bl _welcome_rust
	
	mov x0, #0
FUNC_EXIT 32