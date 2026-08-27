// matmul4x4_neon.s
// ARM64 (AArch64) macOS 어셈블리
// NEON SIMD를 이용한 4x4 float 행렬 곱셈: C = A * B
// 행렬은 column-major 순서로 저장 (float[16], 컬럼 단위로 4개씩)
//
// C 함수 시그니처:
//   void matmul4x4_neon(const float* A, const float* B, float* C);
//
// 스칼라 버전이라면 아래처럼 삼중 for문이 필요합니다:
//   for (j = 0; j < 4; j++)
//     for (i = 0; i < 4; i++) {
//       C[j][i] = 0;
//       for (k = 0; k < 4; k++)
//         C[j][i] += A[k][i] * B[j][k];
//     }
//
// NEON 버전에서는 안쪽 두 루프(i, k)를 벡터 연산 4개로 대체합니다.
// 즉, B의 컬럼 j 하나를 가져와 A의 4개 컬럼과 각각 곱-누적(FMLA)하면
// C의 컬럼 j 전체(4개 원소)가 한 번에 계산됩니다.

.text
.align 4
.global _matmul4x4_neon

_matmul4x4_neon:
    // x0 = A, x1 = B, x2 = C

    // A의 4개 컬럼을 레지스터에 미리 로드 (v0~v3)
    // 각 컬럼은 float 4개 = 16바이트
    ld1     {v0.4s}, [x0], #16     // v0 = A col0 (A[0][0..3])
    ld1     {v1.4s}, [x0], #16     // v1 = A col1
    ld1     {v2.4s}, [x0], #16     // v2 = A col2
    ld1     {v3.4s}, [x0], #16     // v3 = A col3

    mov     x3, #4                 // 바깥쪽 루프: B/C의 컬럼 4개만 순회

.Lcol_loop:
    // B의 컬럼 j 로드 (b0, b1, b2, b3)
    ld1     {v4.4s}, [x1], #16     // v4 = B col_j

    // 결과 컬럼 계산: acc = A_col0*b0 + A_col1*b1 + A_col2*b2 + A_col3*b3
    // v4.s[n] 은 B 컬럼의 n번째 스칼라를 레인 브로드캐스트하여 곱함
    fmul    v5.4s, v0.4s, v4.s[0]  // acc = A_col0 * b0
    fmla    v5.4s, v1.4s, v4.s[1]  // acc += A_col1 * b1
    fmla    v5.4s, v2.4s, v4.s[2]  // acc += A_col2 * b2
    fmla    v5.4s, v3.4s, v4.s[3]  // acc += A_col3 * b3

    // 결과 컬럼을 C에 저장
    st1     {v5.4s}, [x2], #16

    subs    x3, x3, #1
    b.ne    .Lcol_loop

    ret
