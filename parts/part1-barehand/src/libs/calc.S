
.include "section_macros.inc"

// [코드 구역]
// __TEXT,__text, regular, pure_instructions
CODE_SECTION
FUNC_START_FULL calc, 128
	mov x19, #0x25     // a = 37
	mov x20, #0x43     // b = 67
	add x21, x19, x20  // c = a + b
FUNC_EXIT_FULL 128


// 	int    main() {
// 	int    a = 37;     // 소스 1줄
// 	int    b = 67;     // 소스 1줄
// 	int    c = a + b;  // 소스 1줄 
// 	return 0;
// }
