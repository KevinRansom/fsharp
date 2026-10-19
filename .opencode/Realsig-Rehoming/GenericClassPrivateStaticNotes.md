- Thought: 52.5s
The user is providing an F# program, its generated IL, and the errors from ILVerify.

Looking at the F# code:
module Sample
type Safe<'T>(mark: 'T) =
    static let mutable stage = 0
    static member Set v = stage <- v
    member _.Mark = mark
    [<NoCompilerInlining>]
    static member private Secret() = stage + 1
    member _.Run<'U>(u: 'U) =
        let rec go (n: int) (acc: int) (p: 'U) =
            if n <= 0 then acc
            elif box p = null then acc - 1
            else skip (n - 1) (acc + Safe<'T>.Secret()) p
        and skip (n: int) (acc: int) (p: 'U) =
            if n % 2 = 0 then skip (n - 1) acc p
            else go (n - 1) acc p
        go 1000 0 u
[<EntryPoint>]
let main _ =
    let s = Safe<int>(0)
    Safe<int>.Set 41
    if s.Run<string>("x") = 21000 then 0 else 1 

The Run<'U> method is a member of Safe<'T>. It takes a generic parameter 'U.
Within Run<'U>, it defines recursive functions go and skip which also use 'U.

Now let's look at the generated IL:
Safe is a generic class Safe1<T>.
Run is an instance method: .method public hidebysig instance int32 Run<U>(!!U u) cil managed.
It calls go@9<U>`.

Wait, look at go@9<U>'s signature in IL:
.method assembly static int32 go@9<U>(int32 n, int32 acc, !T p) cil managed

Here's the bug: go@9<U> is defined as a static method that is generic over U, but its third parameter p is of type !T (the class's generic parameter), NOT !!U (the method's generic parameter).

In the F# code, go is defined inside Run<'U>, and p is of type 'U.
So go's signature should be go (n: int) (acc: int) (p: 'U).
In IL, this should be go@9<U>(int32 n, int32 acc, !!U p).

But the IL shows:
.method assembly static int32 go@9<U>(int32 n, int32 acc, !T p) cil managed

This is why ILVerify is complaining:
[IL]: Error [StackUnexpected]: [ ... Safe1::Run(!!0)]offset 0x00000009expected value 'T'
When Run<U> calls go@9<U>, it pushes a value of type U on the stack. But go@9<U> expects a value of type T`.

Similarly for go@9 itself:
[IL]: Error [StackUnexpected]: [ ... Safe1::go@9(int32, int32, !0)]offset 0x00000007expected value 'U'
In go@9, it does ldarg.2 (which is T) and then box !!U. It should be boxing p (which should be U`).

The compiler is incorrectly using the class generic parameter T instead of the method generic parameter U for the argument p in the lifted recursive functions go and skip.

This looks like a bug in how the F# compiler handles lifting local recursive functions that capture method-level generic parameters.

I need to find where these local functions are lifted and their signatures generated in the compiler.

I'll start by exploring the codebase to find where local functions are handled and lifted.
This is a bug in the F# compiler. The local recursive functions go and skip defined inside the generic method Run<'U> are being "lifted" to static methods in IL, but the compiler is incorrectly assigning the class-level generic parameter 'T to the parameter p instead of the method-level generic parameter 'U.
This causes a type mismatch in the generated IL: Run<U> passes a value of type U, but the lifted go<U> expects a value of type T.
I will investigate the compiler's lifting logic for local functions and generic parameters.