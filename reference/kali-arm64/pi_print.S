.include "section_macros.inc"

// [코드 구역] .text
CODE_SECTION
FUNC_START_FULL pi_print, 128

	// ================================================
	// 1. LITERAL4_SECTION(float) 상수를 불러와서 출력
	// ================================================
	// (1) pi_float 메모리 주소 로드
	//     Apple : adrp x10, _pi_float@PAGE  / add x10, x10, _pi_float@PAGEOFF
	//     Linux : adrp x10, pi_float        / add x10, x10, :lo12:pi_float
	//     → 언더스코어 없음 + @PAGE/@PAGEOFF 대신 :lo12: 재배치 지시자
	adrp x10, pi_float
	add  x10, x10, :lo12:pi_float

	// (2) 32비트 float 값 로드 (s 레지스터 사용)
	ldr s0, [x10]  // 3.1415927 (float)

	// (3) printf 전달을 위해 float(s0) -> double(d0)로 정밀도 확장
	fcvt d0, s0  // d0 = (double)s0

	// (4) 포맷 문자열 로드 후 printf 호출 (glibc printf, 언더스코어 없음)
	adrp x0, fmt_float
	add  x0, x0, :lo12:fmt_float
	sub  sp, sp, #16
	str  d0, [sp, #0]
	bl   printf
	add  sp, sp, #16

	mov x0, #0

FUNC_EXIT_FULL 128

// -----------------------------------------------------------------
// 참고: 원본 pi_print.S엔 pi_float / fmt_float 정의가 없어서
// (다른 데이터 전용 파일에 있었을 것으로 추정) 여기선 예시로 채워둠.
// 실제 교안에선 기존 데이터 정의 파일을 그대로 이 패턴대로만
// 바꿔주면 됨.
// -----------------------------------------------------------------
LITERAL4_SECTION
pi_float: .float 3.1415927

CSTRING_SECTION
fmt_float: .asciz "pi is approximately %f\n"
