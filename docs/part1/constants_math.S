.include "section_macros.inc"

// ====================================================================
//  constants_math.S — 순수 수치 상수
//  ★ "값 자체가 지식"인 것들만 모은다. 출력용 서식 문자열은 여기 두지
//    않는다 (해당 데모를 소유한 partN_*.S 파일 소관 — 예: pi_print의
//    _fmt_pi_f32/_fmt_pi_f64는 part4_hardware.S에 있다).
// ====================================================================

LITERAL4_SECTION
.global _const_pi_f32
_const_pi_f32: .float 3.1415927            // 32비트 단정도 PI

LITERAL8_SECTION
.global _const_pi_f64
_const_pi_f64: .double 3.141592653589793   // 64비트 배정밀도 PI
