#include <stdio.h>

int main(void)
{

  int a = 9;
  printf("Hello, World! - %d\n", a);
  return 0;
}

// #include <unistd.h>

// int main(void)
// {
//   write(1, "Hello, ARM64!\n", 14);
//   return 0;
// }

// clang  -g -o p1 p1.c
// clang  -g -O0 -arch arm64 -o p1c p1.c
// clang -g -O0 -arch arm64 p1.c -S -o p1.s
// as -g -arch arm64 p1.s -o p1.o
// ld -lSystem -syslibroot $(xcrun --show-sdk-path) -e _main -arch arm64 p1.o -o p1

// - 소스 코드와 어셈블리 종시 출력
// (lldb) disassemble --mixed --frame
// (lldb) disassemble --mixed --frame