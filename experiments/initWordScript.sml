Theory initWord
Ancestors initLoops panWordCv
Libs preamble cv_transLib
val _ = cv_memLib.use_long_names := true;
val result = cv_eval_pat (cvName "prepared_word")
  ``loop_to_word$compile prepared_loop``;
val _ = if null (hyp result) then save_thm ("prepared_word_compilation", check_thm result)
  else failwith "word compilation has assumptions";
