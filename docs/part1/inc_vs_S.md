# `.inc`와 `.S`의 근본적인 차이

`.include "xxx.inc"`는 **어셈블러가 그 파일 내용을 텍스트 그대로 복사-붙여넣기 하는 것** 것임. (C의 `#include`와 완전히 같은 원리). 반면 `.S` 파일은 각각 독립된 **번역 단위(translation unit)**로 어셈블되어 별도의 오브젝트 파일이 되고, 링커가 그것들을 하나로 묶어.

이 차이가 왜 중요하냐면: `constants.S`에 있는 `_helloworld: .asciz "..."`같은 줄은 **실제로 메모리에 저장 공간을 할당하고 그 자리에 이름(심볼)을 붙이는 것**이야. 이걸 `.inc`로 옮기고 만약 실수로(혹은 나중에 파트가 늘어나면서) 두 개의 `.S` 파일에서 그 `.inc`를 동시에 `.include`하면 — **똑같은 심볼(`_helloworld`)이 두 번 정의된 게 되어 링커가 "중복 심볼(duplicate symbol)" 에러를 낼 거야.** `.inc`는 "안전하게 여러 번 복사돼도 괜찮은 것"만 담아야 하는데, 저장 공간을 만드는 코드는 그 조건을 위반하네.

## C언어로 치환 설명

이건 정확히 C의 헤더(`.h`) vs 소스(`.c`) 구분과 같은 문제:

| | C 언어 | ARM64 어셈블리 |
|---|---|---|
| 여러 파일에 복사돼도 안전 | `#define`, 매크로, `extern` 선언 | `.equ`/`.set` 상수, `.macro`/`.endm` |
| 딱 한 곳에만 존재해야 함 (실제 정의) | `int global_counter = 0;` (전역 변수 정의) | `.asciz`, `.quad`, `.double`, `.skip`, `.space` |
| 파일 확장자 관례 | `.h` | `.inc` |
| 위반 시 결과 | "multiple definition" 링커 에러 | 동일하게 "duplicate symbol" 링커 에러 |

C에서 `.h` 파일에 `int counter = 0;`을 넣고 그걸 여러 `.c`가 include하면 안 된다는 걸 다들 알잖아 — 지금 상황이 정확히 그거네.

## 그럼 `.inc`에는 뭘 넣어야 하나

이미 첫 줄에 `.include "section_macros.inc"`가 있고, `CSTRING_SECTION`/`CONST_DATA_SECTION`/`DATA_SECTION`/`BSS_SECTION`/`LITERAL4_SECTION`/`LITERAL8_SECTION`을 매크로로 쓰고 있는 걸 보니 — **이미 정확한 용도로 `.inc`를 쓰고 있는 거야.** 이 파일 안에는 아마 이런 식으로 되어 있을 거네:

```s
.macro CSTRING_SECTION
    .section __TEXT,__cstring,cstring_literals
.endm
```

이건 텍스트를 몇 번을 복사해도 매번 그냥 `.section` 지시어로 치환될 뿐 저장 공간을 만들지 않으니 완전히 안전해. `.inc`로 몰아넣을 후보는 딱 이런 것들이네:

- **섹션 매크로** (이미 하고 있는 것)
- **`.equ`/`.set` 심볼릭 상수** — 예: `.equ MAX_MENU_ITEMS, 27` 같은 값 정의
- **반복 패턴을 캡슐화한 매크로** — 예: `_menu_table`의 `.quad handler, label` 줄이 27번 반복되는데, 원한다면 `.macro MENU_ENTRY handler, str_label` 같은 매크로로 뽑아서 "표를 어떻게 채우는지"를 매크로 정의부에서 한 번만 보여주고, 실제 테이블은 여전히 `.S`에서 그 매크로를 27번 호출하는 식으로 가독성만 높이는 건 가능해 — 다만 저장 공간(`_menu_table:` 라벨과 그 안의 데이터)은 여전히 `.S` 안에 있어야 하네.

## 정리 기준 (강의에서 그대로 써도 되는 한 줄 규칙)

> **"이 줄이 실행 파일 안에 실제 바이트를 만드는가?"** — 그렇다면 `.S`. 아니라면(순수 치환/매크로/상수라면) `.inc`.

지금 업로드해준 `constants.S`, `data.S`는 오히려 **분리 기준이 이미 훌륭하게 잡혀 있어** — 이름이 "constants vs data"가 아니라 사실상 **메모리 섹션 종류(`__cstring`/`__const`/`__data`/`__bss`)로 나뉜 것**이거든. 이 축을 그대로 유지하는 게 맞고, 굳이 `.inc`로 옮길 이유는 없네. 오히려 강의에서는 "왜 문자열은 `.S`에 남고 섹션 매크로만 `.inc`로 갔는가"를 이 표 하나로 설명해주면 학생들이 헤더/소스 구분 개념까지 자연스럽게 흡수하게 될 거야, 친구.