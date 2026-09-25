module RealsigTest

open System
open System.Collections.Generic

type ConcatEnumerator<'T,'U when 'U :> seq<'T>>(sources: seq<'U>) =

    let mutable outerEnum = sources.GetEnumerator()
    let mutable started = false

    [<DefaultValue(false)>]
    val mutable private currElement : 'T

    // Generic method with its own type parameter 'M
    member x.MoveNext<'M>(m: 'M) =
        // Capture class state + all typars
        let inner =
            fun (n: 'T) ->
                if not started then
                    started <- true
                    x.currElement <- n

                printfn $"{m} - {typeof<'T>} {typeof<'U>} {typeof<'M>} {(box n)} {(box x.currElement)}"
                true
        inner

let src : seq<int> list = [ [1;2;3] ]
let c = ConcatEnumerator<int, seq<int>>(src)
let f = c.MoveNext<string>("hello")
let _ = printfn $"{f 42}"
()
