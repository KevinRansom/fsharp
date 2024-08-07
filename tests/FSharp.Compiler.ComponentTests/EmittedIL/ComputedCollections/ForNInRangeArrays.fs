﻿let f0 f = [|for n in 1..10 do f (); yield n|]
let f00 f g = [|for n in 1..10 do f (); g (); yield n|]
let f000 f = [|for n in 1..10 do f (); yield n; yield n + 1|]
let f0000 () = [|for n in 1..10 do yield n|]
let f00000 () = [|for n in 1..10 do n|]
let f000000 () = [|for n in 1..10 do let n = n in n|]
let f0000000 () = [|for n in 1..10 do let n = n in yield n|]
let f00000000 () = [|for n in 1..10 do let n = n in let n = n in yield n|]
let f000000000 x y = [|for n in 1..10 do let foo = n + x in let bar = n + y in yield n + foo + bar|]
let f0000000000 f g = [|for n in 1..10 do f (); g (); n|]
let f00000000000 (f : unit -> int) (g : unit -> int) = [|for n in 1..10 do f (); g (); n|]
let f1 () = [|for n in 1..10 -> n|]
let f2 () = [|for n in 10..1 -> n|]
let f3 () = [|for n in 1..1..10 -> n|]
let f4 () = [|for n in 1..2..10 -> n|]
let f5 () = [|for n in 10..1..1 -> n|]
let f6 () = [|for n in 1..-1..10 -> n|]
let f7 () = [|for n in 10..-1..1 -> n|]
let f8 () = [|for n in 10..-2..1 -> n|]
let f9 start = [|for n in start..10 -> n|]
let f10 finish = [|for n in 1..finish -> n|]
let f11 start finish = [|for n in start..finish -> n|]
let f12 start = [|for n in start..1..10 -> n|]
let f13 step = [|for n in 1..step..10 -> n|]
let f14 finish = [|for n in 1..1..finish -> n|]
let f15 start step = [|for n in start..step..10 -> n|]
let f16 start finish = [|for n in start..1..finish -> n|]
let f17 step finish = [|for n in 1..step..finish -> n|]
let f18 start step finish = [|for n in start..step..finish -> n|]
let f19 f = [|for n in f ()..10 -> n|]
let f20 f = [|for n in 1..f () -> n|]
let f21 f g = [|for n in f ()..g() -> n|]
let f22 f = [|for n in f ()..1..10 -> n|]
let f23 f = [|for n in 1..f ()..10 -> n|]
let f24 f = [|for n in 1..1..f () -> n|]
let f25 f g h = [|for n in f ()..g ()..h () -> n|]
let f26 start step finish = [|for n in start..step..finish -> n, float n|]
let f27 start step finish = [|for n in start..step..finish -> struct (n, float n)|]
let f28 start step finish = [|for n in start..step..finish -> let x = n + 1 in n * n|]

let f29 f g = [|let y = f () in let z = g () in for x in 1..2..10 -> x + y + z|]
let f30 f g = [|let y = f () in g (); for x in 1..2..10 -> x + y|]
let f31 f g = [|f (); g (); for x in 1..2..10 -> x|]
let f32 f g = [|f (); let y = g () in for x in 1..2..10 -> x + y|]
