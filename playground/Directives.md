# 지시자

## 섹션 및 바인딩

- `.section .text` : 코드
- `.section .dat` : 데이터
- `.section .rodata` : 읽기 전용 데이터 영역 정의
- `.global` : 해당 심볼을  외부에서 참조할 수 있게 공개 합니다.
- `.set` : 값(또는 .equ) : 상수를 정의 합니다. (C 언어의 #define 과 유사)

## 데이터 정의 

- `.byte` : 1
- `.word` : 2
- `.long` : 4
- `.quad` : 8

- `.ascii` : 널 문자가 없는 문자열을 정의 합니다.
- `.asciz`, `.string` : 끝에 **널 문자 (\0)** 가 포함된 C 스타일 문자열을 정의 

## 조건부 컴파일

- `.if, .else, .endif` : 주어진 조건에 따라 코드를 선택적으로 어셈블 합니다.

- `.ifnc 인자1, 인자2` (if Not Compare) : 두 인자가 서로 다르면 참이 됩니다.
```assembly
.ifnc \인자, ""      // 만약 인자가 빈 문자열("")이 아니라면 (참이면)
    .set IS_VALID, 1 // IS_VALID를 1로 세팅해라!
.endif
```

- `.ifdef 심볼` : 심볼이 정의 되어 있으면 참이 됩니다.

- `.ifndef 심볼` : 심볼이 정의 되어 있지 않으면 참(True)이 됨.

```assembly

// 만약 SECTION_MACROS_H 라는 이름이 정의 되어 있지 않다면 
// 즉, 이 어셈블리 파일을 오늘 처음 읽는 거라면 참(True) 외 됨.

.ifndef SECTION_MACROS_H
.set SECTION_MACROS_H, 1

...
// 매크로가 정의된 파일을 여러번 불러 올 수 있는 데
// 똑같은 매크로와 코드를 중복해서 읽으면 에러 발생

```
## **#pragma once**

- 컴파일러야 알아서 이 파일 딱 한 번만 읽어라 
- 딱 한 줄만 맨위에 적어두면 동일하게 작동


## .set

- **.set** 은 "지금부터 이 이름을 이 값으로 정의 하겠다" 라는 뜻

```assembly
.set MY_VAL, 10    // MY_VAL을 10으로 설정 (C언어의 #define MY_VAL 10)
```

- 조건이 맞으면 HAS_M4_FEATURES 를 1로 만들어라 라는 의미
```assembly
.if  (어떤 외계인 조건)
    .set  HAS_M4_FEATURES, 1   // 참이면: HAS_M4_FEATURES라는 플래그를 1(참)로 세팅해라!
.else
    .set  HAS_M4_FEATURES, 0   // 거짓이면: 0(거짓)으로 세팅해라!
.endif
```


## Apple Silicon 독자적인 지시자 및 특징 

- **PAC** (포인터 인증)` : 함수가 실행될 때 복귀 주소(x30) 를 암호화 서명하고, 리턴할 때 검증햐여 해킹을 방지 

```assembly

_secure_function:
    pacibsp                     // [프롤로그] B-키를 이용해 현재 X30(링크 레지스터) 서명인증
    stp x29, x30, [sp, #-16]!
    
    // ... 함수 본문 ...
    
    ldp x29, x30, [sp], #16
    autibsp                     // [에필로그] X30의 서명이 올바른지 검증 (위조 시 크래시)
    ret

```

- **adrp** 데이터 로드 지시자

```assembly
.section .rodata
_my_str:
    .asciz "Hello M4 Silicon!"

.section .text
_print_msg:
    // _my_str의 주소가 포함된 4KB 페이지의 시작 주소를 X0에 로드
    adrp x0, _my_str@PAGE
    
    // 페이지 내의 정확한 하위 12비트 오프셋 위치를 X0에 더함
    add x0, x0, _my_str@PAGEOFF
    
    // 이제 X0에는 완전한 "Hello M4 Silicon!" 문자열 주소가 들어있음
    bl _printf
```