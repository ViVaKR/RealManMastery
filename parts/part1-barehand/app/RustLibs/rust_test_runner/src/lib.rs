// rust_test_runner/src/lib.rs
#![allow(dead_code)] // ⚠️ 주의: 느낌표(!)가 꼭 들어가야 파일 전체에 적용되네!

// 빌드 스크립트(build.rs)가 컴파일한 어셈블리 정적 라이브러리를 연동합니다.
#[link(name = "rust_test_asm", kind = "static")]
// 1. 외부 어셈블리 함수 선언 모음
unsafe extern "C" {

    // 덧셈 테스트 용 (test_add.S)
    #[link_name = "test_add"]
    pub fn asm_test_add(a: i64, b: i64) -> i64;

    // 두 값 중 큰 값을 반환하는 어셈블리 함수 매핑
    #[link_name = "test_csel"]
    pub fn asm_test_csel(a: i64, b: i64) -> i64;

    // 👑 우주의 네이밍 컨벤션을 장착한 배열 합산 함수!
    #[link_name = "test_array_sum"]
    pub fn asm_test_array_sum(ptr: *const i64, len: i64) -> i64;
}

// -------------------------------------------------------------
// 🧪 단위 테스트 부대 (외부 노출 없는 순수 테스트 영역)
// -------------------------------------------------------------
#[cfg(test)]
mod tests {
    // 부모(super) 모듈에 있는 test_add 함수를 가져옵니다.
    use super::*;

    #[test]
    fn test_add() {
        // FFI 호출은 언제나 안전을 보장할 수 없으므로 unsafe 블록으로 감싸 정중히 호출합니다.
        let res = unsafe { asm_test_add(120, 34) };

        // 기댓값과 다르면 FAIL! 아주 깔끔하고 군더더기 없는 검증.
        assert_eq!(res, 154);
    }

    #[test]
    fn test_csel() {
        let result = unsafe { asm_test_csel(42, 99) };
        // Rust의 정석 assert! 기댓값(99)과 다르면 에러 메시지를 뿜으며 FAIL 처리됩니다.
        assert_eq!(result, 99, "최대값 구하기 실패! 99가 나와야 하네 제독!");
    }

    /// 🌌 [테스트 1] 정확히 4KB (1 Page) 분량의 배열 데이터 루프 검증!
    #[test]
    fn test_array_loop_exact_one_page() {
        // i64(8바이트) * 512개 = 4096바이트 (정확히 4KB 페이지 1개를 채우는 크기!)
        let mut data = vec![0i64; 512];

        // 계산하기 쉽게 모든 요소를 2로 채움 (총합 기댓값: 512 * 2 = 1024)
        for val in data.iter_mut() {
            *val = 2;
        }

        // 배열의 시작 메모리 주소를 확인하여 4KB 복습!
        let ptr = data.as_ptr();
        println!("\n💡 [4KB 복습] 현재 배열의 시작 메모리 주소: {:p}", ptr);
        println!(
            "💡 [4KB 복습] 배열이 끝나는 메모리 주소: {:p}",
            unsafe { ptr.add(512) }
        );
        // 어셈블리 부대 투입!
        let total_sum = unsafe { asm_test_array_sum(ptr, data.len() as i64) };

        // 무결점 검증
        assert_eq!(total_sum, 1024, "4KB 페이지 단일 순회중 데이터 유실 발생!");
    }
}

/*

cargo test -p rust_test_runner -- --nocapture

- 원래 cargo test는 성공한 테스트의 출력(stdout)은 굳이 보여주지 않고 뒤로 숨겨두는 게 기본 설정
- 오직 실패한 테스트의 피눈물 섞인 출력만 콘솔에 띄워줌.

- 성공했더라도 기어코 저 주소값 출력을 보고야 말겠다면,
- 아래와 같이 --nocapture 옵션을 뒤에 붙여서 격발!

- 주의: 중간에 꼭 -- (더블 대시)를 넣고 한 칸 띈 다음 **--nocapture**를 적어줘야 함!
- 앞의 --는 "여기서부터는 cargo 옵션이 아니라,
- 실제 테스트 실행 바이너리에게 전달할 옵션이다!"라고 선언하는 표식.

*/
