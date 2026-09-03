# ARM64 예제 코드 — 15주차: 종합 프로젝트, 퀵 정렬(Quick Sort)

> 지금까지 배운 모든 것의 결정판이네: **함수(9주차) + 재귀(10주차) + 배열 주소 계산(11주차) +
> 포인터로 값 교환(12주차) + 비교/분기(5~6주차)**가 전부 하나의 알고리즘 안에 녹아있는 게 퀵 정렬이지.
> "정렬 알고리즘의 꽃"이라 불릴 만큼, 배우는 입장에서도 정말 좋은 종합 소재를 골랐네.

---

## 알고리즘 개요 — 로무토 파티션(Lomuto Partition) 방식

퀵 정렬의 핵심은 **파티션(partition)**: 배열의 마지막 원소를 피벗(pivot)으로 삼아, **피벗보다 작은 값은 왼쪽, 큰 값은 오른쪽**으로 몰아넣고, 피벗을 그 경계 자리에 놓는 것이네. 그 다음 왼쪽/오른쪽 부분배열에 대해 **똑같은 과정을 재귀적으로 반복**하면 전체가 정렬됨.

```
[64, 25, 12, 22, 11, 90, 45, 33]   ← 정렬 전
                ↓ quicksort(arr, 0, 7)
[11, 12, 22, 25, 33, 45, 64, 90]   ← 정렬 후
```

---

## C 등가 코드 (전체 구조 먼저 파악)

```c
extern void go_print_int(int v);

void swap(int* a, int* b) {
    int t = *a;
    *a = *b;
    *b = t;
}

int partition(int* arr, int low, int high) {
    int pivot = arr[high];       // 마지막 원소를 피벗으로
    int i = low - 1;              // "피벗보다 작은 값들의 경계" 인덱스

    for (int j = low; j < high; j++) {
        if (arr[j] < pivot) {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }
    swap(&arr[i + 1], &arr[high]);  // 피벗을 제자리로
    return i + 1;                     // 피벗의 최종 위치
}

void quicksort(int* arr, int low, int high) {
    if (low < high) {
        int pi = partition(arr, low, high);
        quicksort(arr, low, pi - 1);      // 왼쪽 부분배열
        quicksort(arr, pi + 1, high);     // 오른쪽 부분배열
    }
}

int main(void) {
    int arr[8] = {64, 25, 12, 22, 11, 90, 45, 33};

    for (int i = 0; i < 8; i++) go_print_int(arr[i]);   // 정렬 전 출력

    quicksort(arr, 0, 7);

    for (int i = 0; i < 8; i++) go_print_int(arr[i]);   // 정렬 후 출력
    return 0;
}
```

---

## ARM64 어셈블리 전체 구현

```asm
    .text

// ═══════════════════════════════════════════════════════
// void swap(int* a, int* b)   x0=&a, x1=&b
// leaf function — 재귀도 다른 함수 호출도 없어 스택 프레임 불필요 (9주차)
// ═══════════════════════════════════════════════════════
    .align  2
swap:
    ldr     w2, [x0]              // t = *a
    ldr     w3, [x1]              // *b 값
    str     w3, [x0]               // *a = *b
    str     w2, [x1]               // *b = t
    ret

// ═══════════════════════════════════════════════════════
// int partition(int* arr, int low, int high)
//   x0=arr, w1=low, w2=high  →  리턴값 w0 = 피벗의 최종 위치
// 사용 레지스터(callee-saved, 함수 내내 값 보존해야 함 — 9주차 규칙):
//   x19=arr, w20=i, w21=j, w22=high, w23=pivot값
// ═══════════════════════════════════════════════════════
    .align  2
partition:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]      // ★ 호출자의 값 보존 (callee-saved 의무)
    stp     x21, x22, [sp, #32]
    str     x23, [sp, #48]

    mov     x19, x0                    // arr
    mov     w22, w2                     // high (변하지 않는 값)
    ldr     w23, [x19, w22, sxtw #2]     // pivot = arr[high]           ← 11주차 스케일드 인덱스

    sub     w20, w1, #1                  // i = low - 1
    mov     w21, w1                       // j = low

part_loop:
    cmp     w21, w22                       // j < high ?
    b.ge    part_loop_end

    ldr     w0, [x19, w21, sxtw #2]         // arr[j]
    cmp     w0, w23                          // arr[j] vs pivot
    b.ge    part_skip                         // arr[j] >= pivot 이면 skip

    add     w20, w20, #1                       // i++
    add     x0, x19, w20, sxtw #2                // &arr[i]
    add     x1, x19, w21, sxtw #2                 // &arr[j]
    bl      swap                                   // swap(&arr[i], &arr[j])   ← 12주차 포인터 전달

part_skip:
    add     w21, w21, #1                            // j++
    b       part_loop

part_loop_end:
    // swap(&arr[i+1], &arr[high]) — 피벗을 제자리로
    add     w9, w20, #1                              // i+1 (임시, caller-saved라 부담없이 사용)
    add     x0, x19, w9, sxtw #2
    add     x1, x19, w22, sxtw #2
    bl      swap

    add     w0, w20, #1                               // 리턴값 = i+1 (피벗 최종 위치)

    ldr     x23, [sp, #48]                             // ★ 호출자의 값 복원 (반드시!)
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// ═══════════════════════════════════════════════════════
// void quicksort(int* arr, int low, int high)   x0=arr, w1=low, w2=high
// ═══════════════════════════════════════════════════════
    .align  2
quicksort:
    cmp     w1, w2
    b.ge    qs_end                     // low >= high 이면 원소 0~1개, 종료 (base case — 10주차)

    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]         // arr, low 보존
    stp     x21, x22, [sp, #32]         // high, pi 보존

    mov     x19, x0
    mov     w20, w1
    mov     w21, w2

    mov     x0, x19
    mov     w1, w20
    mov     w2, w21
    bl      partition                     // int pi = partition(arr, low, high)
    mov     w22, w0                        // pi 보관

    mov     x0, x19                         // quicksort(arr, low, pi-1)  ← 재귀 호출 1
    mov     w1, w20
    sub     w2, w22, #1
    bl      quicksort

    mov     x0, x19                          // quicksort(arr, pi+1, high) ← 재귀 호출 2
    add     w1, w22, #1
    mov     w2, w21
    bl      quicksort

    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48

qs_end:
    ret

// ═══════════════════════════════════════════════════════
// main
// ═══════════════════════════════════════════════════════
    .global _main
    .extern _go_print_int

_main:
    stp     x29, x30, [sp, #-48]!    // FP/LR(16) + arr[8]*4=32 = 48
    mov     x29, sp

    mov     w0, #64
    str     w0, [sp, #16]
    mov     w0, #25
    str     w0, [sp, #20]
    mov     w0, #12
    str     w0, [sp, #24]
    mov     w0, #22
    str     w0, [sp, #28]
    mov     w0, #11
    str     w0, [sp, #32]
    mov     w0, #90
    str     w0, [sp, #36]
    mov     w0, #45
    str     w0, [sp, #40]
    mov     w0, #33
    str     w0, [sp, #44]

    add     x19, sp, #16               // arr 시작주소 (main 전체에서 재사용, callee-saved)

    // ── 정렬 전 출력 ──
    mov     w20, #0
print_before:
    cmp     w20, #8
    b.ge    before_done
    ldr     w0, [x19, w20, sxtw #2]
    bl      _go_print_int
    add     w20, w20, #1
    b       print_before
before_done:

    // ── 퀵 정렬 실행 ──
    mov     x0, x19
    mov     w1, #0
    mov     w2, #7
    bl      quicksort

    // ── 정렬 후 출력 ──
    mov     w20, #0
print_after:
    cmp     w20, #8
    b.ge    after_done
    ldr     w0, [x19, w20, sxtw #2]
    bl      _go_print_int
    add     w20, w20, #1
    b       print_after
after_done:

    mov     w0, #0
    ldp     x29, x30, [sp], #48
    ret
```

**예상 출력**
```
64 25 12 22 11 90 45 33      ← 정렬 전
11 12 22 25 33 45 64 90      ← 정렬 후
```

---

## 이 프로젝트에서 지금까지 배운 게 어떻게 다 모였는지

| 코드 부분 | 사용된 개념 | 주차 |
|---|---|---|
| `swap`이 프레임 없는 leaf function | leaf function은 FP/LR 저장 불필요 | 9주차 |
| `partition`/`quicksort`가 x19~x23 저장/복원 | callee-saved 레지스터는 함수 스스로 지킬 의무 | 9주차 |
| `quicksort(arr, low, pi-1)` / `(arr, pi+1, high)` | 함수가 자기 자신을 두 번 호출(재귀) | 10주차 |
| `partition`이 리턴 전 `pi`를 스택에 잠깐 보관 | 재귀 호출 사이 caller-saved 값 보호 | 10주차 |
| `ldr w0, [x19, w21, sxtw #2]` | 스케일드 인덱스 주소 계산(`arr[j]`) | 11주차 |
| `swap(&arr[i], &arr[j])`로 주소를 넘김 | 포인터 전달, 함수가 원본 메모리를 직접 수정 | 9,11주차 |
| `cmp w0, w23` + `b.ge` | 조건 비교와 분기 | 5,6주차 |
| `_go_print_int` 브릿지 호출 | AAPCS64 규약 하나로 언어 무관 상호운용 | 9,14주차 |

**한 가지 짚고 넘어갈 것 — "정렬 알고리즘이지만 새 명령어는 하나도 없다"**
이번 15주차 코드에 등장하는 명령어(`LDR`, `STR`, `CMP`, `B.cond`, `BL`, `ADD`, `SUB`, `MOV`)는 **전부 초반 2~6주차에서 이미 배운 것들**이네. 퀵 정렬이 "어렵다"고 느껴진다면, 그건 새로운 어셈블리 지식이 필요해서가 아니라 **기존 도구들을 올바른 순서로 조합하는 설계력**이 필요해서라는 걸 이번 프로젝트로 체감했으면 하네. 이게 바로 이 강좌 전체가 지향했던 방향 — **"명령어 목록 암기"가 아니라 "적은 원시 개념의 조합"**이라는 첫 시간의 약속이 여기서 완성되는 셈이네.

---

## 복잡도 참고 (알고리즘 이론)

| 경우 | 시간복잡도 | 원인 |
|---|---|---|
| 평균 | O(n log n) | 매 파티션이 대략 절반씩 나뉨 |
| 최악 (이미 정렬된 배열 등) | O(n²) | 피벗이 항상 최솟값/최댓값이 되어 한쪽으로 치우침 |
| 공간복잡도 | O(log n) 평균 | 재귀 호출 스택 깊이 (10주차에서 배운 "재귀 = 스택 프레임 누적"이 여기서 실전 비용으로 연결됨) |

---

법우, 15주차 종합 프로젝트로 퀵 정렬을 완성했네. 남은 건 16주차 **총정리 & Q&A**뿐일세 — 전체 커리큘럼 리뷰와 고급언어↔ARM64 최종 대응표를 정리해줄까, 아니면 이번 퀵 정렬을 실제로 타이핑/빌드해보고 결과를 들고 다시 이야기 나눌까?
