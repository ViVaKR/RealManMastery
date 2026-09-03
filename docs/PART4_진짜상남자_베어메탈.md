# 4부 — 진짜 상남자: 베어메탈 (3시간)
### "상남자 코스"로 끝내는 ARM64 AArch64 어셈블리 — 대미

---

## 전체 흐름 (타임라인)

| 시간 | 세션 | 핵심 목표 |
|---|---|---|
| 0:00–0:10 | 오프닝 | 3부 리마인드 + "지금까지 배운 모든 것이 여기 모입니다" |
| 0:10–0:50 | 세션 1 | delegate ↔ blr — 함수 포인터의 실체 |
| 0:50–1:25 | 세션 2 | 피보나치 메모이제이션 — C#으로 간결하게, ASM으로 그 아래를 |
| 1:25–1:35 | 휴식 | — |
| 1:35–2:05 | 세션 3 | QEMU virt 베어메탈 부팅 — 최소 커널 |
| 2:05–2:35 | 세션 4 | UART 출력 — 화면 없이 세상과 대화하기 |
| 2:35–2:55 | 세션 5 | 예외 벡터 테이블 맛보기 |
| 2:55–3:00 | 클로징 | 성취감으로 마무리 |

---

## 오프닝 (10분)

**전달할 톤**: "1부에서 레지스터를 배웠고, 2부에서 함수가 서로를 부르는 법을, 3부에서 메모리와 벡터를 만졌습니다. 오늘은 그 모든 걸 딱 하나로 모아서, 여러분 손으로 컴퓨터를 처음부터 깨우는 겁니다. OS도, 런타임도, 아무것도 없는 상태에서요."

- 오늘 다룰 커널은 준님이 실제로 만드신 **Yeoji OS의 축소판**임을 밝히기: "이건 제가 실전에서 QEMU virt 타겟으로 직접 부팅시킨 커널의 핵심만 뽑아낸 겁니다."
- 오늘의 구성 예고: "전반부는 지금까지 배운 개념들이 C#/닷넷 세계와 어떻게 이어지는지 마지막으로 정리하고, 후반부는 진짜 베어메탈로 들어갑니다."

---

## 세션 1 — delegate ↔ blr: 함수 포인터의 실체 (40분)

### 참조 코드 먼저 — C# delegate

```csharp
delegate int MathOp(int a, int b);

static int Add(int a, int b) => a + b;
static int Sub(int a, int b) => a - b;

static void Main()
{
    MathOp op = Add;              // 함수를 "값"으로 담음
    Console.WriteLine(op(10, 3));  // 13

    op = Sub;                       // 다른 함수로 갈아끼움
    Console.WriteLine(op(10, 3));  // 7
}
```

> **질문 던지기**: "`op`라는 변수 안에 도대체 뭐가 들어있는 걸까요? 함수 자체가 변수에 담긴다는 게 말이 되나요? 오늘 그 답을 보여드립니다."

### 진실: delegate 안에는 결국 "주소"가 들어있다

- 2부에서 배운 `bl`은 **고정된 주소**로 점프하는 명령어 (`bl _add`처럼 컴파일 시점에 주소가 정해짐)
- 오늘 배우는 `blr`(Branch with Link to Register)은 **레지스터에 담긴 주소**로 점프 — 이게 바로 delegate의 정체

### 따라 만들기 — ASM으로 함수 포인터 다루기

```asm
_add:
    add x0, x0, x1
    ret

_sub:
    sub x0, x0, x1
    ret

_main:
    sub sp, sp, #16
    str x30, [sp]

    adrp x9, _add@PAGE          // _add 함수의 "주소"를 x9에 담음 — 이게 delegate!
    add x9, x9, _add@PAGEOFF

    mov x0, #10
    mov x1, #3
    blr x9                        // x9에 담긴 주소로 점프 — bl이 아니라 blr!
    // x0 = 13

    adrp x9, _sub@PAGE           // 다른 함수로 갈아끼우기
    add x9, x9, _sub@PAGEOFF

    mov x0, #10
    mov x1, #3
    blr x9
    // x0 = 7

    ldr x30, [sp]
    add sp, sp, #16
    mov x0, #0
    ret
```

> **핵심 통찰 (오늘 강좌 전체의 하이라이트)**: "`bl`과 `blr`, 딱 글자 하나 차이입니다. 하지만 그 하나가 '정해진 곳으로만 가는 것'과 '어디로 갈지 실행 중에 결정하는 것'의 차이를 만듭니다. C#의 delegate, 이벤트 핸들러, 콜백, 심지어 가상 함수 호출(virtual/override)까지 — 이 모든 게 결국 이 `blr` 한 줄로 귀결됩니다. 여러분이 오늘 오전에 이해한 이 원리가, 사실 닷넷 런타임 전체를 관통하는 원리예요."

---

## 세션 2 — 피보나치 메모이제이션: C#으로 간결하게, ASM으로 그 아래를 (35분)

### 참조 코드 먼저 — C#의 간결함이 빛나는 지점

```csharp
static Dictionary<int, long> memo = new Dictionary<int, long>();

static long Fib(int n)
{
    if (n <= 1) return n;
    if (memo.ContainsKey(n)) return memo[n];

    long result = Fib(n - 1) + Fib(n - 2);
    memo[n] = result;
    return result;
}

static void Main()
{
    Console.WriteLine(Fib(40));   // 순식간에 계산됨
}
```

> **솔직한 인정 멘트**: "이 부분은 제가 일부러 C#으로만 짜서 참조로 보여드립니다. `Dictionary`라는 자료구조를 어셈블리로 처음부터 직접 만들려면 오늘 하루가 다 갑니다. 여기서는 '왜 메모이제이션이 필요한가'를 개념으로만 짚고, 실제 재귀 호출이 스택에서 어떻게 폭발하는지는 2부에서 배운 도구로 직접 확인해보겠습니다."

### 대신 보여줄 것: 메모이제이션 없이 vs 있이, 호출 횟수의 극적인 차이

```
fib(10) 메모이제이션 없이: 함수 호출 177회
fib(10) 메모이제이션 있이: 함수 호출 19회

fib(30) 메모이제이션 없이: 함수 호출 2,692,537회  ← 이쯤에서 체감 훅 들어옴
fib(30) 메모이제이션 있이: 함수 호출 59회
```

> **2부와 연결**: "기억하시나요? 2부에서 재귀가 스택에 종이 더미처럼 쌓인다고 했죠. 메모이제이션 없는 피보나치는 그 종이 더미를 수백만 번 쌓았다 허물었다 반복하는 겁니다. 이게 왜 비효율적인지, 여러분은 이제 눈으로 그 스택을 본 사람이라 진짜로 이해하실 수 있어요."

### 미니 실습: 카운터로 호출 횟수 직접 확인 (ASM)

```asm
// call_count를 전역 변수로 두고, 함수 진입마다 증가시켜서
// 메모이제이션 유무에 따른 차이를 눈으로 확인
.data
call_count: .word 0

_fib:
    adrp x9, call_count@PAGE
    add x9, x9, call_count@PAGEOFF
    ldr w10, [x9]
    add w10, w10, #1
    str w10, [x9]            // 호출될 때마다 카운트 증가

    // ... (기존 재귀 피보나치 로직) ...
```

> "복잡한 자료구조 없이, 이 카운터 하나만 추가해도 '메모이제이션이 왜 필요한가'를 몸으로 느끼실 수 있습니다."

---

## 휴식 (10분)

---

## 세션 3 — QEMU virt 베어메탈 부팅: 최소 커널 (30분)

### 오늘부터는 참조할 C#이 없습니다

> "지금부터는 닷넷도, macOS도, 심지어 printf도 없는 세계입니다. 진짜 상남자 구간, 시작하겠습니다."

### 필요한 도구

```bash
brew install qemu
# 크로스 컴파일용 툴체인 (aarch64-none-elf)
brew install aarch64-elf-gcc aarch64-elf-binutils
```

### 최소 부팅 커널

```asm
// boot.s — 부팅 즉시 실행되는 첫 코드
.global _start
.section .text

_start:
    ldr x0, =stack_top    // 스택 포인터 초기 설정 (아무도 안 해주니 우리가 직접)
    mov sp, x0

    bl kernel_main          // C로 짤 메인 로직 호출 (2부에서 배운 그 bl)

hang:
    wfi                       // Wait For Interrupt — 할 일 없으면 대기
    b hang

.section .bss
.align 4
stack_bottom:
    .skip 4096                // 4KB 스택 공간
stack_top:
```

> **강조 포인트**: "이 코드 위에는 아무것도 없습니다. 운영체제도, 런타임도, 심지어 스택 포인터 초기값조차 아무도 안 챙겨줍니다. 지금까지는 `_main`이 실행되기 전에 누군가(macOS, 닷넷 런타임)가 이런 걸 미리 해놨던 겁니다. 오늘 그 '누군가'가 우리 자신이 됩니다."

### 링커 스크립트로 QEMU virt 메모리 맵에 맞추기

```ld
/* link.ld */
ENTRY(_start)
SECTIONS
{
    . = 0x40080000;    /* QEMU virt가 커널을 로드하는 주소 */
    .text : { *(.text) }
    .bss  : { *(.bss) }
}
```

### 빌드 & QEMU 부팅

```bash
aarch64-none-elf-as boot.s -o boot.o
aarch64-none-elf-ld -T link.ld boot.o -o kernel.elf
qemu-system-aarch64 -M virt -cpu cortex-a72 -kernel kernel.elf -nographic
```

> **라이브 시연**: 부팅 성공 시 화면엔 아무것도 안 뜨지만(아직 UART 연결 전) — "지금 화면엔 아무것도 안 보이지만, 이 순간 CPU는 우리가 짠 코드를 실행하며 `hang` 루프를 돌고 있습니다. 다음 세션에서 이걸 눈으로 보이게 만들어보겠습니다."

---

## 세션 4 — UART 출력: 화면 없이 세상과 대화하기 (30분)

### PL011 UART — 커널이 세상에 말 거는 유일한 통로

> 준님이 실제로 Yeoji OS에서 쓰신 것과 동일하게: PL011 UART, 주소 `0x09000000` (QEMU virt 기본 매핑)

```asm
.equ UART0_BASE, 0x09000000

// void uart_putc(char c) — x0에 문자 하나가 담겨 들어옴
uart_putc:
    ldr x1, =UART0_BASE
    strb w0, [x1]           // UART 데이터 레지스터에 1바이트 쓰면 그대로 출력됨
    ret

// void uart_puts(char* str) — x0에 문자열 시작 주소
uart_puts:
    sub sp, sp, #16
    str x30, [sp]
    str x19, [sp, #8]

    mov x19, x0

_uart_puts_loop:
    ldrb w0, [x19], #1        // 한 바이트 읽고 주소 자동 증가
    cbz w0, _uart_puts_end     // NUL 문자면 종료
    bl uart_putc
    b _uart_puts_loop

_uart_puts_end:
    ldr x19, [sp, #8]
    ldr x30, [sp]
    add sp, sp, #16
    ret
```

### 감동의 순간: "Hello from bare metal"

```asm
.data
msg: .asciz "Hello, 상남자 여러분. 여기는 베어메탈입니다.\n"

kernel_main:
    adrp x0, msg@PAGE
    add x0, x0, msg@PAGEOFF
    bl uart_puts
    ret
```

```bash
qemu-system-aarch64 -M virt -cpu cortex-a72 -kernel kernel.elf -nographic
# 터미널에 메시지가 찍히는 순간!
```

> **여기가 오늘, 그리고 어쩌면 12시간 전체의 감정적 클라이맥스입니다.** 이 메시지가 화면에 뜨는 순간을 위해 지금까지 1부부터 쌓아온 것. "printf도, Console.WriteLine도 아닙니다. 우리가 UART 레지스터에 바이트를 하나씩 직접 밀어넣어서 만든 겁니다."

---

## 세션 5 — 예외 벡터 테이블 맛보기 (20분)

### 왜 필요한가

> "지금 우리 커널은 뭔가 잘못되면(0으로 나누기, 잘못된 메모리 접근) 그냥 조용히 죽거나 알 수 없는 상태로 빠집니다. 진짜 OS는 이런 상황에 '대응'을 합니다. 그 대응의 첫 관문이 예외 벡터 테이블이에요."

### 개념만 맛보기 — 전체 구현은 오늘 범위 밖

```asm
.align 11              // 예외 벡터 테이블은 2048바이트 정렬 필수
.global vector_table
vector_table:
    // 각 예외 종류마다 정해진 오프셋에 코드가 있어야 함
    b sync_handler        // Synchronous exception
    .align 7
    b irq_handler           // IRQ (인터럽트)
    .align 7
    b fiq_handler            // FIQ
    .align 7
    b serror_handler          // SError
    .align 7
    // ... (EL 레벨별로 반복되는 구조)

sync_handler:
    // 여기서 뭐가 잘못됐는지 조사하고 대응
    b hang
```

```asm
// VBAR_EL1 레지스터에 이 테이블의 주소를 등록해야
// CPU가 예외 발생 시 이곳으로 자동 점프함
    adrp x0, vector_table@PAGE
    add x0, x0, vector_table@PAGEOFF
    msr VBAR_EL1, x0
```

> **실전 회고 멘트**: "Yeoji OS에서 이 테이블 정렬 규칙(`.align 11`, `.align 7`) 때문에 처음에 애 좀 먹었습니다. 한 칸이라도 어긋나면 CPU가 완전히 엉뚱한 곳으로 튀거든요. 오늘은 이 구조가 존재한다는 것과, 왜 이렇게 정렬에 집착하는지 이유만 이해하고 넘어가면 충분합니다. 이걸 완전히 정복하는 건 그 자체로 또 다른 강좌 분량이에요."

---

## 클로징 (5분)

**전달할 톤**: 지금까지와 다르게, 여기서는 가르치기보다 함께 온 여정을 돌아보는 톤으로.

> "여러분, 12시간 전에 `mov x0, #10` 한 줄로 시작하셨습니다. 지금 여러분은 CPU를 처음부터 깨우고, 화면 없이 세상에 말을 걸고, 함수를 값처럼 주고받는 법까지 손으로 만들어보셨습니다.
>
> 어셈블리는 어렵지 않습니다. 다만 낯설 뿐이었어요. 그리고 낯섦은, 오늘 여러분이 직접 확인하셨듯 몇 번 보면 사라집니다.
>
> 무소의 뿔처럼 혼자서 가라고 했습니다. 근데 오늘 이 여정, 혼자 가신 게 아닙니다. 여러분 옆엔 항상 C#이라는 익숙한 참조가 있었고, 이 화면 너머의 저도 함께였습니다.
>
> 나무아미타불, 여러분 모두 진짜 상남자십니다. 고맙습니다."

### 다음 단계 안내 (선택)
- NEON 심화, 예외 벡터 테이블 완전 정복, 인터럽트 처리 — 이런 후속 콘텐츠 여지를 짧게 언급하며 채널 구독/다음 시리즈 예고

---

## 준비물 체크리스트 (녹화 전)

- [ ] aarch64-none-elf 툴체인 설치 및 빌드 테스트 완료
- [ ] link.ld, boot.s 사전 컴파일 및 QEMU 부팅 테스트 완료 (여러 번 리허설 필수 — 이 부분은 라이브 실패 리스크가 가장 큼)
- [ ] UART 출력 세션은 반드시 사전 성공 확인 후 녹화 (실패 시 감동 포인트가 무너짐)
- [ ] 예외 벡터 테이블은 "개념 설명 + 코드 낭독" 수준으로, 라이브 코딩 강행하지 않기
- [ ] 클로징 멘트 리허설 — 톤 전환(가르침 → 회고)이 자연스럽도록 별도 연습
