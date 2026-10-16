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
        if (args.Length < 3)
        {
            Console.WriteLine("Usage: dumper <assembly> <class> <method>");
            return;
        }

        var asmPath = args[0];
        var className = args[1];
        var methodName = args[2];

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
        Console.WriteLine($"\nMethod: {methodName}");
        Console.WriteLine($"Token: 0x{MetadataTokens.GetToken(methodHandle):X8}");

        DumpGenericParameters(md, methodDef.GetGenericParameters());
    }

    // ============================================================
    // Dump generic parameters + constraints
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

            Console.WriteLine($"  GP: {gpName} (index {gp.Index})");

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
                    Console.WriteLine($"    Decoded: {DecodeTypeSpec(ref blob, md)}");
                }
                else
                {
                    Console.WriteLine("    (Non-TypeSpec constraint)");
                }
            }
        }
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
    static string DecodeTypeSpec(ref BlobReader blob, MetadataReader md)
    {
        var et = blob.ReadByte(); // ELEMENT_TYPE_*

        return et switch
        {
            0x12 => DecodeClassOrValueType(ref blob, md, "class"),       // ELEMENT_TYPE_CLASS
            0x11 => DecodeClassOrValueType(ref blob, md, "valuetype"),  // ELEMENT_TYPE_VALUETYPE
            0x15 => DecodeGenericInst(ref blob, md),                    // ELEMENT_TYPE_GENERICINST
            0x1E => $"mvar({blob.ReadCompressedInteger()})",            // ELEMENT_TYPE_MVAR
            0x13 => $"var({blob.ReadCompressedInteger()})",             // ELEMENT_TYPE_VAR
            0x1D => $"byref({DecodeTypeSpec(ref blob, md)})",           // ELEMENT_TYPE_BYREF
            0x1F => $"szarray({DecodeTypeSpec(ref blob, md)})",         // ELEMENT_TYPE_SZARRAY
            _    => $"unknown-element-type(0x{et:X2})"
        };
    }

    static string DecodeClassOrValueType(ref BlobReader blob, MetadataReader md, string kind)
    {
        var token = blob.ReadCompressedInteger();
        var handle = MetadataTokens.EntityHandle(token);

        return $"{kind}({ResolveTypeName(md, handle)})";
    }

    static string DecodeGenericInst(ref BlobReader blob, MetadataReader md)
    {
        var et = blob.ReadByte(); // class or valuetype
        var kind = et == 0x12 ? "class" : "valuetype";

        var typeToken = blob.ReadCompressedInteger();
        var typeHandle = MetadataTokens.EntityHandle(typeToken);

        var arity = blob.ReadCompressedInteger();

        var args = new string[arity];
        for (int i = 0; i < arity; i++)
            args[i] = DecodeTypeSpec(ref blob, md);

        return $"genericinst({kind} {ResolveTypeName(md, typeHandle)}<{string.Join(", ", args)}> )";
    }

    static string ResolveTypeName(MetadataReader md, EntityHandle handle)
    {
        return handle.Kind switch
        {
            HandleKind.TypeReference =>
                ResolveTypeRef(md.GetTypeReference((TypeReferenceHandle)handle), md),

            HandleKind.TypeDefinition =>
                ResolveTypeDef(md.GetTypeDefinition((TypeDefinitionHandle)handle), md),

            HandleKind.TypeSpecification =>
                "TypeSpec",

            _ => $"UnknownHandleKind({handle.Kind})"
        };
    }

    static string ResolveTypeRef(TypeReference tr, MetadataReader md)
    {
        var ns = md.GetString(tr.Namespace);
        var name = md.GetString(tr.Name);
        return $"{ns}.{name}";
    }

    static string ResolveTypeDef(TypeDefinition td, MetadataReader md)
    {
        var ns = md.GetString(td.Namespace);
        var name = md.GetString(td.Name);
        return $"{ns}.{name}";
    }
}
