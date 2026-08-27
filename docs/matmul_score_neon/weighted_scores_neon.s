// weighted_scores_neon.s
// ARM64 (AArch64) macOS 어셈블리
// NEON SIMD를 이용한 "다중 기준 가중치 채점" 배치 연산
//
//   x(학생) = [출석, 과제, 시험]   (1x3 벡터, 학생 N명)
//   W       = [[w00,w01],[w10,w11],[w20,w21]]  (3x2 행렬, 고정 가중치)
//   xW      = x * W  ->  (score1, score2)      (1x2 벡터, 학생마다)
//
// 핵심 아이디어:
//   학생 1명의 연산(1x3 * 3x2)은 너무 작아서 NEON 이득이 거의 없습니다.
//   대신 "학생 N명"을 한 번에 계산합니다 - NEON 벡터 레인 하나 = 학생 1명.
//   즉, 스칼라 이중 for문 (학생 i, 출력 j)을
//   "학생 4명씩 묶어서 처리하는 단일 루프"로 대체합니다.
//
// C 함수 시그니처:
//   void weighted_scores_neon(
//       const float* attendance, const float* homework, const float* exam,
//       float w00, float w10, float w20,   // score1 가중치 (시험 중요)
//       float w01, float w11, float w21,   // score2 가중치 (과제 중요)
//       float* score1, float* score2, int n);
//
// AArch64 macOS 호출 규약(AAPCS64):
//   x0=attendance, x1=homework, x2=exam, x3=score1, x4=score2, w5=n (정수/포인터)
//   s0=w00, s1=w10, s2=w20, s3=w01, s4=w11, s5=w21 (float, 별도의 v레지스터 뱅크)

.text
.align 4
.global _weighted_scores_neon

_weighted_scores_neon:
    // 6개의 가중치 스칼라를 각각 4-레인 벡터로 브로드캐스트
    // (v16~v21은 루프 내내 고정된 상수로 사용)
	dup v16.4s, v0.s[0]  // w00
	dup v17.4s, v1.s[0]  // w10
	dup v18.4s, v2.s[0]  // w20
	dup v19.4s, v3.s[0]  // w01
	dup v20.4s, v4.s[0]  // w11
	dup v21.4s, v5.s[0]  // w21

	cmp  w5, #4
	b.lt .Lremainder  // 학생이 4명 미만이면 바로 나머지 처리로

.Lmain_loop:                       // 학생 4명씩 병렬 처리
	ld1 {v0.4s}, [x0], #16  // 출석 4명분
	ld1 {v1.4s}, [x1], #16  // 과제 4명분
	ld1 {v2.4s}, [x2], #16  // 시험 4명분

    // score1 = 출석*w00 + 과제*w10 + 시험*w20  (4명 동시에)
	fmul v4.4s, v0.4s, v16.4s
	fmla v4.4s, v1.4s, v17.4s
	fmla v4.4s, v2.4s, v18.4s
	st1  {v4.4s}, [x3], #16

    // score2 = 출석*w01 + 과제*w11 + 시험*w21  (4명 동시에)
	fmul v5.4s, v0.4s, v19.4s
	fmla v5.4s, v1.4s, v20.4s
	fmla v5.4s, v2.4s, v21.4s
	st1  {v5.4s}, [x4], #16

	sub  w5, w5, #4
	cmp  w5, #4
	b.ge .Lmain_loop

.Lremainder:                       // 4의 배수로 안 떨어지는 나머지 학생 (0~3명)
	cbz w5, .Ldone

.Lscalar_loop:
	ldr s0, [x0], #4
	ldr s1, [x1], #4
	ldr s2, [x2], #4

    // 스칼라 곱셈+누적은 fmla가 아니라 fmadd(Sd = Sn*Sm + Sa) 사용
	fmul  s6, s0, s16
	fmadd s6, s1, s17, s6
	fmadd s6, s2, s18, s6
	str   s6, [x3], #4

	fmul  s7, s0, s19
	fmadd s7, s1, s20, s7
	fmadd s7, s2, s21, s7
	str   s7, [x4], #4

	subs w5, w5, #1
	b.ne .Lscalar_loop

.Ldone:
    ret