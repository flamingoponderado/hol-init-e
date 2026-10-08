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

(* Fixed library facts may be requested with quantified variables instantiated
   or conjunctions projected. These steps are kernel inferences, too. *)
fun instance facts seq =
  let
    val (_,c) = seq;
    val (variables,body) = strip_forall c;
    fun attempt th =
      let val result = GENL variables (PART_MATCH I (checked th) body)
      in if same_sequent seq result then SOME (checked result) else NONE end
      handle HOL_ERR _ => NONE;
    fun first [] = NONE
      | first (th::rest) =
          case attempt th of SOME result => SOME result | NONE => first rest;
    fun search [] = NONE
      | search (th::rest) =
          case first (th :: CONJUNCTS (SPEC_ALL th)) of
            SOME result => SOME result | NONE => search rest;
  in search facts end;

(* Article-defined CV functions have no cv_trans metadata. Recover their code
   equations only from already checked theorems, then ask the kernel compute
   primitive to prove the requested equality. No article equation is assumed. *)
fun raw_compute facts c =
  let
    val (lhs,_) = dest_eq c;
    val _ = if type_of lhs = cvSyntax.cv andalso null (free_vars lhs)
            then () else reject "not a closed CV computation";
    (* Representation theorems can have the same head as executable code.
       Select only equations in the kernel evaluator's CV expression language. *)
    fun code_expression tm =
      type_of tm = cvSyntax.cv andalso
      (if is_var tm then true
       else if cvSyntax.is_cv_num tm then
         numSyntax.is_numeral (cvSyntax.dest_cv_num tm)
       else if boolSyntax.is_let tm then
         let val (binding,value) = boolSyntax.dest_let tm
             val (v,body) = dest_abs binding
         in type_of v = cvSyntax.cv andalso code_expression value andalso
            code_expression body end
       else let val (f,args) = strip_comb tm
            in is_const f andalso not (null args) andalso
               List.all code_expression args end)
      handle HOL_ERR _ => false;
    fun equation th =
      let
        val th = SPEC_ALL (checked th);
        val (l,r) = dest_eq (concl th);
        val (f,args) = strip_comb l;
        val _ = if null (hyp th) andalso is_const f andalso not (null args)
                   andalso #Thy (dest_thy_const f) <> "cv"
                   andalso code_expression r
                   andalso List.all (fn v => is_var v andalso type_of v = cvSyntax.cv) args
                   andalso HOLset.numItems (HOLset.addList (empty_tmset,args)) = length args
                   andalso List.all (fn v => List.exists (aconv v) args) (free_vars r)
                then () else raise Fail "not a code equation";
      in SOME (f,(th,r)) end
      handle HOL_ERR _ => NONE | Fail _ => NONE;
    val equations = List.mapPartial equation facts;
    fun collect [] seen result = result
      | collect (f::todo) seen result =
          if List.exists (aconv f) seen then collect todo seen result
          else case List.find (fn (g,_) => aconv f g) equations of
            NONE => collect todo (f::seen) result
          | SOME (_,(th,r)) => collect (find_terms is_const r @ todo)
                                      (f::seen) (th::result);
    val code = collect (find_terms is_const lhs) [] [];
  in cv_computeLib.cv_compute code lhs end;

(* Re-prove large byte-list decoding without an article containing one proof
   step per byte. A named RHS must resolve to an already checked definition. *)
fun decode_literal facts c =
  let
    val (l,r) = dest_eq c;
    val (f,value) = dest_comb l;
    val expected = ``cv_type$to_list (cv_type$to_word : cv -> word8)``;
    val _ = if aconv f expected then () else reject "not a byte decoding request";
    val decoded = literalDecodeLib.decode value;
    fun literal_definition th =
      null(hyp th) andalso is_eq (concl th) andalso
      aconv (lhs(concl th)) r andalso aconv (rhs(concl th)) (rhs(concl decoded));
  in if aconv (rhs(concl decoded)) r then decoded
     else case List.find literal_definition facts of
       SOME def => TRANS decoded (SYM (checked def))
     | NONE => reject "decoded bytes differ from the fixed literal"
  end;

(* EVAL requests are limited to the fixed vocabulary. Candidate definitions
   must supply their checked equations through the raw CV path above. *)
fun fixed_eval c =
  let
    val _ = if List.exists
      (fn tm => #Thy (dest_thy_const tm) = current_theory ())
      (find_terms is_const c) then reject "candidate constant in fixed EVAL request"
      else ();
  in EQT_ELIM (bossLib.EVAL c) end;

fun bool_taut c =
  let
    val (variables,body) = strip_forall c;
    fun propositional tm =
      if is_var tm then type_of tm = bool
      else if aconv tm T orelse aconv tm F then true
      else let val (f,args) = strip_comb tm
               val {Thy,Name,...} = dest_thy_const f
           in ((Thy = "min" andalso (Name = "=" orelse Name = "==>")) orelse
               (Thy = "bool" andalso
                List.exists (fn n => n = Name) ["/\\","\\/","~"])) andalso
              List.all propositional args end
           handle HOL_ERR _ => false;
    val _ = if propositional body then () else reject "not a propositional request";
  in GENL variables (tautLib.TAUT_PROVE body) end;

fun logical_compute c =
  EQT_ELIM (QCONV (SIMP_CONV bool_ss [boolTheory.FUN_EQ_THM]) c)
  handle HOL_ERR _ =>
    (bool_taut c handle HOL_ERR _ =>
      (fixed_eval c handle HOL_ERR _ => EQT_ELIM (cv_transLib.cv_eval c))
      | Fail _ => (fixed_eval c handle HOL_ERR _ => EQT_ELIM (cv_transLib.cv_eval c)));

(* Computation requests are re-proved by the local HOL kernel. An article
   cannot make the result trusted merely by labelling it an axiom. *)
fun resolve trusted proved (hs,c) =
  let val facts = trusted @ Net.listItems proved
  in case List.find (same_sequent (hs,c)) facts of
    SOME th => checked th
  | NONE =>
      if not (null hs) then reject "unresolved assumption"
      else let
        val th = case instance facts (hs,c) of
          SOME th => th
        | NONE => (decode_literal facts c
                   handle HOL_ERR _ => raw_compute facts c
                        | Fail _ => raw_compute facts c)
                 handle HOL_ERR _ =>
                   logical_compute c
                      | Fail _ =>
                   logical_compute c
      in if same_sequent (hs,c) th then checked th
         else reject "computation proved a different statement" end
  end
  handle cv_repLib.NeedsTranslation _ => reject "no checked computation for requested theorem";

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
    val proved = articleReaderLib.raw_read_article input (reader trusted);
  in case List.find (same_sequent ([],expected)) (Net.listItems proved) of
       NONE => reject "exact fixed certificate conclusion was not proved"
     | SOME th => checked th
  end;
end
