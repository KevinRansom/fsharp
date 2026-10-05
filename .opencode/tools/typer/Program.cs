using System;
using System.IO;
using System.Linq;
using System.Reflection.Metadata;
using System.Reflection.Metadata.Ecma335;
using System.Reflection.PortableExecutable;

class Program
{
    static void Main(string[] args)
    {
        if (args.Length < 1) return;
        using var s = File.OpenRead(args[0]);
        using var p = new PEReader(s);
        var m = p.GetMetadataReader();

        Console.WriteLine("== TypeRefs ==");
        int i = 1;
        foreach (var h in m.TypeReferences)
        {
            var t = m.GetTypeReference(h);
            Console.WriteLine($"  {i}: {m.GetString(t.Namespace)}.{m.GetString(t.Name)}");
            i++;
        }
        Console.WriteLine("== TypeDefs ==");
        i = 1;
        foreach (var h in m.TypeDefinitions)
        {
            var t = m.GetTypeDefinition(h);
            Console.WriteLine($"  {i}: {m.GetString(t.Namespace)}.{m.GetString(t.Name)}  (gen={t.GetGenericParameters().Count})");
            i++;
        }
    }
}
