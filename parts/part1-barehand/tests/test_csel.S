.global _test_csel

.align 2

_test_csel:

	cmp  x0, x1          // x0와 x1 값을 비교
	csel x0, x0, x1, ge  // 만약 x0 >= x1 이면 x0 , 아니면 x1
	ret                  // x0 을 가지고 함수 반환