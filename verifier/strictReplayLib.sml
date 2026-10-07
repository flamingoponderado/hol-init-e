(* Data-only OpenTheory replay. No candidate ML, no axiom_in_db fallback.
   This is a checked component, not yet a complete challenge verifier. *)
structure strictReplayLib =
struct
open HolKernel boolLib bossLib;

fun reject s = raise Fail ("certificate replay: " ^ s);
fun checked th =
  if Tag.isEmpty (Thm.tag th) orelse Tag.isDisk (Thm.tag th) then th
  else reject "theorem uses an oracle or additional axiom";

fun same_sequent (hs,c) th =
  aconv c (concl th) andalso
  HOLset.equal (HOLset.addList (empty_tmset,hs), hypset th);

(* Computation requests are re-proved by the local HOL kernel. An article
   cannot make the result trusted merely by labelling it an axiom. *)
fun resolve trusted proved (hs,c) =
  case List.find (same_sequent (hs,c)) (trusted @ Net.listItems proved) of
    SOME th => checked th
  | NONE =>
      if not (null hs) then reject "unresolved assumption"
      else let val th = EQT_ELIM (cv_transLib.cv_eval c)
           in if same_sequent (hs,c) th then checked th
              else reject "computation proved a different statement" end;

(* Candidate definitions may only extend a fresh, operator-created theory.
   Fixed challenge, library, bytecode and score constants cannot be replaced. *)
fun reader trusted =
  let
    val namespace = current_theory ();
    fun const_name (["HOL4",thy],name) = {Thy=thy,Name=name}
      | const_name n = OpenTheoryReader.const_name_in_map n;
    fun tyop_name (["HOL4",thy],name) = {Thy=thy,Tyop=name}
      | tyop_name n = OpenTheoryReader.tyop_name_in_map n;
    fun def_const (c as {Thy,...}) rhs =
      if Thy = namespace andalso not (can prim_mk_const c)
      then OpenTheoryReader.define_const_in_thy I c rhs
      else reject "definition outside candidate theory";
    fun def_type (r as {name={Thy,...},rep,abs,...}) =
      if Thy = namespace andalso #Thy rep = namespace andalso #Thy abs = namespace
         andalso not (Option.isSome (Type.op_arity (#name r)))
         andalso not (can prim_mk_const rep) andalso not (can prim_mk_const abs)
      then OpenTheoryReader.define_tyop_in_thy r
      else reject "type definition outside candidate theory";
  in {const_name=const_name, tyop_name=tyop_name,
      define_const=def_const, define_tyop=def_type,
      axiom=resolve (map checked trusted)} end;

fun read trusted expected input =
  let
    val _ = if type_of expected = bool andalso null (free_vars expected)
            then () else reject "expected statement is not closed";
    val proved = OpenTheoryReader.raw_read_article input (reader trusted);
  in case List.find (same_sequent ([],expected)) (Net.listItems proved) of
       NONE => reject "exact fixed certificate conclusion was not proved"
     | SOME th => checked th
  end;
end
