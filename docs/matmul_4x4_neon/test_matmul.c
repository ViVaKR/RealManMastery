// test_matmul.c
// matmul4x4_neon.s 를 테스트하는 간단한 드라이버
#include <stdio.h>

// 어셈블리에서 구현한 함수 선언
extern void matmul4x4_neon(const float *A, const float *B, float *C);

// 결과 검증용 스칼라 버전 (일반 이중/삼중 for문)
static void matmul4x4_scalar(const float *A, const float *B, float *C)
{
    for (int j = 0; j < 4; j++)
    {
        for (int i = 0; i < 4; i++)
        {
            float sum = 0.0f;
            for (int k = 0; k < 4; k++)
            {
                sum += A[k * 4 + i] * B[j * 4 + k];
            }
            C[j * 4 + i] = sum;
        }
    }
}

static void print_mat(const char *name, const float *M)
{
    printf("%s =\n", name);
    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            printf("%8.2f ", M[j * 4 + i]); // column-major 접근
        }
        printf("\n");
    }
}

int main(void)
{
    // column-major 저장: A[col][row]
    float A[16] = {
        1, 0, 0, 0, // col0
        0, 1, 0, 0, // col1
        0, 0, 1, 0, // col2
        0, 0, 0, 1  // col3
    };

    float B[16] = {
        1, 2, 3, 4,    // col0
        5, 6, 7, 8,    // col1
        9, 10, 11, 12, // col2
        13, 14, 15, 16 // col3
    };

    float C_neon[16] = {0};
    float C_scalar[16] = {0};

    matmul4x4_neon(A, B, C_neon);
    matmul4x4_scalar(A, B, C_scalar);

    print_mat("A", A);
    print_mat("B", B);
    print_mat("C (NEON)", C_neon);
    print_mat("C (scalar, 검증용)", C_scalar);

    int ok = 1;
    for (int i = 0; i < 16; i++)
    {
        if (C_neon[i] != C_scalar[i])
            ok = 0;
    }
    printf("\n결과 일치 여부: %s\n", ok ? "OK (일치)" : "FAIL (불일치)");

    return 0;
}
