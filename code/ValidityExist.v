Require Import Notations.
Require Import Coq.Lists.List.
Require Import Coq.Arith.Le.
Require Import Coq.Numbers.Natural.Peano.NPeano.
Require Import Coq.Arith.Compare_dec.
Require Import Coq.omega.Omega.
Require Import Bool.Sumbool.
Require Import Bool.Bool.
Require Import Coq.Logic.ConstructiveEpsilon.
Require Import Permutation.
Require Import Coq.ZArith.ZArith.
Require Import ListLemma.
Require Import Psatz.               
Require Import Coq.Logic.Decidable.
Import ListNotations.

Notation "'existsT' x .. y , p" :=
  (sigT (fun x => .. (sigT (fun y => p)) ..))
    (at level 200, x binder, right associativity,
     format "'[' 'existsT' '/ ' x .. y , '/ ' p ']'") : type_scope.

Section Cand.
  Variable A : Type.
  Variable P : A -> A -> Z.
  Hypothesis Adec : forall (c d : A), {c = d} + {c <> d}.
  (* Our matrix is -1, 0, or 1 *)
  Hypothesis Pdec : forall (c d : A), {P c d = -1} + {P c d = 0} + {P c d = 1}.

  
  (* A is finite. finite : Type -> Type *)
  Definition finite := existsT (l : list A), forall (a : A), In a l.

  
  (* vl : forall A : Type, (P : A -> A -> Z) -> (list A) -> Prop *)
  Definition vl (l : list A) :=
    exists (f : A -> nat), forall (c d : A),
        In c l -> In d l ->
        ((P c d = 1 <-> (f c < f d)%nat) /\
         (P c d = 0 <-> (f c = f d)%nat) /\
         (P c d = -1 <-> (f c > f d)%nat)).

  
  Fixpoint listmax (f : A -> nat) (l : list A) : nat :=
    match l with
    | [] => O
    | [h] => f h
    | h :: t => max (f h) (listmax f t)
    end.


  Lemma listmax_upperbound :
    forall (l : list A) (d : A) (f : A -> nat) (Hin : In d l),
      (f d <= listmax f l)%nat.
  Proof.
    induction l.
    intros. inversion Hin.

    intros d f Hin.
    assert (Hm : {(f a >= listmax f l)%nat} + {(f a < listmax f l)%nat}).
    pose proof (lt_eq_lt_dec (f a) (listmax f l)) as H1.
    destruct H1 as [[H1 | H1] | H1]. right. auto.
    left. omega. left. omega.

    assert (Ht : listmax f (a :: l) = max (f a) (listmax f l)).
    simpl. destruct l. simpl. SearchAbout (max _ 0 = _).
    rewrite Max.max_0_r. auto. auto.

    rewrite Ht. clear Ht.
    destruct Hin. destruct Hm. rewrite H.
    apply Max.le_max_l.
    rewrite H. apply Max.le_max_l.
    destruct Hm.

    pose proof (IHl d f H).
    rewrite Max.max_l. omega. omega.
    rewrite Max.max_r.
    pose proof (IHl d f H).
    omega. omega.
  Qed.
 
   Lemma validity_after_remove_cand :
    forall (l : list A) (a0 : A),
      vl (a0 :: l) <->
      vl l /\ P a0 a0 = 0 /\
      (forall (c d e : A), In c (a0 :: l) -> In d (a0 :: l) -> In e (a0 :: l) ->
                      (P c d = 1 -> P d e = 1 -> P c e = 1) /\
                      (P c d = 1 -> P d e = 0 -> P c e = 1) /\
                      (P c d = 0 -> P d e = 1 -> P c e = 1) /\
                      (P c d = 0 -> P d e = 0 -> P c e = 0) /\
                      (P c d = 0 -> P d e = -1 -> P c e = -1) /\
                      (P c d = -1 -> P d e = 0 -> P c e = -1) /\
                      (P c d = -1 -> P d e = -1 -> P c e = -1)) /\
      (forall (c e : A), In c l -> In e l ->
                    (P c a0 = 1 -> P a0 e = 1 -> P c e = 1) /\
                    (P c a0 = 1 -> P a0 e = 0 -> P c e = 1) /\
                    (P c a0 = 0 -> P a0 e = 1 -> P c e = 1) /\
                    (P c a0 = 0 -> P a0 e = 0 -> P c e = 0) /\
                    (P c a0 = 0 -> P a0 e = -1 -> P c e = -1) /\
                    (P c a0 = -1 -> P a0 e = 0 -> P c e = -1) /\
                    (P c a0 = -1 -> P a0 e = -1 -> P c e = -1)) /\
      ((exists (a0' : A), In a0' l /\ forall (x : A), In x l ->
                                           (P a0 x = P a0' x) /\
                                           (P x a0 = P x a0')) \/
       (forall (x : A), In x l -> (P x a0 = 1 /\ P a0 x = -1)
                            \/ (P a0 x = 1 /\ P x a0 = -1))).
   Proof. 
     unfold vl; split; intros.
     destruct H as [f H].
     split.
     exists f.  intros. 
     specialize (H c d (or_intror H0) (or_intror H1)).
     assumption.
     (* P a0 a0 *)
     split.
     specialize (H a0 a0 (in_eq a0 l) (in_eq a0 l)).
     destruct H as [H1 [H2 H3]].
     specialize ((proj2 H2) eq_refl). intros. assumption.


     repeat (split; intros).
     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]].
     specialize ((proj1 H5) H3); intros.
     specialize ((proj1 H6) H4); intros.
     assert (f c < f e)%nat by lia.
     pose proof (H c e H0 H2). destruct H14.
     apply H14. assumption.

     
     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]]. 
     specialize ((proj1 H5) H3); intros.
     specialize ((proj1 H9) H4); intros.
     assert (f c < f e)%nat by lia.
     pose proof (H c e H0 H2). destruct H14.
     apply H14.  assumption.

     (* Learn bloody LTac *)

     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]].
     specialize ((proj1 H7) H3); intros.
     specialize ((proj1 H6) H4); intros.
     assert (f c < f e)%nat by lia.
     pose proof (H c e H0 H2). destruct H14.
     apply H14. assumption.

    
     
     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]].
     apply H7 in H3. apply H9 in H4.
     rewrite H4 in H3.
     pose proof (H c e H0 H2).
     destruct H11. destruct H12. apply H12.
     assumption.


     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]].
     apply H7 in H3. apply H10 in H4.
     assert (f c  > f e)%nat by lia.
     pose proof (H c e H0 H2).
     destruct H12.  destruct H13. apply H14.
     assumption.

     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]].
     apply H8 in H3. apply H9 in H4.
     assert (f c  > f e)%nat by lia.
     pose proof (H c e H0 H2).
     destruct H12.  destruct H13. apply H14.
     assumption.

     pose proof (H c d H0 H1).
     pose proof (H d e H1 H2).
     destruct H5 as [H5 [H7 H8]].
     destruct H6 as [H6 [H9 H10]].
     apply H8 in H3. apply H10 in H4.
     assert (f c  > f e)%nat by lia.
     pose proof (H c e H0 H2).
     destruct H12.  destruct H13. apply H14.
     assumption.

     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H6 in H2. apply H9 in H3.
     assert (f c < f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H5. assumption.

     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H6 in H2. apply H10 in H3.
     assert (f c < f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H5. assumption.



     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H7 in H2. apply H9 in H3.
     assert (f c < f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H5. assumption.

     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H7 in H2. apply H10 in H3.
     assert (f c = f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H12. assumption.


     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H7 in H2. apply H11 in H3.
     assert (f c > f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H13. assumption.


     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H8 in H2. apply H10 in H3.
     assert (f c > f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H13. assumption.


     pose proof (H c a0 (in_cons _ c l H0) (in_eq a0 l)).
     pose proof (H a0 e (in_eq a0 l) (in_cons _ e l H1)).
     destruct H4 as [H6 [H7 H8]].
     destruct H5 as [H9 [H10 H11]].
     apply H8 in H2. apply H11 in H3.
     assert (f c > f e)%nat by lia.
     pose proof (H c e (or_intror H0) (or_intror H1)).
     destruct H5. destruct H12.
     apply H13. assumption.


     assert (Hnat : forall x y : nat, {x = y} + {x <> y}) by (auto with arith).
     pose proof (in_dec Hnat (f a0) (map f l)).  clear Hnat.
     destruct H0.
     apply in_map_iff in i. destruct i as [a [Hl Hr]].
     (* I know the exitence of element which is in l and equal to f a0 *)
     left. exists a. split. assumption.
     intros x Hx. split.


     pose proof (H a0 x (in_eq a0 l) (or_intror Hx)).
     pose proof (H a x (or_intror Hr) (or_intror Hx)).
     destruct H0 as [[H2 H3] [[H5 H6] [H7 H8]]].
     destruct H1 as [[H9 H10] [[H11 H12] [H13 H14]]].
     pose proof (lt_eq_lt_dec (f a) (f x)).
     destruct H0. destruct s.
     pose proof (H10 l0). rewrite Hl in l0.
     pose proof (H3 l0). rewrite H0. rewrite H1. auto.
     pose proof (H12 e). rewrite Hl in e.
     pose proof (H6 e). rewrite H0, H1. auto.
     assert (f a > f x)%nat by lia.
     pose proof (H14 H0). rewrite Hl in H0.
     pose proof (H8 H0). rewrite H1, H4. auto.

     pose proof (H x a0 (or_intror Hx) (in_eq a0 l)).
     pose proof (H x a (or_intror Hx) (or_intror Hr)).
     destruct H0 as [[H2 H3] [[H5 H6] [H7 H8]]].
     destruct H1 as [[H9 H10] [[H11 H12] [H13 H14]]].
     pose proof (lt_eq_lt_dec (f a) (f x)).
     destruct H0. destruct s.
     assert (f x > f a)%nat by lia.
     pose proof (H14 H0). rewrite Hl in H0.
     pose proof (H8 H0). rewrite H1, H4. auto.
     assert (f x = f a)%nat by lia.
     pose proof (H12 H0). rewrite Hl in H0.
     pose proof (H6 H0). rewrite H1, H4. auto.
     pose proof (H10 l0). rewrite Hl in l0.
     pose proof (H3 l0). rewrite H0, H1. auto.

     (* time to go right *)
     right. intros x Hx.
     destruct (lt_eq_lt_dec (f a0) (f x)) as [[H1 | H1] | H1].
     pose proof (H a0 x (in_eq a0 l) (or_intror Hx)).
     right. split. firstorder. firstorder.

     (* f 0 can not be equal to f x *)
     unfold not in n. assert False. apply n.
     rewrite H1. Check in_map.
     pose proof (in_map f l x Hx). assumption.
     inversion H0.

     pose proof (H x a0 (or_intror Hx) (in_eq a0 l)).
     firstorder.
     
     (* finished first half of the proof *) 
     
     destruct H as [[f H1] [Ht [Hcd [Ht1 [[a [H2 H3]] | H2]]]]].  
     (* from H3 I know that f a = f a0  so I am going to supply same function  *)
     exists (fun c => if Adec c a0 then f a else f c). intros c d H4 H5. destruct H4, H5.  

     subst. firstorder.
     split.
     split; intros.
     subst. destruct (Adec c c); destruct (Adec d c); try congruence.
     pose proof (H3 d H0).
     destruct H. clear H5.
     assert (P a d = 1) by lia.
     pose proof (H1 a d H2 H0). firstorder.

     subst. destruct (Adec c c); destruct (Adec d c);
              try congruence; try lia.
     pose proof (H1 a d H2 H0). firstorder.

     split.
     split; intros.
     subst. destruct (Adec c c); destruct (Adec d c);
              try congruence; try lia.
     pose proof (H3 d H0). assert (P a d = 0) by lia.
     pose proof (H1 a d H2 H0).  firstorder.
     subst. destruct (Adec c c); destruct (Adec d c);
              try congruence; try lia.
     pose proof (H1 a d H2 H0).
     pose proof (H3 d H0).
     destruct H. destruct H6. apply H6 in H4.
     destruct H5. rewrite H4 in H5.  assumption.

     split; intros.
     subst. destruct (Adec c c); destruct (Adec d c);
              try congruence; try lia.
     pose proof (H3 d H0).
     pose proof (H1 a d H2 H0).
     assert (P a d = -1) by lia. firstorder.
     subst. destruct (Adec c c); destruct (Adec d c);
              try congruence; try lia.
     pose proof (H3 d H0).
     pose proof (H1 a d H2 H0).
     destruct H5. 
     destruct H6. apply H7 in H4.
     assert (P c d = -1) by lia.
     assumption.

     split.
     split; intros.
     subst. destruct (Adec c d); destruct (Adec d d);
              try congruence; try lia.
     pose proof (H3 c H). assert (P c a = 1) by lia.
     pose proof (H1 c a H H2). firstorder.
     subst. destruct (Adec c d); destruct (Adec d d);
              try congruence; try lia.
     pose proof (H3 c H).
     pose proof (H1 c a H H2).
     destruct H5. destruct H6.
     apply H5 in H4. destruct H0.
     rewrite H4 in H8. assumption.

     split.
     split; intros.
     subst. destruct (Adec c d); destruct (Adec d d); try congruence;
              try lia.
     pose proof (H3 c H).
     assert (P c a = 0) by lia.
     pose proof (H1 c a H H2). firstorder.
     subst. destruct (Adec c d); destruct (Adec d d);
              try congruence; try lia.
     pose proof (H3 c H). destruct H0.
     pose proof (H1 c a H H2). destruct H6.
     destruct H7. apply H7 in H4. rewrite H4 in H5.
     assumption.

     split; intros.
     subst. destruct (Adec c d); destruct (Adec d d); try congruence;
              try lia.
     pose proof (H3 c H).
     assert (P c a = -1) by lia.
     pose proof (H1 c a H H2). firstorder.
     subst. destruct (Adec c d); destruct (Adec d d);
              try congruence; try lia.
     pose proof (H3 c H). destruct H0.
     pose proof (H1 c a H H2). destruct H6.
     destruct H7. apply H8 in H4. rewrite H4 in H5.
     assumption.


     split. 
     split; intros. 
     subst. destruct (Adec c a0); destruct (Adec d a0); try congruence;
              try lia.
     subst. pose proof (H3 d H0).
     destruct H5. assert (P a d = 1) by lia.
     pose proof (H1 a d H2 H0).
     destruct H8. apply H8. assumption.
     subst. pose proof (H3 c H).
     destruct H5. assert (P c a = 1) by lia.
     pose proof (H1 c a H H2). destruct H8.
     apply H8. assumption.

     pose proof (H1 c d H H0). firstorder.
     destruct (Adec c a0); destruct (Adec d a0);
       try congruence; try lia.
     subst.
     pose proof (H1 a d H2 H0).
     pose proof (H3 d H0). destruct H6.
     destruct H5. destruct H8. apply H5 in H4.
     rewrite H4 in H6. assumption.

     subst. pose proof (H1 c a H H2).
     destruct H5. apply H5 in H4.
     pose proof (H3 c H). assert (P c a0 = 1) by lia.
     assumption.

     pose proof (H1 c d H H0). destruct H5.
     apply H5. assumption.


     split.
     split; intros.
     destruct (Adec c a0); destruct (Adec d a0);
       try congruence; try lia.
     subst. pose proof (H3 d H0).
     destruct H5. pose proof (H1 a d H2 H0).
     destruct H7. destruct H8. apply H8.
     rewrite H4 in H5. congruence.

     subst. pose proof (H3 c H).
     destruct H5.
     pose proof (H1 c a H H2).
     destruct H7. destruct H8.
     apply H8. rewrite H4 in H6.
     congruence.

     pose proof (H1 c d H H0). destruct H5.
     destruct H6. apply H6. assumption.
     destruct (Adec c a0); destruct (Adec d a0);
       try congruence; try lia.
     subst. pose proof (H3 d H0).
     destruct H5. pose proof (H1 a d H2 H0).
     destruct H7. destruct H8.
     apply H8 in H4. rewrite H4 in H5.
     assumption.

     subst. pose proof (H3 c H).
     destruct H5. pose proof (H1 c a H H2).
     destruct H7. destruct H8.
     apply H8 in H4. rewrite H4 in H6.
     assumption.

     pose proof (H1 c d H H0).
     destruct H5. destruct H6.
     apply H6. assumption.

     split; intros.
     destruct (Adec c a0); destruct (Adec d a0);
       try congruence; try lia.
     subst. pose proof (H3 d H0).
     destruct H5. pose proof (H1 a d H2 H0).
     destruct H7. destruct H8. apply H9.
     rewrite H4 in H5. congruence.

     subst. pose proof (H3 c H).
     destruct H5. pose proof (H1 c a H H2).
     destruct H7. destruct H8.
     apply H9. rewrite H4 in H6. congruence.

     pose proof (H1 c d H H0). destruct H5.
     destruct H6. apply H7. assumption.

     destruct (Adec c a0); destruct (Adec d a0);
       try congruence; try lia.
     subst. pose proof (H3 d H0).
     destruct H5. pose proof (H1 a d H2 H0).
     destruct H7. destruct H8.
     apply H9 in H4. rewrite H4 in H5. assumption.

     subst. pose proof (H1 c a H H2).
     destruct H5. destruct H6.
     pose proof (H3 c H). destruct H8.
     apply H7 in H4. rewrite H4 in H9.
     assumption.

     pose proof (H1 c d H H0). destruct H5.
     destruct H6. apply H7. assumption.

     (* finished equivalent function *)

     (* filter all elements which are more preffered over a0 in l *)
     remember (filter (fun x => if P x a0 =? 1 then true else false) l) as l1.
     (* filter all elements for which a0 is preferred *)
     remember (filter (fun x => if P a0 x =? 1 then true else false) l) as l2.
     assert (Ht2 : forall x, In x l1 -> P x a0 = 1 /\ P a0 x = -1).
     intros. rewrite Heql1 in H.
     pose proof (proj1 (filter_In _ _ _) H).
     destruct H0.  pose proof (H2 x H0).
     destruct H4. auto.  destruct H4. rewrite H5 in H3.
     simpl in H3. inversion H3.

     assert (Ht3 : forall x, In x l2 -> P a0 x = 1 /\ P x a0 = -1).
     intros. rewrite Heql2 in H.
     pose proof (proj1 (filter_In _ _ _) H).
     destruct H0. pose proof (H2 x H0). destruct H4.
     destruct H4. rewrite H5 in H3. simpl in H3. inversion H3.
     auto.

     remember (fun x => if P x a0 =? 1 then true else false) as f1.
     remember (fun x => if P a0 x =? 1 then true else false) as g1.
     assert (Ht4 : forall x, In x l -> f1 x = negb (g1 x)).
     intros. rewrite Heqf1. rewrite Heqg1.
     pose proof (H2 x H). destruct H0.
     destruct H0. rewrite H0. rewrite H3.
     simpl. auto.
     destruct H0. rewrite H3. rewrite H0.
     simpl. auto. 
     pose proof (complementary_filter_In _ l f1 g1 Ht4). 
     rewrite <- Heql1 in H. rewrite <- Heql2 in H.
 
     (* for a0,  take maximum of all the candidates which is preferred over
       a0 and add one to it.
       a1, a2 ......, a0, ....., an
       We don't need to change the values for candidates preferred over a0, but
       those who are less preferred over a0 should be shifted by 1 *)


     exists (fun x =>
              match Adec x a0 with
              | left _ =>
                plus (S O)
                     (listmax f (filter (fun y => if P y a0 =? 1 then true else false) l))
              | right _ =>
                if andb (if P a0 x =? 1 then true else false)
                        (if (in_dec Adec x l) then true else false)
                then plus (S (S O)) (f x)
                else  (f x)
              end).

     split.
     split; intros.
     destruct H0, H3.
     subst. 
     (* c = a0 and d = a0 *)
     congruence. 

     (* c = a0 and In d l *)
     rewrite <- H0. rewrite <- H0 in H4.
     destruct (Adec a0 a0).
     destruct (Adec d a0). congruence.
     rewrite H4. simpl.
     destruct (in_dec Adec d l).
     simpl. apply lt_n_S.

     clear e.  clear i. clear n.
     pose proof Permutation_in. 
     pose proof (H5 A l (l1 ++ l2) d H H3).
     apply in_app_iff in H6. destruct H6.
     pose proof (Ht2 d H6). firstorder.
     rewrite <- Heqf1.
     rewrite <- Heql1.
 
     assert (Ht5: forall x, In x l1 -> forall y, In y l2 -> (f x < f y)%nat).
     intros. apply H1.
     apply Permutation_sym in H. 
     pose proof (H5 A (l1 ++ l2) l y H). apply H9.
     firstorder.
     apply Permutation_sym in H.
     pose proof (H5 A (l1 ++ l2) l x H). apply H9.
     firstorder.
     apply Ht1.
     apply Permutation_sym in H.
     pose proof (H5 A (l1 ++ l2) l y H). apply H9.
     firstorder.
     apply Permutation_sym in H.
     pose proof (H5 A (l1 ++ l2) l x H). apply H9.
     firstorder. firstorder. firstorder.

     clear H. clear H5. clear Heql1. clear Ht2.
     induction l1. simpl. omega.
     simpl. destruct l1.
     pose proof (Ht5 a (in_eq a []) d H6). omega.
     apply Nat.max_lub_lt_iff. split.
     pose proof (Ht5 a (in_eq a (a1 :: l1)) d H6).
     omega. apply IHl1. firstorder.
     congruence. congruence.

     (* In c l and d = a0 *) 
     rewrite <- H3. rewrite <- H3 in H4.
     destruct (Adec c a0). destruct (Adec a0 a0).
     congruence. congruence. 

     pose proof (H2 c H0). destruct H5. destruct H5.
     rewrite H6. simpl. destruct (Adec a0 a0).
     simpl.
     clear n. clear e. 
     pose proof Permutation_in. pose proof (H7 A l (l1 ++ l2) c H H0).
     apply in_app_iff in H8. destruct H8.
     pose proof (Ht2 c H8).
     rewrite <- Heqf1.
     rewrite <- Heql1.

     clear H. clear Heql1. clear Ht2. clear H5.
     induction l1.
     inversion H8.
      
     simpl. destruct l1.
     destruct H8. rewrite H. omega. inversion H.
     pose proof (Max.max_dec (f a) (listmax f (a1 :: l1))).
     destruct H as [H | H].
     rewrite H.
     destruct H8. rewrite H5. omega.
     pose proof (IHl1 H5).
     apply Nat.max_l_iff in H. omega.
     rewrite H. destruct H8.
     rewrite <- H5.
     apply Nat.max_r_iff in H. omega.
     pose proof (IHl1 H5). assumption.
     firstorder. congruence.
     destruct H5. rewrite H5. simpl.
     destruct (Adec a0 a0). congruence.
     rewrite Ht. simpl. rewrite H4 in H6. inversion H6.
 
     (* In c l and In d l *)
     destruct (Adec c a0).
     destruct (Adec d a0).
     congruence. rewrite e in H0.
     pose proof (H2 a0 H0). firstorder.
     simpl. 
     pose proof (H2 c H0) as Htt.
     destruct Htt as [[Htt1 Htt2] | [Htt1 Htt2]].
     rewrite Htt2. simpl.
     destruct (Adec d a0).
     rewrite e in H3.
     pose proof (H2 a0 H3). firstorder.
     pose proof (H2 d H3) as Ht5.
     destruct Ht5 as [[Ht5 Ht6] | [Ht5 Ht6]].
     rewrite Ht6. simpl. firstorder.
     rewrite Ht5. simpl. destruct (in_dec Adec d l).
 
     pose proof (H2 c H0).
     pose proof (H2 d H3).
     destruct H5, H6.
     destruct H5. destruct H6. firstorder.
     destruct H5. destruct H6.
     pose proof (Ht1 c d H0 H3).
     destruct H9. specialize (H9 H5 H6).
     pose proof (H1 c d H0 H3). destruct H11.
     apply H11 in H9. lia.
     destruct H5. destruct H6. firstorder.
     destruct H5. congruence. congruence.
     rewrite Htt1. simpl.
     destruct (in_dec Adec c l).
     destruct (Adec d a0).
     apply lt_n_S. rewrite e in H4. rewrite H4 in Htt2.
     congruence.
     assert ((if in_dec Adec d l then true else false) = true).
     destruct (in_dec Adec d l). auto. congruence.
     rewrite H5. clear H5. simpl.
     pose proof (H2 d H3). destruct H5.
     destruct H5. rewrite H6. simpl.
     pose proof (Ht1 c d H0 H3).
     destruct H7. destruct H8. destruct H9.
     destruct H10. destruct H11. destruct H12.
     specialize (H13 Htt2 H6). rewrite H13 in H4.
     lia.
     destruct H5. rewrite H5. simpl.
     repeat (apply lt_n_S).
     pose proof (H1 c d H0 H3).
     destruct H7. apply H7. assumption.
     congruence.

     pose proof Permutation_in as Hp.
     destruct H0, H3.
     (* c = a0 and d = a0 *)
     rewrite <- H0 in H4.
     rewrite <- H3 in H4.
     omega.

     (* c = a0 and In d l *)
     rewrite <- H0 in H4.
     destruct (Adec a0 a0).
     destruct (Adec d a0). omega.
     pose proof (H2 d H3). destruct H5.
     destruct H5. rewrite H6 in H4. simpl in H4.
     rewrite <- Heqf1 in H4.
     rewrite <- Heql1 in H4.
     rewrite <- H0.
     pose proof (listmax_upperbound l1 d f).
     rewrite Heqf1 in Heql1.
     pose proof (Hp _ _ _ d H H3).
     apply in_app_iff in H8. destruct H8.
     specialize (H7 H8). omega.
     firstorder.
     destruct H5. rewrite H5 in H4. simpl in H4.
     assert ((if in_dec Adec d l then true else false) = true).
     destruct (in_dec Adec d l). auto. congruence.
     rewrite H7 in H4. clear H7.
     rewrite <- H0. auto.
     congruence.

     (* In c l and d = a0 *)
     rewrite <- H3 in H4. rewrite <- H3.
     destruct (Adec c a0).
     rewrite e in H0.
     pose proof (H2 a0 H0). firstorder.
     pose proof (H2 c H0) as Ht5.
     destruct Ht5 as [[Ht5 Ht6] | [Ht5 Ht6]].
     auto. rewrite Ht5 in H4. simpl in H4.
     assert ((if in_dec Adec c l then true else false) = true).
     destruct (in_dec Adec c l). auto. congruence.
     rewrite H5 in H4. clear H5.
     destruct (Adec a0 a0). simpl in H4.
     rewrite <- Heqf1 in H4. rewrite <- Heql1 in H4.
     apply lt_S_n in H4.  clear n.  clear e.
     pose proof (Hp A l (l1 ++ l2) c H H0).
     apply in_app_iff in H5. destruct H5. firstorder.


     assert (Htt5: forall x, In x l1 -> forall y, In y l2 -> (f x < f y)%nat).
     intros. apply H1.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l y H). apply H8.
     firstorder.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l x H). apply H8.
     firstorder.
     apply Ht1.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l y H). apply H8.
     firstorder.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l x H). apply H8.
     firstorder. firstorder. firstorder.
     apply Nat.lt_succ_l in H4.

     clear Heql1. clear H. clear Ht2.
     assert (Htt6 : (listmax f l1 < f c)%nat).
     induction l1. inversion H4.
     assert (Hm : {(f a >= listmax f l1)%nat} + {(f a < listmax f l1)%nat}).
     pose proof (lt_eq_lt_dec (f a) (listmax f l1)) as H11.
     destruct H11 as [[H11 | H11] | H11]. right. auto.
     left. omega. left. omega.

     assert (Ht7 : listmax f (a :: l1) = max (f a) (listmax f l1)).
     simpl. destruct l1. simpl.
     rewrite Max.max_0_r. auto. auto.
 
     rewrite Ht7. rewrite Ht7 in H4. clear Ht7.
     destruct Hm.
     rewrite max_l.  pose proof (Htt5 a (in_eq a l1) c H5).
     omega. omega.
     rewrite max_r. rewrite max_r in H4.
     apply IHl1.  omega. firstorder. omega. omega.
     omega. congruence.

     (* In c l and In d l *)
     assert (Ht5: forall x, In x l1 -> forall y, In y l2 -> (f x < f y)%nat).
     intros. apply H1.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l y H). apply H7.
     firstorder.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l x H). apply H7.
     firstorder.
     apply Ht1.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l y H). apply H7.
     firstorder.
     apply Permutation_sym in H.
     pose proof (Hp A (l1 ++ l2) l x H). apply H7.
     firstorder. firstorder. firstorder.

     destruct (Adec c a0). 
     rewrite e in H0. pose proof (H2 a0 H0).
     firstorder.

     pose proof (H2 c H0). destruct H5 as [[Htt5 Htt6] | [Htt5 Htt6]].
     rewrite Htt6 in H4. simpl in H4.
     destruct (Adec d a0).  rewrite e in H3.
     firstorder.

     pose proof (H2 d H3). destruct H5 as [[Htt7 Htt8] | [Htt7 Htt8]].
     rewrite Htt8 in H4. simpl in H4.  firstorder.
     rewrite Htt7 in H4. simpl in H4.

     assert ((if in_dec Adec d l then true else false) = true).
     destruct (in_dec Adec d l). auto. congruence.
     rewrite H5 in H4. clear H5.
     pose proof (Ht1 c d H0 H3). firstorder.
     rewrite Htt5 in H4. simpl in H4.
     assert ((if in_dec Adec c l then true else false) = true).
     destruct (in_dec Adec c l). auto. congruence.
     rewrite H5 in H4. clear H5. destruct (Adec d a0).
     rewrite e in H3. firstorder.
     pose proof (H2 d H3). destruct H5 as [[Htt7 Htt8] | [Htt7 Htt8]].
     rewrite Htt8 in H4. simpl in H4.
     pose proof (Hp A l (l1 ++ l2) c H H0).
     pose proof (Hp A l (l1 ++ l2) d H H3).
     apply in_app_iff in H5. destruct H5.
     pose proof (Ht2 c H5). firstorder.
     apply in_app_iff in H6. destruct H6.
     pose proof (Ht5 d H6 c H5). omega.
     firstorder.  rewrite Htt7 in H4. simpl in H4.
     assert ((if in_dec Adec d l then true else false) = true).
     destruct (in_dec Adec d l). auto. congruence.
     rewrite H5 in H4. clear H5. 
     pose proof (H1 c d H0 H3). destruct H5. apply H5. omega.

     