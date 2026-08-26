use std::ffi::CStr;
use std::io::{self, Write};
use std::os::raw::c_char;

// 어셈블리에서 전달할 파라미터 타입 (64비트 정수 또는 문자열 포인터)
#[repr(C)]
pub enum FfiArg {
    Int(i64),
    Str(*const c_char),
}

// .NET 의 params object[] 처럼 배열과 개수를 받아 동적 포맷팅
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sys_print_fmt(
    fmt: *const c_char,
    args_ptr: *const FfiArg,
    args_len: usize,
) -> i32 {
    if fmt.is_null() {
        return -1;
    }

    let fmt_str = unsafe { CStr::from_ptr(fmt) }.to_string_lossy();

    // Rust 슬라이스로 안전하게 변환
    let args = if args_ptr.is_null() || args_len == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(args_ptr, args_len) }
    };

    let mut result = String::with_capacity(fmt_str.len() + 32);
    let mut arg_idx = 0;
    let mut chars = fmt_str.chars().peekable();

    while let Some(ch) = chars.next() {
        // "{}" 패턴을 만나면 파라미터 배열에서 순서대로 꺼내어 대체!
        if ch == '{' && chars.peek() == Some(&'}') {
            chars.next(); // '}' 소비

            if let Some(arg) = args.get(arg_idx) {
                match arg {
                    FfiArg::Int(val) => result.push_str(&val.to_string()),
                    FfiArg::Str(ptr) => {
                        if !ptr.is_null() {
                            let s = unsafe { CStr::from_ptr(*ptr) }.to_string_lossy();
                            result.push_str(&s);
                        }
                    }
                }
                arg_idx += 1;
            } else {
                result.push_str("{}");
            }
        } else {
            result.push(ch);
        }
    }

    // Fast-path 동기화 출력
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    if write!(handle, "{}", result).is_ok() && handle.flush().is_ok() {
        result.len() as i32
    } else {
        -1
    }
}
