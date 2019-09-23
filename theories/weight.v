(* -------------------------------------------------------------------- *)
From mathcomp Require Import all_ssreflect all_algebra finmap.

Set   Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Unset SsrOldRewriteGoalsOrder.

Import GRing.Theory Num.Theory.

Local Open Scope ring_scope.

(* -------------------------------------------------------------------- *)
Reserved Notation "{ 'fsfun' T ~> R }"
  (at level 0, format "{ 'fsfun'  T  ~>  R }").

Reserved Notation "{ 'conic' T ~> R }"
  (at level 0, format "{ 'conic'  T  ~>  R }").

Reserved Notation "{ 'convex' T ~> R }"
  (at level 0, format "{ 'convex'  T  ~>  R }").

Reserved Notation "0 %:FS"
  (at level 2, format "0 %:FS").

Reserved Notation "0 %:PFS"
  (at level 1, format "0 %:PFS").

(* -------------------------------------------------------------------- *)
Notation "{ 'fsfun' T ~> R }" := {fsfun T -> R for fun => 0} : type_scope.

(* -------------------------------------------------------------------- *)
Section FsFunZmod.
Context {T : choiceType} {R : zmodType}.

Implicit Types f g h : {fsfun T ~> R}.

Definition fs0 : {fsfun T ~> R} := [fsfun].

Definition fsopp f : {fsfun T ~> R} :=
  [fsfun x in finsupp f => -f x].

Definition fsadd f g : {fsfun T ~> R} :=
  [fsfun x in (finsupp f `|` finsupp g)%fset => f x + g x].

Notation "0 %:FS" := fs0 : fsfun_scope.
Notation "- f"    := (fsopp f)  : fsfun_scope.
Notation "f + g"  := (fsadd f g) : fsfun_scope.

Lemma fs0E x : (0%:FS x)%fsfun = 0.
Proof. by rewrite fsfunE. Qed.

Lemma fsoppE f x : (- f)%fsfun x = -(f x).
Proof. by rewrite fsfunE; case: finsuppP => // _; rewrite oppr0. Qed.

Lemma fsaddE f g x : (f + g)%fsfun x = (f x + g x).
Proof.
by rewrite fsfunE in_fsetU; (do 2! case: finsuppP => ? //=); rewrite addr0.
Qed.

Let fsfunwE := (fs0E, fsoppE, fsaddE).

Lemma fsfun_zmod :
  [/\ associative fsadd
    , commutative fsadd
    , left_id fs0 fsadd
    & left_inverse fs0 fsopp fsadd].
Proof. split.
+ by move=> f g h; apply/fsfunP=> x /=; rewrite !fsfunwE addrA.
+ by move=> f g; apply/fsfunP=> x /=; rewrite !fsfunwE addrC.
+ by move=> f; apply/fsfunP=> x /=; rewrite !fsfunwE add0r.
+ by move=> f; apply/fsfunP=> x /=; rewrite !fsfunwE addNr.
Qed.

Let addfA := let: And4 h _ _ _ := fsfun_zmod in h.
Let addfC := let: And4 _ h _ _ := fsfun_zmod in h.
Let add0f := let: And4 _ _ h _ := fsfun_zmod in h.
Let addNf := let: And4 _ _ _ h := fsfun_zmod in h.

Definition fsfun_zmodMixin := ZmodMixin addfA addfC add0f addNf.
Canonical fsfun_zmodType := Eval hnf in ZmodType {fsfun T ~> R} fsfun_zmodMixin.

Lemma supp_fs0 : finsupp 0%R = fset0.
Proof. by rewrite finsupp0. Qed.

Lemma supp_fsN f : finsupp (-f)%fsfun = finsupp f.
Proof.
by apply/fsetP=> x; rewrite !mem_finsupp fsfunwE oppr_eq0.
Qed.

Lemma supp_fsD f g :
  (finsupp (f + g)%R `<=` finsupp f `|` finsupp g)%fset.
Proof.
apply/fsubsetP=> x; rewrite in_fsetU !mem_finsupp !fsfunwE.
case: (f x =P 0) => //= ->; case: (g x =P 0) => //= ->.
by rewrite addr0 eqxx.
Qed.
Lemma mem_fsN x f : (x \in finsupp (-f)%R) -> x \in finsupp f.
Proof. by rewrite supp_fsN. Qed.

Lemma mem_fsD x f g :
  x \in finsupp (f + g)%R -> x \in finsupp f \/ x \in finsupp g.
Proof.
by move/(fsubsetP (supp_fsD _ _)); rewrite in_fsetU (rwP orP).
Qed.
End FsFunZmod.

(* -------------------------------------------------------------------- *)
Section FsFunLmod.
Context {T : choiceType} {R : ringType}.

Implicit Types (c : R) (f g h : {fsfun T ~> R}).

Definition fsscale c f : {fsfun T ~> R} :=
  [fsfun x in finsupp f => c * f x].

Notation "c *: f" := (fsscale c f) : fsfun_scope.

Lemma fsscaleE c f x : (c *: f)%fsfun x = c * f x.
Proof.
by rewrite fsfunE; case: finsuppP => // _; rewrite mulr0.
Qed.

Let fsfunwE := (@fs0E, @fsoppE, @fsaddE, fsscaleE).

Lemma fsfun_lmod :
  [/\ forall c1 c2 f, fsscale c1 (fsscale c2 f) = fsscale (c1 * c2) f
    , left_id 1 fsscale
    , right_distributive fsscale +%R
    & forall f, {morph fsscale^~ f : c1 c2 / c1 + c2}].
Proof. split.
+ by move=> c1 c2 f; apply/fsfunP=> x /=; rewrite !fsfunwE mulrA.
+ by move=> f; apply/fsfunP=> x /=; rewrite !fsfunwE mul1r.
+ by move=> c f g; apply/fsfunP=> x /=; rewrite !fsfunwE mulrDr.
+ by move=> f c1 c2; apply/fsfunP=> x /=; rewrite !fsfunwE mulrDl.
Qed.

Let scale_fsfunA  := let: And4 h _ _ _ := fsfun_lmod in h.
Let scale_fsfun1  := let: And4 _ h _ _ := fsfun_lmod in h.
Let scale_fsfunDr := let: And4 _ _ h _ := fsfun_lmod in h.
Let scale_fsfunDl := let: And4 _ _ _ h := fsfun_lmod in h.

Definition fsfun_lmodMixin :=
  LmodMixin scale_fsfunA scale_fsfun1 scale_fsfunDr scale_fsfunDl.
Canonical fsfun_lmodType :=
  Eval hnf in LmodType R {fsfun T ~> R} fsfun_lmodMixin.
End FsFunLmod.

(* -------------------------------------------------------------------- *)
Section FsFunLmodId.
Context {T : choiceType} {R : idomainType}.

Implicit Types (c : R) (f g h : {fsfun T ~> R}).

Lemma supp_fsZ c f : c != 0 -> finsupp (c *: f)%fsfun = finsupp f.
Proof.
move=> nz_c; apply/fsetP => x; rewrite !mem_finsupp fsscaleE.
by rewrite mulf_eq0 (negbTE nz_c).
Qed.

Lemma mem_fsZ x c f : c != 0 -> x \in finsupp (c *: f)%R -> x \in finsupp f.
Proof. by move/supp_fsZ=> ->. Qed.
End FsFunLmodId.

(* -------------------------------------------------------------------- *)
Definition fsfunwE := (@fs0E, @fsaddE, @fsoppE, @fsscaleE).

(* -------------------------------------------------------------------- *)
Section Combine.
Context {R : ringType} {L : lmodType R}.

Implicit Types (f g h : {fsfun L ~> R}).

Definition combine f := \sum_(x : finsupp f) f (val x) *: val x.

Lemma combinewE E f : (finsupp f `<=` E)%fset ->
  combine f = \sum_(x : E) f (val x) *: (val x).
Proof.
move=> leEw; pose F x := f x *: x; rewrite /combine.
rewrite -!(big_seq_fsetE _ _ predT F) /= {}/F.
have /permEl h := perm_filterC (mem (finsupp f)) E.
rewrite -{h}(perm_big _ h) big_cat /= 2![X in _+X](big_seq, big1) 1?addr0.
+ move=> x; rewrite mem_filter inE memNfinsupp.
  by case/andP=> [/eqP->]; rewrite scale0r.
apply/perm_big/uniq_perm; rewrite ?(fset_uniq, filter_uniq) //.
by move=> x; rewrite mem_filter inE andb_idr // => /(fsubsetP leEw).
Qed.

Lemma combineE f : combine f = \sum_(x : finsupp f) f (val x) *: (val x).
Proof. by []. Qed.
End Combine.

(* -------------------------------------------------------------------- *)
Section Weight.
Context {T : choiceType} {R : zmodType}.

Implicit Types (f g h : {fsfun T ~> R}).

Definition weight f := \sum_(x : finsupp f) f (val x).

Lemma weightwE E w : (finsupp w `<=` E)%fset ->
  weight w = \sum_(x : E) w (val x).
Proof.
move=> leEw; rewrite /weight -!(big_seq_fsetE _ _ predT) /=.
have /permEl h := perm_filterC (mem (finsupp w)) E.
rewrite -{h}(perm_big _ h) big_cat /= 2![X in _+X](big_seq, big1).
+ by move=> x; rewrite mem_filter inE memNfinsupp => /andP[/eqP->].
rewrite addr0; apply/perm_big/uniq_perm; rewrite ?filter_uniq //.
by move=> x; rewrite mem_filter inE andb_idr // => /(fsubsetP leEw).
Qed.

Lemma weightE f : weight f = \sum_(x : finsupp f) f (val x).
Proof. by []. Qed.

Lemma weight0 : weight 0 = 0.
Proof. by apply: big1 => -[/= x _ _]; rewrite fsfunwE. Qed.

Lemma weightD f g : weight (f + g) = weight f + weight g.
Proof.
pose E := (finsupp f `|` finsupp g)%fset.
rewrite !(@weightwE E) 1?(fsubsetUl, fsubsetUr, supp_fsD) // {}/E.
by rewrite -big_split /=; apply: eq_bigr=> -[/= x _ _]; rewrite fsaddE.
Qed.
End Weight.

(* -------------------------------------------------------------------- *)
Section Comb.
Context {T : choiceType} {R : numDomainType}.

Implicit Types (w : {fsfun T ~> R}).

Definition conic  w := [forall x : finsupp w, 0 <= w (val x)].
Definition convex w := conic w && (weight w == 1).

Lemma conicP w :
  reflect (forall x, x \in finsupp w -> 0 <= w x) (conic w).
Proof. apply: (iffP forallP) => /= [h x|h].
+ by move=> xw; apply: (h (Sub x xw)).
+ by case=> [/= x xw]; apply: h.
Qed.

Lemma convexP w :
  reflect
    [/\ forall x, x \in finsupp w -> 0 <= w x & weight w = 1]
    (convex w).
Proof. by apply: (iffP andP); case=> /conicP h /eqP ->; split. Qed.

Lemma convex_conic w : convex w -> conic w.
Proof. by case/andP. Qed.

Lemma conicwP w : reflect (forall x, 0 <= w x) (conic w).
Proof. apply: (iffP idP).
+ by move/conicP=> h x; case: (finsuppP w x) => // /h.
+ by move=> h; apply/conicP=> x _; apply: h.
Qed.

Lemma conic0 : conic 0.
Proof. by apply/conicP=> x; rewrite fsfunwE. Qed.

Lemma conicD w1 w2 : conic w1 -> conic w2 -> conic (w1 + w2).
Proof.
move=> /conicwP h1 /conicwP h2; apply/conicwP=> x.
by rewrite fsfunwE addr_ge0.
Qed.

Lemma conic_finsuppE x w : conic w -> (x \in finsupp w) = (0 < w x).
Proof.
by move=> /conicwP h; rewrite ltr_neqAle h andbT eq_sym; apply: mem_finsupp.
Qed.

Lemma conic_weight_ge0 w : conic w -> 0 <= weight w.
Proof. by move/conicwP=> ge0_w; rewrite weightE; apply: sumr_ge0. Qed.
End Comb.

(* -------------------------------------------------------------------- *)
Section SubConic.
Context {T : choiceType} {R : numDomainType}.

Record conicFun := mkConicFun
  { conic_val :> {fsfun T ~> R}; _ : conic conic_val }.

Canonical conicfun_subType := Eval hnf in [subType for conic_val].
Definition conicfun_eqMixin := [eqMixin of conicFun by <:].
Canonical conicfun_eqType := Eval hnf in EqType conicFun conicfun_eqMixin.
Definition conicfun_choiceMixin := [choiceMixin of conicFun by <:].
Canonical conicfun_choiceType :=
  Eval hnf in ChoiceType conicFun conicfun_choiceMixin.

Definition conicfun_of (_ : phant T) (_ : phant R) := conicFun.
Identity Coercion type_of_conicfun : conicfun_of >-> conicFun.
End SubConic.

Notation "{ 'conic' T ~> R }" :=
  (conicfun_of (Phant T) (Phant R)) : type_scope.

Bind Scope conicfun_scope with conicFun.
Bind Scope conicfun_scope with conicfun_of.

Delimit Scope conicfun_scope with cof.

(* -------------------------------------------------------------------- *)
Section SubConicTheory.
Context {T : choiceType} {R : realDomainType}.

Canonical conicfun_of_subType    := Eval hnf in [subType    of {conic T ~> R}].
Canonical conicfun_of_eqType     := Eval hnf in [eqType     of {conic T ~> R}].
Canonical conicfun_of_choiceType := Eval hnf in [choiceType of {conic T ~> R}].

Implicit Types (w : {conic T ~> R}).

Lemma fconicP w1 w2 : w1 =1 w2 <-> w1 = w2.
Proof. by rewrite fsfunP (rwP val_eqP) (rwP eqP). Qed.

Lemma gt0_fconic w x : x \in finsupp w -> 0 < w x.
Proof. by rewrite conic_finsuppE // (valP w). Qed.

Lemma ge0_fconic w x : 0 <= w x.
Proof. by move/conicwP: (valP w); apply. Qed.

(* We have to lock the definitions *)
Definition conicf0 : {conic T ~> R} :=
  nosimpl (mkConicFun conic0).

Definition conicfD : _ -> _ -> {conic T ~> R} :=
  nosimpl (fun w1 w2 => mkConicFun (conicD (valP w1) (valP w2))).

Notation "0 %:PFS" := conicf0 : conicfun_scope.
Notation "f + g" := (conicfD f g) : conicfun_scope.

Lemma fconic0E x : (0%:PFS)%cof x = 0.
Proof. by rewrite fsfunwE. Qed.

Lemma fconicDE w1 w2 x : (w1 + w2)%cof x = w1 x + w2 x.
Proof. by rewrite fsfunwE. Qed.

Definition fconicwE := (fconic0E, fconicDE).

Lemma conic_comoid_r :
  [/\ associative conicfD
    , left_id conicf0 conicfD
    , right_id conicf0 conicfD
    & commutative conicfD].
Proof. split.
+ by move=> w1 w2 w3; apply/fconicP => x; rewrite !fconicwE addrA.
+ by move=> w; apply/fconicP => x; rewrite !fconicwE add0r.
+ by move=> w; apply/fconicP => x; rewrite !fconicwE addr0.
+ by move=> w1 w2; apply/fconicP => x; rewrite !fconicwE addrC.
Qed.

Let addpA := let: And4 h _ _ _ := conic_comoid_r in h.
Let add0p := let: And4 _ h _ _ := conic_comoid_r in h.
Let addp0 := let: And4 _ _ h _ := conic_comoid_r in h.
Let addpC := let: And4 _ _ _ h := conic_comoid_r in h.

Canonical conic_monoid := Monoid.Law addpA add0p addp0.
Canonical conic_comoid := Monoid.ComLaw addpC.

Lemma mem_coffinsupp w x : (x \in finsupp w) = (0 < w x).
Proof. by rewrite mem_finsupp ltr_neqAle eq_sym ge0_fconic andbT. Qed.

Lemma coffinsupp0 : finsupp (0%:PFS)%cof = fset0.
Proof. by rewrite supp_fs0. Qed.

Lemma coffinsuppD w1 w2 :
  finsupp (w1 + w2)%cof = (finsupp w1 `|` finsupp w2)%fset.
Proof.
apply/fsetP=> x; rewrite in_fsetE !mem_coffinsupp fconicwE.
have := ge0_fconic w1 x; rewrite ler_eqVlt => /orP[].
+ by move/eqP=> <-; rewrite ltrr add0r. 
+ by move=> gt0_w1; rewrite gt0_w1 ltr_paddr // ge0_fconic.
Qed.

Lemma ge0_cofweight w : 0 <= weight w.
Proof. by apply/conic_weight_ge0/valP. Qed.
End SubConicTheory.

Notation "0 %:PFS" := conicf0 : conicfun_scope.
Notation "f + g" := (conicfD f g) : conicfun_scope.

(* -------------------------------------------------------------------- *)
Section SubConvex.
Context {T : choiceType} {R : numDomainType}.

Record convexFun := mkConvexfun
  { convex_val :> {fsfun T ~> R}; _ : convex convex_val }.

Canonical convexfun_subType := Eval hnf in [subType for convex_val].
Definition convexfun_eqMixin := [eqMixin of convexFun by <:].
Canonical convexfun_eqType := Eval hnf in EqType convexFun convexfun_eqMixin.
Definition convexfun_choiceMixin := [choiceMixin of convexFun by <:].
Canonical convexfun_choiceType :=
  Eval hnf in ChoiceType convexFun convexfun_choiceMixin.

Definition convexfun_of (_ : phant T) (_ : phant R) := convexFun.
Identity Coercion type_of_convexfun : convexfun_of >-> convexFun.
End SubConvex.

Notation "{ 'convex' T ~> R }" :=
  (convexfun_of (Phant T) (Phant R)) : type_scope.

Bind Scope convexfun_scope with convexFun.
Bind Scope convexfun_scope with convexfun_of.

Delimit Scope convexfun_scope with cvf.

(* -------------------------------------------------------------------- *)
Section SubConvexTheory.
Context {T : choiceType} {R : realDomainType}.

Canonical convexfun_of_subType    := Eval hnf in [subType    of {convex T ~> R}].
Canonical convexfun_of_eqType     := Eval hnf in [eqType     of {convex T ~> R}].
Canonical convexfun_of_choiceType := Eval hnf in [choiceType of {convex T ~> R}].

Implicit Types (w : {convex T ~> R}).

Lemma fconvexP w1 w2 : w1 =1 w2 <-> w1 = w2.
Proof. by rewrite fsfunP (rwP val_eqP) (rwP eqP). Qed.

Lemma conic_fconvex w : conic w.
Proof. by apply/convex_conic/valP. Qed.

Lemma convex_fconvex w : convex w.
Proof. by apply/valP. Qed.

Lemma gt0_fconvex w x : x \in finsupp w -> 0 < w x.
Proof. by rewrite conic_finsuppE //; apply/conic_fconvex. Qed.

Lemma ge0_fconvex w x : 0 <= w x.
Proof. by move/conicwP: (conic_fconvex w); apply. Qed.

Lemma ge0_cvweight w : 0 <= weight w.
Proof. by apply/conic_weight_ge0/conic_fconvex. Qed.
End SubConvexTheory.