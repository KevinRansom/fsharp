// #Conformance #Regression #LetBindings #TypeInference 
#if TESTS_AS_APP
module Core_innerpoly
#endif

let failures = ref []

let report_failure (s : string) = 
    stderr.Write" NO: "
    stderr.WriteLine s
    failures := !failures @ [s]

let test (s : string) b = 
    stderr.Write(s)
    if b then stderr.WriteLine " OK"
    else report_failure (s)

let check s b1 b2 = test s (b1 = b2)

type ('a,'b) r = {a : 'a list; b: 'b list list }
type ('a,'b) r2 = R2 of  'a list * 'b list  list

let () =
  let [(R2((a as a2),(b as b2)))] = [R2 ([],[[]])] in 
  let _ = (a2 : int list) in
  let _ = (a2 : string list) in
  let _ = (b2 : int list list) in
  let _ = (b2 : string list list) in
  let f (x:'a) (y:'b) =
    let _ = (a2 : 'a list) in
    let _ = (a2 : 'a list) in
    let _ = (b2 : 'b list list) in
    let _ = (b2 : 'b list list) in
    () in
  f 1 "a";
  f 1 1; 
  ()


#if TESTS_AS_APP
let RUN() = !failures
#else
let aa =
  match !failures with 
  | [] -> 
      stdout.WriteLine "Test Passed"
      printf "TEST PASSED OK" ;
      exit 0
  | _ -> 
      stdout.WriteLine "Test Failed"
      exit 1
#endif

