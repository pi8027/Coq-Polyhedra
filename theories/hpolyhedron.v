(* --------------------------------------------------------------------
 * Copyright (c) - 2017--2020 - Xavier Allamigeon <xavier.allamigeon at inria.fr>
 * Copyright (c) - 2017--2020 - Ricardo D. Katz <katz@cifasis-conicet.gov.ar>
 * Copyright (c) - 2019--2020 - Pierre-Yves Strub <pierre-yves@strub.nu>
 *
 * Distributed under the terms of the CeCILL-B-V1 license
 * -------------------------------------------------------------------- *)

(* -------------------------------------------------------------------- *)
From mathcomp Require Import all_ssreflect all_algebra finmap.
Require Import extra_misc inner_product vector_order extra_matrix row_submx.
Require Import simplex barycenter.

Import Order.Theory.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.
Import GRing.Theory Num.Theory.

Declare Scope poly_scope.
Delimit Scope poly_scope with PH.

(* -------------------------------------------------------------------- *)
Reserved Notation "'lrel' [ R ]_ n"
  (at level 8, format "'lrel' [ R ]_ n").

Reserved Notation "'lrel'"
  (at level 8).

Reserved Notation "'base_t' [ R , n ]"
  (at level 8, format "'base_t' [ R , n ]").

Reserved Notation "'base_t'"
  (at level 8).

Reserved Notation "[< A , b >]"
  (at level 8, format "[< A ,  b >]").

Reserved Notation "''hpoly[' R ]_ n"
  (at level 8, format "''hpoly[' R ]_ n").

Reserved Notation "''hpoly_' n"
  (at level 8, format "''hpoly_' n").

Reserved Notation "P .`c" (at level 2, format "P .`c").
Reserved Notation "P .`A" (at level 2, format "P .`A").
Reserved Notation "P .`b" (at level 2, format "P .`b").

(* -------------------------------------------------------------------- *)
Section Base.
Context {R : Type} (n : nat).

Variant base_elt_type : predArgType := BaseElt of ('cV[R]_n * R).

Coercion base_elt_val b := let: BaseElt b := b in b.

Canonical base_elt_subType := Eval hnf in [newType for base_elt_val].
End Base.

Notation "'lrel' [ R ]_ n" := (@base_elt_type R n).
Notation "'lrel'" := (lrel[_]_(_)).
Notation "'base_t' [ R , n ]" := {fset lrel[R]_n}.
Notation "'base_t'" := (base_t[_,_]).
Notation "[< A , b >]" := (BaseElt (A, b)).

(* -------------------------------------------------------------------- *)
Definition be_eqMixin (R : eqType) n :=
  Eval hnf in [eqMixin of lrel[R]_n by <:].
Canonical be_eqType (R : eqType) n:=
  Eval hnf in EqType lrel[R]_n  (be_eqMixin R n).
Definition be_choiceMixin (R : choiceType) n :=
  [choiceMixin of lrel[R]_n by <:].
Canonical be_choiceType (R : choiceType) n :=
  Eval hnf in ChoiceType lrel[R]_n (be_choiceMixin R n).
Definition be_countMixin (R : countType) n :=
  [countMixin of lrel[R]_n by <:].
Canonical be_countType (R : countType) n :=
  Eval hnf in CountType lrel[R]_n (be_countMixin R n).
Canonical be_subCountType (R : countType) n :=
  Eval hnf in [subCountType of lrel[R]_n].
Definition be_finMixin (R : finType) n :=
  [finMixin of lrel[R]_n by <:].
Canonical be_finType (R : finType) n :=
  Eval hnf in FinType lrel[R]_n (be_finMixin R n).
Canonical be_subFinType (R : finType) n :=
  Eval hnf in [subFinType of lrel[R]_n].

(* -------------------------------------------------------------------- *)
Section BaseTheory.
Context (R : Type) (n : nat).

Lemma beW (P : lrel[R]_n -> Prop) :
  (forall A b, P [<A, b>]) -> (forall b, P b).
Proof. by move=> ih [[]]. Qed.

Lemma beE (b : lrel[R]_n) : [<b.1, b.2>] = b.
Proof. by elim/beW: b. Qed.
End BaseTheory.

Lemma be_eqE (R : eqType) n (b1 b2 : lrel[R]_n) :
  (b1 == b2) = [&& b1.1 == b2.1 & b1.2 == b2.2].
Proof. by []. Qed.

Lemma be_eqP (R : eqType) n (b1 b2 : lrel[R]_n) :
  reflect (b1.1 = b2.1 /\ b1.2 = b2.2) (b1 == b2).
Proof.
rewrite be_eqE; apply: (iffP andP).
+ by case=> [/eqP-> /eqP->]. + by case=> -> ->.
Qed.

(* -------------------------------------------------------------------- *)
Section BaseEncoding.
Context {R : eqType} (n : nat).

Definition base_elt_to_col (v : lrel[R]_n) : 'cV[R]_(n+1) :=
  col_mx v.1 (const_mx v.2).

Definition col_to_base_elt (v : 'cV[R]_(n+1)) : lrel[R]_n :=
  [< usubmx v, dsubmx v 0 0 >].

Lemma base_elt_to_colK : cancel col_to_base_elt base_elt_to_col.
Proof.
move=> c; apply/colP=> i; rewrite mxE.
by case: splitP' => j -> /=; rewrite !mxE ?ord1.
Qed.

Lemma col_to_base_eltK : cancel base_elt_to_col col_to_base_elt.
Proof.
elim/beW=> A b; apply/eqP/be_eqP=> /=; split.
+ by apply/colP=> i; rewrite mxE col_mxEu.
+ by rewrite mxE col_mxEd mxE.
Qed.
End BaseEncoding.

(* -------------------------------------------------------------------- *)
Section BaseEncodingTheory.
Context {R : realFieldType} (n m : nat).

Lemma base_elt_to_colM (A : 'M[R]_(n, m)) (b : 'cV[R]_n) (x : 'cV[R]_n) :
  base_elt_to_col [< A^T *m x, '[b, x] >] = (row_mx A b)^T *m x.
Proof.
apply/colP=> i; rewrite ![in X in X = _]mxE /=; case: splitP'.
+ by move=> j ->; rewrite tr_row_mx mul_col_mx col_mxEu.
+ move=> j ->; rewrite ord1 tr_row_mx mul_col_mx col_mxEd.
  by rewrite mxE -vdot_def mxE eqxx mulr1n vdotC.
Qed.
End BaseEncodingTheory.

(* -------------------------------------------------------------------- *)
Section BaseZmod.
Context {R : zmodType} {n : nat}.

Implicit Types (b : lrel[R]_n).

Definition be0         := [< (0 : 'cV[R]_n), (0 : R) >].
Definition beadd b1 b2 := [< b1.1 + b2.1, b1.2 + b2.2 >].
Definition beopp b     := [< -b.1, -b.2 >].

Lemma be_zmod_mixin :
  [/\ associative beadd
    , commutative beadd
    , left_id be0 beadd
    & left_inverse be0 beopp beadd].
Proof. split.
+ by move=> b1 b2 b3; rewrite /beadd 2!addrA.
+ by move=> b1 b2; rewrite /beadd [b2.1 + _]addrC [b2.2 + _]addrC.
+ by move=> b; rewrite /beadd 2!add0r beE.
+ by move=> b; rewrite /beadd 2!addNr.
Qed.

Let beaddA  := let: And4 h _ _ _ := be_zmod_mixin in h.
Let beaddC  := let: And4 _ h _ _ := be_zmod_mixin in h.
Let beadd0r := let: And4 _ _ h _ := be_zmod_mixin in h.
Let beaddNr := let: And4 _ _ _ h := be_zmod_mixin in h.

Definition be_zmodMixin := ZmodMixin beaddA beaddC beadd0r beaddNr.
Canonical be_zmodType := Eval hnf in ZmodType lrel be_zmodMixin.

Lemma beaddE b1 b2 : b1 + b2 = [< b1.1 + b2.1, b1.2 + b2.2 >].
Proof. by []. Qed.

Lemma beoppE b : -b = [< -b.1, -b.2 >].
Proof. by []. Qed.
End BaseZmod.

(* -------------------------------------------------------------------- *)
Section BaseEltEncodingZmodMorph.
Context {R : zmodType} {n : nat}.

Lemma base_elt_to_col_is_additive : additive (@base_elt_to_col R n).
Proof.
move=> /= b1 b2; apply/colP=> i; rewrite !mxE.
by case: splitP'=> j _; rewrite !mxE.
Qed.

Canonical base_elt_to_col_additive := Additive base_elt_to_col_is_additive.
End BaseEltEncodingZmodMorph.

(* -------------------------------------------------------------------- *)
Section BaseLmod.
Context {R : ringType} {n : nat}.

Implicit Types (b : lrel[R]_n).

Definition bescale c b := [< c *: b.1, c * b.2 >].

Lemma be_lmod_mixin :
  [/\ forall c1 c2 b, bescale c1 (bescale c2 b) = bescale (c1 * c2) b
    , left_id 1 bescale
    , right_distributive bescale +%R
    & forall b, {morph bescale^~ b : x y / x + y}].
Proof. split.
+ by move=> c1 c2 b; rewrite /bescale scalerA mulrA.
+ by move=> b; rewrite /bescale scale1r mul1r beE.
+ by move=> c b1 b2; rewrite /bescale scalerDr !beaddE mulrDr.
+ by move=> b c1 c2; rewrite /bescale beaddE scalerDl mulrDl.
Qed.

Let bescaleA  := let: And4 h _ _ _ := be_lmod_mixin in h.
Let bescale1  := let: And4 _ h _ _ := be_lmod_mixin in h.
Let bescaleDr := let: And4 _ _ h _ := be_lmod_mixin in h.
Let bescaleDl := let: And4 _ _ _ h := be_lmod_mixin in h.

Definition be_lmodMixin := LmodMixin bescaleA bescale1 bescaleDr bescaleDl.
Canonical be_lmodType := Eval hnf in LmodType R lrel be_lmodMixin.

Lemma bescaleE c b : c *: b = [< c *: b.1, c * b.2 >].
Proof. by []. Qed.
End BaseLmod.

(* -------------------------------------------------------------------- *)
Section BaseEltEncodingLmodMorph.
Context {R : ringType} {n : nat}.

Lemma base_elt_to_col_is_scalable : scalable (@base_elt_to_col R n).
Proof.
move=> c b /=; apply/colP=> i; rewrite !mxE.
by case: splitP'=> j _; rewrite !mxE.
Qed.

Canonical base_elt_to_col_scalable := AddLinear base_elt_to_col_is_scalable.
End BaseEltEncodingLmodMorph.

(* -------------------------------------------------------------------- *)
Section BaseMorph.
Context {R : zmodType} {n : nat}.

Implicit Types (b : lrel[R]_n).

Lemma beadd_p1E b1 b2 : (b1 + b2).1 = b1.1 + b2.1.
Proof. by []. Qed.

Lemma beadd_p2E b1 b2 : (b1 + b2).2 = b1.2 + b2.2.
Proof. by []. Qed.
End BaseMorph.

(* -------------------------------------------------------------------- *)
Section BaseVect.
Context {R : fieldType} {n : nat}.

Fact be_vect_iso : Vector.axiom (n+1) lrel[R]_n.
  (* there should be a way to exploit the connection betwseen base_elt and 'cV[R]_n * R^o
   * for which there is a canonical vectType structure                                    *)
Proof.
pose f (e : lrel[R]_n) := (col_mx e.1 (e.2%:M))^T.
exists f.
- move => ???; by rewrite /f raddfD /= -add_col_mx linearD /= -scale_scalar_mx -scale_col_mx linearZ.
- pose g (x : 'rV_(n+1)) := [< (lsubmx x)^T, (rsubmx x) 0 0 >] : (lrel[R]_n).
  exists g; move => x.
  + apply/eqP/be_eqP; split; rewrite /f /=.
    * by rewrite tr_col_mx row_mxKl trmxK.
    * by rewrite tr_col_mx row_mxKr tr_scalar_mx /= mxE mulr1n.
  + apply/rowP => i; case: (splitP' i) => [i' ->| i' ->].
    * by rewrite /f mxE col_mxEu !mxE.
    * by rewrite /f mxE col_mxEd mxE [i']ord1_eq0 mulr1n /= mxE.
Qed.
Definition be_vectMixin := VectMixin be_vect_iso.
Canonical be_vectType := VectType R lrel[R]_n be_vectMixin.

Lemma base_vect_subset (I I' : base_t[R,n]) :
  (I `<=` I')%fset -> (<< I >> <= << I' >>)%VS.
Proof.
by move => ?; apply/sub_span/fsubsetP.
Qed.

Lemma span_fsetU (I J : base_t[R,n]) :
  (<< (I `|` J)%fset >> = << I >> + << J >>)%VS.
Proof.
rewrite -span_cat; apply/eq_span => x.
by rewrite inE mem_cat.
Qed.

Lemma span_fset1 (v : lrel[R]_n) :
  (<< [fset v]%fset >> = <[ v ]>)%VS.
Proof.
by rewrite -span_seq1; apply/eq_span => x; rewrite !inE.
Qed.

Lemma fst_lmorph : lmorphism (fst : lrel[R]_n -> 'cV_n).
by [].
Qed.

Definition befst := linfun (Linear fst_lmorph).

End BaseVect.

(* -------------------------------------------------------------------- *)
Section VectToFsFun.
Context {T : choiceType} {R : ringType}.

Definition frank (S : {fset T}) (v : S) : 'I_#|`S| :=
  cast_ord (esym (cardfE _)) (enum_rank v).

Lemma frankK (S : {fset T}) :
  cancel (fun i : 'I_#|`S| => [`fnthP i]%fset) (@frank S).
Proof.
move=> i; apply/(@cast_ord_inj _ _ (cardfE S))/eqP.
rewrite cast_ordKV -(inj_eq (enum_val_inj)) enum_rankK -(rwP eqP).
apply/val_eqP => /=; set j := cast_ord _ i.
rewrite /fnth (tnth_nth (val (enum_default j))) /= {1}enum_fsetE.
by rewrite (nth_map (enum_default j)) // -cardE -cardfE.
Qed.

Lemma fnthK (S : {fset T}) :
  cancel (@frank S) (fun i : 'I_#|`S| => [`fnthP i]%fset).
Proof.
move=> x; apply/val_eqP/eqP => /=; rewrite /fnth.
rewrite (tnth_nth (val x)) /= enum_fsetE /=.
by rewrite (nth_map x)? nth_enum_rank // -cardE.
Qed.

Lemma val_fnthK (S : {fset T}) (v : S) : fnth (frank v) = fsval v.
Proof. by have := fnthK v => /(congr1 val). Qed.

Lemma bij_frank (S : {fset T}) : bijective (@frank S).
Proof. exact: (Bijective (@fnthK _) (@frankK S)). Qed.

Definition vect_to_fsfun (I : {fset T}) (c : 'cV[R]_#|`I|) : {fsfun T ~> R} :=
  [fsfun v : I => c (frank v) 0].

Lemma finsupp_vect_to_fsfun (I : {fset T}) (c : 'cV[R]_#|`I|) :
  (finsupp (@vect_to_fsfun I c) `<=` I)%fset.
Proof.
apply/fsubsetP=> x; rewrite mem_finsupp fsfun_ffun.
by case: insubP => //=; rewrite eqxx.
Qed.
End VectToFsFun.

(* -------------------------------------------------------------------- *)
Section VectToFsFunTheory.
Context {T : choiceType} {R : realFieldType}.

Lemma conic_vect_to_fsfun (I : {fset T}) (c : 'cV[R]_#|`I|) :
  (0) <=m (c) -> conic (vect_to_fsfun c).
Proof.
move=> ge0_c; apply/conicwP => x; rewrite fsfun_ffun.
by case: insubP => //= i _ _; apply: gev0P.
Qed.

Lemma convex_vect_to_fsfun (I : {fset T}) (c : 'cV[R]_#|`I|) :
  (0) <=m (c) -> '[const_mx 1, c] = 1 -> convex (vect_to_fsfun c).
Proof.
move=> ge0_c Σc_eq_1; rewrite /convex conic_vect_to_fsfun //=.
rewrite (weightwE (finsupp_vect_to_fsfun _)) -(rwP eqP).
move: Σc_eq_1; rewrite vdotC vdotr_const_mx1 => <-.
rewrite (reindex (@frank _ _)) /=; last by apply/onW_bij/bij_frank.
apply: eq_bigr=> i _; rewrite fsfun_ffun insubT //=.
by move=> hin; rewrite fsetsubE.
Qed.
End VectToFsFunTheory.

(* -------------------------------------------------------------------- *)
Section Combine.
Context {R : realFieldType} {n : nat} (base : base_t[R,n]).

Implicit Types (w : {fsfun lrel[R]_n ~> R}).

Lemma combineb1E w : (finsupp w `<=` base)%fset ->
  (combine w).1 = \sum_(v : base) w (val v) *: (val v).1.
Proof.
move=> le_wb; rewrite (combinewE le_wb).
by apply (big_morph (fst \o val) beadd_p1E).
Qed.

Lemma combineb2E w : (finsupp w `<=` base)%fset ->
  (combine w).2 = \sum_(v : base) w (val v) * (val v).2.
Proof.
move=> le_wb; rewrite (combinewE le_wb).
by apply (big_morph (snd \o val) beadd_p2E). Qed.

Definition combinebE w (h : (finsupp w `<=` base)%fset) :=
  (@combineb1E w h, @combineb2E w h).
End Combine.

(* -------------------------------------------------------------------- *)
Module HPolyhedron.

Section Def.

Variable (R : realFieldType) (n : nat).

Record hpoly := HPoly {
  nb_ineq : nat ;
  _ : 'M[R]_(nb_ineq,n) ;
  _ : 'cV[R]_nb_ineq
}.

Definition mem_hpoly P : {pred 'cV[R]_n} :=
  let: HPoly _ A b := P in
  [pred x : 'cV_n | (A *m x) >=m b].
Coercion mem_hpoly : hpoly >-> pred_sort.

End Def.

Notation "''hpoly[' R ]_ n" := (hpoly R n).
Notation "''hpoly_' n" := (hpoly _ n).

Section Choice.

Variable R : realFieldType.
Variable n : nat.

Definition matrix_from_hpoly (P : 'hpoly[R]_n) :=
  let: HPoly _ A b := P in
    Tagged (fun m => 'M[R]_(m,n) * 'cV[R]_m)%type (A, b).

Definition hpoly_from_matrix (M : {m : nat & 'M[R]_(m,n) * 'cV[R]_m}%type) :=
  let: (A, b) := tagged M in
    HPoly A b.

Lemma matrix_from_hpolyK :
  cancel matrix_from_hpoly hpoly_from_matrix.
Proof.
by move => [m A b]; rewrite /matrix_from_hpoly /hpoly_from_matrix.
Qed.

Definition hpoly_eqMixin := CanEqMixin matrix_from_hpolyK.
Canonical hpoly_eqType := Eval hnf in EqType 'hpoly[R]_n hpoly_eqMixin.
Definition hpoly_choiceMixin := CanChoiceMixin matrix_from_hpolyK.
Canonical hpoly_choiceType := Eval hnf in ChoiceType 'hpoly[R]_n hpoly_choiceMixin.

End Choice.

Section PolyPred.

Context {R : realFieldType} {n : nat}.

Implicit Type (P : 'hpoly[R]_n).

Definition hpoly_c (P : 'hpoly[R]_n) : nat
  := let: HPoly c A b := P in c.

Definition hpoly_A (P : 'hpoly[R]_n) :'M_(hpoly_c P, _)
  := let: HPoly c A b := P in A.

Definition hpoly_b (P : 'hpoly[R]_n) :'cV_(hpoly_c P)
  := let: HPoly c A b := P in b.

Notation "P .`c" := (hpoly_c P).
Notation "P .`A" := (hpoly_A P).
Notation "P .`b" := (hpoly_b P).

Lemma in_hpolyE (P : 'hpoly[R]_n) x : (x \in P) = (P.`A *m x) >=m (P.`b).
Proof. by case: P. Qed.

Definition mk_hs (b : lrel[R]_n) : 'hpoly[R]_n := HPoly (b.1)^T (b.2)%:M.

Lemma in_hs b x : x \in (mk_hs b ) = ('[b.1,x] >= b.2).
Proof.
rewrite inE vdotC -vdot_def.
by apply/forallP/idP => [ /(_ 0) | H i]; rewrite ?[i]ord1_eq0 !mxE /= !mulr1n.
Qed.

Definition poly0 := mk_hs [<0,1>].

Lemma in_poly0 : poly0 =i pred0.
Proof.
by move => x; rewrite in_hs vdot0l inE ler10.
Qed.

Definition polyT : 'hpoly[R]_n := @HPoly _ _ 0 (const_mx 0) 0.

Lemma in_polyT : polyT =i predT.
Proof.
by move => x; rewrite !inE mul0mx lev_refl.
Qed.

Definition polyI P Q :=
  let: HPoly _ A b := P in
  let: HPoly _ A' b' := Q in
    HPoly (col_mx A A') (col_mx b b').

Lemma in_polyI P Q : (polyI P Q) =i [predI P & Q].
Proof.
move => x.
case: P => mP AP bP; case: Q => mQ AQ bQ.
by rewrite !inE mul_col_mx col_mx_lev.
Qed.

Definition bounded P c :=
  let: HPoly _ A b := P in
    Simplex.bounded A b c.

Definition opt_value P c :=
  let: HPoly _ A b := P in
    Simplex.opt_value A b c.

Definition poly_subset P Q :=
  let: HPoly _ A b := P in
  let: HPoly _ A' b' := Q in
    (~~ Simplex.feasible A b) ||
      [forall i, (Simplex.bounded A b (row i A')^T) && (Simplex.opt_value A b (row i A')^T >= b' i 0)].

(*Lemma poly_subsetP {P Q : 'hpoly[R]_n} :
  reflect {subset P <= Q} (poly_subset P Q).
Proof. (* RK *)
case: P => m A b; case: Q => m' A' b'.
apply: (iffP idP) => [/orP poly_subset_P_Q | subset_P_Q].
- case: poly_subset_P_Q => [empty_P | /forallP hs_incl x x_in_P].
  + move => x x_in_P.
    move: empty_P; apply/contraR => _.
    by apply/Simplex.feasibleP; exists x.
  + apply/forallP => i.
    move/andP: (hs_incl i) => [/Simplex.boundedP [_ opt_is_opt] ?].
    apply: (@le_trans _ _ (Simplex.opt_value A b (row i A')^T) _ _); first by done.
    by rewrite -row_vdot; apply: opt_is_opt.
- apply/orP.
  case: (boolP (Simplex.feasible A b)) => [feasible_P | _]; last by left.
  right.
  apply/forallP => i.
  suff bounded_P_row_i_A': Simplex.bounded A b (row i A')^T.
    apply/andP; split; first exact: bounded_P_row_i_A'.
    move/Simplex.boundedP: bounded_P_row_i_A' => [[x [/subset_P_Q  x_in_Q <-]] _].
    rewrite row_vdot.
    exact: ((forallP x_in_Q) i).
  apply/(Simplex.boundedP_lower_bound _ feasible_P).
  exists (b' i 0).
  move => x /subset_P_Q x_in_Q.
  rewrite row_vdot.
  exact: ((forallP x_in_Q) i).
Qed.*)

Lemma poly_subsetPn {P Q : 'hpoly[R]_n} :
  reflect (exists2 x, x \in P & x \notin Q) (~~ (poly_subset P Q)).
Proof. (* RK *)
case: P => m A b; case: Q => m' A' b'.
apply: (iffP idP) => [| [x] x_in_P not_in_Q]; last first.
- move: not_in_Q; apply/contra; rewrite /poly_subset.
  move/orP; case => [empty_P | /forallP hs_incl].
  + move: empty_P; apply/contraR => _.
    by apply/Simplex.feasibleP; exists x.
  + apply/forallP => i.
    move/andP: (hs_incl i) => [/Simplex.boundedP [_ opt_is_opt] ?].
    apply: (@le_trans _ _ (Simplex.opt_value A b (row i A')^T) _ _); first by done.
    by rewrite -row_vdot; apply: opt_is_opt.
- rewrite negb_or negbK negb_forall.
  move/andP => [feasible_P /existsP [i /nandP unbounded_or]].
  have unbounded_suff:
    ~~ Simplex.bounded A b (row i A')^T -> exists2 x : 'cV_n, (x \in HPoly A b) & (x \notin HPoly A' b').
  + rewrite -(Simplex.unbounded_is_not_bounded _ feasible_P) => /Simplex.unboundedP unbounded_P_row_i_A'.
    move: (unbounded_P_row_i_A' (b' i 0)) => [x [x_in_P ineq]].
    exists x; try by done.
    move: ineq; apply: contraL => x_in_Q.
    rewrite -leNgt row_vdot.
    exact: ((forallP x_in_Q) i).
  case: unbounded_or; first exact: unbounded_suff.
  case: (boolP (Simplex.bounded A b (row i A')^T)) => [? | ? _]; last by apply: unbounded_suff.
  rewrite -ltNge => ineq.
  exists (Simplex.opt_point A b (row i A')^T); first exact: Simplex.opt_point_is_feasible.
  move: ineq; apply: contraL => opt_point_in_Q.
  rewrite -leNgt /Simplex.opt_value row_vdot.
  exact: ((forallP opt_point_in_Q) i).
Qed.

Lemma poly_subsetP {P Q : 'hpoly[R]_n} :
  reflect {subset P <= Q} (poly_subset P Q).
Proof.
apply/(iffP idP) => [P_sub_Q x x_in_P | P_sub_Q].
- move: P_sub_Q; apply: contraTT => x_notin_Q.
  by apply/poly_subsetPn; exists x.
- by apply: contraT; move/poly_subsetPn => [x] /P_sub_Q ->.
Qed.

Lemma boundedP (P : 'hpoly[R]_n) c :
  reflect (exists2 x, (x \in P) & poly_subset P (mk_hs [<c, '[c,x]>])) (bounded P c).
Proof. (* RK *)
case: P => m A b.
apply/(equivP (Simplex.boundedP A b c) _);
  split => [[[x [? opt_value_eq]] opt_value_is_opt] | [x ? /poly_subsetP incl_hs]].
- exists x; first by done.
  apply/poly_subsetP => y y_in_P.
  rewrite in_hs opt_value_eq.
  by apply: opt_value_is_opt.
- have opt_value_eq: '[ c, x] = Simplex.opt_value A b c.
    apply: Simplex.opt_value_is_optimal; first by done.
    by move => y /incl_hs; rewrite in_hs.
  split.
  + by exists x.
  + move => y /incl_hs.
    by rewrite in_hs -opt_value_eq.
Qed.

Lemma boundedPn P c :
  ~~ (poly_subset P poly0) ->
    reflect (forall K, ~~ (poly_subset P (mk_hs [<c, K>]))) (~~ bounded P c).
Proof. (* RK *)
case: P => m A b non_empty_P.
have feasible_P: Simplex.feasible A b
  by move/poly_subsetPn: non_empty_P => [x ? _];
  apply/Simplex.feasibleP; exists x.
rewrite /bounded (Simplex.bounded_is_not_unbounded c feasible_P) negbK.
apply/(equivP (Simplex.unboundedP A b c) _);
  split => [unbounded_cond_point K | unbounded_cond_hs K].
- apply/poly_subsetPn.
  move: (unbounded_cond_point K) => [x [? val_x_sineq]].
  exists x; first by done.
  by rewrite in_hs -ltNge.
- move/poly_subsetPn: (unbounded_cond_hs K) => [x ? x_not_in_hs].
  exists x; split; first by done.
  by rewrite in_hs -ltNge in x_not_in_hs.
Qed.

Definition pointed P :=
  ~~ (poly_subset P poly0) ==>
  let: HPoly _ A _ := P in Simplex.pointed A.

Lemma pointedPn P :
  reflect (exists x, exists2 d, (d != 0) & (forall μ, x + μ *: d \in P)) (~~ pointed P).
Proof. (* RK *)
case: P => [m A b].
rewrite /pointed; apply/(iffP idP).
- rewrite negb_imply => /andP [/poly_subsetPn [x x_in _]].
  move/Simplex.pointedPn =>
  [d [d_neq0 /Simplex.feasible_dirP d_feas_dir /Simplex.feasible_dirP md_feas_dir]].
  exists x; exists d => //.
  move => μ; case: (lerP 0 μ) => [?|?].
  + apply/d_feas_dir => //; exists x => //.
  + rewrite -[d]opprK scalerN -scaleNr.
    apply/md_feas_dir => //.
    by rewrite oppr_ge0 ltW.
- move => [x [d d_neq0 sub]].
  have x_in : x \in HPoly A b by move/(_ 0): sub; rewrite scale0r addr0.
  have -> /=: ~~ poly_subset (HPoly A b) poly0 by apply/poly_subsetPn; exists x => //; rewrite in_poly0.
  apply/Simplex.pointedPn.
  by exists d; split => //; apply/(Simplex.feasible_dirP _ x_in) => [μ _];
     rewrite ?scalerN -?scaleNr; apply/sub.
Qed.

Lemma convexP2 (P : 'hpoly[R]_n) (v w : 'cV[R]_n) α :
  v \in P -> w \in P -> 0 <= α <= 1 -> (1-α) *: v + α *: w \in P.
Proof.
case: P => m A b.
rewrite !inE => vP wP.
case/andP => [gt0_a lt1_a]; rewrite mulmxDr -!scalemxAr.
rewrite -[b]scale1r -{1}[1](subrK α) scalerDl.
by rewrite lev_add // lev_wpscalar // subr_ge0.
Qed.

Definition poly_equiv P Q := (poly_subset P Q) && (poly_subset Q P).

Lemma poly_equivP {P Q : 'hpoly[R]_n} : reflect (P =i Q) (poly_equiv P Q).
Proof.
apply/(iffP andP) => [[/poly_subsetP P_le_Q /poly_subsetP Q_le_P] x | P_eq_Q ].
- apply/idP/idP; [exact: P_le_Q | exact: Q_le_P].
- by split; apply/poly_subsetP => x; rewrite P_eq_Q.
Qed.

Lemma poly_equiv_refl : reflexive poly_equiv.
Proof.
by move => P; apply/poly_equivP.
Qed.

Lemma poly_equiv_sym : symmetric poly_equiv.
Proof.
by move => P Q; apply: (sameP poly_equivP);
   apply: (iffP poly_equivP) => [H x | H x]; rewrite H.
Qed.

Lemma poly_equiv_trans : transitive poly_equiv.
Proof.
move => P' P P'' /poly_equivP P_eq_P' /poly_equivP P'_eq_P''.
by apply/poly_equivP => x; rewrite P_eq_P'.
Qed.

(* -------------------------------------------------------------------- *)
Section Farkas.
Variable (base : base_t[R,n]).

Let P := \big[polyI/polyT]_(b : base) (mk_hs (val b)).

Notation m := #|`base|.

Let A := \matrix_(i < m) ((fnth i).1)^T.
Let b :=    \col_(i < m) (fnth i).2.

Lemma fnth_baseE i : @fnth _ base i = [< col i A^T, b i 0 >].
Proof.
apply/eqP/be_eqP => /=; split.
* by apply/colP=> k; rewrite !mxE. * by rewrite mxE.
Qed.

Lemma combinemE w :
  combine (vect_to_fsfun w) = [< A^T *m w, '[b, w] >].
Proof.
rewrite (combinewE (finsupp_vect_to_fsfun _)).
pose h (i : 'I_m) := [`fnthP i]%fset.
rewrite (reindex h) /=; last first.
+ by apply/onW_bij/(Bijective (@frankK _ _) (@fnthK _ _)).
apply: (can_inj (@col_to_base_eltK _ _)) => /=.
rewrite base_elt_to_colM raddf_sum /= mulmx_sum_col.
apply: eq_bigr=> i _; rewrite linearZ /=.
rewrite /vect_to_fsfun fsfun_ffun insubT /=; first by apply: fnthP.
move=> hin; rewrite [hin](bool_irrelevance _ (fnthP i)) frankK.
rewrite tr_row_mx col_col_mx; apply/colP=> j.
rewrite /base_elt_to_col !fnth_baseE /=.
rewrite (_ : const_mx _ = col i b^T) //.
by apply/colP=> k; rewrite !mxE.
Qed.

Lemma memP : P =i HPoly A b.
Proof.
move=> x; have [hI h0] := (fun P1 P2 => in_polyI P1 P2 x, in_polyT x).
rewrite {hI h0}(big_morph (fun P => x \in P) hI h0).
rewrite !inE big_andE; apply/forall_inP/forallP => /= h.
+ move=> i; move/(_ [`fnthP i]%fset isT): h.
  rewrite inE /= !fnth_baseE /= -tr_row trmxK.
  by rewrite -row_mul row_cV -lev_scalar_mx.
+ move=> e _; rewrite inE /=; move/(_ (frank e)): h.
  have: fnth (frank e) = fsval [`fnthP (frank e)]%fset by [].
  rewrite {1}fnth_baseE fnthK => <- /=; rewrite lev_scalar_mx.
  by rewrite tr_col trmxK -row_mul row_cV.
Qed.

Lemma farkas (e : lrel) :
     ~~ (poly_subset P poly0)
  -> (poly_subset P (mk_hs e))
  -> exists2 w : {conic lrel ~> R},
         (finsupp w `<=` base)%fset
       & (combine w).1 = e.1 /\ (combine w).2 >= e.2.
Proof.
move=> nz_P /poly_subsetP le_Pe; case: (Simplex.simplexP A b e.1).
+ move=> d /(intro_existsT (Simplex.infeasibleP _ _)) /negP[].
  apply/Simplex.feasibleP; case/poly_subsetPn: nz_P => [x x_in_P _].
  by exists x; rewrite inE memP in x_in_P |- *.
+ move=> p /(intro_existsT (Simplex.unboundedP_cert _ _ _)).
  case/Simplex.unboundedP/(_ e.2) => [x [x_in_PAb ineq]].
  have /le_Pe: x \in P by rewrite memP inE.
  by rewrite in_hs => /(lt_le_trans ineq); rewrite ltxx.
+ case=> [x w] [x_feas w_feas csc]; move: w_feas.
  rewrite inE /= => /andP[/eqP w_feas1 w_pos].
  exists (mkConicFun (conic_vect_to_fsfun w_pos)).
  + by apply: finsupp_vect_to_fsfun.
  + rewrite combinemE /=; split => //.
    by rewrite -csc -in_hs le_Pe //= memP inE.
Qed.
End Farkas.
End PolyPred.

Section Lift.

Variable (R : realFieldType) (n k : nat).

Definition lift_poly (P : 'hpoly[R]_n) : 'hpoly[R]_(n+k) :=
  let: HPoly _ A b := P in
  HPoly (row_mx A 0) b.

Lemma lift_polyP (P : 'hpoly[R]_n) x :
  (x \in lift_poly P) = (usubmx x \in P).
Proof.
rewrite /lift_poly; case: P => m A b.
by rewrite !inE -{1}[x]vsubmxK mul_row_col mul0mx addr0.
Qed.

End Lift.

Module Import Exports.
Canonical hpoly_eqType.
Canonical hpoly_choiceType.
Notation "''hpoly[' R ]_ n" := (@hpoly R n) (at level 8).
Notation "''hpoly_' n" := ('hpoly[_]_n) (at level 8).
Notation "P .`c" := (hpoly_c P) (at level 2, format "P .`c").
Notation "P .`A" := (hpoly_A P) (at level 2, format "P .`A").
Notation "P .`b" := (hpoly_b P) (at level 2, format "P .`b").
End Exports.
End HPolyhedron.

Export HPolyhedron.Exports.
Coercion mem_hpoly := HPolyhedron.mem_hpoly.
