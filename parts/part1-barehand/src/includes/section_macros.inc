// ====================================================
//  제목: 섹션 선언 및 함수 제어 매크로 모음 (hun.macros.inc)
//  목적: 장문의 지시문을 압축하고 ARM64 최적화 규칙을 강제함
// ====================================================

.ifndef HUN_SECTION_MACROS_INC
.set    HUN_SECTION_MACROS_INC, 1

// ------------------------------------------------------
// [코드 구역] __TEXT,__text
// 명령어는 무조건 4바이트 (2^2) 정렬
// 실제 기계어 명령어가 위치. pure_instructions = 순수 명령어 구역
// ------------------------------------------------------
.macro   CODE_SECTION
.section __TEXT, __text, regular, pure_instructions
.align 2
.endmacro

// -----------------------------------------------------
// [초기화된 변수] __DATA,__data
// 선언과 동시에 값이 존재하며, 실행 중 수정 가능한 전역/정적 변수 영역
// 일반 전역 변수 구역 안전하게 8바이트 정렬
// -----------------------------------------------------
.macro   DATA_SECTION
.section __DATA, __data
.align 3
.endmacro

// -----------------------------------------------------
// [C-스타일 문자열 리터럴] __TEXT,__cstring,cstring_literals
// printf 포맷 스트링 등 널 종료(null-terminated)
// 문자열 상수 전용 (읽기 전용)
// 바이트 스트림
// ------------------------------------------------------
.macro   CSTRING_SECTION
.section __TEXT, __cstring, cstring_literals
.align 3 // Read-Only 문자열 캐시라인 히트율 극대화
.endmacro

// -------------------------------------------------------
// [읽기전용 변수/포인터 테이블] __DATA,__const
// 동적 링킹 시점에 주소가 확정된 후 읽기 전용으로 보호되는 변수 구역
// 주소 재배치 후 읽기 전용으로 보호되는 섹션
// 함수 포인터 테이블, 델리게이트 리스트 등에 최적
// 64비트 주소값(.quad)들의 배열이므로 무조건 8바이트(2^3) 정렬
// -------------------------------------------------------
.macro   CONST_DATA_SECTION
    .section __DATA, __const
.align 3
.endmacro

// -----------------------------------------------------
// [읽기전용 상수 데이터] __TEXT,__const
// 룩업 테이블이나 배열을 담으므로 8바이트(2^3) 고정이 안전함
// 문자열이 아닌 일반 상수 (룩업 테이블, 상수 배열 등) - 재배치 불필요
// -----------------------------------------------------
.macro   CONST_SECTION
    .section __TEXT, __const
.align 3
.endmacro

// ----------------------------------------------------
// [4바이트 실수 상수] __TEXT,__literal4
// float(32비트) 리터럴 전용 이므로 무조건 4바이트(2^2) 정렬 고정
// ----------------------------------------------------
.macro   LITERAL4_SECTION
    .section __TEXT, __literal4, 4byte_literals
.align 2
.endmacro

// ---------------------------------------------------
// [8바이트 실수 상수] __TEXT,__literal8
// double(64비트) 리터럴 전용이므로 무조건 8바이트(2^3) 정렬 고정
// ---------------------------------------------------
.macro   LITERAL8_SECTION
    .section __TEXT, __literal8, 8byte_literals
.align 3
.endmacro

// -------------------------------------------------------
// [0으로 초기화된 변수] __DATA,__bss
// 초기값이 없거나 0인 변수. 바이너리 용량을 차지하지 않고 실행 시 0 할당
// 안전하게 8바이트 정렬
// -------------------------------------------------------
.macro   BSS_SECTION
    .section __DATA, __bss
.align 3
.endmacro

// -------------------------------------------------------------------
// [공용/잠정 정의 심볼] __DATA,__common
// 여러 오브젝트 간 중복 선언된 전역 변수를 링커가 단일화해주는 구역
// .globl _shared_value  ; 1. _sharted_value 라는 이름으로 외부에 공개할 건데,
// .comm _shared_value, 4, 2 ; 4바이트 짜리 임시 공용 예약 공간
// -------------------------------------------------------------------
.macro   COMMON_SECTION
    .section __DATA, __common
.endmacro


// --- [우아한 함수 프롤로그 / 에필로그 제어] ---

// ========================================================================
// [풀 스펙] 전원 참전형 함수 프롤로그 (독서실 레지스터 x19~x28 전원 백업)
// ARM64 규칙에 맞춰 2개씩 짝지어 안전하게 보관하네.
// 최소 stack_size는 독서실 10개(80바이트) + 프레임(16바이트) = 96바이트 이상이어야 함!
// ========================================================================
.macro FUNC_START_FULL name, stack_size
    .if    \stack_size < 96
        .error "FUNC_START_FULL: 모든 독서실을 쓰려면 stack_size는 최소 96 이상이어야 합니다!"
    .endif
    .if    (\stack_size % 16) != 0
        .error "FUNC_START_FULL: stack_size는 16의 배수여야 합니다. ARM64 SP 정렬 규칙"
    .endif
    
.global _\name
.align 2
_\name:
	// 1. 기본 독서실 총무(x29)와 다음갈곳(x30) 방 배정 및 스택 거대 확보
	stp x29, x30, [sp, #-\stack_size]!
	mov x29, sp
    
	// 2. x19부터 x28까지 총 10개의 독서실 레지스터를 16바이트 간격으로 풀 백업!
	stp x19, x20, [sp, #16]
	stp x21, x22, [sp, #32]
	stp x23, x24, [sp, #48]
	stp x25, x26, [sp, #64]
	stp x27, x28, [sp, #80]
.endmacro

// =====================================================
// [풀 스펙] 전원 참전형 함수 에필로그 (독서실 청소 및 복원)
// 들어올 때 어지럽힌 독서실 자리를 나갈 때 완벽하게 대청소하고 퇴장하네.
// =====================================================
.macro FUNC_EXIT_FULL stack_size
	// 1. 들어올 때와 정확히 대칭되는 위치에서 안전하게 복원 (청소 작업)
	ldp x19, x20, [sp, #16]
	ldp x21, x22, [sp, #32]
	ldp x23, x24, [sp, #48]
	ldp x25, x26, [sp, #64]
	ldp x27, x28, [sp, #80]
    
	// 2. 독서실 총무와 다음갈곳을 복구하며 확보했던 거대 스택 통째로 닫기
	ldp x29, x30, [sp], #\stack_size
    ret
.endmacro

// 프롤로그: 표준 프레임 설정 및 x19, x20 안전 백업 필수 보장
.macro FUNC_START name, stack_size
    .if    \stack_size < 32
        .error "FUNC_START: stack_size는 최소 32 이상이어야 합니다 (x19/x20 저장 공간 필요)"
    .endif

    .if    (\stack_size % 16) != 0
        .error "FUNC_START: stack_size는 16의 배수여야 합니다. ARM64 SP 정렬 규칙"
    .endif

.global _\name
.align 2                        // 명령어 시작점 4바이트 정렬 강제
    _\name:
	stp x29, x30, [sp, #-\stack_size]!
	mov x29, sp
	stp x19, x20, [sp, #16]
.endmacro

// 에필로그 (중량형): x19, x20을 쓰고 스택을 유동적으로 닫을 때
.macro FUNC_EXIT stack_size
	ldp x19, x20, [sp, #16]
	ldp x29, x30, [sp], #\stack_size
    ret
.endmacro

// [초경량형] x19, x20 백업 없이 오직 프레임 포인터(x29, x30)만 생성
.macro FUNC_START_LIGHT name, stack_size
    .if    \stack_size < 16
        .error "FUNC_START_LIGHT: stack_size는 최소 16 이상이어야 합니다!"
    .endif
    .if    (\stack_size % 16) != 0
        .error "FUNC_START_LIGHT: stack_size는 16의 배수여야 합니다. ARM64 SP 정렬 규칙"
    .endif
.global _\name
.align 2
    _\name:
	stp x29, x30, [sp, #-\stack_size]!
	mov x29, sp
.endmacro

// 에필로그 (초경량형): 내부에서 x19, x20을 안 쓰고 오직 프레임 포인터만 복원할 때
.macro FUNC_EXIT_LIGHT stack_size
	ldp x29, x30, [sp], #\stack_size
    ret
.endmacro

.endif
