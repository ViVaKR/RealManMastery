# SapienMastery 데이터 계층 네이밍 컨벤션

> 이 문서는 강좌 콘텐츠가 아니라 **프로젝트 운영 규칙**입니다.
> 새 데모를 추가할 때마다 이 표를 기준으로 심볼 이름을 정하세요.

## 1. 접두사 규칙 — 이름만 보고 타입을 알 수 있게

| 접두사 | 의미 | 판별 기준 | 예시 |
|---|---|---|---|
| `_ui_` | 메뉴 프레임워크 자체의 장식 문구 (특정 데모와 무관, 전 프로젝트 공통) | 어떤 데모를 지워도 이 문자열은 남아야 함 | `_ui_menu_title`, `_ui_press_enter` |
| `_prompt_` | 사용자에게 입력을 요구하는 문구 | 문장이 콜론(:)이나 화살표로 끝나며 입력 대기로 이어짐 | `_prompt_select_menu`, `_prompt_two_numbers` |
| `_msg_` | 완결된 안내/오류 메시지 (`%` 서식지정자 없음) | printf에 인자 없이 그대로 찍힘 | `_msg_input_error` |
| `_fmt_` | printf류 서식 문자열 (`%` 서식지정자 포함) | 반드시 `bl _printf`류 호출과 함께 인자를 동반 | `_fmt_sum`, `_fmt_fib_result` |
| `_label_` | 메뉴에 표시되는 항목 이름 (구 `_str_*`) | `_menu_table`의 두 번째 필드로만 쓰임 | `_label_for`, `_label_hanoi` |
| `_const_` | 수치 상수 (문자열 아님) | `.float`/`.double`/`.quad` 등 순수 값 | `_const_pi_f32` |

**판별 팁**: `_fmt_`와 `_msg_`를 헷갈리면 "printf 인자가 있는가?"만 물어보세요. 있으면 `_fmt_`, 없으면 `_msg_`. `_msg_`와 `_prompt_`는 "이 문자열 출력 직후 scanf가 뒤따르는가?"로 구분하세요.

## 2. 파일 레이아웃

```
src/data/
  section_macros.inc     # 기존 유지
  ui_chrome.S             # 메뉴 프레임워크 공통 (영구 재사용 라이브러리)
  constants_math.S        # 수치 상수 (PI 등)
  dispatch_table.S        # 메뉴 디스패치 테이블 (glue, 로직 없음)
  part1_fundamentals.S    # exit, for, if_else, csel, scanf, str_to_int,
                           # writeline, ldrb, loop, function, delegate, variable1
  part2_algorithms.S      # guess, fibonacci, hanoi, sum_numbers, gcd,
                           # palindrome, quicksort
  part3_interop.S         # rust_call1, rust_println, rust_tuple
  part4_hardware.S        # adc, madd, msub, sys_print, sys_print_fmt, pi_print
```

**원칙**: 각 데모의 문자열은 그 데모의 로직 파일과 같은 "파트 파일"에 산다. 나중에 part2 전체를 다른 프로젝트로 이식하고 싶으면 `part2_algorithms.S` 하나(+ 로직 파일들)만 복사하면 됩니다.

## 3. 전체 심볼 이관표 (구 이름 → 신 이름)

⚠️ 기존 데모 로직 파일(.S)에서 이 심볼들을 참조하고 있다면, 로직 파일도 함께 갱신해야 합니다. 아래 표 기준으로 프로젝트 전체에 검색-치환을 돌리세요.

### ui_chrome.S로 이동
| 구 이름 | 신 이름 |
|---|---|
| `_input_prompt_select_menu` | `_prompt_select_menu` |
| `_input_prompt_numbers` | `_prompt_two_numbers` |
| `_err_format` | `_fmt_invalid_choice` |
| `_press_enter` | `_ui_press_enter` |
| `_exit_message` | `_ui_exit_message` |
| `_menu_title` | `_ui_menu_title` |
| `_menu_format` | `_fmt_menu_item` |
| `_line_char` | `_ui_line_char` |
| `_newline_str` | `_ui_newline` |
| `_icon_heart` | `_ui_icon_heart` |
| `_fmt_scanf_1` | `_fmt_scan_i64` |
| `_fmt_scanf_2` | `_fmt_scan_2i64` |
| `_fmt_result` | `_fmt_result_i64` |
| `_msg_input_error` | `_msg_input_error` (변경 없음, 이미 규칙 준수) |

### constants_math.S로 이동
| 구 이름 | 신 이름 |
|---|---|
| `_pi_float` | `_const_pi_f32` |
| `_pi_double` | `_const_pi_f64` |

### part1_fundamentals.S로 이동
| 구 이름 | 신 이름 | 소속 데모 |
|---|---|---|
| `_str_exit` | `_label_exit` | exit |
| `_str_forloop` | `_label_for` | for |
| `_fmt_for_loop` | `_fmt_for_loop` (유지) | for |
| `_str_csel` | `_label_csel` | csel |
| `_str_if_else` | `_label_if_else` | if_else |
| `_str_string_to_integer` | `_label_str_to_int` | str_to_int |
| `_str_readline` | `_label_scanf` | scanf |
| `_str_console_writeline` | `_label_writeline` | writeline |
| `_helloworld` | `_msg_hello_world` | writeline |
| `_str_ldrb` | `_label_ldrb` | ldrb |
| `_ldrb_sample_string` | `_msg_ldrb_sample` | ldrb |
| `_char_format` | `_fmt_char` | ldrb |
| `_char_len` | `_fmt_char_count` | ldrb |
| `_str_loop_int` | `_label_loop` | loop |
| `_fmt_loop` | `_fmt_loop` (유지) | loop |
| `_fmt_loop_deciaml` | `_fmt_loop_decimal` (오타 수정) | loop |
| `_str_function_call` | `_label_function` | function |
| `_fmt_demo` | `_fmt_function_result` | function |
| `_str_delegate` | `_label_delegate` | delegate |
| `_fmt_delegate_add` | `_fmt_delegate_add` (유지) | delegate |
| `_fmt_delegate_sub` | `_fmt_delegate_sub` (유지) | delegate |
| `_delegate_add` | `_delegate_ptr_add` | delegate |
| `_delegate_sub` | `_delegate_ptr_sub` | delegate |
| `_str_variable_size` | `_label_variable1` | variable1 |

### part2_algorithms.S로 이동
| 구 이름 | 신 이름 | 소속 데모 |
|---|---|---|
| `_str_guess_game` | `_label_guess` | guess |
| `_str_fib` | `_label_fibonacci` | fibonacci |
| `_msg_input_number_fib` | `_prompt_fib_count` | fibonacci |
| `_fmt_fib_result` | `_fmt_fib_result` (유지) | fibonacci |
| `_str_hanoi` | `_label_hanoi` | hanoi |
| `_str_sum_numbers` | `_label_sum_numbers` | sum_numbers |
| `_fmt_sum` | `_fmt_sum` (유지) | sum_numbers |
| `_fmt_sum_float` | `_fmt_sum_float` (유지, 대응 데모 확인 필요) | sum_numbers(?) |
| `_str_gcd` | `_label_gcd` | gcd |
| `_fmt_result_mod` | `_fmt_result_mod` (유지) | gcd |
| `_str_is_palindrome` | `_label_palindrome` | palindrome |
| `_str_quicksort` | `_label_quicksort` | quicksort |
| `_label_before` | `_msg_sort_before` | quicksort |
| `_label_after` | `_msg_sort_after` | quicksort |
| `_list_format` | `_fmt_array_index` | quicksort |

### part3_interop.S로 이동
| 구 이름 | 신 이름 | 소속 데모 |
|---|---|---|
| `_str_welcome_rust` | `_label_rust_call1` | rust_call1 |
| `_str_rust_demo` | `_label_rust_println` | rust_println |
| `_str_rust_demo_tup` | `_label_rust_tuple` | rust_tuple |

### part4_hardware.S로 이동
| 구 이름 | 신 이름 | 소속 데모 |
|---|---|---|
| `_str_adc` | `_label_adc` | adc |
| `_str_madd` | `_label_madd` | madd |
| `_fmt_result_madd` | `_fmt_result_madd` (유지) | madd |
| `_str_msub` | `_label_msub` | msub |
| `_str_sys_print` | `_label_sys_print` | sys_print |
| `_str_sys_print_fmt` | `_label_sys_print_fmt` | sys_print_fmt |
| `_str_pi_print` | `_label_pi_print` | pi_print |
| `_fmt_float` | `_fmt_pi_f32` | pi_print |
| `_fmt_double` | `_fmt_pi_f64` | pi_print |

## 4. 로직 파일 갱신용 sed 스크립트 (참고용)

로직 `.S` 파일들에서 옛 심볼을 참조 중이라면, 아래 패턴으로 일괄 치환할 수 있습니다 (실행 전 반드시 git commit 또는 백업):

```zsh
# 예시 일부 — 위 표 전체를 sed -e 로 이어붙여서 한 번에 실행 권장
find src -name '*.S' -exec sed -i '' \
  -e 's/_str_forloop/_label_for/g' \
  -e 's/_str_exit/_label_exit/g' \
  -e 's/_input_prompt_select_menu/_prompt_select_menu/g' \
  -e 's/_press_enter/_ui_press_enter/g' \
  -e 's/_exit_message/_ui_exit_message/g' \
  {} +
```

⚠️ 표 전체를 다 넣진 않았습니다 — 이관표를 보고 필요한 줄만 추가하시거나, 원하시면 표 전체 기준 완성된 스크립트를 별도로 만들어드릴게요.

## 5. "확인 필요" 플래그 안내

split된 각 `.S` 파일에 `// TODO(확인 필요):` 주석이 몇 군데 있습니다. 원본 `data.S`만으로는 어떤 데모가 그 문자열을 쓰는지 100% 단정할 수 없었던 항목들이라, 실제 로직 파일과 대조해서 맞는 파일로 옮겨주세요.
