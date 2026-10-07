Theory initLoops
Ancestors initPrepared panLoopCv
Libs preamble cv_transLib
val _ = cv_memLib.use_long_names := true;
val result = cv_eval_pat (cvName "prepared_loop")
  ``crep_to_loop$compile_prog RISC_V prepared_crep``;
val _ = if null (hyp result) then save_thm ("prepared_loop_compilation", check_thm result)
  else failwith "loop compilation has assumptions";
