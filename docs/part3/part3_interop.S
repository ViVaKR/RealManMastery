.include "section_macros.inc"

// ====================================================================
//  part3_interop.S — 파트3: 언어 간 상호운용 데모 전용 데이터
//  대상 데모: rust_call1, rust_println, rust_tuple
//  ★ 이 파트는 지난 대화에서 다룬 "AOT는 상호운용 시나리오에서
//    선택이 아니라 전제조건이다"의 실습 파트에 대응.
// ====================================================================

CSTRING_SECTION

.global _label_rust_call1, _label_rust_println, _label_rust_tuple

_label_rust_call1:   .asciz "Rust Call 1"
_label_rust_println: .asciz "rust println"
_label_rust_tuple:   .asciz "rust tuple"

// TODO(확인 필요): 세 데모 모두 원본 data.S에 전용 서식/메시지가 없었음.
//   Rust 쪽에서 println!으로 직접 출력하고 ARM64/C# 쪽은 라벨만
//   필요한 구조라면 정상 — 로직 파일 확인 시 실제로 그런지만 대조.
