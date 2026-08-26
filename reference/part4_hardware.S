.include "section_macros.inc"

// ====================================================================
//  part4_hardware.S — 파트4: 하드웨어/명령어 레벨 데모 전용 데이터
//  대상 데모: adc, madd, msub, sys_print, sys_print_fmt, pi_print
// ====================================================================

CSTRING_SECTION

.global _label_adc, _label_madd, _label_msub
.global _label_sys_print, _label_sys_print_fmt, _label_pi_print

.global _fmt_result_madd
.global _fmt_pi_f32, _fmt_pi_f64

// --- 메뉴 라벨 ---
_label_adc:            .asciz "ADC"
_label_madd:            .asciz "MADD 1"
_label_msub:            .asciz "MSUB"
_label_sys_print:       .asciz "sys print"
_label_sys_print_fmt:   .asciz "sys print fmt"
_label_pi_print:        .asciz "PI Print"

// --- adc: Add with Carry 데모 ---
// TODO(확인 필요): 원본에 전용 서식 없음. 범용 _fmt_result_i64(ui_chrome.S) 재사용 추정.

// --- madd: Multiply-Add 데모 ---
_fmt_result_madd: .asciz "madd result: %lld\n"

// --- msub: Multiply-Subtract 데모 ---
// TODO(확인 필요): 원본에 전용 서식 없음. 범용 _fmt_result_i64(ui_chrome.S) 재사용 추정.

// --- sys_print: raw write() 시스템콜 데모 (printf 미사용이 정상) ---
// (서식 문자열이 없는 게 정상 — 이 데모의 포인트가 "printf 없이 직접 syscall" 이므로)

// --- sys_print_fmt: 서식 있는 시스템콜 데모 ---
// TODO(확인 필요): "fmt"가 이름에 있는데 전용 서식이 원본에 없음. 로직 파일 확인 필요.

// --- pi_print: float/double PI 레지스터 데모 (constants_math.S의 _const_pi_f32/_const_pi_f64와 짝) ---
_fmt_pi_f32: .asciz "🍓 Float  (32-bit PI) : %.7f\n"
_fmt_pi_f64: .asciz "🍒 Double (64-bit PI) : %.15lf\n"
