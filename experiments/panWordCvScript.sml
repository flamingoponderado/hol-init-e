(* Experimental translation beyond the simplifier; not in the default build. *)
Theory panWordCv
Ancestors panSimplifyCv pan_to_word
Libs preamble cv_transLib

val _ = cv_memLib.use_long_names := true;
val spec64 = INST_TYPE [alpha |-> ``:64``];
(* Register the mutually recursive shape/shape-list equations together. *)
val _ = cv_auto_trans_rec pan_structsTheory.compile_shape_def
  (WF_REL_TAC
     `inv_image (measure cv$cv_size LEX measure cv$cv_size)
        (\x. case x of INL p => p | INR p => p)` >>
   cv_termination_tac);
val _ = cv_auto_trans (spec64 pan_to_wordTheory.compile_prog_def);
