GNU Assembler (GAS)와 Clang Integrated Assembler는 둘 다 표준 GNU 구문(GNU-Syntax) 지시자와 매크로 시스템을 공유합니다. [1, 2] 
이 문서에서는 GAS 및 Clang 어셈블러에서 공통으로 쓰이는 기본 구문과 매크로(Macro) 작성법, 그리고 유용한 핵심 지시자(Directives)를 요약하여 정리합니다.
------------------------------
## 1. 기본 구문 (Syntax) 규칙
GAS는 x86/x64 아키텍처에서 기본적으로 AT&T 문법을 사용하지만, Intel 문법도 지원합니다. [3, 4] 
## 📌 AT&T vs Intel 구문 비교

* .intel_syntax noprefix 지시자를 상단에 선언하면, Clang과 GAS 모두에서 Intel 문법을 사용할 수 있습니다. [5] 

| 항목 | AT&T 구문 (기본값) | Intel 구문 (.intel_syntax noprefix) |
|---|---|---|
| 연산순서 | 명령어 source, destination | 명령어 destination, source |
| 레지스터 접두사 | % 사용 (예: %rax, %ebx) | 접두사 없음 (예: rax, ebx) |
| 상수(Immediate) | $ 사용 (예: $5, $0x10) | 접두사 없음 (예: 5, 0x10) |
| 메모리 참조 | disp(base, index, scale) | [base + index * scale + disp] |
| 크기 접미사 | 명령어 뒤에 b(byte), w(word), l(long), q(quad) 붙임 | BYTE PTR, WORD PTR, DWORD PTR, QWORD PTR 명시 |


* AT&T 예시: movl $42, %eax (42를 eax에 대입)
* Intel 예시: mov eax, 42 (42를 eax에 대입) [5] 

------------------------------
## 2. 매크로 (Macro) 문법 및 활용
매크로는 중복되는 코드 블록을 이름 하나로 묶어 재사용할 수 있게 해주는 컴파일 타임 치환 도구입니다. [6, 7] 
## 📝 기본 구조
매크로는 .macro로 시작하여 .endm으로 끝납니다. 매크로 내부에서 인자를 사용할 때는 앞에 역슬래시(\)를 붙여 참조합니다. [8, 9, 10] 

```arm
.macro 매크로이름 인자1, 인자2=기본값
    /* 매크로 본문 */
    mov \인자1, \인자2
.endm
```

## 💡 실전 매크로 예제
1. 범용 시스템 콜 매크로 (x86_64 예시)

/* 인자를 받아 리눅스 write 시스템 콜을 수행하는 매크로 */
.macro WRITE_MSG fd, buf, len
    mov $1, %rax      # sys_write 번호
    mov \fd, %rdi     # 파일 디스크립터
    mov \buf, %rsi    # 버퍼 주소
    mov \len, %rdx    # 길이
    syscall           # 커널 호출
.endm
# 호출 방법:
WRITE_MSG $1, $msg, $14

2. 매크로 내 고유 라벨 생성 (\@)
매크로를 여러 번 호출하면 내부 라벨이 중복되어 컴파일 에러가 발생합니다. 이를 방지하기 위해 호출할 때마다 고유한 숫자를 자동 생성해 주는 \@ 의사 변수를 사용합니다. [10, 11] 

.macro LOOP_COUNT reg, limit
    mov $0, \reg
.L_loop_\@:               # 호출될 때마다 .L_loop_0, .L_loop_1로 치환됨
    inc \reg
    cmp \limit, \reg
    jl .L_loop_\@
.endm

3. 가변 인자(:vararg) 및 필수 인자(:req) 지정
GNU 공식 문서에 따르면 필수 값이나 나머지 모든 인자를 묶어 받을 수 있는 고급 속성을 지원합니다. [12] 

.macro MY_FUNC arg1:req, arg2=0, rest:vararg
    # \arg1은 호출 시 무조건 입력해야 함
    # \arg2는 미입력 시 0으로 세팅
    # \rest는 나머지 모든 인자가 통째로 들어옴
.endm

------------------------------
## 3. 주요 핵심 지시자 (Directives)
코드의 흐름을 제어하거나 섹션을 나눌 때 자주 쓰는 핵심 지시자들입니다. [13] 

* 섹션 및 바인딩
* .section .text / .section .data / .section .rodata: 코드, 데이터, 읽기 전용 데이터 영역을 정의합니다.
   * .global 심볼명: 해당 심볼(주로 함수나 링커 진입점)을 외부에서 참조할 수 있게 공개합니다.
   * .set 심볼명, 값 (또는 .equ): 상수를 정의합니다 (C언어의 #define과 유사). [5, 14, 15] 
* 데이터 정의
* .byte, .word, .long, .quad: 각각 1, 2, 4, 8바이트 크기의 공간을 할당하고 값을 초기화합니다.
   * .ascii "문자열": 널 문자가 없는 문자열을 정의합니다.
   * .asciz "문자열" (또는 .string): 끝에 널 문자(\0)가 포함된 C 스타일 문자열을 정의합니다. [5, 9, 16, 17] 
* 조건부 컴파일
* .if, .else, .endif: 주어진 조건에 따라 코드를 선택적으로 어셈블합니다.
   * .ifnc 인자1, 인자2: 두 인자의 문자열이 다를 때 참이 됩니다.
   * .ifdef 심볼: 심볼이 정의되어 있으면 참이 됩니다. [9, 18] 

------------------------------
## 4. Clang 어셈블러 유의사항 및 매크로 전처리

   1. 대문자 .S 확장자 활용: Clang으로 어셈블리 파일을 컴파일할 때 파일 확장자를 대문자 .S로 지정하면, 어셈블하기 전에 C 전처리기가 먼저 실행됩니다. 덕분에 어셈블리 내부에서 #define, #ifdef, #include <stdio.h> 같은 C 스타일 매크로를 그대로 혼용할 수 있습니다. 소문자 .s 파일은 전처리를 거치지 않고 바로 어셈블러로 넘어갑니다. [1, 19] 
   2. Clang-CL(Windows) 주의점: Windows 대상 환경(clang-cl)에서는 레지스터를 가리키는 심볼을 정의할 때 컴파일러가 심볼 자체를 방출하려다 에러를 낼 수 있으므로, 내부 라벨이나 임시 상수는 .L 접두사를 붙여 로컬 기호로 만드는 것이 안전합니다. [20] 

------------------------------

```h
/* 함수의 시작점 정의 및 스택 프레임 생성 매크로 */
.macro START_FUNC name
    .global _\name
    .p2align 2
_\name:
    stp x29, x30, [sp, #-16]!   // 스택을 16바이트 늘리고 X29, X30 저장
    mov x29, sp                 // 현재 SP를 프레임 포인터로 설정
.endm

/* 함수의 종료 및 스택 복원 매크로 */
.macro END_FUNC
    ldp x29, x30, [sp], #16     // X29, X30 복원하고 스택 16바이트 축소
    ret                         // 리턴
.endm

# --- 사용 예시 ---
START_FUNC my_add
    add x0, x0, x1              // X0 = X0 + X1
    END_FUNC
```

### 고유라벨(\@)을 이용한 조건문 매크로

ARM64 에는 CMP 후에 사용하는 조건부 분기 (b.gt, b.eq 등)가 있으며, 매크로 내부에서 분기 처리를 할 때 라벨 충돌을 막기 위해 `\@` 를 하용함 

```h
/* 두 값 중 큰 값을 x0에 담는 매크로 (Max) */
.macro MAX_REG reg1, reg2
    cmp \reg1, \reg2
    b.gt .L_reg1_bigger_\@      // 고유 라벨 분기
    mov x0, \reg2
    b .L_end_\@
.L_reg1_bigger_\@:
    mov x0, \reg1
.L_end_\@:
.endm

# --- 사용 예시 ---
MAX_REG x9, x10



```