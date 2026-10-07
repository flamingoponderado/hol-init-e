Theory panSimplifyCv
Ancestors pan_simp cv_std
Libs preamble cv_transLib

val _ = cv_memLib.use_long_names := true;
val spec64 = INST_TYPE [alpha |-> ``:64``];
val _ = cv_auto_trans (spec64 pan_simpTheory.compile_prog_def);
