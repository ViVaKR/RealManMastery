.include "section_macros.inc"

// ====================================================================
//  part1_fundamentals.S — 파트1: 기초 문법 데모 전용 데이터
//  대상 데모: exit, for, if_else, csel, str_to_int, scanf,
//            writeline, ldrb, loop, function, delegate, variable1
//  ★ 이 파일 하나가 파트1 로직 파일들과 세트로 다른 프로젝트에
//    그대로 이식 가능해야 한다.
// ====================================================================

CSTRING_SECTION

.global _label_exit, _label_for, _label_csel, _label_if_else
.global _label_str_to_int, _label_scanf, _label_writeline, _label_ldrb
.global _label_loop, _label_function, _label_delegate, _label_variable1

.global _fmt_for_loop
.global _msg_hello_world
.global _msg_ldrb_sample, _fmt_char, _fmt_char_count
.global _fmt_loop, _fmt_loop_decimal
.global _fmt_function_result
.global _fmt_delegate_add, _fmt_delegate_sub

// --- 메뉴 라벨 ---
_label_exit:        .asciz "exit"
_label_for:          .asciz "for"
_label_csel:          .asciz "csel"
_label_if_else:       .asciz "if else"
_label_str_to_int:    .asciz "str to int"
_label_scanf:         .asciz "scanf"
_label_writeline:     .asciz "writeline"
_label_ldrb:          .asciz "ldrb"
_label_loop:          .asciz "loop"
_label_function:      .asciz "function"
_label_delegate:      .asciz "delegate"
_label_variable1:     .asciz "Variable 1"

// --- for: 반복 합계 데모 ---
_fmt_for_loop: .asciz "%lld 회 합계 %lld\n"

// --- writeline: Console.WriteLine 대응 데모 ---
_msg_hello_world: .asciz "Hello, World! Fine Thanks And You?"

// --- ldrb: 메모리에서 1바이트씩 읽는 데모 ---
_msg_ldrb_sample: .asciz "메모리에서 1바이트 읽기 데모 문자"
_fmt_char:         .asciz "%c"
_fmt_char_count:   .asciz "\n총 문자수: %lld"

// --- loop: 정수 루프 데모 ---
_fmt_loop:         .asciz "데이터 %lld 번째 값: %.3f\n"
_fmt_loop_decimal: .asciz "%.2f + %.2f = %.3f\n"   // ★ 원본 오타(deciaml) 수정. TODO(확인 필요): 실제 loop 데모가 이 서식을 쓰는지 대조

// --- function: 함수 호출 데모 ---
_fmt_function_result: .asciz "total: %d, count: %d\n"

// --- delegate: 함수 포인터(콜백) 데모 ---
_fmt_delegate_add: .asciz "%lld + %lld = %lld\n"
_fmt_delegate_sub: .asciz "%lld - %lld = %lld\n"

// --- delegate: 콜백 포인터 테이블 ---
// ⚠ _callback_add / _callback_sub는 delegate 데모 로직 파일에 정의될
//   실제 콜백 함수. 아직 업로드되지 않아 extern으로 가정.
.extern _callback_add, _callback_sub

CONST_DATA_SECTION
.global _delegate_ptr_add, _delegate_ptr_sub
_delegate_ptr_add: .quad _callback_add
_delegate_ptr_sub: .quad _callback_sub
