(*************************************************************************)
(* Coq-Polyhedra: formalizing convex polyhedra in Coq/SSReflect          *)
(*                                                                       *)
(* (c) Copyright 2019, Xavier Allamigeon (xavier.allamigeon at inria.fr) *)
(*                     Ricardo D. Katz (katz at cifasis-conicet.gov.ar)  *)
(*                     Vasileios Charisopoulos (vharisop at gmail.com)   *)
(* All rights reserved.                                                  *)
(* You may distribute this file under the terms of the CeCILL-B license  *)
(*************************************************************************)

From mathcomp Require Import all_ssreflect ssralg ssrnum zmodp matrix mxalgebra vector finmap.
Require Import extra_misc inner_product extra_matrix vector_order row_submx.
Require Import hpolyhedron polyhedron barycenter.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.
Local Open Scope poly_scope.
Import GRing.Theory Num.Theory.

Section PolyBase.

Variable (R : realFieldType) (n : nat).

Section FixedBase.

Definition has_base (base : base_t[R,n]) (P : 'poly[R]_n) & (phantom _ P):=
  (P `>` `[poly0]) ==>
    [exists I : {fsubset base}, P == 'P^=(base; I)].

Notation "'[' P 'has' '\base' base ']'" := (has_base base (Phantom 'poly[R]_n P)) : poly_scope.

Variable (base : base_t[R,n]).

Lemma has_baseP (P : 'poly[R]_n) :
  reflect ((P `>` `[poly0]) -> exists I : {fsubset base}, P = 'P^=(base; I)) [P has \base base].
Proof.
by apply/(iffP implyP) => [H /H /exists_eqP [I ->]| H /H [I ->]];
  [|apply/exists_eqP]; exists I.
Qed.

Inductive poly_base := PolyBase { pval :> 'poly[R]_n ; _ : [pval has \base base]}.
Canonical poly_base_subType := [subType for pval].
Definition poly_base_eqMixin := Eval hnf in [eqMixin of poly_base by <:].
Canonical poly_base_eqType := Eval hnf in EqType poly_base poly_base_eqMixin.
Definition poly_base_choiceMixin := Eval hnf in [choiceMixin of poly_base by <:].
Canonical poly_base_choiceType := Eval hnf in ChoiceType poly_base poly_base_choiceMixin.

Lemma poly_base_base (P : poly_base) : [pval P has \base base].
Proof.
(*exact: valP.*)
by case : P.
Qed.

Lemma poly0_baseP : [ `[poly0] has \base base].
Proof.
by rewrite /has_base poly_properxx.
Qed.
Canonical poly0_base := PolyBase poly0_baseP.

End FixedBase.

Notation "'[' P 'has' '\base' base ']'" := (has_base base (Phantom _ P)) : poly_scope.
Notation "'{poly'  base '}'" := (poly_base base) : poly_scope.
Definition poly_base_of base (x : {poly base}) & (phantom 'poly[R]_n x) : {poly base} := x.
Notation "P %:poly_base" := (poly_base_of (Phantom _ P)) (at level 0) : poly_scope.

Lemma polyEq_baseP base I :
  (I `<=` base)%fset -> [('P^=(base; I)) has \base base].
Proof.
move => Isub.
by apply/implyP => _; apply/exists_eqP => /=; exists (I %:fsub).
Qed.

Canonical polyEq_base base I (H : expose (I `<=` base)%fset) := PolyBase (polyEq_baseP H).

(*
Section Test.
Variable (base I : base_t[R,n]) (I' : {fsubset base}).
Hypothesis Isub : (I `<=` base)%fset.
Check ('P^=(base; I)%:poly_base) : {poly base}.
Check ('P^=(base; I')%:poly_base) : {poly base}.
End Test.
 *)

Variable base : base_t[R,n].

Variant poly_base_spec (P : {poly base}) : Prop :=
| PolyBase0 of (P = (`[poly0])%:poly_base) : poly_base_spec P
| PolyBaseN0 (I : {fsubset base}) of (P = 'P^=(base; I)%:poly_base /\ P `>` `[poly0]) : poly_base_spec P.

Lemma poly_baseP (P : {poly base}) : poly_base_spec P.
Proof.
case: (emptyP P) => [/val_inj -> | P_prop0]; first by constructor.
move/implyP/(_ P_prop0)/exists_eqP: (poly_base_base P) => [I ?].
constructor 2 with I.
split; [exact: val_inj | done].
Qed.

(*
Section Test.
Variable P Q : {poly base}.
Goal P = Q.
case/poly_baseP: P.
Abort.

End Test.
*)

Lemma poly_base_subset (P : {poly base}) :
  P `<=` 'P(base).
Proof.
case/poly_baseP : (P) => [->| I [-> _]];
  [ exact: poly0_subset | exact: polyEq_antimono0].
Qed.

Definition set_of_poly_base (P : {poly base}) : option {fsubset base} :=
  if emptyP (P : 'poly[R]_n) is NonEmpty H then
    let I := xchoose (existsP (implyP (poly_base_base P) H)) in
    Some I
  else
    None.

Definition set_of_poly_base_pinv (I : {fsubset base})  : option (poly_base base) :=
  let P := 'P^=(base; I)%:poly_base in
  if set_of_poly_base P == Some I then Some P else None.

Lemma set_of_poly_baseK :
  pcancel set_of_poly_base (obind set_of_poly_base_pinv).
Proof.
move => P.
rewrite /set_of_poly_base.
Admitted.
(*have eq: forall P : poly_base, P `>` (`[poly0]) -> P = '['P^=(base; (set_of_poly_base P))]%:poly_base.
- move => P; apply/val_inj => /=; apply/eqP.
  exact: (xchooseP (existsP (poly_base_base P))).
move => P; rewrite /set_of_poly_base_pinv.
case: ifP; last first.
- move/negbT/negP; by rewrite -eq.
- by move/eqP ->; rewrite -2!eq.
Qed.*)

Definition poly_base_countMixin := PcanCountMixin set_of_poly_baseK.
Canonical poly_base_countType := Eval hnf in CountType (poly_base base) poly_base_countMixin.
Definition poly_base_finMixin := PcanFinMixin set_of_poly_baseK.
Canonical poly_base_finType := Eval hnf in FinType (poly_base base) poly_base_finMixin.
Canonical poly_base_subFinType := [subFinType of (poly_base base)].

Lemma poly_of_baseP :
  ['P(base) has \base base].
Proof.
suff ->: 'P(base) = 'P^=(base; fset0)%:poly_base by exact: poly_base_base.
by rewrite /= polyEq0.
Qed.
Canonical poly_of_base_base := PolyBase (poly_of_baseP).

Lemma polyI_baseP (P Q : {poly base}) & (phantom _ P) & (phantom _ Q):
  [(P `&` Q) has \base base].
Proof.
Admitted.
Canonical polyI_base P Q := PolyBase (polyI_baseP (Phantom _ P) (Phantom _ Q)).

Lemma slice_baseP (e : base_elt) (P : {poly base}) :
  [(slice e P) has \base (e +|` base)].
Proof.
Admitted.
(*case/poly_baseP: P => [ | I _]; first by rewrite (quot_equivP slice0); exact: poly0_baseP.
apply/has_baseP => _.
by exists (slice_set I); rewrite -(quot_equivP slice_polyEq).*)

Canonical slice_base e P := PolyBase (slice_baseP e P).

Lemma argmin_baseP (P : {poly base}) c :
  [(argmin P c) has \base base].
Proof.
(* we first suppose that flat_prop holds, ie this is the situation in which
 * P (here quantified as Q) would play the role of the base *)
suff flat_prop: forall base0, bounded ('P(base0) : 'poly[R]_n) c -> [(argmin ('P(base0) : 'poly[R]_n) c) has \base base0].
- apply/has_baseP; rewrite -bounded_argminN0.
  case/poly_baseP : (P) => [->| I [-> _]]; first by rewrite bounded_poly0.
  rewrite /= (polyEq_flatten _) => bounded_PI.
  move/flat_prop/has_baseP: (bounded_PI); rewrite -bounded_argminN0.
  move => /(_ bounded_PI) => [[J] ->].
  by move: (polyEq_of_polyEq J)
    => [K] ->; exists K.
- (* now this is the classic proof of Schrijver *)
  move => base0 c_bounded.
  move: (dual_opt_sol c_bounded) => [w w_ge0 w_comb].
  apply/has_baseP; exists (finsupp w)%:fsub.
  move: (opt_point c_bounded) => [x x_in_P0 c_x_eq_opt_val].
  have: x \in `[hp (combine w)] : 'poly[R]_n.
  - by rewrite inE w_comb /=; apply/eqP.
  move/(compl_slack_cond w_ge0 x_in_P0) => x_in_P0I.
  have ->: c = (combine w).1 by rewrite w_comb.
  apply/dual_sol_argmin; try by done.
  by apply/proper0P; exists x.
Qed.
Canonical argmin_base (P : {poly base}) c := PolyBase (argmin_baseP P c).

Lemma affine_base : [affine << base >> has \base base].
Admitted.
Canonical affine_baseP := PolyBase affine_base.

End PolyBase.

Notation "'{poly'  base '}'" := (@poly_base _ _ base) : poly_scope.
Notation "P %:poly_base" := (poly_base_of (Phantom _ P)) (at level 0) : poly_scope.
Notation "'[' P 'has' '\base' base ']'" := (has_base base (Phantom _ P)) : poly_scope.

(*
Section Test.

Variable (R : realFieldType) (n : nat) (base : base_t[R,n]).

Variables (P Q : {poly base}) (Q' : 'poly[R]_n) (x : 'cV[R]_n).

Set Printing Coercions.

Check (P `&` Q : 'poly[R]_n).
Check (x \in P).

Goal P `<=` Q' -> forall x, x \in P -> x \in Q'.
move/poly_subsetP => H z z_in_P.
by move/H: z_in_P.
Qed.

Goal (P = Q' :> 'poly[R]_n) -> x \in P -> x \in Q'.
move <-.
done.
Qed.

Unset Printing Coercions.

End Test.
*)

Section Active.

Context {R : realFieldType} {n : nat} {base : base_t[R,n]}.

Fact active_key : unit. by []. Qed.

Definition active (P : {poly base}) := (* TODO: fix broken notation *)
  locked_with active_key ((\big[@fsetU _/fset0]_(I : {fsubset base} | (P `<=` 'P^=(base; I))) I)%:fsub).

Notation "'{eq'  P }" := (active P) : poly_scope.

(*
Section Test.
Variable (P : {poly base}).
Check {eq P}.
Goal {eq P} = fset0%:fsub :> {fsubset base}.
Set Printing Coercions.
apply/fsubset_inj => /=.
Abort.
Check 'P^=(base; {eq P}) : 'poly[R]_n.
Check 'P^=(base; {eq P})%:poly_base : {poly base}.
End Test.
 *)

Lemma repr_active (P : {poly base}) :
  P `>` (`[poly0]) -> P = ('P^=(base; {eq P}))%:poly_base.
Proof.
case/poly_baseP: (P) => [->|]; first by rewrite poly_properxx.
move => I [P_eq _] Pprop0; apply: val_inj => /=.
suff ->: 'P^=(base; {eq P}) =
  \polyI_(I : {fsubset base} | P `<=` 'P^=(base; I)) 'P^= (base; I) :> 'poly[R]_n.
- apply/poly_equivP/andP; split.
  + by apply/big_polyIsP.
  + rewrite P_eq; apply/big_poly_inf; exact: poly_subset_refl.
- rewrite polyEq_big_polyI /active; first by rewrite unlock_with.
  apply/pred0Pn; rewrite P_eq /=; exists I.
  exact: poly_subset_refl.
Qed.

Lemma mem_repr_active (P : {poly base}) x :
  (x \in P) -> (x \in ('P^=(base; {eq P}))%:poly_base).
Proof.
move => x_in_P.
have h: P `>` (`[poly0]) by apply/proper0P; exists x.
by rewrite [P]repr_active in x_in_P.
Qed.

Lemma activeP (P : {poly base}) (I : {fsubset base}) :
  (P `<=` 'P^=(base; I)) = (I `<=` {eq P})%fset.
Proof.
apply/idP/idP.
- by move => Psub; rewrite /active unlock_with; apply/bigfcup_sup.
- case: (emptyP P) => [-> _|]; first exact: poly0_subset.
  move/repr_active => {2}-> /=.
  exact: polyEq_antimono.
Qed.

Lemma repr_active_supset {P : {poly base}} :
  P `<=` 'P^=(base; {eq P}).
apply/poly_subsetP => x x_in_P.
have h: P `>` (`[poly0]) by apply/proper0P; exists x.
by rewrite [P]repr_active in x_in_P.
Qed.

Lemma active0 :
  {eq (`[poly0]%:poly_base : {poly base})} = base%:fsub.
Proof.
set A := {eq _}.
apply/val_inj/FSubset.untag_inj => /=.
apply/eqP; rewrite eqEfsubset; apply/andP; split; first exact: fsubset_subP.
- rewrite -activeP => /=; exact: poly0_subset.
Qed.

Lemma active_polyEq (I : {fsubset base}) :
  (I `<=` {eq 'P^=(base; I)%:poly_base})%fset.
Proof.
rewrite -activeP; exact: poly_subset_refl.
Qed.

Lemma in_active {P : {poly base}} {e} :
  (e \in ({eq P} : {fset _})) -> (P `<=` `[hp e]).
Proof.
move => h.
have e_in_base : ([fset e] `<=` base)%fset.
- rewrite fsub1set.
  by apply/(fsubsetP (valP {eq P})).
set se := [fset e]%:fsub%fset : {fsubset base}.
have: (se `<=` {eq P})%fset by  rewrite fsub1set.
rewrite -activeP polyEq1 => P_sub.
apply: (poly_subset_trans P_sub); exact: poly_subsetIr.
Qed.

Lemma in_activeP {P : {poly base}} {e} :
  e \in base -> (e \in ({eq P} : {fset _})) = (P `<=` `[hp e]).
Proof.
move => e_in_base.
apply/idP/idP; first exact: in_active.
set se := [fset e]%:fsub%fset : {fsubset base}.
move => P_sub.
suff: (se `<=` {eq P})%fset by  rewrite fsub1set.
rewrite -activeP polyEq1.
by apply/poly_subsetIP; split; try exact: poly_base_subset.
Qed.

Lemma poly_base_subset_eq (P Q : {poly base}) :
    (P `<=` Q) -> (({eq Q} : {fset _}) `<=` {eq P})%fset.
Proof.
case: (poly_baseP P) => [-> | ? [_ P_prop0]].
- rewrite active0 poly0_subset => _; exact: fsubset_subP.
- case: (poly_baseP Q) => [-> | ? [_ Q_prop0]].
  + rewrite -subset0N_proper in P_prop0.
    by move/negbTE : P_prop0 ->.
  move/repr_active: Q_prop0 => {1}->.
  by rewrite activeP.
Qed.

Lemma polyI_eq (P Q : {poly base}) :
  ({eq P} `|` {eq Q} `<=` {eq ((P `&` Q)%PH)%:poly_base})%fset.
Proof.
rewrite -activeP -polyEq_polyI.
by apply: polyISS; rewrite activeP.
Qed.

Lemma poly_base_proper (P Q : {poly base}) :
  ({eq Q} `<` {eq P})%fset -> P `<` Q.
Proof.
case: (poly_baseP Q) => [->| J [Q_eq Q_prop0]]; first by rewrite active0 fsubsetT_proper.
case: (poly_baseP P) => [->| I [P_eq P_prop0]]; first done.
rewrite {2}[Q]repr_active // => /fproperP [/fsubsetP eq_sub] [i i_in i_notin].
rewrite [P]repr_active //.
apply/andP; split; first exact: polyEq_antimono.
apply/poly_subsetPn.
move: i_notin; rewrite in_activeP.
- move/poly_subsetPn => [x x_in_Q x_notin].
  exists x; first by move/(poly_subsetP repr_active_supset): x_in_Q.
  move: x_notin; apply: contra => x_in; exact: (polyEq_eq x_in).
- move: i_in; apply/fsubsetP; exact: fsubset_subP.
Qed.

Lemma poly_base_proper_eq (P Q : {poly base}) :
  `[poly0] `<` P -> P `<` Q -> ({eq Q} `<` {eq P})%fset.
Proof.
move => P_prop0 P_prop_Q; rewrite fproperEneq.
have Q_prop0: Q `>` `[poly0] by apply/poly_proper_trans: P_prop_Q.
move/poly_properW/poly_base_subset_eq: (P_prop_Q) ->.
rewrite andbT; move: P_prop_Q; apply: contraTneq.
rewrite {2}[P]repr_active // {2}[Q]repr_active // /val_inj /= => ->.
by rewrite poly_properxx.
Qed.

Lemma active_affine :
  {eq (affine <<base>>)%:poly_base} = base%:fsub.
Proof.
Admitted.

End Active.

Notation "'{eq'  P }" := (active P) : poly_scope.

Section ActiveSlice.

Variable (R : realFieldType) (n : nat).

Lemma active_slice e (base : base_t[R,n]) (P : {poly base}) :
  ((e +|` {eq P}) `<=` {eq (slice e P)%:poly_base})%fset.
Proof.
rewrite -activeP -slice_polyEq.
case: (poly_baseP P) => [-> /= | ? [_ P_prop0] /=].
- rewrite {1}(slice0 _); exact: poly0_subset.
- move/repr_active: P_prop0 => {1}->.
  exact: poly_subset_refl.
Qed.

End ActiveSlice.

Module BaseQuotient.
Section BaseQuotient.

Variable (R : realFieldType) (n : nat).

Axiom poly_has_base :
  forall P, exists (x : { base : base_t[R,n] & {poly base}}),
    P == (tagged x) :> 'poly[R]_n.

Definition of_poly (P : 'poly[R]_n) :=
  xchoose (poly_has_base P).
Definition to_poly (x : { base : base_t[R,n] & {poly base} })
  := pval (tagged x).

Lemma of_polyK : cancel of_poly to_poly.
Proof.
move => P; rewrite /of_poly; symmetry; apply/eqP.
exact: (xchooseP (poly_has_base _)).
Qed.

Definition base_quot_class := QuotClass of_polyK.

Canonical base_quot := QuotType 'poly[R]_n base_quot_class.

Definition repr_base (P : 'poly[R]_n) := (tag (repr P)).
Definition repr_poly_base (P : 'poly[R]_n) : {poly (repr_base P)} := tagged (repr P).

Lemma repr_baseP P : [P has \base (repr_base P)].
Proof.
rewrite -{-1}[P]reprK unlock; exact: poly_base_base.
Qed.
Canonical poly_base_repr_baseP (P : 'poly[R]_n) := PolyBase (repr_baseP P).

End BaseQuotient.
Module Import Exports.
Canonical base_quot.
(*Canonical poly_base_repr_baseP.*)
End Exports.
End BaseQuotient.

Export BaseQuotient.Exports.

Notation "\repr_base P" := (BaseQuotient.repr_base P) (at level 40).
Notation "\repr P" := (BaseQuotient.repr_poly_base P) (at level 40).

Section BaseQuotientAux.

Variable (R : realFieldType) (n : nat).

Lemma reprK (P : 'poly[R]_n) : \repr P = P :> 'poly[R]_n.
Proof.
by rewrite -[P in RHS]reprK [in RHS]unlock.
Qed.

Lemma polybW (Pt : 'poly[R]_n -> Prop) :
  (forall (base : base_t[R,n]) (Q : {poly base}), Pt Q) -> (forall P : 'poly[R]_n, Pt P).
Proof.
by move => ? P; rewrite -[P]reprK.
Qed.

Lemma non_redundant_baseW (Pt : 'poly[R]_n -> Prop) :
  (forall (base : base_t[R,n]), non_redundant_base base -> Pt 'P(base)%:poly_base) -> (forall P : 'poly[R]_n, Pt P).
Proof.
Admitted.

End BaseQuotientAux.

Section PolyBaseFace.

Variable (R : realFieldType) (n : nat) (base : base_t[R,n]).

Definition pb_face_set (P : {poly base}) : {set {poly base}} :=
  [set Q : {poly base} | Q `<=` P].

Notation "\face_set P" := (pb_face_set P) (at level 40).

CoInductive face_spec (P : {poly base}) : {poly base} -> Prop :=
| EmptyFace : face_spec P (`[poly0])%:poly_base
| ArgMin c of (bounded P c) : face_spec P (argmin P c)%:poly_base.

Lemma faceP (P Q : {poly base}) :
  Q \in \face_set P -> face_spec P Q.
Proof.
case: (emptyP ('P(base) : 'poly[R]_n))
  => [base_eq0 | base_prop0].
- suff ->: (P = (`[poly0]%:poly_base)).
  + rewrite inE subset0_equiv => /eqP.
    move/val_inj ->; constructor.
    move: (poly_base_subset P); rewrite base_eq0 //=.
      by rewrite subset0_equiv => /eqP/val_inj.
- case: (poly_baseP Q) => [-> | ]; first constructor.
  move => I [Q_eq Q_prop0].
  rewrite inE; move => Q_sub_P.
  pose w : {conic base_elt ~> R} := (fconicu I).
  pose c := (combine w).1.
  have c_bounded : bounded ('P(base) : 'poly[R]_n) c.
  + apply: dual_sol_bounded => //; rewrite finsupp_fconicu; exact: fsubset_subP.
  have c_bounded_P : (bounded P c).
  + apply: (bounded_mono1 c_bounded); apply/andP; split;
      [ exact: (poly_proper_subset Q_prop0) | exact: poly_base_subset ].
  have c_argmin: argmin 'P(base) c = Q.
  + rewrite Q_eq in Q_prop0 *.
    rewrite dual_sol_argmin /=; rewrite ?/w ?finsupp_fconicu //.
    exact: fsubset_subP.
  suff <- : (argmin P c)%:poly_base = Q by constructor.
  apply: val_inj => /=. rewrite -c_argmin.
  apply/subset_argmin; first by done.
  apply/andP; split; [ by rewrite c_argmin | exact: poly_base_subset ].
Qed.

End PolyBaseFace.

Notation "\face_set P" := (pb_face_set P) (at level 40).

Section Face.
Variable (R : realFieldType) (n : nat).

Definition face_set (P : 'poly[R]_n) :=
  [fset pval x | x in \face_set (\repr P)]%fset.

Lemma face_set_mono (base : base_t[R,n]) (P : {poly base}) :
  face_set P = [fset pval x | x in \face_set P]%fset.
Proof.
suff H: forall base1 base2 (P1 : {poly base1}) (P2 : {poly base2}),
    P1 = P2 :> 'poly[R]_n ->
    ([fset pval x | x in \face_set P1] `<=` [fset pval x | x in \face_set P2])%fset.
- by apply/eqP; rewrite eqEfsubset; apply/andP; split; apply/H; rewrite reprK.
- move => base1 base2 P1 P2 eq_P12.
  apply/fsubsetP => F /imfsetP [F' /= F'_in ->].
  case/faceP : F'_in.
  + apply/imfsetP; exists (`[poly0]%:poly_base) => //=.
    rewrite inE; exact: poly0_subset.
  + move => c c_bounded.
    apply/imfsetP; exists ((argmin P2 c)%:poly_base) => /=.
    rewrite inE; exact: argmin_subset.
    by rewrite eq_P12.
Qed.

Lemma face_set_has_base (base : base_t[R,n]) (P : {poly base}) (Q : 'poly[R]_n) :
  Q \in face_set P -> [Q has \base base].
Proof.
rewrite face_set_mono => /imfsetP [{}Q _ ->].
(*exact: valP.*)
exact: poly_base_base.
Qed.

(*Canonical face_set_has_baseP (base : base_t[R,n]) (P : {poly base}) (Q : 'poly[R]_n) (H : expose (Q \in face_set P)) :=
  PolyBase (face_set_has_base H).

Parameter (base : base_t[R,n]) (P : {poly base}) (Q : 'poly[R]_n).
Hypothesis H : (Q \in face_set P).
Check (Q%:poly_base) : {poly base}.*)

Lemma face_setE (base : base_t[R,n]) (P : {poly base}) :
    (forall F : {poly base}, (pval F \in face_set P) = (F `<=` P))
    * (forall F : 'poly[R]_n, forall H : [F has \base base], (F \in face_set P) = (F `<=` P)).
Proof.
rewrite face_set_mono.
(*apply/imfsetP/idP => [[{}F H ->]| F_sub_P]; first by rewrite inE in H.
by exists F; rewrite ?inE.
Qed.*) Admitted.

Lemma face_set_self (P : 'poly[R]_n) : P \in (face_set P).
Proof.
elim/polybW: P => base P.
rewrite face_setE; exact: poly_subset_refl.
Qed.

(*
Lemma in_face_setP (base : base_t[R,n]) (F : 'poly[R]_n) (P : {poly base}) & (F \in face_set P) :
  F%:poly_base `<=` P.
Proof.
by rewrite -face_setE.
Qed.*)

Variant face_set_spec (base : base_t[R, n]) (P : {poly base}) : 'poly[R]_n -> Type :=
| FaceSetSpec (Q : {poly base}) of (Q `<=` P) : face_set_spec P Q.

Lemma face_setP (base : base_t[R, n]) (P : {poly base}) (Q : 'poly[R]_n) :
  (Q \in face_set P) -> @face_set_spec base P Q.
Proof.
move => Q_face_P.
have Q_eq : Q = (PolyBase (face_set_has_base Q_face_P)) by [].
move: (Q_face_P); rewrite Q_eq => Q_face_P'.
constructor; by rewrite face_setE in Q_face_P'.
Qed.

Lemma face_set_of_face (P Q : 'poly[R]_n) :
  Q \in face_set P -> face_set Q = [fset Q' in (face_set P) | (Q' `<=` Q)%PH]%fset.
Proof.
elim/polybW: P => base P.
case/face_setP => {}Q Q_sub_P.
apply/fsetP => Q'; apply/idP/idP.
- case/face_setP => {}Q' Q'_sub_Q.
  apply/imfsetP; exists (pval Q') => //.
  rewrite inE face_setE Q'_sub_Q andbT.
  exact: (poly_subset_trans Q'_sub_Q).
- rewrite mem_imfset => //= /andP[].
  case/face_setP => {}Q' _.
  by rewrite face_setE.
Qed.

Corollary subset_face_set (P Q : 'poly[R]_n) :
  Q \in face_set P -> (face_set Q `<=` face_set P)%fset.
Proof.
move/face_set_of_face ->; apply/fsubsetP => Q'.
by rewrite mem_imfset // => /andP[].
Qed.

Lemma face_set_subset (F : 'poly[R]_n) (P : 'poly[R]_n)  :
  F \in face_set P -> F `<=` P.
Proof.
elim/polybW: P => base P.
by case/face_setP => ?.
Qed.

Lemma face_set0 : face_set (`[poly0]) = [fset `[poly0]]%fset.
Proof.
apply/fsetP => P; rewrite !inE /=; apply/idP/idP.
- by move/face_set_subset; rewrite subset0_equiv.
- move/eqP ->; exact: face_set_self.
Qed.

Lemma face_set_polyI (P F F' : 'poly[R]_n) :
  F \in face_set P -> F' \in face_set P -> F `&` F' \in face_set P.
Proof.
elim/polybW: P => base P.
case/face_setP => {}F F_sub_P.
case/face_setP => {}F' F'_sub_P.
rewrite face_setE; first by rewrite (poly_subset_trans (poly_subsetIl _ _)).
(*apply/valP.*) (* TODO: valP doesn't work *)
exact: (valP (_ `&` _)%:poly_base).
Qed.

Lemma argmin_in_face_set (P : 'poly[R]_n) c :
  bounded P c -> argmin P c \in face_set P.
Proof.
elim/polybW: P => base P c_bounded.
have ->: (argmin P c) = (argmin P c)%:poly_base by [].
rewrite face_setE; exact: argmin_subset.
Qed.
End Face.

(*
Module PBRelint.
Section PBRelint.

Variable (R : realFieldType) (n : nat) (base : base_t[R,n]).

Implicit Type (P : {poly base}).

Definition relint_pt P :=
  let ceq := (base `\` {eq P})%fset in
  let S := [fset (xchoose (notin_active (valP e))) | e : ceq ]%fset in
  match @idP (S != fset0) with
  | ReflectT H => combine (fconvexu H)
  | _ => ppick P
  end.

Lemma mem_relint_pt P : (P `>` `[poly0]) -> relint_pt P \in P.
Admitted.

Lemma relint_pt_notin_eq P e :
  e \in base -> e \notin ({eq P} : {fset _}) -> relint_pt P \notin `[hp e].
Admitted.

Definition hull (P : {poly base}) := affine << {eq P} >>%VS.

Lemma subset_hull P : P `<=` hull P.
Admitted.



Lemma hullP (P : {poly base}) V :
  (P `>` `[poly0]) -> (P `<=` affine V) = (hull P `<=` affine V).
Proof.
move => P_prop0.
apply/idP/idP.
- move => P_sub.
  apply/poly_subsetP => x.
  x \in hull P >-> x = Ω + d avec d \in (<< eq P >>.1)^OC
  x \in affine V >-> x = Ω + d avec d \in (V.1)^OC
  V <= << eq P >> ?
  v \in V. e in << eq P >> iff forall x, x \in [hp e] ?


  let S := {eq P} : {fset _} in
  if P `>` `[poly0] then
    (<< ((fst : base_elt[R,n] -> 'cV[R]_n) @` S)%fset >>)^OC%VS
  else
    0%VS.

Lemma in_polyEqP' x  I :
  reflect ((forall e, e \in I -> x \in `[hp e]) /\ (forall e, e \in base -> e \notin I -> x \in `[hs e])) (x \in 'P^=(base; I)).
Admitted.

Lemma hull_relintP (P : {poly base}) d :
  (P `>` `[poly0]) ->
  reflect (exists2 α, α != 0 & relint_pt P + α *: d \in P)  (d \in hull P).
Proof.
move => P_prop0.
apply/(iffP idP).
- rewrite /hull ifT // => /orthv_spanP d_in_orth.
  pose x := relint_pt P.
  pose ceq := (base `\` {eq P})%fset.
  pose f : base_elt -> R := fun e => (e.2 - '[e.1,x])/'[e.1,d].
  pose gap_set := (f @` [fset e | e in ceq & '[e.1, d] < 0])%fset.
  pose α := min_seq gap_set 1.
  have α_gtr0 : α > 0.
  + rewrite min_seq_positive; last by right; rewrite ltr01.
    apply/allP => ? /imfsetP [i /= H ->].
    move: H; rewrite !inE /= => /andP [/andP [i_in_base i_notin_eq] ed_lt0].
    admit.
  exists α.
  + exact: lt0r_neq0.
  + move: (mem_relint_pt P_prop0); rewrite {2 4}[P]repr_active // => relint_pt_in_P.
    set y := _ + _.
    apply/in_polyEqP'; split => e.
    * move => e_in_eqP.
      rewrite inE vdotDr vdotZr d_in_orth ?mulr0 ?addr0.
      - admit.
      - by apply/imfsetP; exists e.
    * move => e_in_base e_notin_eqP.
      have e_in_ceq : e \in ceq by rewrite inE; apply/andP; split.
      case: (boolP ('[e.1, d] < 0)).
 Admitted.
End PBRelint.



End PBRelint.
*)

Section SpanActive.

Context {R : realFieldType} {n : nat}.

Implicit Types (base : base_t[R,n]).

Lemma in_span_active base (P : {poly base}) e :
  (e \in << {eq P} >>%VS) -> (P `<=` `[hp e]).
Proof.
move/coord_span ->.
apply/poly_subsetP => x x_in_P; rewrite inE; apply/eqP.
rewrite (big_morph (id1 := 0) (op1 := +%R) (fun x : base_elt[R,n] => x.1)) //.
rewrite (big_morph (id1 := 0) (op1 := +%R) (fun x : base_elt[R,n] => x.2)) //=.
rewrite vdot_sumDl; under eq_big do [| rewrite /= vdotZl].
apply/eq_bigr => i _; apply: congr1.
apply/eqP; rewrite -in_hp; move: x_in_P; apply/poly_subsetP/in_active.
by rewrite mem_nth ?size_tuple.
Qed.

Lemma in_span_activeP base (P : {poly base}) e :
  (P `>` `[poly0]) ->
  (P `<=` `[hp e]) = (e \in << {eq P} >>%VS).
Proof.
move => P_prop0; apply/idP/idP; last exact : in_span_active.
move: (erefl P); rewrite {2}[P]repr_active // => /(congr1 (@pval _ _ _)) /=.
rewrite polyEq_flatten => P_eq P_sub_hp.
move: (poly_subset_trans P_sub_hp (hp_subset_hs _)).
move: (P_prop0); rewrite P_eq; set S := {eq P}: {fset _}.
move/farkas => h /h {h} [w w_supp [e1_eq e2_le]].
suff finsupp_sub_eq: (finsupp w `<=` (S `|` -%R @` S))%fset.
- have comb_in_eqP: combine w \in << {eq P} >>%VS.
  * rewrite (combinewE finsupp_sub_eq).
    apply/memv_suml => i _; rewrite memvZ //.
    move: (valP i); rewrite inE; move/orP; case; try exact: memv_span.
      by move/imfsetP => [? /= ? ->]; rewrite memvN memv_span.
  suff <-: (combine w) = e by [].
  move/proper0P: P_prop0 => [x x_in_P].
  apply/(befst_inj (x := x)) => //.
  * by apply/poly_subsetP/in_span_active: x_in_P.
  * by move/poly_subsetP/(_ _ x_in_P): P_sub_hp.
- move: P_sub_hp; apply: contraTT.
  move/fsubsetPn => [e']; rewrite inE negb_or => e'_in /andP [e'_notin_S /negbTE e'_notin_mS].
  have {e'_notin_S e'_notin_mS} /poly_subsetPn [x x_in x_notin]: ~~ (P `<=` `[hp e']).
  + rewrite -in_activeP ?e'_notin_S //.
    by move/fsubsetP/(_ _ e'_in): w_supp; rewrite inE e'_notin_mS orbF.
  apply/poly_subsetPn; exists x => //.
  rewrite in_hp -e1_eq eq_sym; apply/ltr_neq.
  apply/(ler_lt_trans e2_le).
  rewrite !(combinebE w_supp) /= vdot_sumDl.
  apply/sumr_ltrP.
  + move => i; rewrite vdotZl ler_wpmul2l ?ge0_fconic //.
    rewrite -in_hs; move: x_in; apply/poly_subsetP.
    rewrite P_eq; apply/poly_base_subset_hs; exact: fsvalP.
  + have e'_in_baseEq : e' \in baseEq base S by apply/(fsubsetP w_supp).
    pose e'_idx := [` e'_in_baseEq]%fset.
    exists e'_idx. rewrite vdotZl ltr_pmul2l ?gt0_fconic //.
    rewrite -notin_hp //=.
    move: x_in; apply/poly_subsetP.
    by rewrite P_eq; apply/poly_base_subset_hs.
Qed.

Lemma span_activeS base (P : {poly base}) base' (Q : {poly base'}) :
  (P `>` `[poly0]) -> P `<=` Q -> (<< {eq Q} >> <= << {eq P} >>)%VS.
Proof.
move => P_prop0 P_sub_Q; apply/subvP => e /in_span_active.
rewrite -in_span_activeP //; exact: poly_subset_trans.
Qed.

Lemma span_activeE base (P : {poly base}) base' (Q : {poly base'}) :
  (P `>` `[poly0]) -> P = Q :> 'poly[R]_n -> (<< {eq P} >> = << {eq Q} >>)%VS.
Proof.
move => P_prop0 P_eq_Q.
by apply/subv_anti; apply/andP; split; apply/span_activeS; rewrite -?P_eq_Q ?poly_subset_refl.
Qed.

End SpanActive.

Section AffineHull.

Context {R : realFieldType} {n : nat}.

Implicit Type base : base_t[R,n].

Definition pb_hull base (P : {poly base}) :=
  if P `>` `[poly0] then
    affine << {eq P} >>%VS
  else
    `[poly0].

Notation "\hull P" := (pb_hull P) (at level 40).

Definition hull (P : 'poly[R]_n) := \hull \repr P.

Lemma hullE base (P : {poly base}) :
  hull P = \hull P.
Proof.
case: (emptyP P)  => [| P_propØ].
- rewrite /hull /pb_hull => ->.
  by rewrite ifF ?reprK ?poly_properxx.
- rewrite /hull /pb_hull reprK !ifT //=.
  suff ->: (<<{eq P}>> = <<{eq \repr P}>>)%VS by [].
  by apply/span_activeE; rewrite ?reprK.
Qed.

Lemma subset_hull P : P `<=` hull P.
Proof.
case: (emptyP P) => [->| ]; rewrite ?poly0_subset //.
elim/polybW : P => base P; rewrite hullE /pb_hull => P_prop0.

  by rewrite P_prop0; rewrite {1}[P]repr_active //= polyEq_affine poly_subsetIr.
Qed.

Lemma hull0 : hull (`[poly0] : 'poly[R]_n) = `[poly0].
by rewrite /hull /pb_hull reprK ifF ?poly_properxx.
Qed.

Lemma hullN0 P : (P `>` `[poly0]) = (hull P `>` `[poly0]).
Proof.
case/emptyP : (P) => [-> | P_prop0]; first by rewrite hull0 poly_properxx.
by symmetry; apply/(poly_proper_subset P_prop0)/subset_hull.
Qed.

Lemma hullN0_eq base (P : {poly base}) :
  (P `>` `[poly0]) -> hull P = affine << {eq P} >>.
Proof.
by rewrite hullE /pb_hull => ->.
Qed.

Lemma hullP P U :
  (P `<=` affine U) = (hull P `<=` affine U).
Proof.
case: (emptyP P) => [->|]; rewrite ?hull0 //.
move => P_prop0; apply/idP/idP; last by apply/poly_subset_trans; exact: subset_hull.
elim/polybW : P P_prop0 => base P P_prop0.
rewrite hullN0_eq // => P_sub_affU; apply: affineS.
apply/subvP => e; rewrite -in_span_activeP //.
by move/affineS1; apply/poly_subset_trans.
Qed.

Lemma hull_affine U :
  hull (affine U) = affine U.
Proof.
by apply/poly_subset_anti; rewrite ?subset_hull -?hullP ?poly_subset_refl.
Qed.

Lemma hullI (P : 'poly[R]_n) : hull (hull P) = hull P.
Admitted.

Lemma hullS : {homo hull : P Q / P `<=` Q}.
Proof.
move => P Q.
case: (emptyP Q) => [->|];
  first by rewrite subset0_equiv => /eqP ->; exact: poly_subset_refl.
elim/polybW : Q => base Q Q_prop0 P_sub_Q.
rewrite hullN0_eq // hullP hullI -hullP.
rewrite -hullN0_eq //; apply/(poly_subset_trans P_sub_Q); exact: subset_hull.
Qed.

End AffineHull.

Section Dimension.

Variable (R : realFieldType) (n : nat).

Definition pb_dim (base : base_t[R,n]) (P : {poly base}) :=
  if (P `>` `[poly0]) then
    (n - \dim << {eq P} >>).+1%N
  else 0%N.

Notation "\dim P" := (pb_dim P) (at level 10, P at level 8) : poly_scope.

Definition dim (P : 'poly[R]_n) := \dim (\repr P).

Lemma dimE (base : base_t[R,n]) (P : {poly base}) :
  dim P = \dim P.
Proof.
case: (emptyP P) => [| P_propØ].
- rewrite /dim /pb_dim => ->.
  by rewrite ifF ?reprK ?poly_properxx.
- rewrite /dim /pb_dim reprK !ifT //.
  by do 3![apply/congr1]; symmetry; apply/span_activeE; rewrite ?reprK.
Qed.

Lemma dim0 :
  (dim (`[poly0] : 'poly[R]_n) = 0%N)
  * (forall base, dim (`[poly0] %:poly_base : {poly base}) = 0%N).
Proof.
suff H: forall base, dim (`[poly0] %:poly_base : {poly base}) = 0%N.
- split => //.
  pose base0 := fset0 : base_t[R,n].
  have ->: `[poly0] = (`[poly0]%:poly_base : {poly base0}) by [].
  exact: H.
- by move => base; rewrite dimE /pb_dim ifF // poly_properxx.
Qed.

Lemma dimN0 (P : 'poly[R]_n) : (P `>` `[poly0]) = (dim P > 0)%N.
Proof.
case/emptyP : (P) => [-> | P_prop0]; first by rewrite dim0 ltnn.
by elim/polybW: P P_prop0 => base P P_prop0; rewrite dimE /pb_dim ifT.
Qed.

Lemma dimN0_eq (base : base_t[R,n]) (P : {poly base}) :
  (P `>` `[poly0]) -> dim P = (n - \dim << {eq P} >>).+1%N.
Proof.
by rewrite dimE /pb_dim => ->.
Qed.

Lemma dim_eq0 (P : 'poly[R]_n) :
  dim P = 0%N <-> P = `[poly0].
Proof.
split; last by move ->; rewrite dim0.
by apply/contra_eq; rewrite equiv0N_proper dimN0 lt0n.
Qed.

Lemma mk_affine_prop0 (U : {vspace 'cV[R]_n}) (Ω : 'cV[R]_n) :
  `[affine U & Ω] `>` `[poly0].
Proof.
by apply/proper0P; exists Ω; rewrite in_mk_affine addrN mem0v.
Qed.

Lemma dim_affine (U : {vspace 'cV[R]_n}) Ω :
  (dim (`[affine U & Ω]) = (\dim U).+1)%N.
Proof.
move: (mk_affine_prop0 U Ω).
rewrite /mk_affine.
set V := (X in affine X).
set base := [fset e in ((vbasis V) : seq _)]%fset : {fset base_elt[R,n]}.
have eq: V = << base >>%VS.
- move: (vbasisP V) => /andP [/eqP <- _].
  apply/subv_anti/andP; split; apply/sub_span;
  by move => ?; rewrite inE.
rewrite eq => prop0; rewrite dimN0_eq ?active_affine //=.
by rewrite -eq dim_mk_affine_fun dim_orthv subKn ?dim_cVn.
Qed.

Variant dim_spec : 'poly[R]_n -> nat -> Prop :=
| DimEmpty : dim_spec (`[poly0]) 0%N
| DimNonEmpty (base : base_t[R,n]) (P : {poly base}) of (P `>` `[poly0]) : dim_spec P (n-\dim <<{eq P}>>).+1.

Lemma dimP P : dim_spec P (dim P).
Admitted.

Lemma dim_hull (P : 'poly[R]_n) :
  dim P = dim (hull P).
Proof.
case/dimP: P => [| base P P_prop0]; first by rewrite hull0 dim0.
have hull_prop0: (hull P) `>` `[poly0] by apply/(poly_proper_subset P_prop0); exact: subset_hull.
rewrite hullN0_eq // in hull_prop0 *.
have ->: affine << {eq P} >> = (affine << {eq P} >>)%:poly_base by [].
by rewrite dimN0_eq //= active_affine.
Qed.

Lemma dimS : {homo dim : P Q / (P `<=` Q) >-> (P <= Q)%N}.
Proof.
move => P Q.
case/dimP: P => [| base P P_prop0]; rewrite ?dim0 //.
case/dimP: Q => [| base' Q Q_prop0];
  first by move/(poly_proper_subset P_prop0); rewrite ?poly_properxx.
by rewrite ltnS => P_sub_Q; apply/leq_sub2l/dimvS/span_activeS.
Qed.

Lemma subn_inj (p q r : nat) : (p <= r)%N -> (q <= r)%N -> (r - p == r - q)%N = (p == q).
Proof.
move => p_le_r q_le_r; apply/eqP/idP; last by move/eqP => ->.
move/(congr1 (addn^~ p)); rewrite subnK // addnC.
move/(congr1 (addn^~ q)); rewrite -addnA subnK // addnC.
by move/addIn => ->.
Qed.

Lemma dim_le (base : base_t[R,n]) (P : {poly base}) :
  P `>` (`[poly0]) -> (\dim << {eq P} >> <= n)%N.
Proof.
move => /proper0P [x x_in_P].
have f_linear : lmorphism (fun (v : base_elt[R,n]) => v.1) by done.
pose f := Linear f_linear.
pose linfun_f := linfun f.
have /limg_dim_eq <-: (<<{eq P}>> :&: lker linfun_f)%VS = 0%VS.
- apply/eqP; rewrite -subv0.
  apply/subvP => e; rewrite memv_cap memv_ker memv0 => /andP [e_in /eqP f_e_eq0].
  have e1_eq0 : e.1 = 0 by rewrite lfunE in f_e_eq0.
  apply/be_eqP => /=; split; first done.
  move/(poly_subsetP repr_active_supset): x_in_P.
  rewrite polyEq_affine in_polyI => /andP [_ /in_affine/(_ _ e_in)].
  by rewrite in_hp e1_eq0 vdot0l => /eqP.
- apply/(leq_trans (n := \dim fullv)); first by apply/dimvS/subvf.
  by rewrite dimvf /Vector.dim /= muln1.
Qed.

Lemma face_dim_leqif_eq (P Q : 'poly[R]_n) :
  (P \in face_set Q) -> (dim P <= dim Q ?= iff (P == Q))%N.
Proof.
move => P_face_Q; split; first by apply/dimS; exact: face_set_subset.
apply/eqP/eqP => [| -> //].
case/dimP: Q P_face_Q => [_ /dim_eq0 //| base Q Q_prop0].
case/face_setP => {}P P_sub_Q.
case: (emptyP P) => [->| P_prop0]; rewrite ?dim0 //.
rewrite dimN0_eq // => /eqP; rewrite eqSS subn_inj ?dim_le // => /eqP dim_eq.
suff: (<< {eq P} >> = << {eq Q} >>)%VS.
- by rewrite {2}[P]repr_active ?{2}[Q]repr_active //= ?polyEq_affine => ->.
- apply/eqP; rewrite eq_sym eqEdim {}dim_eq leqnn andbT.
  by apply/span_activeS.
Qed.

Lemma face_proper_ltn_dim (P Q : 'poly[R]_n) :
  P \in face_set Q -> P != Q -> (dim P < dim Q)%N.
Proof.
move => P_face_Q.
by move/face_dim_leqif_eq/ltn_leqif: (P_face_Q) ->.
Qed.

(*
Lemma hull_pt (x : 'cV[R]_n) :
  hull (`[pt x]) = (`[pt x]) :> 'poly[R]_n.
Admitted.
 *)

Lemma dim_pt (x : 'cV[R]_n) :
  dim (`[pt x]) = 1%N.
Proof.
(* this proof would be easier if `[pt x] was defined as an affine subspace *)
by rewrite dim_affine dimv0.
Qed.

Lemma dim_ptP (P : 'poly[R]_n) :
  reflect (exists x, P = `[pt x]) (dim P == 1%N).
Proof.
apply/(iffP eqP) => [ dim1| [? ->]]; last exact: dim_pt.
have P_prop0: (P `>` `[poly0]) by rewrite dimN0 dim1.
move/proper0P: (P_prop0) => [x x_in_P].
exists x; apply/poly_subset_anti; rewrite ?pt_subset //.
elim/polybW : P P_prop0 x_in_P dim1 => base P P_prop0.
move/(poly_subsetP (subset_hull _)) => x_in_hullP dim1.
apply/(poly_subset_trans (subset_hull _)).
rewrite !hullN0_eq // in x_in_hullP *.
apply/poly_subsetP => y.
move: dim1; rewrite dim_hull hullN0_eq //.
by rewrite (affine_orth x_in_hullP) dim_affine => /succn_inj/eqP; rewrite dimv_eq0 => /eqP ->.
Qed.

Lemma dim_line (Ω d : 'cV[R]_n) :
  d != 0 -> dim (`[line d & Ω] ) = 2%N.
Proof.
suff eq : `[line d & Ω] = `[affine <[d]> & Ω ].
- by rewrite eq dim_affine dim_vline => ->.
- apply/poly_eqP => x; apply/in_lineP/in_mk_affineP => [[μ ->] | [y /vlineP [μ ->]]].
  + by exists (μ *: d); rewrite ?memvZ ?memv_line.
  + by exists μ.
Qed.

Lemma hull_conv (V : {fset 'cV[R]_n}) Ω :
  Ω \in V -> hull (conv V) = `[affine << [fset (v - Ω) | v in V]%fset >>%VS & Ω].
Proof.
set P := conv V.
move => Ω_in_V.
have : Ω \in (hull P)
  by apply/(poly_subsetP (subset_hull _))/in_conv.
have : P `>` `[poly0] by admit.
elim/polybW : P => base P P_prop0.
Admitted.

End Dimension.

Section Facet.

Context {R : realFieldType} {n : nat} (base : base_t[R,n]).
Hypothesis non_redundant : non_redundant_base base.

Let P := 'P(base)%:poly_base.
Hypothesis P_prop0 : P `>` `[poly0].

Lemma activeU1 (e : base_elt) & (e \in base) :
  {eq 'P^=(base; [fset e])%:poly_base } = ({eq P} `|` [fset e])%fset%:fsub.
Proof.
case: (boolP (e \in ({eq P} : base_t))).
- move => e_in_eqP.
  have ->: 'P^= (base; [fset e])%:poly_base = 'P(base)%:poly_base.
  + apply/val_inj => /=; rewrite polyEq1; apply/polyIidPl.
    by apply/in_active.
  apply/fsubset_inj => /=.
  by move: e_in_eqP; rewrite -fsub1set => /fsetUidPl ->.
- set I := ({eq P} `|` [fset e])%fset %:fsub.
  move => e_notin_eq; apply/fsubset_inj/eqP; rewrite eqEfsubset.
  apply/andP; split; last first.
  + apply/fsubUsetP; split; last exact: active_polyEq.
    apply/poly_base_subset_eq => /=; exact: polyEq_antimono0.
  + apply/fsubset_fsubsetP => i i_in_eq; apply: contraLR.
    rewrite 2!inE negb_or => /andP [i_notin_eqP i_neq_e].
    apply/(contra in_active)/poly_subsetPn.
    move/non_redundant_baseP/(_ _ H)/poly_subsetPn: non_redundant => [z z_in_P' z_notin_e].
    move: i_notin_eqP; rewrite in_activeP //.
    move/poly_subsetPn => [y y_in_P y_notin_i].
    have y_in_e : y \in `[hs e] by apply/(poly_subsetP _ _ y_in_P)/poly_base_subset_hs.
    move: (hp_itv y_in_e z_notin_e) => [α α01]; rewrite {y_in_e}.
    set x := _ + _ => x_in_e; exists x.
    * rewrite /= polyEq1 inE.
      rewrite x_in_e andbT.
      apply/in_poly_of_baseP => j.
      case: (j =P e) => [-> _| /eqP j_neq_e j_in_base].
      - move: x x_in_e; apply/poly_subsetP; exact: hp_subset_hs.
      - have y_in_P' : y \in 'P(base `\ e)
          by move: y_in_P; apply/poly_subsetP/poly_of_base_antimono; exact: fsubD1set.
        have: x \in 'P(base `\ e) by apply/convexP2 => //; exact: ltW_le.
        apply/poly_subsetP/poly_base_subset_hs.
        by rewrite !inE j_neq_e.
    * move: y_notin_i; apply/contraNN/hp_extremeL => //.
      - by move: y_in_P; apply/poly_subsetP/poly_base_subset_hs.
      - move: z_in_P'; apply/poly_subsetP/poly_base_subset_hs.
        by rewrite !inE i_neq_e.
Qed.

Lemma facet_proper (i : base_elt) & (i \in base) :
  i \notin ({eq P} : {fset _}) -> 'P^=(base; [fset i])%:poly_base `<` P.
Proof.
move => i_notin_eqP.
rewrite poly_properEneq; apply/andP; split.
- by rewrite /= -polyEq0; apply: polyEq_antimono.
- move: i_notin_eqP; apply: contraNneq => /val_inj <-.
  rewrite -fsub1set; exact: active_polyEq.
Qed.

Lemma facet_proper0 (i : base_elt) & (i \in base) : (* A LOT IN COMMON WITH activeU1 *)
  i \notin ({eq P} : {fset _}) -> 'P^=(base; [fset i])%:poly_base `>` `[poly0].
Proof.
move => i_notin_eqP.
move/non_redundant_baseP/(_ _ H)/poly_subsetPn: non_redundant => [y y_in_P' y_notin_i].
move/proper0P: (P_prop0) => [x x_in_P].
have x_in_i : x \in `[hs i] by move: x_in_P; apply/poly_subsetP/poly_base_subset_hs.
move: (hp_itv x_in_i y_notin_i) => [α α01].
set z := _ + _ => z_in_i; apply/proper0P; exists z.
rewrite /= polyEq1 inE z_in_i andbT.
apply/in_poly_of_baseP => j.
case: (j =P i) => [-> _| /eqP j_neq_i j_in_base].
- move: z z_in_i; apply/poly_subsetP; exact: hp_subset_hs.
- have x_in_P' : x \in 'P(base `\ i)
    by move: x_in_P; apply/poly_subsetP/poly_of_base_antimono; exact: fsubD1set.
  have: z \in 'P(base `\ i) by apply/convexP2 => //; exact: ltW_le.
  by apply/poly_subsetP/poly_base_subset_hs; rewrite !inE j_neq_i.
Qed.

Lemma poly_proper_neq (Q Q' : 'poly[R]_n) : Q `<` Q' -> Q != Q'.
Proof.
by rewrite poly_properEneq => /andP[].
Qed.

Lemma poly_dim_facet (i : base_elt) & (i \in base) :
  i \notin ({eq P} : {fset _}) -> dim P = (dim 'P^=(base; [fset i])%:poly_base).+1%N.
Proof.
set S := 'P^=(_; _)%:poly_base.
move => i_notin_eqP.
move/(facet_proper H): (i_notin_eqP) => S_prop_P.
have i_not_in_affP: i \notin << {eq P} >>%VS.
- move: S_prop_P; apply: contraTN => i_in_affP.
  rewrite [P]repr_active //= 2!polyEq_affine.
  have /(polyIS 'P(base)) sub: affine <<{eq P}>> `<=` affine <<[fset i]%fset>>.
  + apply/poly_subsetP => x /in_affine/(_ _ i_in_affP).
    by rewrite affine_span big_fset1 /=.
  apply/negP; move/(poly_subset_proper sub).
  by rewrite poly_properxx.
rewrite !dimN0_eq ?facet_proper0 //; apply: congr1.
rewrite -subnSK; last first.
- suff: (dim P > 1)%N by rewrite dimN0_eq // ltnS subn_gt0.
  apply/(leq_ltn_trans _ (face_proper_ltn_dim (P := S) _ _)).
  + by rewrite -dimN0 facet_proper0.
  + rewrite face_setE; exact: poly_properW.
  + exact: poly_proper_neq.
- do 2![apply: congr1].
  rewrite activeU1 // span_fsetU /= dimv_disjoint_sum.
  + rewrite -addn1; apply: congr1.
    rewrite span_fset1 dim_vline.
    suff ->: (i != 0) by [].
    move: i_not_in_affP; apply: contraNneq => ->.
    exact: mem0v.
  + apply/eqP; rewrite -subv0 span_fset1.
    apply/subvP => x /memv_capP [h1 /vlineP [μ x_eq]].
    rewrite {}x_eq in h1 *.
    case: (μ =P 0) => [-> | /eqP μN0].
    * by rewrite scale0r memv0.
    * suff: i \in <<{eq P}>>%VS by move/negP : i_not_in_affP.
      move/(memvZ μ^-1) : h1.
      by rewrite scalerA mulVf // scale1r.
Qed.

End Facet.

Section Pointed.

Context {R : realFieldType} {n : nat}.

Lemma face_pointed (P : 'poly[R]_n) :
  pointed P -> forall Q, Q \in face_set P -> pointed Q.
Proof.
move => P_pointed Q.
by move/face_set_subset/pointedS/(_ P_pointed).
Qed.

Lemma pointed_facet (P : 'poly[R]_n) :
  P `>` (`[poly0]) -> pointed P -> exists2 F, F \in face_set P & dim P = (dim F).+1.
Proof.
elim/non_redundant_baseW: P => base non_redundant.
set P := 'P(base)%:poly_base => P_prop0 P_pointed.
case: (leqP (dim P) 1%N) => [dimP_le1 | dimP_gt1].
- rewrite dimN0 in P_prop0.
  have ->: dim P = 1%N by apply/anti_leq/andP; split.
  exists (pval ((`[poly0]%:poly_base) : {poly base})).
  + by rewrite face_setE poly0_subset.
  + by rewrite dim0.
- suff: ({eq P} `<` base)%fset.
  + move/fproperP => [_ [i i_base i_notin_eqP]].
    set F := 'P^=(base; [fset i]%fset)%:poly_base.
    exists (pval F); last exact: poly_dim_facet.
    by rewrite face_setE poly_properW ?facet_proper.
  + move: P_pointed; apply: contraLR; rewrite fsubset_properT negbK => /eqP eqP_eq_base.
    have dim_base: (\dim << base >> < n)%N.
    * move: eqP_eq_base => /(congr1 (fun (x : {fsubset _}) => (x : {fset _}))) /= <-.
      by move: dimP_gt1; rewrite dimN0_eq // ltnS subn_gt0.
    pose base' := vbasis <<base>>.
    pose f0 : 'cV[R]_n -> 'cV[R]_(\dim << base>>%VS) :=
      fun x => (\col_i '[((vbasis <<base>>)`_i).1, x]).
    have f0_linear : lmorphism f0. split;
    by move => ??; apply/colP => ?; rewrite !mxE ?vdotBr ?vdotZr.
    pose f := linfun (Linear f0_linear).
    move: (limg_ker_dim f (fullv : {vspace 'cV[R]_n})).
    rewrite capfv dimvf /Vector.dim /= muln1.
    move/dimvS: (subvf (limg f)); rewrite dimvf /Vector.dim /= muln1.
    move/leq_ltn_trans/(_ dim_base) => dim_imf.
    move/(congr1 (subn^~ (\dim (limg f))%N)).
    rewrite -addnBA // subnn addn0 => dim_lker_eq.
    have {dim_lker_eq} {dim_imf}: (\dim (lker f) != 0)%N by rewrite dim_lker_eq -lt0n subn_gt0.
    rewrite dimv_eq0 => kerf_neq0; pose c := vpick (lker f).
    have c_neq0 : c != 0 by rewrite /c vpick0.
    move: (memv_pick (lker f)); rewrite memv_ker -/c !lfunE /f0 /= => /eqP/col0P eq0.
    have e_c_eq0 : forall e, e \in base -> '[e.1, c] = 0.
    * move => e /memv_span/coord_vbasis ->.
      rewrite (@big_morph _ _ (fun e : base_elt[R,n] => e.1) 0 +%R) //.
      rewrite vdot_sumDl; apply: big1 => i _; rewrite vdotZl.
      move/(_ i): eq0; rewrite mxE  => ->; by rewrite mulr0.
    apply/pointedPn; exists (ppick P); exists c => //.
    apply/big_polyIsP => e _; rewrite line_subset_hs.
    apply/eqP/e_c_eq0; first exact: valP.
    move: (ppickP P_prop0); apply/poly_subsetP/poly_base_subset_hs; exact: valP.
Qed.

Lemma pointed_vertex (P : 'poly[R]_n) :
  P `>` (`[poly0]) -> pointed P -> exists2 S, S \in face_set P & dim S = 1%N.
Proof.
pose H k := forall (P : 'poly[R]_n), dim P = k -> P `>` (`[poly0]) -> pointed P -> exists2 S, S \in face_set P & dim S = 1%N.
suff: forall k, H k by move/(_ (dim P) P (erefl _)).
elim => [ Q | k IHk Q ].
- by rewrite dimN0 => ->.
- case: (posnP k) => [-> dimQ1 _ _ | k_gt0 dimQ _ Q_pointed].
  + by exists Q; rewrite ?face_set_self.
  + have : Q `>` `[poly0] by rewrite dimN0 dimQ.
    move/pointed_facet/(_ _); move/(_ Q_pointed) => [F F_face].
    rewrite dimQ; move/succn_inj/esym => dimF.
    move: (IHk _ dimF); rewrite dimN0 dimF.
    move/(_ k_gt0 (face_pointed Q_pointed F_face)) => [S S_face dimS1].
    exists S => //; move: S_face; apply/fsubsetP; exact: subset_face_set.
Qed.

End Pointed.

Section Graded.

Context {R : realFieldType} {n : nat}.

Lemma graded (P Q : 'poly[R]_n) :
  pointed P -> Q \in face_set P -> Q != P -> ~~ [exists S : face_set P, (Q `<` (val S) `<` P)] -> dim P = (dim Q).+1%N.
Proof.
elim/non_redundant_baseW : P => base non_redundant.
set P := 'P(base)%:poly_base => P_pointed.
case/face_setP => {}Q Q_sub_P Q_neq_P.
have {Q_sub_P Q_neq_P} Q_prop_P : Q `<` P by rewrite poly_properEneq Q_sub_P.
have P_prop0 : P `>` `[poly0] by apply/(poly_subset_proper (poly0_subset Q)).
case: (emptyP Q) => [ -> P_cover0 | Q_prop0 P_cover_Q ].
- suff: (dim P <= 1)%N.
  + move: P_prop0; rewrite dim0 dimN0 => ??.
    by apply/anti_leq/andP; split.
  + move: P_cover0; apply: contraR.
    rewrite -ltnNge => dim_lt1.
    move: (pointed_vertex P_prop0 P_pointed) => [S S_face dimS1].
    apply/existsP; exists [`S_face]%fset; apply/andP; split.
    * by rewrite dimN0 dimS1.
    * rewrite poly_properEneq /=.
      case/face_setP: S_face dimS1 => {}S -> /= dimS1.
      by move: dim_lt1; apply: contraTneq => /= <-; rewrite dimS1.
- have eqQ_prop_eqP : ({eq P} `<` {eq Q})%fset by apply/poly_base_proper_eq.
  move/fproperP: (eqQ_prop_eqP) => [_ [i i_in_eqQ i_notin_eqP]].
  have i_in_base: (i \in base) by move: (i) i_in_eqQ; apply/fsubsetP: (valP {eq Q}).
  set S := 'P^=(base; [fset i])%:poly_base.
  have Q_sub_S : Q `<=` S by rewrite activeP fsub1set.
  have S_prop_P : S `<` P.
  + rewrite poly_properEneq; apply/andP; split.
    * by rewrite /= -polyEq0; apply: polyEq_antimono.
    * move: i_notin_eqP; apply: contraNneq => /val_inj <-.
      rewrite -fsub1set; exact: active_polyEq.
  have -> : Q = S.
  + have S_face: (pval S \in (face_set P)) by rewrite face_setE poly_properW.
    move/existsPn/(_ [` S_face]%fset): P_cover_Q.
    rewrite S_prop_P andbT.
    by apply: contraNeq; rewrite poly_properEneq => ->; rewrite andbT.
  exact: poly_dim_facet.
Qed.

End Graded.

Section Atomic.

Context {R : realFieldType} {n : nat}.

Definition vertex_set (P : 'poly[R]_n) :=
  [fset ppick F | F in face_set P & dim F == 1%N]%fset.

Lemma in_vertex_setP (P : 'poly[R]_n) x :
  (x \in vertex_set P) = (`[pt x] \in face_set P).
Proof.
apply/imfsetP/idP => /=.
- move => [F] /andP [F_face /dim_ptP [y F_eq]].
  move: F_face; rewrite {}F_eq => ?.
  by rewrite ppick_pt => ->.
- move => pt_x_face.
  exists (`[pt x]); rewrite ?ppick_pt //=.
  by apply/andP; split; rewrite ?dim_pt.
Qed.

Lemma vertex_setS (P Q : 'poly[R]_n) :
  P \in face_set Q -> (vertex_set P `<=` vertex_set Q)%fset.
Proof.
move => P_face.
apply/fsubsetP => x; rewrite 2!in_vertex_setP.
apply/fsubsetP; exact: subset_face_set.
Qed.

Lemma vertex_set_subset P : {subset (vertex_set P) <= P}.
Proof.
move => x; rewrite in_vertex_setP => /face_set_subset.
by rewrite pt_subset.
Qed.

Lemma opt_vertex (P : 'poly[R]_n) c :
  pointed P -> bounded P c -> exists2 x, x \in vertex_set P & x \in argmin P c.
Proof.
move => P_pointed c_bounded.
set F := argmin P c.
have F_face : F \in face_set P by apply/argmin_in_face_set.
have F_pointed : pointed F by apply/(pointedS (argmin_subset _ _)).
have F_prop0 : F `>` `[poly0] by rewrite -bounded_argminN0.
move/(pointed_vertex F_prop0): F_pointed => [F' F'_face /eqP/dim_ptP [x F'_eq]].
(* TODO: to be improved! Define a pick_vertex function instead? *)
rewrite {}F'_eq in F'_face.
exists x.
- rewrite in_vertex_setP; move: F'_face; apply/fsubsetP.
  exact: subset_face_set.
- by move/face_set_subset: F'_face; rewrite pt_subset.
Qed.

Lemma atomic (P : 'poly[R]_n) :
  (P `>` `[poly0]) -> compact P -> P = conv (vertex_set P).
Proof.
move => P_prop0 P_compact.
apply/poly_eqP => x; apply/idP/idP.
- apply/contraTT.
  move/separation => [e x_notin_hs conv_sub].
  have e_bounded : bounded P e.1 by apply/compactP.
  move/compact_pointed/opt_vertex: P_compact.
  move/(_ _ e_bounded) => [y].
  move/in_conv/(poly_subsetP conv_sub) => y_in_e y_in_argmin.
  move: x_notin_hs; apply/contraNN => x_in_P.
  rewrite !in_hs in y_in_e *; apply/(ler_trans y_in_e).
  by apply/(argmin_lower_bound y_in_argmin).
- apply/poly_subsetP/polyhedron.convexP.
  exact: vertex_set_subset.
Qed.

End Atomic.

(*
(* THE MATERIAL BELOW HAS NOT BEEN YET UPDATED *)

Section Relint.

Variable (R : realFieldType) (n : nat).

Lemma poly_base_extremeL m (base : m.-base[R,n]) (P : {poly base}) x y α :
  x \in ('P(base) : 'poly[R]_n) -> y \in ('P(base) : 'poly[R]_n) ->
    0 <= α < 1 -> (1-α) *: x + α *: y \in P -> x \in P.
Proof.
case: base P x y α => [A b] P x y α.
set z : 'cV_n := _ + _.
move => x_in_P y_in_P α_01 z_in_P.
have P_prop0 : (P `>` `[poly0]) by apply/proper0P; exists z.
rewrite [P]repr_active // in z_in_P *.
apply/in_polyEqP; split; last done.
move => j j_in_eq.
apply: (hp_extremeL (y := y) (α := α)); try by done.
- rewrite in_poly_of_base in x_in_P.
  rewrite // !inE /= row_vdot.
  by move/forallP: x_in_P.
- rewrite in_poly_of_base in y_in_P.
  rewrite // !inE /= row_vdot.
  by move/forallP: y_in_P.
by move/polyEq_eq/(_ j_in_eq) : z_in_P.
Qed.

Lemma poly_base_extremeR m (base : m.-base[R,n]) (P : {poly base}) x y α :
  x \in ('P(base) : 'poly[R]_n) -> y \in ('P(base) : 'poly[R]_n) ->
    0 < α <= 1 -> (1-α) *: x + α *: y \in P -> y \in P.
Proof.
case: base P x y α => [A b] P x y α.
set z : 'cV_n := _ + _.
move => x_in_P y_in_P α_01 z_in_P.
have P_prop0 : (P `>` `[poly0]) by apply/proper0P; exists z.
rewrite [P]repr_active // in z_in_P *.
apply/in_polyEqP; split; last done.
move => j j_in_eq.
apply: (hp_extremeR (x := x) (α := α)); try by done.
- rewrite in_poly_of_base in x_in_P.
  rewrite // !inE /= row_vdot.
  by move/forallP: x_in_P.
- rewrite in_poly_of_base in y_in_P.
  rewrite // !inE /= row_vdot.
  by move/forallP: y_in_P.
by move/polyEq_eq/(_ j_in_eq) : z_in_P.
Qed.

Definition relint m (base : m.-base[R,n]) (P : {poly base}) :=
  [predI P & [pred x | [forall Q : {poly base}, (Q `<` P) ==> (x \notin Q)]]].

Lemma in_relintP m (base : m.-base) (P : {poly base}) x :
  reflect (x \in P /\ (forall Q : {poly base}, (Q `<` P) -> x \notin Q)) (x \in relint P).
Admitted.

Lemma notin_relintP m (base : m.-base) (P Q : {poly base}) x :
  Q `<` P -> x \in Q -> x \notin relint P.
Admitted.

Lemma relint_subset m (base : m.-base) (P : {poly base}) :
  {subset (relint P) <= P}.
Admitted.

Lemma relint_activeP m (base : m.-base) (P : {poly base}) x :
  reflect (x \in P /\ (forall k, k \notin {eq P} -> x \notin (nth_hp base k : 'poly[R]_n))) (x \in relint P).
Proof.
Admitted.

Lemma relint_open_convexL m (base : m.-base) (P : {poly base}) x y α :
  x \in P -> y \in relint P -> 0 < α <= 1 -> (1-α) *: x + α *: y \in relint P.
Proof.
set z : 'cV_n := _ + _.
move => x_in_P y_in_relint α_01.
have y_in_P: y \in P by rewrite relint_subset.
apply/in_relintP; split.
have : z \in (conv ([fset x; y]%fset) : 'poly[R]_n).
- apply/in_segmP; exists α; [by apply/lt_leW | done].
  by apply/poly_subsetP/convexP2.
- move => Q Q_prop_P.
  move/in_relintP: (y_in_relint) => [_ /(_ _ Q_prop_P)].
  apply: contra.
  have Q_face : Q \in face_set P by rewrite inE poly_properW.
  move/faceP : Q_face => [Q_eq0 | c c_bounded].
  + by rewrite /= inE in Q_eq0.
  + rewrite /= argmin_polyI // inE => /andP [_ z_in_hp].
    rewrite inE y_in_P /=.
    apply: (hp_extremeR (x := x) (α := α)); try done.
    * move: (x) x_in_P; apply/poly_subsetP.
      exact: opt_value_lower_bound.
    * move: (y) y_in_P; apply/poly_subsetP.
      exact: opt_value_lower_bound.
Qed.

Lemma relint_open_convexR m (base : m.-base) (P : {poly base}) x y α :
  x \in relint P -> y \in P -> 0 <= α < 1 -> (1-α) *: x + α *: y \in relint P.
Proof.
set z : 'cV_n := _ + _.
move => x_in_relint y_in_P α_01.
have x_in_P: x \in P by rewrite relint_subset.
apply/in_relintP; split.
have : z \in (conv ([fset x; y]%fset) : 'poly[R]_n).
- apply/in_segmP; exists α; [by apply/ltW_le | done].
  by apply/poly_subsetP/convexP2.
- move => Q Q_prop_P.
  move/in_relintP: (x_in_relint) => [_ /(_ _ Q_prop_P)].
  apply: contra.
  have Q_face : Q \in face_set P by rewrite inE poly_properW.
  move/faceP : Q_face => [Q_eq0 | c c_bounded].
  + by rewrite /= inE in Q_eq0.
  + rewrite /= argmin_polyI // inE => /andP [_ z_in_hp].
    rewrite inE x_in_P /=.
    apply: (hp_extremeL (y := y) (α := α)); try done.
    * move: (x) x_in_P; apply/poly_subsetP.
      exact: opt_value_lower_bound.
    * move: (y) y_in_P; apply/poly_subsetP.
      exact: opt_value_lower_bound.
Qed.

End Relint.

Section AffineHull.

Variable (R : realFieldType) (n : nat).

Definition hull (m : nat) (base : m.-base[R,n]) (P : {poly base}) :=
  kermx (row_submx base.1 {eq P})^T.

(*
Lemma in_hullP (m : nat) (A : 'M[R]_(m,n)) (b : 'cV[R]_m) (P : {poly 'P(A,b)}) (d : 'cV[R]_n) :
  reflect (forall j, j \in {eq P} -> (A *m d) j 0 = 0) (d^T <= hull P)%MS.
Proof.
apply: (equivP sub_kermxP); rewrite -trmx_mul -{1}[0]trmx0; split.
- by move/trmx_inj; rewrite -row_submx_mul => /row_submx_col0P.
- by move => ?; apply/congr1; rewrite -row_submx_mul; apply/row_submx_col0P.
Qed.
 *)

Definition Sdim (m : nat) (base : m.-base[R,n]) (P : {poly base}) :=
  if (P == (`[poly0]) :> 'poly[R]_n) then 0%N else ((\rank (hull P)).+1).

(*
Fact relint_key : unit. Proof. by []. Qed.
Definition relint_pt base (P : {poly base}) : 'cV[R]_n := locked_with relint_key 0.

Lemma relint_pt_in_poly base (P : {poly base}) : relint_pt P \in P.
Admitted.

Lemma relint_pt_ineq (m : nat) (A : 'M[R]_(m,n)) (b : 'cV[R]_m) (P : {poly 'P(A,b)}) i :
  i \notin {eq P} -> relint_pt P \notin (`[hp (row i A)^T & b i 0] : 'poly[R]_n).
Admitted.

Lemma hull_relintP base (P : {poly base}) d :
  reflect (exists eps, eps > 0 /\ relint_pt P + eps *: d \in P)
                             ((d^T <= hull P)%MS).
Admitted.

Lemma hullP base (P : {poly base}) d :
   reflect (exists x y, [/\ x \in P, y \in P & ((x-y)^T :=: d^T)%MS])
                              (d^T <= hull P)%MS.
Admitted.
 *)

(* TO BE FIXED : why do we need extra parenthesis for `[pt x] ? *)
Lemma Sdim1P (m : nat) (base : m.-base) (P : {poly base}) :
  reflect (exists x, (P = (`[pt x]) :> 'poly[R]_n)) (Sdim P == 1%N).
Admitted.

Lemma relint_non_empty (m : nat) (base : m.-base) (P : {poly base}) :
  reflect (exists x, x \in relint P) (Sdim P > 1)%N.
Admitted.

Lemma Sdim_homo (m : nat) (base : m.-base) :
  {homo (Sdim (base := base)) : x y / (x `<=` y) >-> (x <= y)%N }.
Admitted.

Lemma dim_homo_proper (m : nat) (base : m.-base) (P Q : {poly base}) :
  P `<` Q -> (Sdim P < Sdim Q)%N.
Admitted.

End AffineHull.

Section Vertex.

Variable (R : realFieldType) (n : nat) (m : nat) (base : m.-base[R,n]).

Definition fvertex := [set F : {poly base} | (Sdim F == 0)%N].

Definition vertex :=
  ((fun (F : {poly base}) => pick_point F) @` fvertex)%fset.

CoInductive fvertex_spec : {poly base} -> 'cV[R]_n -> Prop :=
| FVertex x (H : has_base base (`[pt x])) : fvertex_spec (PolyBase H) x.

Notation "'`[' 'pt'  x  ']%:poly_base'" := (@PolyBase _ _ _ _ (`[pt x]) _).

Lemma fvertexP (F : {poly base}) :
  F \in fvertex -> fvertex_spec F (pick_point F).
Admitted.

Lemma fvertex_baseP (F : {poly base}) :
  reflect (exists2 x, (x \in vertex) & F = (`[pt x]) :> 'poly[R]_n) (F \in fvertex).
Admitted.

(*Lemma dim_vertex x : (x \in vertex_base) ->
  Sdim (`[pt x]%:poly_base) = 0%N.
Admitted.*)

Definition fvertex_set (P : {poly base}) := [set F in fvertex | F `<=` P].
Definition vertex_set (P : {poly base}) := [fset x in vertex | x \in P]%fset.

Lemma mink (P : {poly base}) :
  P = conv (vertex_set P) :> 'poly[R]_n.
Admitted.

Lemma vertex_set_mono (P Q : {poly base}) :
  ((P `<=` Q) = (vertex_set P `<=` vertex_set Q)%fset)
* ((P `<` Q) = (vertex_set P `<` vertex_set Q)%fset).
Admitted.

Lemma vertex_set_subset (P : {poly base}) :
  {subset (vertex_set P) <= P}.
Admitted.

End Vertex.

Notation "x '%:pt'" := (pick_point x) (at level 0).

Section VertexFigure.

Variable (R : realFieldType) (n : nat).
Variable (m : nat) (A : 'M[R]_(m,n)) (b : 'cV[R]_m).

Variable (c : 'cV[R]_n) (d : R).
Variable (v : {poly (A,b)}).
Hypothesis v_vtx : (v \in fvertex (A,b)).
Hypothesis c_v : '[c, v%:pt] < d.

Section SliceFace.

Variable P : {poly (A,b)}.
Hypothesis P_prop : v `<` P.
Hypothesis c_sep : forall w, w \in fvertex_set P -> w != v -> '[c, w%:pt] > d.

(*Fact other_vtx : exists2 w, (w \in vertex_set P) & '[c,w] > d.
Proof.
move: P_prop; rewrite vertex_set_mono => /fproperP [_] [w w_in /= w_neq_v].
rewrite vertex_set1 inE in w_neq_v.
by exists w; try exact: c_sep.
Qed.
*)

Lemma foo x y : '[c,x] < d < '[c, y] ->
                exists2 α, (0 < α < 1) & '[c, (1-α) *: x + α *: y] = d.
Admitted.

(*Lemma slice_face_proper0 : slice c d P `>` `[poly0].
Proof.
move: other_vtx => [w w_in c_w].
have [x x_in c_x] : exists2 x, (x \in (conv [fset v; w]%fset : 'poly[R]_n)) & '[c,x] = d.
- move/andP: (conj c_v c_w) => /foo [α α_0_1].
  set x : 'cV_n := (X in '[c,X] = d) => c_x; exists x; last done.
  admit.
apply/proper0P; exists x; rewrite inE; apply/andP; split; last by rewrite c_x.
move: x_in; apply/poly_subsetP; apply: convexP2;
  [ exact: pt_proper | exact: vertex_set_subset ].
Admitted.*)

Lemma active_slice_eq : slice_set {eq P} = {eq (slice c d P) %:poly_base}.
Proof.
apply/eqP; rewrite eqEsubset; apply/andP; split; first exact: active_slice.
apply/subsetP => i; case: (split1P i) => [_ | k].
- by rewrite inE in_set1.
- rewrite in_active nth_hp_slice => slice_sub.
  apply/setU1P; right; apply: mem_imset; move: slice_sub; apply: contraTT => k_notin_eqP.
  suff [y y_relint c_y]: exists2 y, y \in relint P & '[c,y] = d.
  + move/in_relintP : y_relint => [y_in_P].
    pose Q := ('P^=(A, b; (k |: {eq P})))%:poly_base.
    have Q_prop_P : Q `<` P.
    * admit.
    move/(_ _ Q_prop_P) => y_notin_Q.
    apply/poly_subsetPn; exists y; rewrite //=.
    by rewrite inE; apply/andP; split; rewrite ?c_y.
    Admitted.
(*
  [y /in_relintP [y_in_P /(_ _ k_notin_eqP) H] c_y]
  + apply/poly_subsetPn; exists y; rewrite //=.
    by rewrite inE; apply/andP; split; rewrite ?c_y.
  + have /relint_non_empty [x x_in] : (dim P > 0)%N.
      by move/dim_homo_proper: P_prop; rewrite dim_vertex.
    case: (ltrgtP '[c,x] d) => [c_x | c_x | ? ]; last by exists x.
    - move: other_vtx => [w w_in c_w].
      move/andP : (conj c_x c_w) => /foo [α α_0_1].
      set y : 'cV_n := (X in '[c,X] = d) => c_y; exists y; last done.
      apply: relint_open_convexR;
        [ done | exact: vertex_set_subset | exact: ltW_lt ].
    - move/andP : (conj c_v c_x) => /foo [α α_0_1].
      set y : 'cV_n := (X in '[c,X] = d) => c_y; exists y; last done.
      apply: relint_open_convexL;
        [ by move/pt_proper : P_prop | done | exact: lt_ltW ].
Qed.*)

Lemma dim_slice : Sdim (slice c d P) %:poly_base = (Sdim P - 1)%N.
Admitted.

End SliceFace.

(*
Section SliceFaceSet.

Variable P : {poly 'P(A,b)}.
Hypothesis P_prop : `[pt v]%:poly_base `<` P.
Hypothesis c_sep : forall w, w \in vertex_set P -> w != v -> '[c, w] > d.

Fact sep_face F :
  F \in face_set P -> forall w, w \in vertex_set F -> w != v -> '[c, w] > d.
Proof.
rewrite inE vertex_set_mono => [/fsubsetP vtx_sub] w ??.
by apply: c_sep; try exact: vtx_sub.
Qed.

Local Instance slice_face_proper0' F : F \in face_set P -> infer (slice c d F `>` `[poly0]).
Admitted.

Definition slice_face (F : {poly 'P(A, b)}) :
  (`[pt v]%:poly_base `<` F) -> (F \in face_set P) -> (slice c d F)%:poly_base `<=` (slice c d P)%:poly_base.


Set Printing All.
Lemma active_slice_eq.



End VertexFigure.
 *)

(*


Section VertexBase.

Variable (R : realFieldType) (n : nat) (base : 'hpoly[R]_n).

Inductive vertex_base := VertexBase { pt_val :> 'cV[R]_n; _ : [ `[pt pt_val] has \base base] }.
Canonical vertex_base_subType := [subType for pt_val].
Definition vertex_base_eqMixin := Eval hnf in [eqMixin of vertex_base by <:].
Canonical vertex_base_eqType := Eval hnf in EqType vertex_base vertex_base_eqMixin.
Definition vertex_base_choiceMixin := Eval hnf in [choiceMixin of vertex_base by <:].
Canonical vertex_base_choiceType := Eval hnf in ChoiceType vertex_base vertex_base_choiceMixin.

Lemma vertex_base_baseP (v : vertex_base) : [ `[pt v] has \base base].
Proof.
exact : (valP v).
Qed.

Canonical vertex_base_poly (v : vertex_base) := PolyBase (vertex_base_baseP v).

Lemma poly_base_vertexP (P : {poly base}) :
  P `>` (`[poly0]) -> (dim P == 0%N) -> [ `[pt (pick_point P)] has \base base].
Admitted.

Definition poly_base_vertex (P : {poly base}) :=
  if @idP (P `>` (`[poly0])) is ReflectT P_prop0 then
    if @idP (dim P == 0%N) is ReflectT P_dim0 then
      Some (VertexBase (poly_base_vertexP P_prop0 P_dim0))
    else None
  else None.

Lemma vertex_poly_baseK : pcancel vertex_base_poly poly_base_vertex.
Admitted.

Definition vertex_base_countMixin := PcanCountMixin vertex_poly_baseK.
Canonical vertex_base_countType := Eval hnf in CountType vertex_base vertex_base_countMixin.
Definition vertex_base_finMixin := PcanFinMixin vertex_poly_baseK.
Canonical vertex_base_finType := Eval hnf in FinType vertex_base vertex_base_finMixin.

End VertexBase.

Notation "'{vertex'  base '}'" := (vertex_base base) : poly_scope.

Section Vertex.

Variable (R : realFieldType) (n : nat) (base : 'hpoly[R]_n).

Definition vertex_set (P : {poly base}) := [set v : {vertex base} | (v : 'cV__) \in P].

Lemma vertexP (P : {poly base}) (v : {vertex base}) :
  (v \in vertex_set P) = (`[pt v]%:poly_base \in face_set P).
Proof.
by rewrite inE [RHS]inE pt_proper0 pt_subset.
Qed.

End Vertex.

*)

(*
Section Vertex.

Variable (R : realFieldType) (n : nat) (base : 'hpoly[R]_n).

Implicit Types (P Q F : {poly base}).

Definition fvertex_set P := [set F in face_set P | dim F == 0%N].

Definition vertex_set P :=
  ((fun (F : {poly base}) => pick_point F) @` (fvertex_set P))%fset.

Lemma vertex_has_baseP P x (H : x \in vertex_set P) : [ `[pt x] has \base base].
Proof.
move/imfsetP: H => [fx /=]; rewrite inE => /andP [fx_face].
have fx_non_empty: (fx `>` `[poly0]) by move: fx_face; rewrite inE => /andP [].
move/(dim0P fx_non_empty) => [x'] fx_eq.
rewrite fx_eq pick_point_pt => ->; rewrite -fx_eq.
exact: poly_base_base.
Qed.
Canonical vertex_poly_base P x (H : x \in vertex_set P) := PolyBase (vertex_has_baseP H).

Lemma vertex_in_face_set P x (H : x \in vertex_set P) : vertex_poly_base H \in face_set P.
Admitted.
(*Variable (P : {poly base}) (x : 'cV[R]_n).
  Check (`[pt x]%:poly_base).*)


End Vertex.
*)
End VertexFigure.
*)
