.include "section_macros.inc"

// ====================================================================
//  ui_chrome.S — 메뉴 프레임워크 공통 UI 문구
//  ★ 이 파일은 "이번 강좌"가 아니라 "앞으로 만들 모든 CLI 프로젝트"에
//    그대로 복사해 쓸 수 있도록 설계한다. 특정 데모 주제와 무관한,
//    메뉴 시스템 자체의 문구/서식/범용 유틸리티 서식만 담는다.
//  ⚠ 새 데모 전용 문자열은 여기 넣지 말 것 — 해당 partN_*.S 파일 소관.
// ====================================================================

CSTRING_SECTION

.global _prompt_select_menu
.global _prompt_two_numbers
.global _ui_press_enter
.global _ui_exit_message
.global _ui_menu_title
.global _ui_line_char
.global _ui_newline
.global _ui_icon_heart
.global _fmt_menu_item
.global _fmt_invalid_choice
.global _fmt_scan_i64
.global _fmt_scan_2i64
.global _fmt_result_i64
.global _msg_input_error

// --- 프롬프트: 사용자 입력을 요구하는 문구 (여러 데모가 공유) ---
_prompt_select_menu: .asciz "\n🍒 원하는 메뉴를 선택하세요 🍒 ⇢ "
_prompt_two_numbers: .asciz "두 정수 입력: "

// --- UI 장식: 메뉴 렌더링 자체에만 쓰이는 문구 (특정 데모와 무관) ---
_ui_menu_title:    .asciz "😎 메뉴목록 😎 "
_ui_line_char:     .asciz "👻"
_ui_newline:       .asciz "\n"
_ui_icon_heart:    .asciz "💖 "
_ui_press_enter:   .asciz "\n🧚 엔터(Enter) 키를 누르면 메뉴로 돌아갑니다..."
_ui_exit_message:  .asciz "\n👻 👻 👻 좋은 경험이었습니다. 다음에 또 멋지게 만나요!! 👻 👻 👻\n\n"

// --- 범용 서식: 특정 데모 주제에 종속되지 않는, 여러 데모가 공유하는 포맷 ---
_fmt_menu_item:      .asciz "%2d: %-15s"    // 메뉴 항목 한 칸 렌더링
_fmt_invalid_choice: .asciz "잘못된 선택입니다. (선택범위: 1 ~ %lld)\n"
_fmt_scan_i64:        .asciz "%lld"          // scanf 정수 1개 읽기 공통 서식
_fmt_scan_2i64:       .asciz "%lld %lld"      // scanf 정수 2개 읽기 공통 서식
_fmt_result_i64:      .asciz "결과: %lld\n"    // 범용 "결과: N" 출력 (특정 데모 전용 서식이 없을 때 기본값으로 사용)

// --- 범용 메시지: 입력 검증 실패 시 여러 데모가 공통으로 쓰는 안내문 ---
_msg_input_error: .asciz "잘못된 입력입니다.\n"
