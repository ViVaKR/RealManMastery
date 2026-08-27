using System.Numerics;
using System.Runtime.InteropServices;

namespace DotnetLibs;

public static class CalculateLib
{
  // ==================== 내부 구현: 진짜 제네릭 ====================
  // 정적 가상 인터페이스 멤버(Generic Math) 기반 — 리플렉션 없음, 완전 AOT 안전.
  // checked 컨텍스트: int/long처럼 checked 연산자를 지원하는 타입은
  // 오버플로 시 OverflowException을 던지도록 강제한다.
  // C# 코드끼리는 제네릭으로 깔끔하게 처리!
  private static void WriteLineInternal<T>(T a, T b, T sum)
  {
    Console.WriteLine("===> Hello, World <==");
    Console.WriteLine($"{a} + {b} = {sum}");
  }

  private static T Add<T>(T a, T b) where T : INumber<T> => checked(a + b);
  private static T Sub<T>(T a, T b) where T : INumber<T> => checked(a - b);
  private static T Mul<T>(T a, T b) where T : INumber<T> => checked(a * b);
  private static T Div<T>(T a, T b) where T : INumber<T> => a / b;

  // ==================== 정수 계열 안전 래퍼 ====================
  // 오버플로/0-나누기를 센티널 값(MinValue)으로 치환.
  // [UnmanagedCallersOnly] 경계를 넘어 예외가 새어나가면 프로세스가 죽으므로 필수.
  private static int SafeI32(Func<int> op)
  {
    try { return op(); }
    catch (OverflowException) { return int.MinValue; }
    catch (DivideByZeroException) { return int.MinValue; }
  }

  private static long SafeI64(Func<long> op)
  {
    try { return op(); }
    catch (OverflowException) { return long.MinValue; }
    catch (DivideByZeroException) { return long.MinValue; }
  }

  // ==================== i32 경계 ====================
  [UnmanagedCallersOnly(EntryPoint = "add_i32")]
  public static int AddI32(int a, int b) => SafeI32(() => Add(a, b));

  [UnmanagedCallersOnly(EntryPoint = "sub_i32")]
  public static int SubI32(int a, int b) => SafeI32(() => Sub(a, b));

  [UnmanagedCallersOnly(EntryPoint = "mul_i32")]
  public static int MulI32(int a, int b) => SafeI32(() => Mul(a, b));

  [UnmanagedCallersOnly(EntryPoint = "div_i32")]
  public static int DivI32(int a, int b) => SafeI32(() => Div(a, b));

  // ==================== i64 경계 ====================
  [UnmanagedCallersOnly(EntryPoint = "add_i64")]
  public static long AddI64(long a, long b) => SafeI64(() => Add(a, b));

  [UnmanagedCallersOnly(EntryPoint = "sub_i64")]
  public static long SubI64(long a, long b) => SafeI64(() => Sub(a, b));

  [UnmanagedCallersOnly(EntryPoint = "mul_i64")]
  public static long MulI64(long a, long b) => SafeI64(() => Mul(a, b));

  [UnmanagedCallersOnly(EntryPoint = "div_i64")]
  public static long DivI64(long a, long b) => SafeI64(() => Div(a, b));

  // ==================== f32 경계 ====================
  // IEEE 754: float/double 연산은 오버플로·0-나누기에서 예외를 던지지 않고
  // ±Infinity / NaN 을 반환한다 — 정수 계열과 달리 try/catch가 필요 없다.
  [UnmanagedCallersOnly(EntryPoint = "add_f32")]
  public static float AddF32(float a, float b) => Add(a, b);

  [UnmanagedCallersOnly(EntryPoint = "sub_f32")]
  public static float SubF32(float a, float b) => Sub(a, b);

  [UnmanagedCallersOnly(EntryPoint = "mul_f32")]
  public static float MulF32(float a, float b) => Mul(a, b);

  [UnmanagedCallersOnly(EntryPoint = "div_f32")]
  public static float DivF32(float a, float b) => Div(a, b);

  // ==================== f64 경계 ====================
  [UnmanagedCallersOnly(EntryPoint = "add_f64")]
  public static double AddF64(double a, double b) => Add(a, b);

  [UnmanagedCallersOnly(EntryPoint = "sub_f64")]
  public static double SubF64(double a, double b) => Sub(a, b);

  [UnmanagedCallersOnly(EntryPoint = "mul_f64")]
  public static double MulF64(double a, double b) => Mul(a, b);

  [UnmanagedCallersOnly(EntryPoint = "div_f64")]
  public static double DivF64(double a, double b) => Div(a, b);

  // ==================== FFI 외부 노출 (명시적 타입) ====================
  // i32 전용 (어셈블리: w0, w1, w2)
  [UnmanagedCallersOnly(EntryPoint = "console_writeline_i32")]
  public static void ConsoleWriteLine(int a, int b, int sum)
    => WriteLineInternal(a, b, sum);

  // i64 전용 (어셈블리: x0, x1, x2)
  [UnmanagedCallersOnly(EntryPoint = "console_writeline_i64")]
  public static void ConsoleWriteLineI64(long a, long b, long sum)
      => WriteLineInternal(a, b, sum);

  // f64 전용 (어셈블리: d0, d1, d2)
  [UnmanagedCallersOnly(EntryPoint = "console_writeline_f64")]
  public static void ConsoleWriteLineF64(double a, double b, double sum)
      => WriteLineInternal(a, b, sum);

  [UnmanagedCallersOnly(EntryPoint = "console_print_string")]
  public static unsafe void ConsolePrintString(byte* utf8String)
  {
    if (utf8String == null) return;
    string? str = Marshal.PtrToStringUTF8((nint)utf8String);
    Console.WriteLine(str);
  }
}