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
        if (args.Length >= 1 && (args[0] == "--list" || args[0] == "-l"))
        {
            ListTypes(args[1]);
            return;
        }

        var className = args[0];
        var methodName = args[1];
        var asmPath = args[2];
        Console.WriteLine($"className:{args[0]}");
        Console.WriteLine($"methodName:{args[1]}");
        Console.WriteLine($"asmPath:{args[2]}");

        using var stream = File.OpenRead(asmPath);
        using var peReader = new PEReader(stream);
        var md = peReader.GetMetadataReader();

        // ============================================================
        // 1. Find the type
        // ============================================================
        var typeHandle = md.TypeDefinitions
            .FirstOrDefault(h =>
            {
                var td = md.GetTypeDefinition(h);
                var name = md.GetString(td.Name);
                var ns = md.GetString(td.Namespace);
                var full = $"{ns}.{name}";
                return full == className || name == className;
            });

        if (typeHandle.IsNil)
        {
            Console.WriteLine($"Type '{className}' not found.");
            return;
        }

        var typeDef = md.GetTypeDefinition(typeHandle);
        Console.WriteLine($"Type: {className}");
        Console.WriteLine($"Token: 0x{MetadataTokens.GetToken(typeHandle):X8}");

        DumpGenericParameters(md, typeDef.GetGenericParameters());

        // ============================================================
        // 2. Find the method
        // ============================================================
        var methodHandle = typeDef.GetMethods()
            .FirstOrDefault(h =>
            {
                var m = md.GetMethodDefinition(h);
                return md.GetString(m.Name) == methodName;
            });

        if (methodHandle.IsNil)
        {
            Console.WriteLine($"Method '{methodName}' not found on type '{className}'.");
            return;
        }

        var methodDef = md.GetMethodDefinition(methodHandle);
        var attrs = methodDef.Attributes.ToString();
        Console.WriteLine($"\nMethod: {methodName}");
        Console.WriteLine($"Token: 0x{MetadataTokens.GetToken(methodHandle):X8}");
        Console.WriteLine($"  Attributes: {attrs}");

        DumpGenericParameters(md, methodDef.GetGenericParameters());
    }

    // ============================================================
    // --list mode: print every type, its [g=N] generic count, and its method names
    // ============================================================
    static void ListTypes(string asmPath)
    {
        using var stream = File.OpenRead(asmPath);
        using var peReader = new PEReader(stream);
        var md = peReader.GetMetadataReader();

        foreach (var h in md.TypeDefinitions)
        {
            var td = md.GetTypeDefinition(h);
            var name = md.GetString(td.Name);
            var ns = md.GetString(td.Namespace);
            int g = td.GetGenericParameters().Count;
            var suffix = g > 0 ? $" [g={g}]" : "";
            var methods = string.Join(", ", td.GetMethods()
                .Select(mh => md.GetString(md.GetMethodDefinition(mh).Name)));
            Console.WriteLine($"{ns}.{name}{suffix}  ({methods})");
        }
    }

    // ============================================================
    // Dump generic parameters + constraints (with flags)
    // ============================================================
    static void DumpGenericParameters(MetadataReader md, GenericParameterHandleCollection gps)
    {
        if (gps.Count == 0)
        {
            Console.WriteLine("  (No generic parameters)");
            return;
        }

        foreach (var gpHandle in gps)
        {
            var gp = md.GetGenericParameter(gpHandle);
            var gpName = md.GetString(gp.Name);
        var flags = gp.Attributes;
        Console.WriteLine($"  GP: {gpName} (index {gp.Index})  Attr=0x{((int)flags):X8} ({flagsToString((int)flags)})");

            foreach (var cHandle in gp.GetConstraints())
            {
                var constraint = md.GetGenericParameterConstraint(cHandle);
                var typeHandle = constraint.Type;

                Console.WriteLine(
                    $"    Constraint token: 0x{MetadataTokens.GetToken(typeHandle):X8}");

                if (typeHandle.Kind == HandleKind.TypeSpecification)
                {
                    var ts = md.GetTypeSpecification((TypeSpecificationHandle)typeHandle);
                    var blob = md.GetBlobReader(ts.Signature);

                    Console.WriteLine("    Constraint Blob:");
                    DumpBlob(blob);

                    blob = md.GetBlobReader(ts.Signature);
                    DumpDecoded(blob);
                }
                else
                {
                    Console.WriteLine("    (Non-TypeSpec constraint)");
                }
            }
        }
    }

    static string flagsToString(int f)
    {
        if (f == 0) return "none";
        var parts = new System.Collections.Generic.List<string>();
        // GenericParameterFlag bits (System.Reflection.GenericParameterFlags):
        //   0x1 Covariant, 0x2 Contravariant, 0x4 ReferenceTypeConstraint,
        //   0x8 RequireReferenceType, 0x10 DefaultConstructorConstraint,
        //   0x100 VarianceModifier (bit 8)
        if ((f & 0x8) != 0) parts.Add("reference-type-constraint");
        if ((f & 0x4) != 0) parts.Add("require-ref-type");
        if ((f & 0x10) != 0) parts.Add("default-ctor");
        if ((f & 0x20) != 0) parts.Add("variance-modifier");
        return string.Join(", ", parts);
    }

    static string DumpDecoded(BlobReader blob)
    {
        return $"    Decoded: {DecodeTypeSpec(ref blob)}";
    }

    static void DumpBlob(BlobReader reader)
    {
        var bytes = reader.ReadBytes(reader.Length);
        foreach (var b in bytes)
            Console.Write($"{b:X2} ");
        Console.WriteLine();
    }

    // ============================================================
    // Minimal TypeSpec decoder — stable across all SRM versions
    // ============================================================
    static string DecodeTypeSpec(ref BlobReader blob)
    {
        var et = blob.ReadByte(); // ELEMENT_TYPE_*

        return et switch
        {
            0x12 => DecodeClassOrValueType(ref blob, "class"),       // ELEMENT_TYPE_CLASS
            0x11 => DecodeClassOrValueType(ref blob, "valuetype"),  // ELEMENT_TYPE_VALUETYPE
            0x15 => DecodeGenericInst(ref blob),                    // ELEMENT_TYPE_GENERICINST
            0x1E => $"mvar({blob.ReadCompressedInteger()})",            // ELEMENT_TYPE_MVAR
            0x13 => $"var({blob.ReadCompressedInteger()})",             // ELEMENT_TYPE_VAR
            0x1D => $"byref({DecodeTypeSpec(ref blob)})",           // ELEMENT_TYPE_BYREF
            0x1F => $"szarray({DecodeTypeSpec(ref blob)})",         // ELEMENT_TYPE_SZARRAY
            _    => $"unknown-element-type(0x{et:X2})"
        };
    }

    static string DecodeClassOrValueType(ref BlobReader blob, string kind)
    {
        var token = blob.ReadCompressedInteger();
        return $"{kind}(token=0x{token:X8})";
    }

    static string DecodeGenericInst(ref BlobReader blob)
    {
        var et = blob.ReadByte(); // class or valuetype
        var kind = et == 0x12 ? "class" : "valuetype";

        var typeToken = blob.ReadCompressedInteger();
        var typeHandle = MetadataTokens.EntityHandle(typeToken);

        var arity = blob.ReadCompressedInteger();

        var args = new string[arity];
        for (int i = 0; i < arity; i++)
            args[i] = DecodeTypeSpec(ref blob);

        return $"genericinst({kind} 0x{typeToken:X8}<{string.Join(", ", args)}> )";
    }
}
