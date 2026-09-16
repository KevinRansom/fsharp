..\..\artifacts\bin\fsc\Release\net11.0\fsc ..\..\tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig- --optimize- --out:..\..\artifacts\Temp\realsig\realsigminusoptimizeminus.exe
..\..\artifacts\bin\fsc\Release\net11.0\fsc ..\..\tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig- --optimize+ --out:..\..\artifacts\Temp\realsig\realsigminusoptimizeplus.exe
..\..\artifacts\bin\fsc\Release\net11.0\fsc ..\..\tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig+ --optimize- --out:..\..\artifacts\Temp\realsig\realsigplusoptimizeminus.exe
..\..\artifacts\bin\fsc\Release\net11.0\fsc ..\..\tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig+ --optimize+ --out:..\..\artifacts\Temp\realsig\realsigplusoptimizeplus.exe

ildasm ..\..\artifacts\Temp\realsig\realsigminusoptimizeminus.exe -out:..\..\artifacts\Temp\realsig\realsigminusoptimizeminus.il
ildasm ..\..\artifacts\Temp\realsig\realsigminusoptimizeplus.exe -out:..\..\artifacts\Temp\realsig\realsigminusoptimizeplus.il
ildasm ..\..\artifacts\Temp\realsig\realsigplusoptimizeminus.exe -out:..\..\artifacts\Temp\realsig\realsigplusoptimizeminus.il
ildasm ..\..\artifacts\Temp\realsig\realsigminusoptimizeplus.exe -out:..\..\artifacts\Temp\realsig\realsigplusoptimizeplus.il
