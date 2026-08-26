# Zig

Zig는 "C언어의 현대적 재설계이자, C/C++ 빌드 시스템을 대체하기 위해 태어난 시스템 프로그래밍 언어"입니다.

---

**Zig의 정체와 출생 목적**

2015년 Andrew Kelley가 창시한 언어로, 복잡해진 C++이나 복잡한 빌드 도구(CMake 등)의 구질구질함을 제거하고 "가장 명확하고 정직한 C의 대체제"를 목표로 태어났습니다.

* **C언어의 완벽한 수용:** 별도의 바인딩 작업 없이 C 헤더 파일(`.h`)을 직접 `@cImport`하여 바로 쓸 수 있으며, C 컴파일러(`zig cc`)로도 동작합니다.
* **통합 빌드 시스템:** CMake, Makefile 같은 외산 빌드 도구 없이 `build.zig`라는 **Zig 코드 자체로 빌드 스크립트**를 작성합니다.

* **크로스 컴파일의 혁신:** 플래그 하나만 주면 툴체인 추가 설치 없이 macOS에서 Linux/Windows 바이너리를 즉시 생성합니다.

---

**Zig를 관통하는 핵심 철학 (3無)**

1. **숨겨진 제어 흐름 없음:** 연산자 오버로딩, 프로퍼티(getter/setter)가 없어 코드에 적힌 그대로만 실행됩니다.
2. **숨겨진 메모리 할당 없음:** 모든 메모리 할당은 개발자가 `Allocator`를 통해 명시적으로 주입해야 하므로, 메모리 유출이나 힙 할당 위치를 완벽히 통제할 수 있습니다.
3. **매크로 없음:** C의 `#define` 같은 복잡한 전처리기가 없고, **`comptime`**(컴파일 타임 코드 실행) 키워드로 모든 메타프로그래밍을 해결합니다.

---

**Zig 기본 문법 핵심**

**변수 및 상수 선언**

```zig
const std = @import("std"); // 상수 (수정 불가)
var count: i32 = 10;        // 변수 (수정 가능)

```

**에러 처리 (Result 타입 방식)**
C처럼 에러 코드를 반환하거나 C++처럼 예외(Exception)를 던지지 않고, 에러 유무를 명시합니다.

```zig
fn divide(a: f32, b: f32) !f32 {
    if (b == 0) return error.DivisionByZero;
    return a / b;
}

// 사용할 때 try 키워드로 간단히 전파
const result = try divide(10.0, 2.0);

```

**명시적 메모리 할당과 `defer**`
자원 해제를 함수 끝에 깔끔하게 보장합니다.

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// 메모리 할당
const memory = try allocator.alloc(u8, 100);
defer allocator.free(memory); // 함수 종료 시 자동 해제!

```

---

C의 하드웨어 제어 능력과 최신 언어의 안전함, 그리고 CMake를 차버릴 수 있는 명쾌한 빌드 시스템까지 갖춘 녀석