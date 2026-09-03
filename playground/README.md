# Background knowledge

**ARM64 어셈블리 언어**는
"고급언어 문법 목록"을 그대로 1:1 매핑하려 하면 오히려 어색해 지므로
어셈블리는 _문법_ 이 아니라 **"레지스터 + 메모리 + 분기"** 라는 
훨씬 적은 원시 개념으로 모든 걸 표현하므로 아래의 6단계로 기초 배경지식을 필요로 함.

## 1단계 — 자료형 → "저장 공간의 크기와 해석"
고급언어의 `int, float, char, bool...` 대신 ARM64에서는:
- 레지스터 폭: W(32bit) vs X(64bit)
- 정수 부호/비부호 → LDRSB/LDRB, SXTW 같은 확장 명령
- 부동소수점 → S/D 레지스터 (FP/SIMD 유닛)
- 엔디언, 정렬(alignment) 개념

즉 "자료형"이 아니라 **"이 데이터를 몇 바이트로, 어떻게 읽고 확장할 것인가"**로 재정의.

## 2단계 — 변수 → "저장 위치 3분류"
- 레지스터 (임시)
- 스택 (지역변수, SP 기준 오프셋)
- 메모리/전역 (ADRP+ADD로 주소 계산)

여기서 "변수 선언"이라는 개념 자체가 없고 "값을 어디에 둘 것인가"만 있다는 걸 강조하면 학습자가 헷갈리지 않네.

## 3단계 — 연산자 → 산술/논리/시프트 명령 + 조건 플래그(NZCV)
`+, -, *, /, %, <<, >>, &, |, ^` 하나하나를 대응 명령어로 매핑하고, **CMP/CMN이 플래그를 세팅한다**는 개념을 여기서 먼저 못 박아야 다음 단계(if/for)가 자연스럽게 이어지네.

## 4단계 — 제어문 → "조건부 분기의 조합"
여기가 핵심 포인트인데, 고급언어의 `if/for/while/switch`는 사실 ARM64 관점에서 전부 **CMP + B.cond + B**의 조합일 뿐이야.
- `if` → CMP + B.cond (조건 실패 시 skip)
- `while/for` → 조건 체크 + 무조건 분기(루프백)
- `switch` → 점프 테이블(ADR + LDR + BR) 또는 단순 CMP 체인

그래서 "if, for, switch를 각각 별개 문법"으로 안 가르치고, **"분기 = 조건 + 목적지"라는 하나의 원리**로 통합해서 가르친 다음, 그 위에서 패턴별 관용구(idiom)로 보여주는 게 학습자에게 훨씬 예측 가능해 보이네.

## 5단계 — 함수 → 호출 규약(AAPCS64)
- 인자 전달: X0~X7
- 리턴값: X0(또는 X0/X1 쌍)
- BL/RET, 스택 프레임 관리(스택 정렬 16바이트!)
- 지역변수의 저장(callee-saved 레지스터 X19~X28)

## 6단계 — 배열/포인터/구조체 → 주소 연산
- 배열 인덱싱 → LDR/STR의 addressing mode (base+offset, base+register<<shift)
- 구조체 → 필드 오프셋 상수화
- 포인터 연산 = 그냥 정수 덧셈이라는 걸 명확히

---

### 순서

1. 레지스터/자료형(크기와 해석)
2. 저장 위치(레지스터/스택/메모리)
3. 산술·논리 명령 + 플래그
4. 분기 원리 → if/loop/switch 패턴
5. 함수 호출 규약
6. 배열/포인터/구조체(주소 계산)

즉, 목차 자체가 고급언어 학습자에게 "낯익은 이름"이면서도, 
내부적으로는 ARM64의 진짜 원리(레지스터+분기+주소계산)로 자연스럽게 흘러가게됨

---

## 오케스트레이터 : zig (build.zig)

- .NET AOT (DotnetLibs.csproj, NativeLib=Shared, PublishAot=true) → .dylib/.so

- Go (main.go, -buildmode=c-shared) → libgo_core.dylib/.so

- Rust (lib.rs, console.rs) → librust_core.dylib/.so

> 세 개를 각각 빌드한 뒤, **ARM64 어셈블리로 작성된 `src/*.S`**와 함께 `RealManApp` 실행파일로 링크하는 구조
  `link_libc = true`가 걸려있으므로, 순수 시스템 콜이 아니라 **C 런타임(crt) 위에서 도는 진짜 `main`**을 쓰는 방식으로 강좌 구성


## `_start` → `main`

- `_start`는 커널이 프로세스에 직접 넘겨주는 진입점이라 **런타임 초기화(libc, TLS, 스택 정렬 등)를 전혀 안 해준 상태**로 시작함. 
   Linux ELF에서는 관용적으로 되지만, macOS(Mach-O)는 Apple 자체 `crt1.o`가 `_start`를 이미 점유하고 있어서 사용자가 재정의하는 걸 보장 안 함
   
- 반면 `main`은 **libc(Apple의 경우 Apple libSystem)의 표준 부트스트랩이 호출해주는 함수**라서, dotnet/go/rust 런타임 초기화 타이밍이나 스택 정렬(16바이트) 같은 게 훨씬 안전하게 보장됨

### 1. libC

C 런타임 환경을 구축해 주는 이 라이브러리의 정확한 명칭은 **`crt0.o` (C Runtime Zero)** 또는 **C Runtime Startup Library**입니다.

* **기능:** OS가 프로그램을 로드한 직후 실행되는 시작 지점(`_start`)을 미리 구현해 둔 객체 파일입니다.
* **역할:** 스택 정렬, `argc`/`argv` 인자 파싱, 환경 변수(`envp`) 전달, 글로벌 객체 초기화 등을 마친 뒤 비로소 우리가 잘 아는 `main()` 함수를 호출해 줍니다.
* **생략 시 현상:** `_start`를 직접 작성하면 `crt0.o`가 완전히 빠지므로 `main` 함수 호출 절차도 없고, Exit System Call(`mov x8, #93` 등)을 직접 안 써주면 프로그램 종료 시 바로 Segfault가 발생합니다.

---

### 2. C 런타임(libc)을 구성하는 주요 요소

우리가 C 표준 라이브러리(libc)라고 부르는 집합체는 운영체제(macOS / Linux)에 따라 구현체 이름이 조금씩 다르며, 크게 4가지 핵심 요소로 구성됨.

**주요 구현체 명칭 (OS별)**

* **macOS:** `libSystem.dylib` (내부에 C 런타임, System Call 래퍼, pthread 등이 통째로 포함됨)
* **Linux:** `glibc` (GNU C Library, 파일명: `libc.so.6`) 또는 `musl-libc` (경량화 임베디드용)

**libc의 주요 구성 라이브러리/모듈**

* **C 런타임 스타트업 (`crt1.o`, `crti.o`, `crtn.o`)**
* 프로세스 생성 시 표준 I/O(stdin, stdout, stderr)를 초기화하고 프로그램 종료 시 `exit()` 핸들러 및 소멸자(`destructor`)를 호출합니다.


* **시스템 콜 래퍼 (System Call Wrapper)**
* OS 커널 명령어(`SVC #0` 등)를 직접 호출하지 않고 C 함수처럼 쓸 수 있게 해주는 래퍼 라이브러리입니다 (`open`, `read`, `write`, `fork`, `malloc` 등).


* **표준 입출력 및 문자열 처리 (`stdio`, `string`)**
* `printf`, `scanf`, `strcpy`, `memcpy` 등 메모리와 입출력을 제어하는 표준 기능 모듈입니다.


* **스레드 라이브러리 (`pthread`)**
* Multi-threading 환경을 제어하기 위한 POSIX 스레드 구현체입니다.

### 💡 핵심사항

"왜 어셈블리에서는 `_start`를 쓸 때 `printf`나 `malloc`을 그냥 쓸 수 없는가?" 하는 의문점?, 
바로 이 `crt0`와 `libc`가 링킹 단계에서 제거되었기 때문이라고 연결해 주면 정신적으로 확고한 훌륭한 빌드업이 됩니다!

---

**심볼 네이밍 컨벤션 차이**:
| 플랫폼 | 오브젝트 포맷 | 어셈블리에서 `main`을 가리킬 때 |
|---|---|---|
| macOS (Apple Silicon) | Mach-O | `.global _main` (언더스코어 prefix 필수) |
| Linux (aarch64) | ELF | `.global main` (언더스코어 없음) |

`build.zig`가 두 OS를 다 지원하니, 이 부분은 조건부 매크로나 별도 진입 스텝으로 분기. 
브릿지 라이브러리 함수 호출할 때도 마찬가지로 macOS에서는 `bl _csharp_entry`, `bl _calc_sum`, `bl _go_add`처럼 앞에 언더스코어가 붙는다는 점에 유의

## 준비된 브릿지 함수 목록 (다음 주차부터 쓸 도구들)

| 언어 | 함수 | 시그니처 (ARM64 관점) | 역할 |
|---|---|---|---|
| .NET AOT | `csharp_entry` | `w0=val` → `w0`(ret) | printf 대체, Console.WriteLine |
| .NET AOT | `csharp_read_int` | 인자 없음 → `w0`(ret) | scanf 대체, Console.ReadLine |
| Go | `go_add` / `go_sub` | `w0=a, w1=b` → `w0`(ret) | 산술 예제용 |
| Go | `go_print_int` | `w0=v` | 정수 출력 |
| Go | `go_print_sum` | `w0=a, w1=b, w2=sum` | 포맷 출력 |
| Rust | `calc_sum` / `welcome_rust` | `x0=a, x1=b`(64bit) | 인사말/합계 출력 |
| Rust | `to_print` | `x0=ptr, x1=len` | 길이 기반 raw 문자열 출력 (null 불필요) |
| Rust | `sys_print` | `x0=ptr(C문자열)` → `w0`(ret, 길이/에러) | null-terminated 문자열 출력 |
| Rust | `sys_print_fmt` | `x0=fmt, x1=args_ptr, x2=len` → `w0`(ret) | `{}` 플레이스홀더 포맷팅 |

**미리 짚어둘 난이도 포인트 하나** — `sys_print_fmt`가 받는 `FfiArg`는 `#[repr(C)] enum { Int(i64), Str(*const c_char) }`라 **태그된 유니온**. 
어셈블리에서 이 배열을 직접 구성하려면 각 원소마다 (discriminant 8바이트 + payload 8바이트) 정도의 메모리 레이아웃을 스택/데이터 섹션에 손수 쌓아야 하니, 
이건 나중 주차에서 "FFI 복합 자료구조 전달" 예제로 다뤄볼 만한 좋은 소재로 남겨둠.

---

정리:
1. 진입점 `main`(플랫폼별 언더스코어 유의)
2. syscall 대신 위 표의 브릿지 함수 `bl` 호출
3. AAPCS64 규약 그대로(x0~x7 인자, x0 리턴) 유지

---