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
Reserved Notation "[ c '\separates' x '\from' V ]" (at level 0, format "[ c  '\separates'  x  '\from'  V ]").

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
Proof.
case: finsuppP; first done.
move/and3P: (w_weight_over_V) => [/fsubsetP supp_incl /forallP w_ge0 _].
move/supp_incl => v_in_V.
pose v' := [`v_in_V]%fset.
have ->: v = val v' by done.
exact: w_ge0.
Qed.

Lemma weight_eq0 v : v \notin V -> w v = 0.
Proof.
move => v_notin_V; apply: fsfun_dflt.
move: v_notin_V; apply: contra.
move/and3P: (w_weight_over_V) => [/fsubsetP supp_incl _ _].
exact: supp_incl.
Qed.

Lemma weight_gt0 v : w v > 0 -> v \in V.
Proof.
move => w_v_gt0.
suff: v \in finsupp w.
- move/and3P: (w_weight_over_V) => [/fsubsetP supp_incl _ _]; exact: supp_incl.
- rewrite mem_finsupp; exact: lt0r_neq0.
Qed.

Lemma weight_sum1 : \sum_(v <- V) w v = 1.
Proof.
rewrite big_seq_fsetE /=.
by move/and3P: (w_weight_over_V) => [_ _ /eqP].
Qed.

End CoreProp.

Section OtherProp.

Implicit Types V : {fset 'cV[R]_n}.
Implicit Type w : {fsfun 'cV[R]_n -> R for fun => 0%R}.

Lemma weightP V w :
  reflect [/\ (forall v, w v >= 0), (forall v, v \notin V -> w v = 0) & (\sum_(v <- V) w v = 1)]
          [w \weight over V].
Proof.
apply: (iffP idP).
- move => w_weight; split;
    [exact: (weight_ge0 w_weight) | exact: weight_eq0 | exact: weight_sum1].
- move => [w_ge0 w_supp sum_w].
  apply/and3P; split.
  + apply/fsubsetP => v.
    by apply: contraTT; move/w_supp/eqP; rewrite memNfinsupp.
  + apply/forallP => v; apply: w_ge0.
  + by apply/eqP; move: sum_w; rewrite big_seq_fsetE.
Qed.

Lemma weight_subset V V' w : (V `<=` V')%fset -> [w \weight over V] -> [w \weight over V'].
Admitted.

End OtherProp.

Definition bary (V : {fset 'cV[R]_n}) w : 'cV[R]_n := \sum_(v <- V) (w v) *: v.

Definition nth_fset (V : {fset 'cV[R]_n}) (i : 'I_#|predT: pred V|) := val (enum_val i).

Lemma nth_fsetP (V : {fset 'cV[R]_n}) (i : 'I_#|predT: pred V|) :
  nth_fset i \in V.
Proof.
rewrite /nth_fset; exact: fsvalP.
Qed.

Definition mat_fset (V : {fset 'cV[R]_n}) :=
  (\matrix_(i < #|predT : pred V|) (nth_fset i)^T)^T.

Fact col_mat_fset V i : col i (mat_fset V) = nth_fset i .
Proof.
by rewrite -tr_row rowK trmxK.
Qed.

Definition vect_fset (V : {fset 'cV[R]_n}) (w : 'cV[R]_n -> R) :=
  \col_(i < #|predT : pred V|) (w (nth_fset i)).

Lemma baryE V w : bary V w = (mat_fset V) *m (vect_fset V w).
Proof.
rewrite /bary mulmx_sum_col.
rewrite big_seq_fsetE (reindex (@enum_val _ V)) /=.
- apply: eq_bigr => i _.
  by rewrite col_mat_fset /vect_fset mxE.
- apply: onW_bij; exact: enum_val_bij.
Qed.

Lemma sum_vect_fset (V : {fset 'cV[R]_n}) (w : 'cV[R]_n -> R) :
  \sum_(v <- V) (w v) = '[const_mx 1, vect_fset V w].
Proof.
rewrite big_seq_fsetE (reindex (@enum_val _ V)) /=.
- apply: eq_bigr => i _.
  by rewrite !mxE mul1r.
- apply: onW_bij; exact: enum_val_bij.
Qed.

End Barycenter.

Notation "[ w '\weight' 'over' V ]" := (weight V w).
Notation "\bary[ w ] V" := (bary V w).

Section ConvexHullDef.

Variable R : realFieldType.
Variable n : nat.
Variable V : {fset 'cV[R]_n}.

Let p := #|predT : pred V|.
Definition e := (const_mx 1):'cV[R]_p.

Definition A := col_mx (col_mx (mat_fset V) e^T) 1%:M.

Definition b (x: 'cV[R]_n) :=
  col_mx (col_mx x 1) (0:'cV_p).

Definition is_in_convex_hull := [pred x | HPrim.non_empty 'P^=(A, b x; (lshift p) @: [set: 'I_(n+1)]) ].

Section ConvexHullPolyProp.

Variable x : 'cV[R]_n.
Let I := (lshift p) @: [set: 'I_(n+1)].
Let P := 'P^=(A, b x; I).
Let V_mat := mat_fset V.

Fact sum_w w : e^T *m w = 1 <-> '[const_mx 1, w] = 1.
Proof.
rewrite -vdot_def vdotC.
split; last by move ->.
by move/matrixP/(_ 0 0); rewrite !mxE /= mulr1n.
Qed.

Fact poly_cvx_hull_inP w :
  reflect [/\ V_mat *m w = x, '[const_mx 1, w] = 1 & w >=m 0] (w \in P).
Proof.
apply/(iffP hpolyEq_inP).
- move => [w_ineq w_eq].
  have : (col_mx V_mat e^T) *m w = col_mx x 1.
  + apply/colP => i; pose i' := lshift p i.
    have i'_in_I : i' \in I by exact: mem_imset.
    move/(_ _ i'_in_I): w_eq.
    by rewrite mul_col_mx !col_mxEu.
  rewrite mul_col_mx; move/eq_col_mx => [? ?].
  split; try by [done | apply/sum_w].
  apply/gev0P => i.
  pose i' := rshift (n+1) i.
  rewrite inE in w_ineq.
  move/forallP/(_ i'): w_ineq.
  by rewrite !mul_col_mx !col_mxEd mul1mx mxE.
- move => [V_mat_eq sum_eq1 ge0].
  suff w_eq : forall j, j \in I -> (A *m w) j 0 = (b x) j 0.
  + split; last by done.
    rewrite inE !mul_col_mx mul1mx.
    rewrite col_mx_lev; apply/andP; split; last by done.
    apply/forallP => i; pose i' := lshift p i.
    have i'_in_I : i' \in I by exact: mem_imset.
    by move/(_ _ i'_in_I): w_eq; rewrite 2!mul_col_mx !col_mxEu => ->.
  + move => ? /imsetP [i _ ->]; rewrite !mul_col_mx !col_mxEu V_mat_eq.
    by move/sum_w: sum_eq1 ->.
Qed.

End ConvexHullPolyProp.

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
rewrite inE; apply: (iffP HPrim.non_emptyP) => [ [w] | [w] ].
- move/poly_cvx_hull_inP => [V_w_eq_x e_w_eq1 w_ge0].
  pose w' := [fsfun v : V => w (enum_rank v) 0 | 0].
  have w_eq_w' : w = (vect_fset V w').
  + apply/colP => i; rewrite mxE fsfun_ffun insubT => [ | ? /=];
      first exact: nth_fsetP; last by rewrite fsetsubE enum_valK.
  exists w'; split; last first.
  + by rewrite baryE -V_w_eq_x; apply: congr1.
  + apply/weightP; split.
    * move => v; rewrite fsfun_ffun; case: insubP => [? _ _ /= | /=];
        try by [ move/gev0P: w_ge0 | done ].
    * move => v v_notin_V; rewrite fsfun_ffun insubF //; exact: negbTE.
    * by rewrite sum_vect_fset -w_eq_w'.
- move => [/weightP [w_ge0 w_supp sum_w_eq1] x_bary].
  pose w' := vect_fset V w.
  exists w'; apply/poly_cvx_hull_inP; split.
  + by rewrite -baryE x_bary.
  + by rewrite -sum_vect_fset.
  + apply/gev0P => i; rewrite mxE; exact: w_ge0.
Qed.

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

Definition separate (V : {fset 'cV[R]_n}) c x := exists z, ('[c,x] < z /\ forall (v: 'cV_n), v \in V -> '[c,v] >= z).
Notation "[ c '\separates' x '\from' V ]" := (separate V c x).

Variable V : {fset 'cV[R]_n}.

Lemma separationP c x :
  [ c \separates x \from V ] <-> (forall (v: 'cV_n), v \in V -> '[c, x] < '[c, v]).
Proof.
split.
- move => [z [c_x_lt_z c_V_ge_z]] v v_in_V.
  move/(_ _ v_in_V): c_V_ge_z.
  exact: ltr_le_trans.
- move => c_x_lt_c_V.
  pose S := [seq '[c,v] | v <- V].
  pose z := min_seq S ('[c,x] + 1).
  exists z; split.
  + case: (boolP (S == [::] :> seq _)).
    * rewrite /z; move/eqP => -> /=.
      by rewrite ltr_addl ltr01.
    * rewrite /z.
      move/(min_seq_eq ('[c,x]+1))/hasP => [? /mapP [v v_in_V ->]] /eqP ->.
      exact: c_x_lt_c_V.
  + move => v v_in_V.
    by rewrite /z; apply: min_seq_ler; apply: map_f.
Qed.

Lemma separationP_proper c x :
  [ c \separates x \from V ] <-> exists z, ('[c,x] < z /\ forall (v: 'cV_n), v \in V -> '[c,v] > z).
Proof.
split.
- move => [z [c_x_lt_z c_V_ge_z]].
  pose z' := ('[c,x]+z) / 2%:R; exists z'; split.
  + by rewrite midf_lt.
  + move => v /c_V_ge_z; apply: ltr_le_trans.
    by rewrite midf_lt.
- move => [z [c_x_lt_z c_V_gt_z]].
  exists z; split; first by done.
  move => v /c_V_gt_z; exact: ltrW.
Qed.

Fact mul_A_tr_u c z w i :
  let u := col_mx (col_mx c z%:M) w in
  let v := @nth_fset _ _ V i in
  row i ((A V)^T *m u) = ('[c, v] + z + w i 0)%:M.
Proof.
move => u v.
rewrite row_mul -tr_col 2!col_col_mx.
rewrite col_mat_fset.
rewrite trmx_const col_const.
rewrite 2!tr_col_mx trmx_const tr_col trmx1 row1.
rewrite 2!mul_row_col -vdot_def -rowE.
by rewrite const_mx11 -scalar_mxM mul1r row_cV -2!raddfD /=.
Qed.

Lemma convPn x :
  reflect (exists c, [ c \separates x \from V ]) (x \notin \conv V).
Proof.
apply: (iffP hpolyEq_non_emptyPn_cert).
- move => [u [u_ge0 A_u_eq0 b_u_lt0]].
  pose c := -usubmx (usubmx u).
  pose z := dsubmx (usubmx u) 0 0.
  pose w := dsubmx u.
  have split_u : u = col_mx (col_mx (-c) z%:M) w.
  + by rewrite opprK -mx11_scalar 2!vsubmxK.
  have w_ge0 : w >=m 0.
  + apply/gev0P => i; rewrite mxE.
    apply: u_ge0; apply/memPn => ? /imsetP [j _] ->; exact: lrshift_distinct.
  exists c; exists z; split.
  + move: b_u_lt0; rewrite split_u 2!vdot_col_mx vdot0l addr0.
    rewrite vdotNr vdotC addrC subr_gt0.
    suff ->: '[1,z%:M] = z by done.
    * have ->: '[1,z%:M] = \sum_(i < 1) z.
        by apply/eq_bigr => i _; rewrite !mxE [i]ord1_eq0 /= mul1r mulr1n.
    * by rewrite big_const cardT size_enum_ord /= addr0.
  + move => v v_in_V.
    move/row_matrixP/(_ (enum_rank [`v_in_V]%fset)): A_u_eq0.
    rewrite split_u mul_A_tr_u /= row0.
    rewrite /nth_fset enum_rankK /=.
    move/eqP; rewrite  scalar_mx_eq0 mxE /= mulr1n -addrA addrC vdotNl subr_eq0 => /eqP <-.
    rewrite ler_addl; by move/gev0P: w_ge0.
- move => [c [z [c_x_lt_z c_V_gt_z]]].
  pose w := \col_i ('[c, nth_fset i] - z) :'cV_(#|predT : pred V|).
  pose u := col_mx (col_mx (-c) z%:M) w.
  exists u; split.
  + move => j; rewrite -in_setC lshift_set_compl => /imsetP [k] _ ->.
    by rewrite col_mxEd mxE subr_ge0; apply: c_V_gt_z; exact: nth_fsetP.
  + apply/row_matrixP => i. rewrite mul_A_tr_u row0 mxE.
    by rewrite vdotNl addrACA addrN addNr addr0 -const_mx11.
  + rewrite 2!vdot_col_mx vdot0l addr0 vdotC vdotNl addrC subr_gt0.
    suff ->: '[1,z%:M] = z by done.
    * have ->: '[1,z%:M] = \sum_(i < 1) z.
        by apply/eq_bigr => i _; rewrite !mxE [i]ord1_eq0 /= mul1r mulr1n.
    * by rewrite big_const cardT size_enum_ord /= addr0.
Qed.

End Separation.

(*
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