(*************************************************************************)
(* Coq-Polyhedra: formalizing convex polyhedra in Coq/SSReflect          *)
(*                                                                       *)
(* (c) Copyright 2018, Xavier Allamigeon (xavier.allamigeon at inria.fr) *)
(*                     Ricardo D. Katz (katz at cifasis-conicet.gov.ar)  *)
(* All rights reserved.                                                  *)
(* You may distribute this file under the terms of the CeCILL-B license  *)
(*************************************************************************)

From mathcomp Require Import all_ssreflect ssralg ssrnum zmodp matrix mxalgebra vector perm finmap.
Require Import extra_misc inner_product vector_order extra_matrix row_submx hpolyhedron polyhedron.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.
Import GRing.Theory Num.Theory.

Reserved Notation "[ w '\weight' 'over' V ]" (at level 0, format "[ w  '\weight'  'over'  V ]").
Reserved Notation "\bary[ w ] V " (at level 70, format "\bary[ w ]  V").
Reserved Notation "\conv V " (at level 50, format "\conv  V").

Section Barycenter.

Variable R : realFieldType.
Variable n : nat.

Definition weight (V : {fset 'cV[R]_n}) (w : {fsfun 'cV[R]_n -> R for fun => 0%R}) :=
  [&& (finsupp w `<=` V)%fset, [forall v : V, w (val v) >= 0] & (\sum_(v : V) w (val v) == 1)].

Notation "[ w '\weight' 'over' V ]" := (weight V w).

Section CoreProp.

Variable V : {fset 'cV[R]_n}.
Variable w : {fsfun 'cV[R]_n -> R for fun => 0%R}.
Hypothesis w_weight_over_V : [ w \weight over V ].

Implicit Type v : 'cV[R]_n.

Lemma weight_ge0 v : w v >= 0.
Admitted.

Lemma weight_eq0 v : v \notin V -> w v = 0.
Admitted.

Lemma weight_gt0 v : w v > 0 -> v \in V.
Admitted.

Lemma weight_sum1 : \sum_(v <- V) w v = 1.
Admitted.

End CoreProp.

Section OtherProp.

Implicit Types V : {fset 'cV[R]_n}.
Implicit Type w : {fsfun 'cV[R]_n -> R for fun => 0%R}.

Lemma weightP V w :
  reflect [/\ (forall v, w v >= 0), (forall v, v \notin V -> w v = 0) & (\sum_(v <- V) w v = 1)]
    [w \weight over V].
Admitted.

Lemma weight_subset V V' w : (V `<=` V')%fset -> [w \weight over V] -> [w \weight over V'].
Admitted.

End OtherProp.

Definition bary (V : {fset 'cV[R]_n}) w : 'cV[R]_n := \sum_(v <- V) (w v) *: v.

End Barycenter.

Notation "[ w '\weight' 'over' V ]" := (weight V w).
Notation "\bary[ w ] V" := (bary V w).

Section ConvexHullDef.

Variable R : realFieldType.
Variable n : nat.
Variable V : {fset 'cV[R]_n}.

Let p := #|`V|.
Let V_mat := \matrix_(i < n, j < #|`V|) ((nth 0 V j) i 0).

Definition e := (const_mx 1):'cV[R]_p.

Definition A :=
  (col_mx (col_mx (col_mx V_mat (-V_mat)) (col_mx e^T (-e^T))) 1%:M).

Definition b (x: 'cV[R]_n) :=
  col_mx (col_mx (col_mx x (-x)) (col_mx 1 (-1))) (0:'cV_p).

Definition is_in_convex_hull x := HPrim.non_empty 'P(A, b x).

End ConvexHullDef.

Notation "\conv V" := (is_in_convex_hull V).

Section ConvexHullProp.

Variable R : realFieldType.
Variable n : nat.

Implicit Type V : {fset 'cV[R]_n}.
Implicit Type x : 'cV[R]_n.

Lemma convP V x :
  reflect (exists w, [w \weight over V] /\ x = \bary[w] V) (x \in \conv V).
Proof.
Admitted.

Lemma convP1 v x :
  reflect (x = v) (x \in \conv [fset v]%fset).
Admitted.

Lemma convP2 v v' x :
  reflect (exists a, 0 <= a <= 1 /\ x = a *: v + (1-a) *: v) (x \in \conv ([fset v] `|` [fset v'])%fset).
Admitted.

Lemma conv_mono V V' x : (V `<=` V')%fset -> x \in \conv V -> x \in \conv V'.
Proof.
Admitted.

Lemma convU V V' x :
  reflect (exists a v v', [/\ 0 <= a <= 1, v \in \conv V, v' \in \conv V' & x = a *: v + (1-a) *: v'])
  (x \in \conv(V `|` V')%fset).
Admitted.

Lemma convU1 v V' x :
   reflect (exists a v', [/\ 0 <= a <= 1, v' \in \conv V' & x = a *: v + (1-a) *: v'])
           (x \in \conv(v |` V')%fset).
Admitted.

End ConvexHullProp.

Section Separation.

Variable R : realFieldType.
Variable n : nat.

Lemma convPn (V : {fset 'cV[R]_n}) x :
  reflect (exists c, forall v, v \in V -> '[c,x] < '[c,v]) (x \notin \conv V).
Admitted.

End Separation.

(*apply: (iffP HPrim.non_emptyP) => [[l] |[l [Hlpos Hlsum Hl]]].
- rewrite inE !mul_col_mx !col_mx_lev.
  move => /andP [/andP [Hl Hlsum] Hlpos].
  rewrite mul1mx in Hlpos.
  have Hlsum': '[e,l] = 1.
  + move: Hlsum; rewrite mulNmx -!vdot_def.
    rewrite lev_opp2; move/lev_antisym.
    by rewrite vdotC; move/colP/(_ 0); rewrite !mxE /= !mulr1n.
  have Hl' : x = V *m l.
  + by move: Hl; rewrite mulNmx lev_opp2; move/lev_antisym.
  by exists l; split.
- exists l; rewrite inE !mul_col_mx !col_mx_lev.
  rewrite Hl mulNmx !lev_refl /=.
  rewrite mul1mx Hlpos andbT.
  by rewrite mulNmx -vdot_def vdotC Hlsum !lev_refl.
Qed.*)


(*

Lemma separation (x: 'cV_n) :
  ~~ (is_in_convex_hull x) -> exists c, [forall i, '[c, col i V] > '[c, x]].
Proof.
move/infeasibleP => [d [/andP [HdA Hdpos] Hdb]].
- set d1 := usubmx (usubmx d).
  set d2 := dsubmx (usubmx d).
  set d3 := dsubmx d.
  set c := (usubmx d1) - (dsubmx d1).
  set y := ((usubmx d2) - (dsubmx d2)) 0 0.
  have Hineq1: ((V^T *m c) + (const_mx y)) <=m 0.
  + move: HdA.
    rewrite !tr_col_mx !linearN /= trmxK trmx1.
    rewrite -[d]vsubmxK mul_row_col mul1mx.
    move: Hdpos; rewrite -{1}[d]vsubmxK; rewrite col_mx_gev0 => /andP [_].
    rewrite -lev_opp2 oppr0 => Hdpos.
    rewrite addr_eq0 => /eqP => HdA.
    move: Hdpos; rewrite -HdA.
    set d' := usubmx d.
    rewrite -[d']vsubmxK mul_row_col -/d1 -/d2.
    rewrite -[d1]vsubmxK mul_row_col mulNmx -mulmxN -mulmxDr -/c.
    rewrite -[d2]vsubmxK mul_row_col mulNmx -mulmxN -mulmxDr.
      by rewrite [_ - _]mx11_scalar mul_mx_scalar scalemx_const mulr1.
  have Hineq2: '[c, x] + y > 0.
  + move: Hdb.
    rewrite -[d]vsubmxK vdot_col_mx vdot0l addr0.
    set d' := usubmx d.
    rewrite -[d']vsubmxK vdot_col_mx -/d1 -/d2.
    rewrite -[d1]vsubmxK vdot_col_mx vdotNl -vdotNr -vdotDr -/c.
    rewrite -[d2]vsubmxK vdot_col_mx vdotNl -vdotNr -vdotDr.
    rewrite [_ - _]mx11_scalar -/y.
    suff: y%:M = (('[ 1, y%:M])%:M : 'cV_1).
    * by move/colP/(_ 0); rewrite 2!mxE /= 2!mulr1n => <-; rewrite vdotC.
    * by rewrite vdot_def tr_scalar_mx mulmx1.
  + exists (-c); apply/forallP => i.
    rewrite !vdotNl ltr_opp2.
    have: (row i ((V^T *m c + const_mx y))) <=m 0.
    * move/forallP/(_ i): Hineq1.
      rewrite [X in _ <= X]mxE => Hineq1.
      by apply/forallP => ?; rewrite mxE [X in _ <= X]mxE.
    rewrite linearD /= row_mul -tr_col -vdot_def row_const.
    move/forallP/(_ 0); rewrite !mxE /= mulr1n => Hineq1'.
    move: (ler_lt_trans Hineq1' Hineq2).
    by rewrite ltr_add2r.
Qed.

End Def.

Section Minkowski.

Variable R : realFieldType.
Variable m n: nat.

Variable A: 'M[R]_(m,n).
Variable b: 'cV[R]_m.

Definition bases := [set: feasible_basis A b].
Notation p := #|bases|.

Definition matrix_of_vertices :=
  \matrix_(i < n, j < p) (point_of_basis b (enum_val j)) i 0.

Lemma col_matrix_of_vertices j :
  col j matrix_of_vertices = point_of_basis b (enum_val j).
Proof.
by apply/colP => i; rewrite !mxE.
Qed.

Lemma minkowski :
  bounded_polyhedron A b -> (polyhedron A b) =i (is_in_convex_hull matrix_of_vertices).
Proof.
move => Hbounded.
case: (boolP (feasible A b)) => [Hfeas x| Hinfeas x].

(* the case where polyhedron A b is feasible *)
- apply/idP/idP.
  (* the difficult part of the statement:
   * if x \in polyhedron A b, then x is in the convex hull of the vertices *)
  + move => Hx; apply: contraT.
    move/separation => [c Hc].
    have Hpointed: pointed A
      by exact: (feasible_bounded_polyhedron_is_pointed Hfeas Hbounded).
    move/(bounded_polyhedronP_feasible Hfeas)/(_ c)/(bounded_pointedP _ _ Hpointed): Hbounded => [[bas]].
    set z := point_of_basis _ _; move <-.
    move/(_ _ Hx) => Hzx.
    pose i := enum_rank_in (in_setT bas) bas.
    move/forallP/(_ i): Hc.
    rewrite col_matrix_of_vertices enum_rankK_in; last exact: in_setT.
    by move/(ler_lt_trans Hzx); rewrite ltrr.
  (* the converse part, in which we show that polyhedra are convex (!) *)
  + move/is_in_convex_hullP => [l [Hl Hel ->]].
    rewrite inE mulmxA mulmx_sum_col.
    have {1}->: b = \sum_i (l i 0 *: b).
    * rewrite -scaler_suml.
      suff ->: \sum_i l i 0 = 1 by rewrite scale1r.
      - move: Hel; rewrite /vdot => <-.
        apply: eq_bigr.
        by move => i _; rewrite mxE mul1r.
    apply: lev_sum => i _.
    * apply: lev_wpscalar; first by move/forallP/(_ i): Hl; rewrite mxE.
      - rewrite col_mul col_matrix_of_vertices.
        exact: feasible_basis_is_feasible.

(* the case where polyhedron A b is not feasible *)
- have /negbTE ->: ~~ (x \in polyhedron A b).
  + move: Hinfeas; apply: contra => Hx.
    by apply/(feasibleP A b); exists x.
  symmetry; apply: negbTE; apply/negP.
  move/is_in_convex_hullP => [l [_ Hl _]].
  suff Hl': '[e R #|bases|, l] = 0.
  + by rewrite Hl' in Hl; move: (@ltr01 R); rewrite Hl ltrr /=.
  + rewrite /vdot big_seq.
    apply: big_pred0 => i; apply/negbTE.
    rewrite /index_enum -enumT.
    suff: bases == set0.
    * rewrite -cards_eq0.
      by rewrite -{1}[#|bases|]card_ord cardT; move/eqP/size0nil ->.
    * apply: contraT.
      rewrite exists_feasible_basis.
      by move/negbTE : Hinfeas ->.
Qed.

End Minkowski.*)