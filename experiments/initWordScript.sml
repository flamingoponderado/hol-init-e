(* Extension experiment: translate the remaining Pancake-to-word passes. *)
Theory initWord
Ancestors initSimplify panWordCv
Libs preamble cv_transLib

val _ = cv_memLib.use_long_names := true;
val _ = save_thm ("guest_to_word",
  cv_eval_pat (cvName "guest_word")
    ``pan_to_word$compile_prog RISC_V guestAst``);
