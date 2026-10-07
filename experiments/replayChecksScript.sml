Theory replayChecks
Ancestors initParams
Libs preamble cv_transLib strictReplayLib

val empty = Net.empty : thm Net.net;
val _ = strictReplayLib.resolve [TRUTH] empty ([],T);
val _ = strictReplayLib.resolve [] empty ([],``1n + 2 = 3``);
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

Theorem replay_component_checked:
  T
Proof
  ACCEPT_TAC TRUTH
QED
