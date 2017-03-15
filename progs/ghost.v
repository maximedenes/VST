(* This probably doesn't belong in progs. Talk to Santiago about where it should go. *)
Require Import progs.conclib.

Class PCM (A : Type) :=
  { join : A -> A -> A -> Prop;
    join_comm : forall a b c (Hjoin : join a b c), join b a c;
    join_assoc : forall a b c d e (Hjoin1 : join a b c) (Hjoin2 : join c d e),
                 exists c', join b d c' /\ join a c' e }.

Section Ghost.

Context {CS : compspecs}.

Section PCM.

Context `{M : PCM}.

(* This is an overapproximation of IRIS's concept of view shift. *)
Definition view_shift A B := forall (Espec : OracleKind) D P Q R C P',
  semax D (PROPx P (LOCALx Q (SEPx (B :: R)))) C P' ->
  semax D (PROPx P (LOCALx Q (SEPx (A :: R)))) C P'.

Axiom view_shift_super_non_expansive : forall n P Q, compcert_rmaps.RML.R.approx n (!!view_shift P Q) =
  compcert_rmaps.RML.R.approx n (!!view_shift (compcert_rmaps.RML.R.approx n P) (compcert_rmaps.RML.R.approx n Q)).

Definition joins a b := exists c, join a b c.

Definition update a b := forall c, joins a c -> joins b c.

(* General PCM-based ghost state *)
Parameter ghost : forall (g : A) (p : val), mpred.

(*Axiom new_ghost : forall t v p (g : A), initial g ->
  view_shift (data_at Tsh t v p) (ghost Tsh g p * data_at Tsh t v p).*)

Axiom ghost_join : forall g1 g2 g p, join g1 g2 g -> ghost g1 p * ghost g2 p = ghost g p.
Axiom ghost_conflict : forall g1 g2 p, ghost g1 p * ghost g2 p |-- !!joins g1 g2.
Axiom ghost_update : forall g g' p, update g g' -> view_shift (ghost g p) (ghost g' p).
Axiom ghost_inj : forall p g1 g2 r1 r2 r
  (Hp1 : predicates_hered.app_pred (ghost g1 p) r1)
  (Hp1 : predicates_hered.app_pred (ghost g2 p) r2)
  (Hr1 : sepalg.join_sub r1 r) (Hr2 : sepalg.join_sub r2 r),
  r1 = r2 /\ g1 = g2.

Lemma ex_ghost_precise : forall p, precise (EX g : A, ghost g p).
Proof.
  intros ???? (? & ?) (? & ?) ??.
  eapply ghost_inj; eauto.
Qed.

Corollary ghost_precise : forall g p, precise (ghost g p).
Proof.
  intros.
  eapply derives_precise, ex_ghost_precise.
  intros ??; exists g; eauto.
Qed.

End PCM.

(* operations on PCMs *)

Section Ops.

Context {A B : Type} {MA : PCM A} {MB : PCM B}.

Instance prod_PCM : PCM (A * B) := { join a b c := join (fst a) (fst b) (fst c) /\ join (snd a) (snd b) (snd c) }.
Proof.
  - intros ??? (? & ?); split; apply join_comm; auto.
  - intros ????? (? & ?) (HA & HB).
    eapply join_assoc in HA; eauto.
    eapply join_assoc in HB; eauto.
    destruct HA as (c'a & ? & ?), HB as (c'b & ? & ?); exists (c'a, c'b); split; split; auto.
Defined.

(* Two different ways of adding a unit to a PCM. *)
Instance option_PCM : PCM (option A) := { join a b c :=
  match a, b, c with
  | Some a', Some b', Some c' => join a' b' c'
  | Some a', None, Some c' => c' = a'
  | None, Some b', Some c' => c' = b'
  | None, None, None => True
  | _, _, _ => False
  end }.
Proof.
  - destruct a, b, c; auto.
    apply join_comm.
  - destruct a, b, c, d, e; try contradiction; intros; subst;
      try solve [eexists (Some _); split; auto; auto]; try solve [exists None; split; auto].
    eapply join_assoc in Hjoin2; eauto.
    destruct Hjoin2 as (c' & ? & ?); exists (Some c'); auto.
Defined.

Instance exclusive_PCM : PCM (option A) := { join a b c := a = c /\ b = None \/ b = c /\ a = None }.
Proof.
  - tauto.
  - intros ????? [(? & ?) | (? & ?)]; subst; eauto.
Defined.

End Ops.

Global Instance share_PCM : PCM share := { join := sepalg.join }.
Proof.
  - intros; apply sepalg.join_comm; auto.
  - intros.
    eapply sepalg.join_assoc in Hjoin2; eauto.
    destruct Hjoin2; eauto.
Defined.

(* Instances of ghost state *)
Section GVar.

Context {A : Type}.

Lemma join_Bot : forall a b, sepalg.join a b Share.bot -> a = Share.bot /\ b = Share.bot.
Proof.
  intros ?? (? & ?).
  apply lub_bot_e; auto.
Qed.

Global Instance Var_PCM : PCM (share * A) := { join a b c := sepalg.join (fst a) (fst b) (fst c) /\
  (fst a = Share.bot /\ c = b \/ fst b = Share.bot /\ c = a \/ snd a = snd b /\ snd b = snd c) }.
Proof.
  - intros ??? (? & Hcase); split; [apply sepalg.join_comm; auto|].
    destruct Hcase as [? | [? | (-> & ?)]]; auto.
  - intros ????? (? & Hcase1) (Hj2 & Hcase2).
    eapply sepalg.join_assoc in Hj2; eauto.
    destruct Hj2 as (sh & Hj1' & Hj2').
    destruct Hcase2 as [(Hbot & ?) | [(Hbot & ?) | (? & He)]]; subst.
    + rewrite Hbot in H; apply join_Bot in H; destruct H as (Ha & Hb); rewrite Ha in *.
      assert (fst d = sh).
      { eapply sepalg.join_eq; eauto. }
      exists (sh, snd d); split; split; auto; destruct d; subst; auto.
    + rewrite Hbot in *; assert (fst b = sh).
      { eapply sepalg.join_eq; eauto. }
      exists (sh, snd b); split; split; auto; destruct b; subst; auto.
    + destruct Hcase1 as [(Hbot & ?) | [(Hbot & ?) | (? & ?)]]; subst.
      * exists (sh, snd b); split; split; auto; destruct b; subst; auto.
        rewrite Hbot in *; assert (fst e = sh).
        { eapply sepalg.join_eq; eauto. }
        destruct e; subst; simpl in *.
        rewrite He in *; auto.
      * exists (sh, snd d); split; split; auto.
        rewrite Hbot in *; assert (fst d = sh).
        { eapply sepalg.join_eq; eauto. }
        destruct d; auto.
      * rewrite <- He.
        exists (sh, snd d); split; split; auto; destruct d; simpl in *; subst; auto.
        replace (snd a) with (snd b) in *; auto.
Defined.

Lemma joins_id : forall a b, sepalg.joins (fst a) (fst b) -> snd a = snd b -> joins a b.
Proof.
  intros ?? (sh & ?) ?.
  exists (sh, snd a); simpl; auto.
Qed.

Definition ghost_var (sh : share) (v : A) p := ghost (sh, v) p.

Lemma ghost_var_share_join : forall sh1 sh2 sh v p, sepalg.join sh1 sh2 sh ->
  ghost_var sh1 v p * ghost_var sh2 v p = ghost_var sh v p.
Proof.
  intros; apply ghost_join; simpl; auto.
Qed.

Lemma unreadable_bot : ~readable_share Share.bot.
Proof.
  unfold readable_share, nonempty_share, sepalg.nonidentity.
  rewrite Share.glb_bot; auto.
Qed.

Lemma ghost_var_inj : forall sh1 sh2 v1 v2 p, readable_share sh1 -> readable_share sh2 ->
  ghost_var sh1 v1 p * ghost_var sh2 v2 p |-- !!(v1 = v2).
Proof.
  intros.
  eapply derives_trans; [apply ghost_conflict|].
  apply prop_left; intros (? & ? & [(? & ?) | [(? & ?) | (? & ?)]]); simpl in *; subst;
    try (exploit unreadable_bot; eauto; contradiction).
  apply prop_right; auto.
Qed.

Lemma join_Tsh : forall a b, sepalg.join Tsh a b -> b = Tsh /\ a = Share.bot.
Proof.
  intros ?? (? & ?).
  rewrite Share.glb_commute, Share.glb_top in H; subst; split; auto.
  apply Share.lub_bot.
Qed.

Lemma ghost_var_update : forall v p v', view_shift (ghost_var Tsh v p) (ghost_var Tsh v' p).
Proof.
  intros; apply ghost_update; intros ? (? & ? & Hcase); simpl in *.
  apply join_Tsh in H; destruct H as (? & Hbot).
  exists (Tsh, v'); simpl; split; auto.
  rewrite Hbot; auto.
Qed.

Lemma ghost_var_precise : forall sh p, precise (EX v : A, ghost_var sh v p).
Proof.
  intros; eapply derives_precise, ex_ghost_precise.
  intros ? (x & ?); exists (sh, x); eauto.
Qed.

Lemma ghost_var_precise' : forall sh v p, precise (ghost_var sh v p).
Proof.
  intros; apply derives_precise with (Q := EX v : A, ghost_var sh v p);
    [exists v; auto | apply ghost_var_precise].
Qed.

End GVar.

Section Reference.
(* One common kind of PCM is one in which a central authority has a reference copy, and clients pass around
   partial knowledge. When a client recovers all pieces, it can gain full knowledge. *)

Context `{P : PCM}.

Instance pos_PCM : PCM (option (share * A)) := { join a b c :=
  match a, b, c with
  | Some (sha, a'), Some (shb, b'), Some (shc, c') =>
      sha <> Share.bot /\ shb <> Share.bot /\ sepalg.join sha shb shc /\ join a' b' c'
  | Some (sha, a'), None, Some c' => sha <> Share.bot /\ c' = (sha, a')
  | None, Some (shb, b'), Some c' => shb <> Share.bot /\ c' = (shb, b')
  | None, None, None => True
  | _, _, _ => False
  end }.
Proof.
  - destruct a as [(?, ?)|], b as [(?, ?)|], c as [(?, ?)|]; auto.
    intros (? & ? & ? & ?); repeat (split; auto); apply join_comm; auto.
  - destruct a as [(?, ?)|], b as [(?, ?)|], c as [(?, ?)|], d as [(?, ?)|], e as [(?, ?)|]; try contradiction;
      intros; decompose [and] Hjoin1; decompose [and] Hjoin2;
      repeat match goal with H : (_, _) = (_, _) |- _ => inv H end;
      try solve [eexists (Some _); split; auto; auto]; try solve [exists None; split; auto].
    + destruct (@sepalg.join_assoc _ _ _ s s0 s2 s1 s3) as (sh' & ? & ?); auto.
      destruct (join_assoc a a0 a1 a2 a3) as (a' & ? & ?); auto.
      exists (Some (sh', a')); repeat (split; auto).
      intro; subst.
      exploit join_Bot; eauto; tauto.
    + exists (Some (s2, a2)); repeat (split; auto).
      intro; subst.
      exploit join_Bot; eauto; tauto.
Defined.

Definition completable a r := exists x, join a x (Some (Tsh, r)).

Global Instance ref_PCM : PCM (option (share * A) * option A) :=
  { join a b c := join (fst a) (fst b) (fst c) /\ @join _ exclusive_PCM (snd a) (snd b) (snd c) /\
      match snd c with Some r => completable (fst c) r | None => True end }.
Proof.
  - intros ??? (Hfst & Hsnd & ?).
    split; [|split]; try apply join_comm; auto.
  - intros ????? (Hfst1 & Hsnd1 & Hcase1) (Hfst2 & Hsnd2 & Hcase2).
    destruct (join_assoc _ _ _ _ _ Hfst1 Hfst2) as (c'1 & ? & Hc'1).
    destruct (join_assoc _ _ _ _ _ Hsnd1 Hsnd2) as (c'2 & ? & Hc'2).
    exists (c'1, c'2).
    destruct Hc'2 as [(He & ?) | (? & ?)]; subst; [repeat split; simpl; auto|].
    repeat split; try solve [simpl; auto].
    simpl snd; destruct (snd e); auto.
    unfold completable.
    destruct Hcase2 as (? & Hcase2).
    apply join_comm in Hc'1.
    destruct (join_assoc _ _ _ _ _ Hc'1 Hcase2) as (? & ? & ?); eauto.
Defined.

Lemma ref_sub : forall (sh : share) (a b : A) p,
  ghost (Some (sh, a), @None A) p * ghost (@None (share * A), Some b) p |--
    !!(if eq_dec sh Tsh then a = b else exists x, join a x b).
Proof.
  intros.
  eapply derives_trans; [apply ghost_conflict|].
  apply prop_left; intros (c & Hjoin & [(? & ?) | (Hc & ?)] & Hcompat); [discriminate | apply prop_right].
  rewrite <- Hc in Hcompat; destruct Hcompat as (c' & Hsub).
  simpl in Hjoin.
  destruct (fst c); [|contradiction].
  destruct Hjoin; subst.
  simpl in Hsub.
  destruct c' as [(?, ?)|].
  - destruct Hsub as (? & ? & Hsh & ?).
    if_tac; eauto; subst.
    apply join_Tsh in Hsh; tauto.
  - destruct Hsub as (? & Hsub); inv Hsub.
    rewrite eq_dec_refl; auto.
Qed.

End Reference.

Section GHist.

(* Ghost histories in the style of Nanevsky *)
Context {hist_el : Type}.

Notation hist_part := (list (nat * hist_el)).

Require Import Sorting.Permutation.

Definition disjoint (h1 h2 : hist_part) := forall n e, In (n, e) h1 -> forall e', ~In (n, e') h2.

Lemma disjoint_nil : forall l, disjoint l [].
Proof.
  repeat intro; contradiction.
Qed.
Hint Resolve disjoint_nil.

Lemma disjoint_comm : forall a b, disjoint a b -> disjoint b a.
Proof.
  intros ?? Hdisj ?? Hin ? Hin'.
  eapply Hdisj; eauto.
Qed.

Lemma disjoint_app : forall a b c, disjoint (a ++ b) c <-> disjoint a c /\ disjoint b c.
Proof.
  split.
  - intro; split; repeat intro; eapply H; eauto; rewrite in_app; eauto.
  - intros (Ha & Hb) ?????.
    rewrite in_app in H; destruct H; [eapply Ha | eapply Hb]; eauto.
Qed.

Require Import Morphisms.

Global Instance Permutation_disjoint :
  Proper (@Permutation _ ==> @Permutation _ ==> iff) disjoint.
Proof.
  intros ?? Hp1 ?? Hp2.
  split; intro Hdisj; repeat intro.
  - eapply Hdisj; [rewrite Hp1 | rewrite Hp2]; eauto.
  - eapply Hdisj; [rewrite <- Hp1 | rewrite <- Hp2]; eauto.
Qed.

Instance map_PCM : PCM hist_part := { join a b c := disjoint a b /\ Permutation (a ++ b) c }.
Proof.
  - intros ??? (Hdisj & ?); split.
    + apply disjoint_comm; auto.
    + etransitivity; [|eauto].
      apply Permutation_app_comm.
  - intros ????? (Hd1 & Hc) (Hd2 & He).
    rewrite <- Hc, disjoint_app in Hd2; destruct Hd2 as (Hd2 & Hd3).
    exists (b ++ d); repeat split; auto.
    + apply disjoint_comm; rewrite disjoint_app; split; apply disjoint_comm; auto.
    + etransitivity; [|eauto].
      rewrite app_assoc; apply Permutation_app_tail; auto.
Defined.

Definition hist_sub sh h hr := if eq_dec sh Tsh then h = hr
  else sh <> Share.bot /\ exists h', disjoint h h' /\ Permutation (h ++ h') hr.

(* up *)
Lemma comp_join_top : forall sh, sepalg.join sh (Share.comp sh) Tsh.
Proof.
  intro; pose proof (Share.comp1 sh).
  apply comp_parts_join with (L := sh)(R := Share.comp sh); auto;
    rewrite Share.glb_idem, Share.glb_top.
  - rewrite Share.comp2; auto.
  - rewrite Share.glb_commute, Share.comp2; auto.
Qed.

Lemma completable_alt : forall sh h hr, completable (Some (sh, h)) hr <-> hist_sub sh h hr.
Proof.
  unfold completable, hist_sub; intros; simpl; split.
  - intros ([(?, ?)|] & Hcase).
    + destruct Hcase as (? & ? & Hsh & ? & ?).
      if_tac; eauto.
      subst; apply join_Tsh in Hsh; tauto.
    + destruct Hcase as (? & Heq); inv Heq.
      rewrite eq_dec_refl; auto.
  - if_tac.
    + intro; subst; exists None; split; auto.
      apply Share.nontrivial.
    + intros (? & h' & ?); exists (Some (Share.comp sh, h')).
      split; auto.
      split.
      { intro Hbot; contradiction H.
        rewrite <- Share.comp_inv at 1.
        rewrite Hbot; apply comp_bot. }
      split; [apply comp_join_top | auto].
Qed.

Lemma hist_sub_snoc : forall sh h hr t' e (Hsub : hist_sub sh h hr) (Hfresh : ~In t' (map fst hr)),
  hist_sub sh (h ++ [(t', e)]) (hr ++ [(t', e)]).
Proof.
  unfold hist_sub; intros.
  if_tac; subst; auto.
  destruct Hsub as (? & h' & ? & Hperm); split; auto.
  exists h'; split.
  - rewrite disjoint_app; split; auto.
    intros ?? [Heq | ?]; [inv Heq | contradiction].
    intros ??; contradiction Hfresh; rewrite in_map_iff.
    do 2 eexists; [|rewrite <- Hperm, in_app; eauto]; auto.
  - rewrite <- app_assoc; etransitivity; [apply Permutation_app_head, Permutation_app_comm|].
    rewrite app_assoc; apply Permutation_app; auto.
Qed.

Definition ghost_hist (sh : share) (h : hist_part) p := (ghost (Some (sh, h), @None hist_part) p).

Definition hist_incl (h : hist_part) l := forall t e, In (t, e) h -> nth_error l t = Some e.

Definition hist_list (h : hist_part) l := forall t e, In (t, e) h <-> nth_error l t = Some e.

Lemma hist_list_inj : forall h l1 l2 (Hl1 : hist_list h l1) (Hl2 : hist_list h l2), l1 = l2.
Proof.
  unfold hist_list; intros; apply list_nth_error_eq.
  intro j; specialize (Hl1 j); specialize (Hl2 j).
  destruct (nth_error l1 j).
  - symmetry; rewrite <- Hl2, Hl1; auto.
  - destruct (nth_error l2 j); auto.
    specialize (Hl2 h0); rewrite Hl1 in Hl2; tauto.
Qed.

Definition ghost_ref l p := EX hr : hist_part, !!(hist_list hr l) &&
  ghost (@None (share * hist_part), Some hr) p.

Lemma hist_add : forall (sh : share) (h h' : hist_part) e p t' (Hfresh : ~In t' (map fst h')),
  view_shift (ghost (Some (sh, h), Some h') p) (ghost (Some (sh, h ++ [(t', e)]), Some (h' ++ [(t', e)])) p).
Proof.
  intros; apply ghost_update.
  intros (c1, c2) ((d1, d2) & Hjoin1 & [(<- & ?) | (? & ?)] & Hcompat); try discriminate.
  simpl in *.
  destruct c1 as [(shc, hc)|], d1 as [(?, ?)|]; try contradiction.
  - destruct Hjoin1 as (? & ? & ? & Hdisj & Hperm).
    rewrite completable_alt in Hcompat; unfold hist_sub in Hcompat.
    destruct (eq_dec s Tsh).
    + subst; exists (Some (Tsh, h' ++ [(t', e)]), Some (h' ++ [(t', e)])).
      repeat (split; simpl; auto).
      * rewrite disjoint_app; split; auto.
        intros ?? [Heq | ?]; [inv Heq | contradiction].
        intros ??; contradiction Hfresh; rewrite in_map_iff.
        do 2 eexists; [|rewrite <- Hperm, in_app; eauto]; auto.
      * rewrite <- app_assoc.
        etransitivity; [apply Permutation_app_head, Permutation_app_comm|].
        rewrite app_assoc; apply Permutation_app; auto.
      * rewrite completable_alt; apply hist_sub_snoc; auto.
        unfold hist_sub; rewrite eq_dec_refl; auto.
    + destruct Hcompat as (? & l' & ? & Hperm').
      exists (Some (s, h ++ hc ++ [(t', e)]), Some (h' ++ [(t', e)])); repeat (split; simpl; auto).
      * rewrite disjoint_app; split; auto.
        intros ?? [Heq | ?]; [inv Heq | contradiction].
        intros ??; contradiction Hfresh; rewrite in_map_iff.
        do 2 eexists; [|rewrite <- Hperm', in_app, <- Hperm, in_app; eauto]; auto.
      * rewrite <- app_assoc; apply Permutation_app_head, Permutation_app_comm.
      * rewrite completable_alt, app_assoc; apply hist_sub_snoc; auto.
        unfold hist_sub; if_tac; [contradiction n; auto|].
        split; auto; exists l'; split.
        { eapply Permutation_disjoint; eauto. }
        etransitivity; [|eauto].
        apply Permutation_app; auto.
  - simpl in H; destruct Hjoin1 as (? & Hjoin1); inv Hjoin1.
    exists (Some (sh, h ++ [(t', e)]), Some (h' ++ [(t', e)])); simpl; repeat (split; auto).
    rewrite completable_alt in *; apply hist_sub_snoc; auto.
Qed.

Lemma hist_next : forall h l (Hlist : hist_list h l), ~In (length l) (map fst h).
Proof.
  intros; rewrite in_map_iff; intros ((?, ?) & ? & Hin); simpl in *; subst.
  unfold hist_list in Hlist; rewrite Hlist in Hin.
  pose proof (nth_error_Some l (length l)) as (Hlt & _).
  exploit Hlt; [|omega].
  rewrite Hin; discriminate.
Qed.

Lemma hist_ref_join : forall sh h l p, sh <> Share.bot ->
  ghost_hist sh h p * ghost_ref l p =
  EX h' : hist_part, !!(hist_list h' l /\ hist_sub sh h h') && ghost (Some (sh, h), Some h') p.
Proof.
  unfold ghost_hist, ghost_ref; intros; apply mpred_ext.
  - Intros hr; Exists hr.
    eapply derives_trans; [apply prop_and_same_derives, ghost_conflict|].
    apply derives_extract_prop; intros (x & Hj1 & Hj2 & Hcompat).
    destruct Hj2 as [(? & ?) | (Hsnd & ?)]; [discriminate|].
    rewrite <- Hsnd in Hcompat; simpl in *.
    destruct (fst x); [destruct Hj1 as (_ & Heq); inv Heq | contradiction].
    assert (hist_sub sh h hr) by (rewrite <- completable_alt; auto).
    entailer!.
    erewrite ghost_join; eauto.
    simpl; auto.
  - Intros h'.
    Exists h'; entailer!.
    erewrite ghost_join; eauto.
    repeat (split; simpl; auto).
    rewrite completable_alt; auto.
Qed.

Lemma hist_incl_nil : forall h, hist_incl [] h.
Proof.
  repeat intro; contradiction.
Qed.

Lemma hist_list_nil : hist_list [] [].
Proof.
  split; [contradiction | rewrite nth_error_nil; discriminate].
Qed.

Lemma hist_list_snoc : forall h l e, hist_list h l -> hist_list (h ++ [(length l, e)]) (l ++ [e]).
Proof.
  unfold hist_list; intros.
  rewrite in_app; split.
  - intros [Hin | [Heq | ?]]; try contradiction.
    + rewrite H in Hin.
      rewrite nth_error_app1; auto.
      rewrite <- nth_error_Some, Hin; discriminate.
    + inv Heq; rewrite nth_error_app2, minus_diag; auto.
  - destruct (lt_dec t (length l)).
    + rewrite nth_error_app1 by auto.
      rewrite <- H; auto.
    + rewrite nth_error_app2 by omega.
      destruct (eq_dec t (length l)).
      * subst; rewrite minus_diag.
        intro Heq; inv Heq; simpl; auto.
      * destruct (t - length l)%nat eqn: Hminus; [omega | simpl; rewrite nth_error_nil; discriminate].
Qed.

Lemma hist_incl_permute : forall h1 h2 h' (Hincl : hist_incl h1 h') (Hperm : Permutation h1 h2),
  hist_incl h2 h'.
Proof.
  repeat intro.
  rewrite <- Hperm in H; auto.
Qed.

Lemma hist_sub_incl : forall sh h h', hist_sub sh h h' -> incl h h'.
Proof.
  unfold hist_sub; intros.
  destruct (eq_dec sh Tsh); [subst; apply incl_refl|].
  destruct H as (? & ? & ? & Hperm); repeat intro.
  rewrite <- Hperm, in_app; auto.
Qed.

Corollary hist_sub_list_incl : forall sh h h' l (Hsub : hist_sub sh h h') (Hlist : hist_list h' l),
  hist_incl h l.
Proof.
  unfold hist_list, hist_incl; intros.
  rewrite <- Hlist; eapply hist_sub_incl; eauto.
Qed.

Definition newer (l : hist_part) t := Forall (fun x => fst x < t)%nat l.

Lemma newer_trans : forall l t1 t2, newer l t1 -> (t1 <= t2)%nat -> newer l t2.
Proof.
  intros.
  eapply Forall_impl, H; simpl; intros; omega.
Qed.

Corollary newer_snoc : forall l t1 e t2, newer l t1 -> (t1 < t2)%nat -> newer (l ++ [(t1, e)]) t2.
Proof.
  unfold newer; intros.
  rewrite Forall_app; split; [|repeat constructor; auto].
  eapply newer_trans; eauto; omega.
Qed.

Variable (d : hist_el).

Definition ordered_hist h := forall i j (Hi : 0 <= i < j) (Hj : j < Zlength h),
  (fst (Znth i h (O, d)) < fst (Znth j h (O, d)))%nat.

Lemma ordered_nil : ordered_hist [].
Proof.
  repeat intro.
  rewrite Zlength_nil in *; omega.
Qed.

Lemma ordered_cons : forall t e h, ordered_hist ((t, e) :: h) ->
  Forall (fun x => let '(m, _) := x in t < m)%nat h /\ ordered_hist h.
Proof.
  unfold ordered_hist; split.
  - rewrite Forall_forall; intros (?, ?) Hin.
    apply In_Znth with (d0 := (O, d)) in Hin.
    destruct Hin as (j & ? & Hj).
    exploit (H 0 (j + 1)); try omega.
    { rewrite Zlength_cons; omega. }
    rewrite Znth_0_cons, Znth_pos_cons, Z.add_simpl_r, Hj by omega; auto.
  - intros; exploit (H (i + 1) (j + 1)); try omega.
    { rewrite Zlength_cons; omega. }
    rewrite !Znth_pos_cons, !Z.add_simpl_r by omega; auto.
Qed.

Lemma ordered_last : forall t e h (Hordered : ordered_hist h) (Hin : In (t, e) h)
  (Ht : Forall (fun x => let '(m, _) := x in m <= t)%nat h), last h (O, d) = (t, e).
Proof.
  induction h; [contradiction | simpl; intros].
  destruct a; apply ordered_cons in Hordered; destruct Hordered as (Ha & ?).
  inversion Ht as [|??? Hp]; subst.
  destruct Hin as [Hin | Hin]; [inv Hin|].
  - destruct h; auto.
    inv Ha; inv Hp; destruct p; omega.
  - rewrite IHh; auto.
    destruct h; auto; contradiction.
Qed.

Lemma ordered_snoc : forall h t e, ordered_hist h -> newer h t -> ordered_hist (h ++ [(t, e)]).
Proof.
  repeat intro.
  rewrite Zlength_app, Zlength_cons, Zlength_nil in Hj.
  rewrite app_Znth1 by omega.
  destruct (eq_dec j (Zlength h)).
  - rewrite Znth_app1; auto.
    apply Forall_Znth; auto; omega.
  - specialize (H i j).
    rewrite app_Znth1 by omega; apply H; auto; omega.
Qed.

End GHist.

Section AEHist.

(* These histories should be usable for any atomically accessed location. *)
Inductive AE_hist_el := AE (r : val) (w : val).

Fixpoint apply_hist a h :=
  match h with
  | [] => Some a
  | AE r w :: h' => if eq_dec r a then apply_hist w h' else None
  end.

Arguments eq_dec _ _ _ _ : simpl never.

Lemma apply_hist_app : forall h1 i h2, apply_hist i (h1 ++ h2) =
  match apply_hist i h1 with Some v => apply_hist v h2 | None => None end.
Proof.
  induction h1; auto; simpl; intros.
  destruct a.
  destruct (eq_dec r i); auto.
Qed.

End AEHist.

Notation AE_hist := (list (nat * AE_hist_el)).

End Ghost.

Hint Resolve disjoint_nil hist_incl_nil hist_list_nil ordered_nil.
Hint Resolve ghost_var_precise ghost_var_precise'.