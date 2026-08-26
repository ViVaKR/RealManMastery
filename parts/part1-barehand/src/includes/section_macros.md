# Sections


>- 매크로 헤더는 Mach-O(macOS) ARM64 환경의 메모리 권한과 ABI 정렬 규칙을 반영함

>- 교육용 자료로 사용할 수 있도록 **1) 메모리 레이아웃 직관 아스키 아트**, **2) 섹션별 역할 정리 표**, **3) 추가 검토/보완 포인트**를 정리함.

---

### **1. macOS Mach-O 프로세스 메모리 지도 (초장 잡기용 시각화)**

수강생들이 "내 코드가 메모리 어디에 올라가는가?"를 한눈에 파악할 수 있는 구조입니다.

```text
  [ 프로세스 메모리 주소 공간 ]
  ┌──────────────────────────────────────────────────────────┐
  │  __TEXT Segment (Read-Only / Execute: 실행 권한 구역)      │
  ├──────────────────────────────────────────────────────────┤
  │   ├── __text        │ CODE_SECTION       (실행 명령어)     │
  │   ├── __cstring     │ CSTRING_SECTION    ("Hello" 문자열)  │
  │   ├── __const       │ CONST_SECTION      (상수 테이블)     │
  │   ├── __literal4    │ LITERAL4_SECTION   (float 상수)      │
  │   └── __literal8    │ LITERAL8_SECTION   (double 상수)     │
  ├──────────────────────────────────────────────────────────┤
  │  __DATA Segment (Read-Write: 읽기/쓰기 가능 구역)         │
  ├──────────────────────────────────────────────────────────┤
  │   ├── __data        │ DATA_SECTION       (초기화된 전역변수)│
  │   ├── __const       │ CONST_DATA_SECTION (Got/Reloc 포인터) │
  │   ├── __bss         │ BSS_SECTION        (0 초기화 변수)    │
  │   └── __common      │ COMMON_SECTION     (공용 미초기화)   │
  ├──────────────────────────────────────────────────────────┤
  │  Stack Area (가변 영역 / 함수 호출 프레임)                   │
  ├──────────────────────────────────────────────────────────┤
  │   └── [x29, x30, x19~x28 백업] (FUNC_START / FUNC_EXIT)     │
  └──────────────────────────────────────────────────────────┘

```

---

### **2. 핵심 섹션 비교 요약**

## 핵심 섹션 비교 요약

| 구분 | 섹션 매크로 | 실제 Mach-O 섹션 | 권한 | 주요 용도 | 정렬 규칙 |
|---|---|---|---|---|---|
| 코드 | `CODE_SECTION` | `__TEXT,__text` | `r-x` | 실행할 기계어 명령어 | 4Byte (`.align 2`) |
| 상수 | `CSTRING_SECTION` | `__TEXT,__cstring` | `r--` | C-스타일 널 종료 문자열 | 8Byte (`.align 3`) |
| 상수 | `CONST_SECTION` | `__TEXT,__const` | `r--` | 일반 상수 데이터, 룩업 테이블 | 8Byte (`.align 3`) |
| 상수 | `LITERAL4_SECTION` | `__TEXT,__literal4` | `r--` | 32비트 `float` 실수 상수 | 4Byte (`.align 2`) |
| 상수 | `LITERAL8_SECTION` | `__TEXT,__literal8` | `r--` | 64비트 `double` 실수 상수 | 8Byte (`.align 3`) |
| 변수 | `DATA_SECTION` | `__DATA,__data` | `rw-` | 초기값이 존재하는 전역/정적 변수 | 8Byte (`.align 3`) |
| 변수 | `CONST_DATA_SECTION` | `__DATA,__const` | `rw-` → `r--` | 동적 링킹 재배치 후 읽기 전용 전환되는 포인터 | 8Byte (`.align 3`) |
| 변수 | `BSS_SECTION` | `__DATA,__bss` | `rw-` | 초기값이 없는(0으로 채워질) 변수 | 8Byte (`.align 3`) |
| 변수 | `COMMON_SECTION` | `__DATA,__common` | `rw-` | 여러 오브젝트 간 공유되는 잠정 정의 심볼 | 기본 정렬 |

---

### **3. 검토**


>- CPU는 메모리를 볼 때 단순한 1차원 공간으로 보지만, 
>- OS는 보안(W^X: Write Xor Execute)을 위해 
>- **'실행 가능한 코드 구역(__TEXT)'**과 
>- **'수정 가능한 데이터 구역(__DATA)'**으로 엄격히 담장을 쳐놓았습니다. 
>- 이 매크로는 여러분이 실수로 데이터 구역에 코드를 짜거나, 
>- 코드 구역에 변수를 써서 **Crash(SEGV)**가 나는 것을 방지해 주는 안전장치입니다.