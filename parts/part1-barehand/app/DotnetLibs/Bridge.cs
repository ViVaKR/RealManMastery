using System.Runtime.InteropServices;

namespace DotnetLibs;

public class Bridge
{
  [UnmanagedCallersOnly(EntryPoint = "csharp_entry")]
  public static int MainEntry(int val)
  {
    Console.WriteLine($"[ASM → .NET] Received x0 = 0x{val:X}");
    return 0;
  }

  [UnmanagedCallersOnly(EntryPoint = "csharp_read_int")]
  public static int ReadIntFromUser()
  {
    Console.Write("정수를 입력하게: ");
    string? line = Console.ReadLine();
    return int.TryParse(line, out var n) ? n : -1;
  }
}
