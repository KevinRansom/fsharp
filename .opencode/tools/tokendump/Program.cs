using System;
using System.IO;
using System.Linq; using System.Reflection;
class P {
  static void Main(string[] args) {
    if (args.Length < 3) return;
    var asmPath = args[0]; var className = args[1]; var methodSuffix = args[2];
    var asm = Assembly.LoadFile(Path.GetFullPath(asmPath));
    var target = asm.GetTypes().FirstOrDefault(t => t.Name.StartsWith(className));
    if (target == null) { Console.WriteLine("class not found " + className); return; }
    var meth = target.GetMethods(BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Static|BindingFlags.Instance)
        .FirstOrDefault(m => m.Name.StartsWith(methodSuffix));
    if (meth == null) { Console.WriteLine("method not found " + methodSuffix); return; }
    Console.WriteLine("Assembly: " + asmPath);
    Console.WriteLine("Class: " + target.FullName);
    Console.WriteLine("  Class generic params:");
    foreach (var gp in target.GetGenericParameters())
        Console.WriteLine("    " + gp.Name + " (index " + gp.Position + ") metadataToken=0x" + gp.MetadataToken.ToString("X8"));
    Console.WriteLine("Method: " + meth.Name + " static=" + meth.IsStatic);
    Console.WriteLine("  Method generic params:");
    foreach (var gp in meth.GetGenericParameters()) {
        Console.WriteLine("    " + gp.Name + " (index " + gp.Position + ") metadataToken=0x" + gp.MetadataToken.ToString("X8"));
        foreach (var c in gp.GetGenericParameterConstraints()) {
            Console.WriteLine("      constraint type = " + c.FullName + " token=0x" + c.MetadataToken.ToString("X8"));
            if (c.IsGenericType)
                foreach (var ga in c.GetGenericArguments())
                    Console.WriteLine("        arg " + ga.Name + " token=0x" + ga.MetadataToken.ToString("X8") + "  isGenericParam=" + (ga.IsGenericParameter));
        }
    }
  }
}
