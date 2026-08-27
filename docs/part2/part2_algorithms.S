.include "section_macros.inc"

// ====================================================================
//  part2_algorithms.S — 파트2: 알고리즘 데모 전용 데이터
//  대상 데모: guess, fibonacci, hanoi, sum_numbers, gcd,
//            palindrome, quicksort
// ====================================================================

CSTRING_SECTION

.global _label_guess, _label_fibonacci, _label_hanoi, _label_sum_numbers
.global _label_gcd, _label_palindrome, _label_quicksort

.global _prompt_fib_count, _fmt_fib_result
.global _fmt_sum, _fmt_sum_float
.global _fmt_result_mod
.global _msg_sort_before, _msg_sort_after, _fmt_array_index

// --- 메뉴 라벨 ---
_label_guess:       .asciz "Guess"
_label_fibonacci:   .asciz "Fibonacci"
_label_hanoi:        .asciz "Hanoi"
_label_sum_numbers:  .asciz "Sum Numbers"
_label_gcd:           .asciz "GCD"
_label_palindrome:    .asciz "Palindrome"
_label_quicksort:     .asciz "Quick Sort"

// --- guess: 숫자 맞추기 게임 ---
// TODO(확인 필요): 원본 data.S에서 이 데모 전용 프롬프트/메시지를 못 찾음.
//   ("숫자를 맞춰보세요", "너무 큽니다" 류) 실제 로직 파일에 인라인돼
//   있거나 별도 파일에 있을 수 있음 — 로직 파일 분리 시 확인.

// --- fibonacci ---
_prompt_fib_count: .asciz "피보나치 시행 할 정수 입력: "
_fmt_fib_result:   .asciz "(fib)\ninput\t--> %lld\nresult\t--> %lld\n"

// --- hanoi ---
// TODO(확인 필요): 원본에서 하노이 탑 전용 서식을 찾지 못함.
//   (예: "%lld번째 이동: %c → %c" 류) 로직 파일 확인 후 추가.

// --- sum_numbers ---
_fmt_sum:       .asciz "%lld + %lld = %lld\n"
_fmt_sum_float: .asciz "%.2f + %.2f = %.3f\n"   // TODO(확인 필요): float 버전 sum 데모가 실제 존재하는지 대조

// --- gcd ---
_fmt_result_mod: .asciz "%lld %% %lld = %lld\n"

// --- palindrome ---
// TODO(확인 필요): 원본에서 팰린드롬 전용 서식을 찾지 못함 (예: "%s 는 회문입니다" 류)

// --- quicksort: 정렬 전/후 배열 출력 ---
_msg_sort_before: .asciz "\n정렬 전: "
_msg_sort_after:  .asciz "정렬 후: "
_fmt_array_index: .asciz "Index [%lld]: Value = %lld\n"
