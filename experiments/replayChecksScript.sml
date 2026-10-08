Theory replayChecks
Ancestors initParams While
Libs preamble cv_transLib strictReplayLib

val empty = Net.empty : thm Net.net;
val _ = List.app (fn th => ignore (strictReplayLib.resolve
  strictReplayLib.kernel_axioms empty ([],concl th))) strictReplayLib.kernel_axioms;
val _ = strictReplayLib.resolve [TRUTH] empty ([],T);
val _ = strictReplayLib.resolve [] empty ([],``1n + 2 = 3``);
val _ = strictReplayLib.resolve [numeralTheory.numeral_lt] empty
  ([],``!m n. arithmetic$BIT1 n < arithmetic$BIT1 m <=> n < m``);
val _ = strictReplayLib.resolve [] empty ([],``COND T = (\t1 t2:bool. t1)``);
fun must_reject name f =
  if (f (); false) handle HOL_ERR _ => true | Fail _ => true
  then () else raise Fail ("accepted invalid replay: " ^ name);
val _ = must_reject "false axiom"
  (fn () => (strictReplayLib.resolve [] empty ([],F); ()));
val _ = must_reject "unproved assumption"
  (fn () => (strictReplayLib.resolve [] empty ([F],T); ()));
val _ = must_reject "cheated trusted theorem"
  (fn () => (strictReplayLib.reader [mk_thm([],F)]; ()));
val _ = must_reject "fixed constant replacement"
  (fn () => (#define_const (strictReplayLib.reader [])
    {Thy="initParams",Name="gasLimit"} ``0n``; ()));
val _ = must_reject "empty proof article"
  (fn () => (strictReplayLib.read [] T (TextIO.openString ""); ()));

fun atomic_article name = String.concatWith "\n"
  ["nil", "\"HOL4.bool." ^ name ^ "\"", "const",
   "\"HOL4.min.bool\"", "typeOp", "nil", "opType", "constTerm",
   "0", "def", "axiom", "nil", "0", "ref", "thm", ""];
val _ = strictReplayLib.read [TRUTH] T
  (TextIO.openString (atomic_article "T"));
val _ = must_reject "forged article axiom"
  (fn () => (strictReplayLib.read [] F
    (TextIO.openString (atomic_article "F")); ()));
val _ = must_reject "different expected conclusion"
  (fn () => (strictReplayLib.read [TRUTH] F
    (TextIO.openString (atomic_article "T")); ()));

val candidate_def = #define_const (strictReplayLib.reader [])
  {Thy=current_theory (),Name="candidateLiteral"} ``17n``;
val _ = must_reject "candidate constant redefinition"
  (fn () => (#define_const (strictReplayLib.reader [])
    {Thy=current_theory (),Name="candidateLiteral"} ``18n``; ()));

val _ = strictReplayLib.resolve [] empty
  ([],``cv$cv_add (cv$Num 19) (cv$Num 23) = cv$Num 42``);
val _ = must_reject "wrong primitive CV result"
  (fn () => (strictReplayLib.resolve [] empty
    ([],``cv$cv_add (cv$Num 19) (cv$Num 23) = cv$Num 43``); ()));

(* Representation conversion produces CV data but is checked by ordinary
   evaluation of the fixed encoder, not by the raw CV instruction evaluator. *)
val _ = strictReplayLib.resolve [] empty
  ([],``cv_type$from_list cv$Num [1n;2] =
    cv$Pair (cv$Num 1) (cv$Pair (cv$Num 2) (cv$Num 0))``);
val _ = must_reject "wrong CV representation conversion"
  (fn () => (strictReplayLib.resolve [] empty
    ([],``cv_type$from_list cv$Num [1n;2] = cv$Num 0``); ()));

(* Replay CV equations for fresh functions, without cv_trans registrations. *)
Definition candidateCv_def:
  candidateCv x = cv$cv_add x (cv$Num 7)
End
Definition candidateCvOuter_def:
  candidateCvOuter x = candidateCv (candidateCv x)
End
val cv_facts = [candidateCv_def,candidateCvOuter_def];
val _ = strictReplayLib.resolve cv_facts empty
  ([],``candidateCvOuter (cv$Num 3) = cv$Num 17``);
val _ = strictReplayLib.resolve [CONJ candidateCv_def candidateCvOuter_def] empty
  ([],``candidateCvOuter (cv$Num 3) = cv$Num 17``);
val non_code = prove
  (``candidateCv x = if T then candidateCv x else cv$Num 0``, simp []);
val _ = strictReplayLib.resolve (non_code::cv_facts) empty
  ([],``candidateCvOuter (cv$Num 3) = cv$Num 17``);
Definition candidateCvEq_def:
  candidateCvEq x = cv$cv_eq x (cv$Num 3)
End
val _ = strictReplayLib.resolve [cvTheory.cv_eq_def,candidateCvEq_def] empty
  ([],``candidateCvEq (cv$Num 3) = cv$Num 1``);
Definition candidateCvPower_def:
  candidateCvPower x = cv$cv_exp (cv$Num 2) x
End
val power_facts = [candidateCvPower_def,cvTheory.cv_exp_eq];
val _ = strictReplayLib.resolve power_facts empty
  ([],``candidateCvPower (cv$Num 7) = cv$Num 128``);
val _ = must_reject "wrong CV exponentiation result"
  (fn () => (strictReplayLib.resolve power_facts empty
    ([],``candidateCvPower (cv$Num 7) = cv$Num 129``); ()));
val _ = must_reject "wrong CV result"
  (fn () => (strictReplayLib.resolve cv_facts empty
    ([],``candidateCvOuter (cv$Num 3) = cv$Num 18``); ()));
val _ = must_reject "missing CV equation"
  (fn () => (strictReplayLib.resolve [candidateCvOuter_def] empty
    ([],``candidateCvOuter (cv$Num 3) = cv$Num 17``); ()));
val _ = must_reject "forged CV equation"
  (fn () => (strictReplayLib.resolve
    [mk_thm([],``candidateCvOuter x = cv$Num 18``)] empty
    ([],``candidateCvOuter (cv$Num 3) = cv$Num 18``); ()));

Definition sanitizedTestBytes_def:
  sanitizedTestBytes = [0w;255w;17w] : word8 list
End
val byte_request = ``cv_type$to_list (cv_type$to_word : cv -> word8)
  (cv$Pair (cv$Num 0) (cv$Pair (cv$Num 255) (cv$Pair (cv$Num 17) (cv$Num 0)))) =
  sanitizedTestBytes``;
val _ = strictReplayLib.resolve [sanitizedTestBytes_def] empty ([],byte_request);
val _ = must_reject "changed byte literal"
  (fn () => (strictReplayLib.resolve [sanitizedTestBytes_def] empty
    ([],``cv_type$to_list (cv_type$to_word : cv -> word8)
      (cv$Pair (cv$Num 1) (cv$Num 0)) = sanitizedTestBytes``); ()));
val _ = must_reject "forged byte literal definition"
  (fn () => (strictReplayLib.resolve
    [mk_thm([],``sanitizedTestBytes = [0w;255w;17w]``)] empty ([],byte_request); ()));

val _ = strictReplayLib.resolve [] empty
  ([],``(a <=> b) ==> (b ==> (c <=> d)) ==> ((a ==> c) <=> (b ==> d))``);
val _ = strictReplayLib.bool_taut
  ``(a <=> b) ==> (b ==> (c <=> d)) ==> ((a ==> c) <=> (b ==> d))``;
val _ = must_reject "false propositional request"
  (fn () => (strictReplayLib.bool_taut ``a /\ ~a``; ()));
val _ = strictReplayLib.resolve [] empty
  ([],``(([]:'a list) = a0::a1) = F``);
val _ = must_reject "false datatype distinctness"
  (fn () => (strictReplayLib.resolve [] empty
    ([],``(([]:'a list) = a0::a1) = T``); ()));
val _ = strictReplayLib.resolve [] empty ([],``(m:num) < n <=> 1 + m <= n``);
val _ = must_reject "false symbolic arithmetic equivalence"
  (fn () => (strictReplayLib.resolve [] empty ([],``(m:num) < n <=> m <= n``); ()));
val _ = strictReplayLib.logical_compute ``!x:'a # 'b. x = (FST x,SND x)``;
val _ = strictReplayLib.fixed_eval ``LENGTH [T;F;T] = 3``;
val _ = must_reject "symbolic recursive evaluation request"
  (fn () => (strictReplayLib.fixed_eval
    ``!(f:'a -> 'a + 'b) x. While$TAILREC f x =
       sum$sum_CASE (f x) (While$TAILREC f) combin$I``; ()));
val _ = must_reject "false fixed EVAL request"
  (fn () => (strictReplayLib.fixed_eval ``LENGTH [T;F;T] = 4``; ()));
val _ = must_reject "candidate constant in fixed EVAL request"
  (fn () => (strictReplayLib.fixed_eval ``sanitizedTestBytes = [0w;255w;17w]``; ()));

Theorem replay_component_checked:
  T
Proof
  ACCEPT_TAC TRUTH
QED
