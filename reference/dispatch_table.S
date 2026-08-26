.include "section_macros.inc"

// ====================================================================
//  dispatch_table.S — 메뉴 디스패치 테이블 (순수 glue, 로직 없음)
//  ★ 이 파일은 "무엇을 어디로 연결할지"만 안다. 실제 로직/문자열은
//    각 파트 데모 파일(part1_fundamentals.S 등)이 소유한다.
//  ⚠ 함수 심볼(_menu_forloop 등)은 아직 분리되지 않은 각 데모의
//    루틴 파일에 정의되어 있다고 가정하고 .extern 처리했다.
//    실제 루틴 파일을 분리할 때 이름이 다르면 이 파일의 .extern 목록과
//    아래 테이블만 고치면 된다 — 로직 파일 자체는 안 건드려도 된다.
// ====================================================================

// --- 데모 루틴 (각 데모 구현 파일에서 정의될 것으로 가정) ---
.extern _menu_exit, _menu_forloop, _csel, _menu_welcome_rust, _if_else
.extern _string_to_number, _readline, _delegate, _menu_function_call, _menu_loop_int
.extern _console_writeline, _mnemonic_ldrb, _guess_game, _fib_print, _variable_size
.extern _hanoi, _sum_of_numbers, _gcd, _is_palindrome, _quicksort
.extern _mnemonic_adc, _mnemonic_madd, _mnemonic_msub, _run_sys_print, _run_sys_print_fmt
.extern _demo, _demo_tuple, _pi_print

// --- 메뉴 라벨 (각 파트 데이터 파일에서 정의됨: part1~4) ---
.extern _label_exit, _label_for, _label_csel, _label_rust_call1, _label_if_else
.extern _label_str_to_int, _label_scanf, _label_delegate, _label_function, _label_loop
.extern _label_writeline, _label_ldrb, _label_guess, _label_fibonacci, _label_variable1
.extern _label_hanoi, _label_sum_numbers, _label_gcd, _label_palindrome, _label_quicksort
.extern _label_adc, _label_madd, _label_msub, _label_sys_print, _label_sys_print_fmt
.extern _label_rust_println, _label_rust_tuple, _label_pi_print

CONST_DATA_SECTION
.global _menu_table, _menu_table_end

_menu_table:
    .quad _menu_exit,          _label_exit                 // 0
    .quad _menu_forloop,       _label_for
    .quad _csel,               _label_csel
    .quad _menu_welcome_rust,  _label_rust_call1
    .quad _if_else,            _label_if_else
    .quad _string_to_number,   _label_str_to_int           // 5
    .quad _readline,           _label_scanf
    .quad _delegate,           _label_delegate
    .quad _menu_function_call, _label_function
    .quad _menu_loop_int,      _label_loop
    .quad _console_writeline,  _label_writeline            // 10
    .quad _mnemonic_ldrb,      _label_ldrb
    .quad _guess_game,         _label_guess
    .quad _fib_print,          _label_fibonacci
    .quad _variable_size,      _label_variable1
    .quad _hanoi,              _label_hanoi                // 15
    .quad _sum_of_numbers,     _label_sum_numbers
    .quad _gcd,                _label_gcd
    .quad _is_palindrome,      _label_palindrome
    .quad _quicksort,          _label_quicksort
    .quad _mnemonic_adc,       _label_adc                  // 20
    .quad _mnemonic_madd,      _label_madd
    .quad _mnemonic_msub,      _label_msub
    .quad _run_sys_print,      _label_sys_print
    .quad _run_sys_print_fmt,  _label_sys_print_fmt
    .quad _demo,               _label_rust_println         // 25
    .quad _demo_tuple,         _label_rust_tuple
    .quad _pi_print,           _label_pi_print
_menu_table_end:
