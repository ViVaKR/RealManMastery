use std::ffi::CStr;
use std::io::{self, Write};
use std::os::raw::c_char;

pub mod console;

#[unsafe(no_mangle)]
pub extern "C" fn calc_sum(a: u64, b: u64) {
    println!("{} + {} = {}", a, b, a + b);
}

#[unsafe(no_mangle)]
pub extern "C" fn welcome_rust(num: u64) {
    println!("하하하하! 우주에 평화 !!!");
    println!("제독 법우님이 어셈블리에서 보내신 값: {}\n", num);
}

#[unsafe(no_mangle)]
pub extern "C" fn to_print(ptr: *const u8, len: usize) {
    let text = unsafe { std::str::from_utf8_unchecked(std::slice::from_raw_parts(ptr, len)) };
    print!("{}", text);
    io::stdout().flush().unwrap();
}

/// C-style 널 종료 문자열을 받아 안전하게 출력하는 세련된 Rust 대체제
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sys_print(fmt: *const c_char) -> i32 {
    if fmt.is_null() {
        return -1;
    }

    // 1. Raw poiner를 CStr로 안전하게 래핑 및 UTF-8 검증 (손실 없는 인코딩 처리)
    let c_str = unsafe { CStr::from_ptr(fmt) };
    let text = c_str.to_string_lossy();

    // 2. 버퍼링 문제 해결을 위한 동기화된 Fast-Path 출력
    let stdout = io::stdout();
    let mut handle = stdout.lock(); // Lock 을 직접 잡아 I/O 오버헤드를 최소화 함
    if write!(handle, "{}", text).is_ok() && handle.flush().is_ok() {
        text.len() as i32
    } else {
        -1
    }
}
