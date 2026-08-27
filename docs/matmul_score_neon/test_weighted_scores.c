// test_weighted_scores.c
#include <stdio.h>

extern void weighted_scores_neon(
    const float* attendance, const float* homework, const float* exam,
    float w00, float w10, float w20,
    float w01, float w11, float w21,
    float* score1, float* score2, int n);

// 검증용 스칼라 버전
static void weighted_scores_scalar(
    const float* attendance, const float* homework, const float* exam,
    float w00, float w10, float w20,
    float w01, float w11, float w21,
    float* score1, float* score2, int n)
{
    for (int i = 0; i < n; i++) {
        score1[i] = attendance[i]*w00 + homework[i]*w10 + exam[i]*w20;
        score2[i] = attendance[i]*w01 + homework[i]*w11 + exam[i]*w21;
    }
}

int main(void) {
    // 캡처 이미지와 동일한 가중치
    // W = [[0.2,0.2],[0.3,0.5],[0.5,0.3]]
    float w00=0.2f, w10=0.3f, w20=0.5f;   // score1: 시험(0.5) 중요
    float w01=0.2f, w11=0.5f, w21=0.3f;   // score2: 과제(0.5) 중요

    // 학생 5명 (4명 + 나머지 1명으로 main_loop/remainder 둘 다 검증)
    // 첫 번째 학생은 캡처 이미지의 예시(90,80,70)와 동일
    float attendance[5] = {90, 85, 70, 95, 100};
    float homework[5]   = {80, 90, 60, 88, 75};
    float exam[5]        = {70, 75, 65, 92, 80};

    float score1_neon[5]={0}, score2_neon[5]={0};
    float score1_ref[5]={0},  score2_ref[5]={0};

    weighted_scores_neon(attendance, homework, exam,
                          w00, w10, w20, w01, w11, w21,
                          score1_neon, score2_neon, 5);

    weighted_scores_scalar(attendance, homework, exam,
                            w00, w10, w20, w01, w11, w21,
                            score1_ref, score2_ref, 5);

    printf("학생별 결과 (NEON) vs (스칼라, 검증용)\n");
    printf("--------------------------------------\n");
    int ok = 1;
    for (int i = 0; i < 5; i++) {
        printf("학생%d: score1=%.2f score2=%.2f   (검증: %.2f, %.2f)\n",
               i+1, score1_neon[i], score2_neon[i], score1_ref[i], score2_ref[i]);
        if (score1_neon[i] != score1_ref[i] || score2_neon[i] != score2_ref[i]) ok = 0;
    }

    printf("\n결과 일치 여부: %s\n", ok ? "OK (일치)" : "FAIL (불일치)");
    printf("(참고: 학생1은 캡처 이미지 예시와 동일 -> xW = [77, 79] 이어야 함)\n");

    return 0;
}
