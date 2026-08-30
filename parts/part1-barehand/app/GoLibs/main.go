package main

import "C"

import "fmt"

// ==================== FFI 외부 노출 ====================
// ARM64 호출 규약: w0 = a, w1 = b, 리턴값은 w0.
// .NET의 [UnmanagedCallersOnly(EntryPoint = "...")] 와 동일한 역할.
//
// Go 네이티브 고정폭 타입(int32)을 그대로 노출 —
// cgo가 자동으로 C 헤더의 GoInt32(=int32_t)로 매핑해주니
// C.int32_t / #include <stdint.h> 는 필요 없다네.
//
//export go_add
func go_add(a int32, b int32) int32 {
	return a + b
}

//export go_sub
func go_sub(a int32, b int32) int32 {
	return a - b
}

// ==================== 순혈주의 출력 (printf/scanf 대체) ====================
// C의 printf/scanf는 포맷 스트링 취약점, 버퍼 관리, null-termination 같은
// 구질구질한 책임을 떠안기 마련이지. 여기선 Go의 fmt가 GC 관리 하에
// 메모리 안전하게 처리하도록 맡겨버리네.
// 어셈블리 입장에선 w0, w1, w2에 값 채워넣고 bl 하면 끝 — printf처럼
// 포맷 문자열 주소를 따로 만들어 넘길 필요가 아예 없어지는 게 핵심이라네.

//export go_print_int
func go_print_int(v int32) {
	fmt.Println(v)
}

//export go_print_sum
func go_print_sum(a int32, b int32, sum int32) {
	fmt.Printf("[Go] %d + %d = %d\n", a, b, sum)
}

// c-shared / c-archive 빌드모드는 반드시 package main + func main() 을
// 요구하지만, 이 main()은 절대 실행되지 않는 형식상의 빈 껍데기라네.
// 실제 진입점은 위의 //export 함수들 뿐이야.
func main() {}
