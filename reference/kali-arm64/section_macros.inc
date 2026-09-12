// =================================================
//  제목: 섹션 선언 및 함수 제어 매크로 모음 (Linux ELF / AArch64 버전)
//  목적: Kali/Ubuntu 등 GNU as + ld 환경에 맞춘 섹션/함수 매크로.
//        Apple Mach-O 버전(section_macros.inc)과 매크로 이름·사용법은
//        완전히 동일하게 유지해서, .S 파일 쪽 코드는 거의 안 바뀌게 함.
// =================================================

.ifndef HUN_SECTION_MACROS_INC
.set    HUN_SECTION_MACROS_INC, 1

// ------------------------------------------------------
// [코드 구역] .text
// Mach-O의 "regular, pure_instructions" 속성은 ELF엔 없음.
// "실행 가능(x) + 메모리 할당(a)" 플래그만 명시하면 충분함.
// ------------------------------------------------------
.macro   CODE_SECTION
.section .text, "ax", %progbits
.align 2
.endm

// -----------------------------------------------------
// [초기화된 변수] .data
// 실행 중 값이 바뀔 수 있는 전역/정적 변수 영역.
// -----------------------------------------------------
.macro   DATA_SECTION
.section .data, "aw", %progbits
.align 3
.endm

// -----------------------------------------------------
// [C-스타일 문자열 리터럴]
// Mach-O의 __cstring(문자열 전용 병합 섹션) 같은 전용 타입이
// ELF엔 없어서 그냥 .rodata를 씀. (진짜 문자열 중복 병합까지
// 원하면 ".section .rodata.str1.1,\"aMS\",%progbits,1" 로 바꿀 것)
// -----------------------------------------------------
.macro   CSTRING_SECTION
.section .rodata, "a", %progbits
.align 3
.endm

// -----------------------------------------------------
// [읽기전용 변수/포인터 테이블] — __DATA,__const 대응
//
// ⚠️ 가장 중요한 차이점:
// _menu_table 처럼 함수 포인터·문자열 주소를 .quad 절대주소로
// 채워 넣는 테이블은, 리눅스 기본값인 PIE(위치독립실행파일)에서는
// 컴파일/링크 시점이 아니라 "로드 시점"에 동적 링커가 relocation을
// 채워 넣어야 함. 그래서 진짜 읽기전용(.rodata)에 두면
//   relocation R_AARCH64_ABS64 against symbol ...
//   recompile with -fPIC
// 같은 링크 에러가 남. 로드 시점까지는 "쓰기 가능"해야 하는
// .data.rel.ro 섹션에 둬야 함 (로더가 채운 뒤 다시 읽기전용으로
// mprotect 해줌 — RELRO 보안 기법과 동일한 메커니즘).
// -----------------------------------------------------
.macro   CONST_DATA_SECTION
.section .data.rel.ro, "aw", %progbits
.align 3
.endm

// -----------------------------------------------------
// [읽기전용 상수 데이터] — __TEXT,__const 대응
// 재배치가 필요 없는 순수 숫자/룩업 테이블은 진짜 .rodata에 둬도 안전.
// -----------------------------------------------------
.macro   CONST_SECTION
.section .rodata, "a", %progbits
.align 3
.endm

// ----------------------------------------
// [4바이트 실수 상수] — __TEXT,__literal4 대응
// ELF엔 전용 리터럴 섹션이 없어서 .rodata로 통합.
// ----------------------------------------
.macro   LITERAL4_SECTION
.section .rodata, "a", %progbits
.align 2
.endm

// ----------------------------------------
// [8바이트 실수 상수] — __TEXT,__literal8 대응
// ----------------------------------------
.macro   LITERAL8_SECTION
.section .rodata, "a", %progbits
.align 3
.endm

// ----------------------------------------
// [0으로 초기화된 변수] .bss
// ----------------------------------------
.macro   BSS_SECTION
.section .bss, "aw", %nobits
.align 3
.endm

// -------------------------------------------------------------------
// [공용/잠정 정의 심볼] — __DATA,__common 대응
// ELF에서는 .comm 지시어 자체가 "현재 섹션과 무관하게" 공용 심볼을
// 만들어주므로 원래 별도 섹션 전환이 필요 없음. 원본과 사용법을
// 맞추기 위해 매크로는 남겨두되, 실제로는 .bss로 전환만 해줌.
// -------------------------------------------------------------------
.macro   COMMON_SECTION
.section .bss, "aw", %nobits
.endm


// --- [우아한 함수 프롤로그 / 에필로그 제어] ---
// AAPCS64(리눅스 표준 ARM64 호출규약)도 SP 16바이트 정렬 의무는
// Apple ABI와 동일함. 스택 규칙 자체는 손댈 게 없고, 유일하게 바뀌는
// 건 "심볼 이름 앞 언더스코어 유무" 뿐 (_\name → \name).
// (또한 .endmacro → .endm 으로 교체: GNU as 표준 지시어)

.macro FUNC_START_FULL name, stack_size

    .if    \stack_size < 96
        .error "FUNC_START_FULL: 모든 독서실을 쓰려면 stack_size는 최소 96 이상이어야 합니다!"
    .endif
    .if    (\stack_size % 16) != 0
        .error "FUNC_START_FULL: stack_size는 16의 배수여야 합니다. ARM64 SP 정렬 규칙"
    .endif

.global \name
.align 2

\name:
	stp x29, x30, [sp, #-\stack_size]!
	mov x29, sp

	stp x19, x20, [sp, #16]
	stp x21, x22, [sp, #32]
	stp x23, x24, [sp, #48]
	stp x25, x26, [sp, #64]
	stp x27, x28, [sp, #80]
.endm

.macro FUNC_EXIT_FULL stack_size
	ldp x19, x20, [sp, #16]
	ldp x21, x22, [sp, #32]
	ldp x23, x24, [sp, #48]
	ldp x25, x26, [sp, #64]
	ldp x27, x28, [sp, #80]

	ldp x29, x30, [sp], #\stack_size
    ret
.endm

.macro FUNC_START name, stack_size
    .if    \stack_size < 32
        .error "FUNC_START: stack_size는 최소 32 이상이어야 합니다 (x19/x20 저장 공간 필요)"
    .endif

    .if    (\stack_size % 16) != 0
        .error "FUNC_START: stack_size는 16의 배수여야 합니다. ARM64 SP 정렬 규칙"
    .endif

.global \name
.align 2
    \name:
	stp x29, x30, [sp, #-\stack_size]!
	mov x29, sp
	stp x19, x20, [sp, #16]
.endm

.macro FUNC_EXIT stack_size
	ldp x19, x20, [sp, #16]
	ldp x29, x30, [sp], #\stack_size
    ret
.endm

.macro FUNC_START_LIGHT name, stack_size
    .if    \stack_size < 16
        .error "FUNC_START_LIGHT: stack_size는 최소 16 이상이어야 합니다!"
    .endif
    .if    (\stack_size % 16) != 0
        .error "FUNC_START_LIGHT: stack_size는 16의 배수여야 합니다. ARM64 SP 정렬 규칙"
    .endif
.global \name
.align 2
    \name:
	stp x29, x30, [sp, #-\stack_size]!
	mov x29, sp
.endm

.macro FUNC_EXIT_LIGHT stack_size
	ldp x29, x30, [sp], #\stack_size
    ret
.endm

.endif
