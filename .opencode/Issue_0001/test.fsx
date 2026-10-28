// #Regression #Conformance #Regression #Exceptions #Constants #LetBindings #Lists #Collections #Stress #Sequences #Optimizations #Records #Unions 
#if TESTS_AS_APP
module Core_libtest
#endif


#nowarn "62"
#nowarn "44"

let failures = ref []
let reportFailure s = 
  stdout.WriteLine "\n................TEST FAILED...............\n"; failures := !failures @ [s]

let check s e r = 
  if r = e then  stdout.WriteLine (s+": YES") 
  else (stdout.WriteLine ("\n***** "+s+": FAIL\n"); reportFailure s)

let test s b = 
  if b then ( (* stdout.WriteLine ("passed: " + s) *) ) 
  else (stderr.WriteLine ("failure: " + s); 
        reportFailure s)

let format_uint64 outc formatc width left_justify add_zeros num_prefix_if_pos (n:uint64) = 
  let _ = match formatc with 'd' | 'i' | 'u' -> 10UL | 'o' -> 8UL | 'x' | 'X'-> 16UL | _ -> failwith "invalid value" in
  failwith "hello"

module SeqTestsOnEnumerableEnforcingDisposalAtEnd = begin
   
   let mutable numActiveEnumerators = 0
   
   let countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd (seq: seq<'a>) =
       let enumerator() = 
                 numActiveEnumerators <- numActiveEnumerators + 1;
                 let disposed = ref false in
                 let endReached = ref false in
                 let ie = seq.GetEnumerator() in
                 { new System.Collections.Generic.IEnumerator<'a> with 
                      member x.Current =
                          test "rvlrve0" (not !endReached);
                          test "rvlrve1" (not !disposed);
                          ie.Current
                      member x.Dispose() = 
                          test "rvlrve2" !endReached;
                          test "rvlrve4" (not !disposed);
                          numActiveEnumerators <- numActiveEnumerators - 1;
                          disposed := true;
                          ie.Dispose() 
                   interface System.Collections.IEnumerator with 
                      member x.MoveNext() = 
                          test "rvlrve0" (not !endReached);
                          test "rvlrve3" (not !disposed);
                          endReached := not (ie.MoveNext());
                          not !endReached
                      member x.Current = 
                          test "qrvlrve0" (not !endReached);
                          test "qrvlrve1" (not !disposed);
                          box ie.Current
                      member x.Reset() = 
                          ie.Reset()
                   } in

       { new seq<'a> with 
             member x.GetEnumerator() =  enumerator() 
         interface System.Collections.IEnumerable with 
             member x.GetEnumerator() =  (enumerator() :> _) }

   let countEnumeratorsAndCheckedDisposedAtMostOnce (seq: seq<'a>) =
       let enumerator() = 
                 let disposed = ref false in
                 let endReached = ref false in
                 let ie = seq.GetEnumerator() in
                 numActiveEnumerators <- numActiveEnumerators + 1;
                 { new System.Collections.Generic.IEnumerator<'a> with 
                      member x.Current =
                          test "qrvlrve0" (not !endReached);
                          test "qrvlrve1" (not !disposed);
                          ie.Current
                      member x.Dispose() = 
                          test "qrvlrve4" (not !disposed);
                          numActiveEnumerators <- numActiveEnumerators - 1;
                          disposed := true;
                          ie.Dispose() 
                   interface System.Collections.IEnumerator with 
                      member x.MoveNext() = 
                          test "qrvlrve0" (not !endReached);
                          test "qrvlrve3" (not !disposed);
                          endReached := not (ie.MoveNext());
                          not !endReached
                      member x.Current = 
                          test "qrvlrve0" (not !endReached);
                          test "qrvlrve1" (not !disposed);
                          box ie.Current
                      member x.Reset() = 
                          ie.Reset()
                   } in

       { new seq<'a> with 
             member x.GetEnumerator() =  enumerator() 
         interface System.Collections.IEnumerable with 
             member x.GetEnumerator() =  (enumerator() :> _) }

   // This one gave a stack overflow when we weren't tail-calling on 64-bit
   do check "Seq.filter-length" ({ 1 .. 1000000 } |> countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd |> Seq.filter (fun n -> n <> 1) |> Seq.length) 999999
end

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

