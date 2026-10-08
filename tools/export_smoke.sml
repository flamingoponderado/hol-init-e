(* Author-side export regression; run through tools/test_exporter.py. *)
val _ = TraceMode.mode := TraceMode.TraceOnly;
load "cv_computeLib";
load "Logging";
open HolKernel boolLib bossLib;
val _ = PolyML.print_depth 0;
val _ = new_theory "exportSmoke";
val _ = TraceMode.mode := TraceMode.TraceOnly;
val _ = Logging.set_const_name_handler
  (fn {Thy,Name} => (["HOL4",if Thy = "exportSmoke" then "candidateCertificate" else Thy],Name));
val _ = Logging.set_tyop_name_handler
  (fn {Thy,Tyop} => (["HOL4",Thy],Tyop));
val _ = Logging.raw_start_logging [] (TextIO.openOut "cv-smoke.art");
val specs = gen_new_specification("smoke_pair",
 CONJ (ASSUME ``leftValue = cv$Num 2``) (ASSUME ``rightValue = cv$Num 5``));
val _ = Logging.export_thm specs;
val code = new_definition("smoke_def",``smoke x = cv$cv_add x (cv$Num 7)``);
val result = cv_computeLib.cv_compute [code] ``smoke (cv$Num 10)``;
val _ = Logging.export_thm result;
val _ = List.app (fn _ => ignore (Logging.export_thm result)) (List.tabulate (33,I));
val decoded = literalDecode.decode
  ``cv$Pair (cv$Num 0) (cv$Pair (cv$Num 255) (cv$Pair (cv$Num 17) (cv$Num 0)))``;
val _ = if aconv (rhs (concl decoded)) ``[0w;255w;17w] : word8 list`` then ()
        else raise Fail "literal decoder mismatch";
val _ = Logging.export_thm decoded;
val _ = Logging.stop_logging ();
val _ = print "EXPORT_SMOKE_OK\n";
