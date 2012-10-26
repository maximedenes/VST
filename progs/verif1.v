Require Import msl.Coqlib2.
Require Import veric.SeparationLogic.
Require Import compcert.Ctypes.
Require veric.SequentialClight.
Import SequentialClight.SeqC.CSL.
Require Import progs.field_mapsto.
Require Import progs.client_lemmas.
Require Import progs.assert_lemmas.
Require Import progs.forward.
Require Import progs.list.

Local Open Scope logic.

Require progs.test1.
Module P := progs.test1.

Local Open Scope logic.

Instance t_list_spec: listspec P.t_listptr.
Proof.
econstructor.
reflexivity.
intro Hx; inv Hx.
intros.
unfold unroll_composite; simpl.
reflexivity.
econstructor; simpl; reflexivity.
Defined.

Definition ilseg (s: list int) := lseg P.t_listptr (map Vint s).

Definition ilseg_nil (l: list  int) x z : mpred := !! (ptr_eq x z) && !! (l=nil) && emp.
Definition ilseg_cons (s: list int) := lseg_cons P.t_listptr (map Vint s).

Lemma ilseg_unroll: forall l x z , 
    ilseg l x z = ilseg_nil l x z || ilseg_cons l x z.
Proof.
intros.
unfold ilseg at 1.
rewrite lseg_unroll.
unfold ilseg_cons, ilseg_nil, ilseg.
f_equal.
f_equal. f_equal.
f_equal.
apply prop_ext; split; intro; destruct l; simpl in *; congruence.
Qed.

Lemma ilseg_eq: forall s p, 
   typecheck_val p P.t_listptr = true -> 
    (ilseg s p p = !!(s=nil) && emp).
Proof. intros. unfold ilseg. rewrite lseg_eq; auto. f_equal. f_equal.
 apply prop_ext. destruct s; simpl; intuition congruence.
Qed.
Hint Rewrite ilseg_eq : normalize.

Lemma ilseg_nonnull:
  forall s v,
      typed_true P.t_listptr v ->
     ilseg s v nullval = ilseg_cons s v nullval.
Proof.
intros. subst. 
rewrite ilseg_unroll.
unfold ilseg_cons, ilseg_nil.
apply pred_ext; normalize.
apply orp_left; auto. normalize.
unfold typed_true, strict_bool_val,ptr_eq in *.
destruct v; simpl in *; try contradiction.
rewrite H0 in H. inv H.
intros.
normalize.
apply orp_right2.
assert (~ ptr_eq v nullval).
intro. unfold typed_true,ptr_eq in *. destruct v; simpl in *; auto.
rewrite H0 in H; inv H.
normalize.
Qed.

Lemma ilseg_nil_eq: forall p q, ilseg nil p q = !! (ptr_eq p q) && emp.
Proof. intros.
 rewrite ilseg_unroll.
 apply pred_ext.
 apply orp_left.
 unfold ilseg_nil.  normalize.
 unfold ilseg_cons. normalize. unfold lseg_cons. normalize. intros. inv H0.
 apply orp_right1. unfold ilseg_nil. normalize.
Qed.
Hint Rewrite ilseg_nil_eq : normalize.

Lemma lift2_ilseg_cons: 
 forall s p q, lift2 (ilseg_cons s)  p q =
    local (lift2 ptr_neq p q) &&
    EX h:int, EX r: list int, EX y: val,
      !! (s = h::r) &&
      lift2 (field_mapsto Share.top list_struct list_data) p (lift0 (Vint h)) *
      lift2 (field_mapsto Share.top list_struct list_link) p (lift0 y) *
      |> lift2 (ilseg r) (lift0 y) q.
Proof.
 intros.
 unfold ilseg_cons, lseg_cons, lift2. extensionality rho. simpl.
 unfold local, lift1. unfold ptr_neq. f_equal.
 unfold ilseg.
 apply pred_ext; normalize.
 intros. destruct s; inv H. apply exp_right with i. apply exp_right with s.
 apply exp_right with x1. normalize.
 intros. apply exp_right with (Vint x). apply exp_right with (map Vint x0).
 apply exp_right with x1. normalize.
 apply andp_right; auto.
 forget (field_mapsto Share.top list_struct P.i_h (p rho) (Vint x) ) as A.
 forget (|>lseg P.t_listptr (map Vint x0) x1 (q rho)) as B.
 erewrite (field_mapsto_typecheck_val); try reflexivity.
 normalize.
 apply prop_right.
 replace P.t_listptr with (type_of_field
         (unroll_composite_fields list_structid list_struct
            (Fcons list_data list_dtype
               (Fcons list_link (Tcomp_ptr list_structid noattr) Fnil)))
         P.i_t); auto.
 type_of_field_tac.
Qed.
(* Hint Rewrite lift2_ilseg_cons : normalize. *)

Definition sumlist_spec :=
 DECLARE P.i_sumlist
  WITH contents 
  PRE [ P.i_p : P.t_listptr]  lift2 (ilseg contents) (eval_id P.i_p) (lift0 nullval)
  POST [ P.t_int ]  local (lift1 (eq (Vint (fold_right Int.add Int.zero contents))) retval).

Definition reverse_spec :=
 DECLARE P.i_reverse
  WITH contents : list int
  PRE  [ P.i_p : P.t_listptr ] lift2 (ilseg contents) (eval_id P.i_p) (lift0 nullval)
  POST [ P.t_listptr ] lift2 (ilseg (rev contents)) retval (lift0 nullval).

Definition main_spec := (P.i_main, mk_funspec (nil, P.t_int) _ (main_pre P.prog) (main_post P.prog)).

Definition Gprog : funspecs := 
   sumlist_spec :: reverse_spec :: main_spec::nil.

Definition partial_sum (contents cts: list int) (v: val) := 
     fold_right Int.add Int.zero contents = Int.add (force_int  v) (fold_right Int.add Int.zero cts).

Definition sumlist_Inv (contents: list int) : assert :=
          (EX cts: list int, 
            PROP () LOCAL ((* lift1 (tc_val P.t_int) (eval_id P.i_s); *)
                                     lift1 (partial_sum contents cts) (eval_id P.i_s)) 
            SEP (TT * lift2 (ilseg cts) (eval_id P.i_t) (lift0 nullval))).

Ltac start_function :=
match goal with |- semax_body _ _ ?spec => try unfold spec end;
match goal with |- semax_body _ _ (pair _ (mk_funspec _ _ ?Pre _)) =>
  match Pre with fun i => _ => intro i end;
  simpl fn_body; simpl fn_params; simpl fn_return;
  normalize; canonicalize_pre
 end.


Opaque sepcon.
Opaque emp.
Opaque andp.

Lemma lower_PROP_LOCAL_SEP:
  forall P Q R rho, PROPx P (LOCALx Q (SEPx R)) rho = 
     (!!fold_right and True P && (local (fold_right (lift2 and) (lift0 True) Q) && (fold_right sepcon emp R))) rho.
Proof. reflexivity. Qed.
Hint Rewrite lower_PROP_LOCAL_SEP : normalize.

Ltac go_lower' := let rho := fresh "rho" in intro rho; normalize.

Lemma lower_TT: forall rho, @TT assert Nassert rho = @TT mpred Nveric.
Proof. reflexivity. Qed.
Hint Rewrite lower_TT : normalize.

Lemma lower_FF: forall rho, @FF assert Nassert rho = @FF mpred Nveric.
Proof. reflexivity. Qed.
Hint Rewrite lower_FF : normalize.

Lemma body_sumlist: semax_body Gprog P.f_sumlist sumlist_spec.
Proof.
start_function.     
forward.
forward.
forward_while (sumlist_Inv contents)
    (PROP() LOCAL (lift1 (fun v => fold_right Int.add Int.zero contents = force_int v) (eval_id P.i_s))SEP(TT)).
(* Prove that current precondition implies loop invariant *)
unfold sumlist_Inv.
apply exp_right with contents.
go_lower'.
rewrite H0. rewrite H1. unfold partial_sum.
rewrite Int.add_zero_l. normalize.
rewrite sepcon_comm.
apply sepcon_TT.
(* Prove that loop invariant implies typechecking condition *)
normalizex.
(* Prove that invariant && not loop-cond implies postcondition *)
unfold sumlist_Inv.
go_lower'. intros.
unfold partial_sum in H0;  rewrite H0.
rewrite (typed_false_ptr H).
normalize.
(* Prove that loop body preserves invariant *)
unfold sumlist_Inv at 1.
normalize.
apply extract_exists_pre; intro cts.
normalize.
replace_in_pre (ilseg cts) (ilseg_cons cts).
rewrite ilseg_nonnull by auto. auto.
rewrite lift2_ilseg_cons.
normalizex. intro h.
normalizex. intro r.
normalizex. intro y.
normalizex. subst cts.
simpl list_data; simpl list_link.
(*
match goal with
 | |- semax ?Delta (PROPx ?P (LOCALx ?Q (SEPx ?R)))
                  (Ssequence (Sset _ (Efield (Ederef ?e _) ?fld _)) _) _ =>
  apply (semax_pre (PROPx P (LOCALx (tc_expr Delta e :: Q) (SEPx R))));
   [ go_lower 
   |isolate_field_tac e fld R (*;  hoist_later_in_pre;
     eapply semax_seq; [ apply sequential'; semax_field_tac1  
                                          | simpl update_tycon; apply extract_exists_pre
                                          ]
*)
    ]
end.
*)
forward.
forward.  intro old_t.
forward.
(* Prove postcondition of loop body implies loop invariant *)
normalize.
intro x; unfold sumlist_Inv.
 apply exp_right with r.
go_lower'.
simpl in H0.
autorewrite with normalize in H0.
rewrite H0.
unfold partial_sum in *.
simpl in H4. rewrite H4. clear H4. rewrite <- H1. clear H1.
assert (tc_val P.t_int (eval_id P.i_s rho)) by (eapply tc_eval_id_i; eauto).
destruct (tc_val_extract_int _ _ _ _ H1) as [n ?].
rewrite H4 in *.
destruct x; inv H0.
simpl. normalize. rewrite Int.add_assoc. normalizex.
repeat rewrite <- sepcon_assoc.
apply sepcon_derives; auto.
normalize.
(* After the loop *)
forward.
go_lower'. simpl opt2list. simpl eval_exprlist. normalize.
apply andp_right; normalize.
eapply tc_eval_id_i; eauto.
rewrite H0.
assert (tc_val P.t_int (eval_id P.i_s rho)) by (eapply tc_eval_id_i; eauto).
destruct (eval_id P.i_s rho); inv H1; auto.
unfold retval; simpl. normalize.
Qed.

Definition reverse_Inv (contents: list int) : assert :=
          (EX cts1: list int, EX cts2 : list int,
            PROP (contents = rev cts1 ++ cts2) 
            LOCAL ()
            SEP (lift2 (ilseg cts1) (eval_id P.i_w) (lift0 nullval) *
                   lift2 (ilseg cts2) (eval_id P.i_v) (lift0 nullval))).

Lemma body_reverse: semax_body Gprog P.f_reverse reverse_spec.
Proof.
start_function.
forward.
go_lower'. simpl. normalize.
forward.
forward_while (reverse_Inv contents)
         (PROP() LOCAL () SEP( lift2 (ilseg (rev contents)) (eval_id P.i_w) (lift0 nullval))).
(* precondition implies loop invariant *)
unfold reverse_Inv.
go_lower.
apply exp_right with nil.
apply exp_right with contents.
normalize.
rewrite H0. rewrite H1.
simpl; normalize. 
(* loop invariant implies typechecking of loop condition *)
normalizex.
(* loop invariant (and not loop condition) implies loop postcondition *)
unfold reverse_Inv.
go_lower. intro cts2.
rewrite (typed_false_ptr H). 
normalize.
rewrite <- app_nil_end. rewrite rev_involutive. auto.
(* loop body preserves invariant *)
unfold reverse_Inv at 1.
normalize.
apply extract_exists_pre; intro cts.
normalize.
apply extract_exists_pre; intro cts2.
normalizex.
subst.
replace_in_pre (ilseg cts2) (ilseg_cons cts2).
   rewrite (ilseg_nonnull cts2) by auto. auto.
rewrite lift2_ilseg_cons.
normalizex. intro h.
normalizex; intro r.
normalizex; intro y.
normalizex; subst cts2.
simpl list_data; simpl list_link.
forward.
forward.
forward. intro old_w.
forward.
intros.
unfold reverse_Inv.
go_lower.
apply exp_right with (h::cts).
apply exp_right with r.
normalize.
simpl. rewrite app_ass.
simpl.
normalize.
rewrite (ilseg_unroll (h::cts)).
apply derives_trans with (ilseg_cons (h :: cts) (eval_id P.i_w rho) nullval *
    ilseg r (eval_id P.i_v rho) nullval).
unfold ilseg_cons, lseg_cons.
normalize. apply exp_right with (Vint h).
normalize. apply exp_right with (map Vint cts).
normalize. apply exp_right with old_w.
normalize. rewrite H0.
simpl list_data; simpl list_link.
repeat rewrite <- sepcon_assoc.
erewrite (field_mapsto_typecheck_val _ _ _ _ _ P.i_list _  noattr); [ | reflexivity].
type_of_field_tac.
normalize.
assert (eval_cast P.t_listptr P.t_listptr old_w = old_w)
  by (destruct old_w ; inv H3; simpl; auto).
rewrite H4 in *.
normalize.
repeat pull_right (field_mapsto Share.top P.t_list P.i_t (eval_id P.i_w rho) old_w).
apply sepcon_derives; auto.
repeat pull_right (field_mapsto Share.top list_struct P.i_h (eval_id P.i_w rho) (Vint h)).
apply sepcon_derives; auto.
rewrite sepcon_comm.
apply sepcon_derives; auto.
apply now_later.
apply sepcon_derives; auto.
apply orp_right2; auto.
(* after the loop *)
forward.
go_lower.
simpl.
apply andp_right; normalize.
apply prop_right.
eapply tc_eval_id_i; eauto.
unfold retval; normalize.
Qed.


Definition fun_assert_emp fsig A P Q v := emp && fun_assert fsig A P Q v.

Lemma substopt_unfold {A}: forall id v, @substopt A (Some id) v = @subst A id v.
Proof. reflexivity. Qed.
Lemma substopt_unfold_nil {A}: forall v (P:  environ -> A), substopt None v P = P.
Proof. reflexivity. Qed.
Hint Rewrite @substopt_unfold @substopt_unfold_nil : normalize.


Lemma get_result_unfold: forall id, get_result (Some id) = get_result1 id.
Proof. reflexivity. Qed.
Lemma get_result_None: get_result None = globals_only.
Proof. reflexivity. Qed.
Hint Rewrite get_result_unfold get_result_None : normalize.

Lemma semax_call': forall Delta A (Pre Post: A -> assert) (x: A) ret fsig a bl P Q R,
           match_fsig fsig bl ret = true ->
  semax Delta
         (PROPx P (LOCALx (tc_expr Delta a :: tc_exprlist Delta bl :: Q)
            (SEPx (lift1 (Pre x) ( (make_args' fsig (eval_exprlist bl))) ::
                      lift1 (fun_assert_emp fsig A Pre Post) (eval_expr a) :: R))))
          (Scall ret a bl)
          (normal_ret_assert 
            (EX old:val, 
              PROPx P (LOCALx (map (substopt ret (lift0 old)) Q) 
                (SEPx (lift1 (Post x) (get_result ret) :: map (substopt ret (lift0 old)) R))))).
Proof.
intros.
eapply semax_pre_post ; [ | | 
   apply (semax_call Delta A Pre Post x (PROPx P (LOCALx Q (SEPx R))) ret fsig a bl H )].
go_lower.
unfold fun_assert_emp.
repeat rewrite corable_andp_sepcon2 by apply corable_fun_assert.
normalize.
rewrite corable_sepcon_andp1 by apply corable_fun_assert.
apply andp_derives; auto.
rewrite sepcon_comm; auto.
intros.
normalize.
intro old.
apply exp_right with old; normalizex.
destruct ret; normalizex.
go_lower.
rewrite sepcon_comm; auto.
go_lower.
rewrite sepcon_comm; auto.
unfold substopt.
repeat rewrite list_map_identity.
normalize.
Qed.

Lemma semax_call1: forall Delta A (Pre Post: A -> assert) (x: A) id fsig a bl P Q R,
           match_fsig fsig bl (Some id) = true ->
  semax Delta
         (PROPx P (LOCALx (tc_expr Delta a :: tc_exprlist Delta bl :: Q)
            (SEPx (lift1 (Pre x) ( (make_args' fsig (eval_exprlist bl))) ::
                      lift1 (fun_assert_emp fsig A Pre Post) (eval_expr a) :: R))))
          (Scall (Some id) a bl)
          (normal_ret_assert 
            (EX old:val, 
              PROPx P (LOCALx (map (subst id (lift0 old)) Q) 
                (SEPx (lift1 (Post x) (get_result1 id) :: map (subst id (lift0 old)) R))))).
Proof.
intros.
apply semax_call'; auto.
Qed.

Lemma semax_fun_id':
      forall id fsig (A : Type) (Pre Post : A -> assert)
              Delta P Q R PostCond c
            (GLBL: (var_types Delta) ! id = None),
            (glob_types Delta) ! id = Some (Global_func (mk_funspec fsig A Pre Post)) ->
       semax Delta 
        (PROPx P (LOCALx Q (SEPx (lift1 (fun_assert_emp fsig A Pre Post)
                         (eval_lvalue (Evar id (Tfunction (type_of_params (fst fsig)) (snd fsig))))
                                                       :: R))))
                              c PostCond ->
       semax Delta (PROPx P (LOCALx Q (SEPx R))) c PostCond.
Proof.
intros. 
apply (semax_fun_id id fsig A Pre Post Delta); auto.
eapply semax_pre; [ | apply H0].
forget (eval_lvalue
                      (Evar id
                         (Tfunction (type_of_params (fst fsig)) (snd fsig)))) as f.
go_lower.
rewrite andp_comm.
unfold fun_assert_emp.
rewrite corable_andp_sepcon2 by apply corable_fun_assert.
rewrite emp_sepcon; auto.
Qed.


Ltac in_tac1 :=  ((left; reflexivity) || (right; in_tac1)).

Ltac semax_call_tac1 :=
match goal with 
 |- semax ?Delta (PROPx ?P (LOCALx ?Q (SEPx 
          (lift1 (fun_assert_emp ?fs ?A ?Pre ?Post) ?f :: ?R))))
        (Ssequence (Scall (Some ?id) ?a ?bl) _)
        _ =>
 let H := fresh in let x := fresh "x" in let F := fresh "F" in
      evar (x:A); evar (F: list assert); 
       let PR := fresh "Pre" in pose (PR := Pre);
     assert (H: lift1 (PR x)  (make_args' fs (eval_exprlist bl)) * SEPx F |-- SEPx R);
     [ | 
            apply semax_pre with (PROPx P
                (LOCALx (tc_expr Delta a :: tc_exprlist Delta bl :: Q)
                 (SEPx (lift1 (PR x)  (make_args' fs (eval_exprlist bl)) ::
                           lift1 (fun_assert_emp fs A Pre Post) f  :: F))));
              unfold F in *; clear F H
      ];
 idtac
 end.


Ltac semax_call_id_tac :=
  match goal with
   | |- semax _ _ (Scall _ (Eaddrof (Evar ?fid _) _) _) _ =>  
         eapply (semax_fun_id' fid) ; [ simpl; reflexivity | simpl; reflexivity | ]
   | |- semax _ _ (Ssequence (Scall _ (Eaddrof (Evar ?fid _) _) _) _) _ =>  
         eapply (semax_fun_id' fid) ; [ simpl; reflexivity | simpl; reflexivity | ]
  end.

Lemma body_main:  semax_body Gprog P.f_main main_spec.
Proof.
intro u.
simpl fn_body; simpl fn_params; simpl fn_return.
replace (main_pre P.prog u) with 
   (lift2 (ilseg (map Int.repr (1::2::3::nil))) (eval_expr (Eaddrof (Evar P.i_three P.t_list) P.t_listptr)) (lift0 nullval))
 by admit. (* must improve global var specifications *)
simpl fn_body; simpl fn_params; simpl fn_return.
normalize.
canonicalize_pre.
semax_call_id_tac.
semax_call_tac1.
go_lower. 
unfold Pre,x,F.
instantiate (2:= (Int.repr 1 :: Int.repr 2 :: Int.repr 3 :: nil)).
instantiate (1:=nil).
normalize.
go_lower.
repeat apply andp_right; try apply prop_right.
repeat split; simpl; hnf; auto.
admit.  (* can't find i_three in func_tycontext *)
unfold Pre. clear Pre.
rewrite sepcon_comm.
apply sepcon_derives; auto.
normalize.
eapply semax_seq; [ apply sequential' ; apply semax_call'| ].
unfold match_fsig; simpl; rewrite if_true; auto.
apply extract_exists_pre; normalize.
clear Pre. unfold x; clear x.

semax_call_id_tac.
semax_call_tac1.
unfold x; unfold F; apply sepcon_derives.
instantiate (1:= Int.repr 3 :: Int.repr 2 :: Int.repr 1 :: nil).
unfold Pre.
go_lower.
instantiate (1:=nil); auto.
normalize.
apply andp_right; normalize.
simpl; normalize.
apply andp_right.
intro rho; apply prop_right.
repeat split; hnf; auto.
normalize.
unfold Pre, x.
go_lower.
rewrite sepcon_comm.
apply sepcon_derives; auto.
eapply semax_seq; [ apply sequential' ; apply semax_call' | ].
unfold match_fsig; simpl; rewrite if_true; auto.
apply extract_exists_pre; intro old.
normalize. clear old.
forward.
go_lower.
eapply tc_eval_id_i; eauto.
Qed.

Lemma all_funcs_correct:
  semax_func Gprog (prog_funct P.prog) Gprog.
Proof.
unfold Gprog, P.prog.
apply semax_func_cons; [ reflexivity | apply body_sumlist | ].
apply semax_func_cons; [ reflexivity | apply body_reverse | ].
apply semax_func_cons; [ reflexivity | apply body_main | ].
apply semax_func_nil.
Qed.

