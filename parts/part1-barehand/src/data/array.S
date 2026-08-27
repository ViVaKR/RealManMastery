.section __DATA, __data

.global _quad_arr, _quad_arr_end
.global _int_arr, _int_arr_end

// 64비트 배열 (8바이트 정렬)
.align 3
_quad_arr: .quad 3, 1, 7, 9, 5, 2, 6, 4, 8
_quad_arr_end:

// 32 비트 정수형 배열 (4바이트 정렬)
.align 2
_int_arr: .int 1, 2, 3, 4, 5, 6, 7, 8, 9
_int_arr_end:
