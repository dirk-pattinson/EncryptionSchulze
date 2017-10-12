Require Import Notations.
Require Import Coq.Lists.List.
Require Import Coq.Arith.Le.
Require Import Coq.Numbers.Natural.Peano.NPeano.
Require Import Coq.Arith.Compare_dec.
Require Import Coq.omega.Omega.
Require Import Bool.Sumbool.
Require Import Bool.Bool.
Require Import Coq.Logic.ConstructiveEpsilon.
 (* Require Import Coq.ZArith.ZArith.
 Require Import ListLemma. *)
Import ListNotations.



Notation "'existsT' x .. y , p" :=
  (sigT (fun x => .. (sigT (fun y => p)) ..))
    (at level 200, x binder, right associativity,
     format "'[' 'existsT' '/ ' x .. y , '/ ' p ']'") : type_scope.


Lemma filter_empty : forall (A : Type) (l : list A) (f : A -> bool),
    filter f l = [] <->
    (forall x, In x l -> f x = false).
Proof.
  intros A. induction l.
  split; intros. inversion H0. reflexivity.
  split; intros. destruct H0. simpl in H.
  destruct (f a) eqn : Ht. inversion H.
  rewrite <- H0. assumption.
  simpl in H. destruct (f a). inversion H.
  pose proof (proj1 (IHl f) H x H0). assumption.
  simpl. destruct (f a) eqn: Ht.
  pose proof (H a (in_eq a l)). congruence.
  pose proof (IHl f). destruct H0.
  apply H1. intros. firstorder.
Qed.

  
Section Cand.    

  Variable A : Type.
  Variable P : A -> A -> Prop.
  Hypothesis Adec : forall (c d : A), {c = d} + {c <> d}. (* A is decidable *)
  Hypothesis Pdec : forall c d, {P c d} + {~P c d}. (* P is decidable *)
  
  (* A is finite. finite : Type -> Type *)
  Definition finite := existsT (l : list A), forall (a : A), In a l.

  (* vl : forall A : Type, (P : A -> A -> Prop) -> (list A) -> Prop *)
  Definition vl (l : list A) :=
    exists (f : A -> nat), forall (c d : A), In c l -> In d l -> (P c d <-> (f c < f d)%nat).

 
  Fixpoint listmax (A : Type) (l : list A) (f : A -> nat) : nat :=
    match l with
    | [] => O
    | h :: t => max (f h) (listmax A t f)
    end.
 
    
  Lemma validity_after_remove_cand :
    forall (l : list A) (a0 : A),
      vl (a0 :: l) <->
      vl l /\ ~P a0 a0 /\ 
      ((exists (a0' : A), In a0' l /\ forall (x : A), In x l -> (P a0 x <-> P a0' x) /\
                                                    (P x a0 <-> P x a0')) \/
       (forall (x : A), In x l -> P x a0 \/ P a0 x)).
  Proof.
    unfold vl; split; intros.
    destruct H as [f H]. 
    split.
    exists f. firstorder.
    
    split. unfold not. intros. pose proof (proj1 (H a0 a0 (in_eq a0 l) (in_eq a0 l)) H0).
    omega.
    
    assert (Hnat : forall x y : nat, {x = y} + {x <> y}) by (auto with arith).
      
    pose proof (in_dec Hnat (f a0) (map f l)).  clear Hnat.
    destruct H0.
    apply in_map_iff in i. destruct i as [a [Hl Hr]].
    (* I know the exitence of element which is in l and equal to f a0 *)
    left. exists a. split. assumption.
    intros x Hx. split. split; intros.

    pose proof (H a0 x (in_eq a0 l) (or_intror Hx)).
    firstorder.

    pose proof (H a x (or_intror Hr) (or_intror Hx)).
    firstorder.

    split; intros.

    pose proof (H x a0 (or_intror Hx) (in_eq a0 l)).
    firstorder.

    pose proof (H x a (or_intror Hx) (or_intror Hr)).
    firstorder.

    (* time to go right *)
    right.
    intros x Hx.

    destruct (lt_eq_lt_dec (f a0) (f x)) as [[H1 | H1] | H1]. 
    pose proof (H a0 x (in_eq a0 l) (or_intror Hx)).
    firstorder.

    (* f a0 can't be equal to f x *)
    assert (Ht : f a0 <> f x).
    induction l. inversion Hx.

    apply not_in_cons in n.
    destruct n. destruct Hx. rewrite <- H3 in H1.
    omega.

    apply IHl. intros.
    firstorder. assumption. assumption.
    omega.

    pose proof (H x a0 (or_intror Hx) (in_eq a0 l)).
    firstorder.

    (* finally finished the first half. feeling great :) *)

    destruct H as [[f H1] [Ht [[a [H2 H3]] | H2]]].    
    (* From H3, I know that f a = f a0  so I am going to supply same function *)

    exists (fun c => if Adec c a0 then f a else f c). intros c d H4 H5. destruct H4, H5.
    split; intros. 
    rewrite <- H in H4. rewrite <- H0 in H4.
    firstorder. rewrite <- H0 in H4.
    rewrite -> H in H4. omega.

    split; intros.
    rewrite <- H. destruct (Adec a0 a0).
    destruct (Adec d a0).
    subst. congruence.
    subst. firstorder.
    congruence. subst.
    destruct (Adec c c). destruct (Adec d c).
    omega. firstorder.
    firstorder.

    split; intros.
    subst. destruct (Adec c d). destruct (Adec d d).
    subst. congruence.
    firstorder. destruct (Adec d d). firstorder.
    firstorder. destruct (Adec c a0). destruct (Adec d a0).
    subst. firstorder. subst. firstorder.
    subst. destruct (Adec d d). firstorder.
    firstorder.

    split; intros.
    destruct (Adec c a0). destruct (Adec d a0).
    subst. firstorder.
    subst. firstorder.
    destruct (Adec d a0).
    subst. firstorder.
    firstorder.

    destruct (Adec c a0). destruct (Adec d a0).
    subst. firstorder.
    subst. firstorder.
    destruct (Adec d a0).
    subst. firstorder.
    subst. firstorder.

    
    (*
    remember (filter (fun y => if Pdec y a0 then true else false) l) as l1.
    remember (filter (fun y => if Pdec a0 y then true else false) l) as l2.
    assert (Ht1 : forall x, In x l1 -> P x a0).
    intros. rewrite Heql1 in H.
    pose proof (proj1 (filter_In _ _ _) H).
    destruct H0. destruct (Pdec x a0). auto. inversion H3.
    assert (Ht2 : forall x, In x l2 -> P a0 x).
    intros. rewrite Heql2 in H.
    pose proof (proj1 (filter_In _ _ _) H).
    destruct H0. destruct (Pdec a0 x). auto. inversion H3.
    remember (fun y : A => if Pdec y a0 then true else false) as f1.
    remember (fun y : A => if Pdec a0 y then true else false) as g1.
    assert (Ht3 : forall x, In x l -> (f1 x = true -> g1 x = false) /\ (g1 x = true -> f1 x = false)).
    intros. split; intros. rewrite Heqf1 in H0.
    rewrite Heqg1. destruct (Pdec x a0).
    destruct (Pdec a0 x). 
    
    assert (Ht3 : l = l1 ++ l2). *)
      
    (* for a0,  take maximum of all the candidates which is preferred over 
       a0 and add one to it. 
       a1, a2 ......, a0, ....., an
       We don't need to change the values for candidates preferred over a0, but 
       those who are less preferred over a0 should be shifted by 1 *)

    
    exists (fun x =>
         match Adec x a0 with
         | left _ =>
           plus (S O)
                (listmax A (filter (fun y => proj1_sig (bool_of_sumbool (Pdec y a0))) l) f)
         | right _ => 
           if andb (proj1_sig (bool_of_sumbool (Pdec a0 x)))
                   (proj1_sig (bool_of_sumbool (in_dec Adec x l)))
           then plus (S O) (f x)
           else  (f x)
         end).

    split; intros.
    destruct H, H0.

    (* first case c = a0, d = a0 *)
    congruence.

    (* second case c = a0, In d l *)
    rewrite <- H. rewrite <- H in H3.
    destruct (Adec a0 a0).
    destruct (Adec d a0).
    congruence.
    destruct (Pdec a0 d).
    destruct (in_dec Adec d l).
    simpl. apply lt_n_S.
    remember (filter (fun y : A => proj1_sig (bool_of_sumbool (Pdec y a0))) l) as l1.
    (* Now l1 can be empty of non empty *) 

    pose proof (list_eq_dec Adec l1 []).
    destruct H4. rewrite e0 in Heql1. rewrite e0. simpl.
    symmetry in Heql1.
    pose proof (proj1 (filter_empty _ l (fun y : A => proj1_sig (bool_of_sumbool (Pdec y a0)))) Heql1).
    pose proof (H4 d i). simpl in H5.
    destruct (Pdec d a0).    
    simpl in H5. inversion H5.
    simpl in H5. clear H5. 

    
  (* This proof is mostly followed by validity_after_remove_cand. *)
  Lemma vl_or_notvl : forall l : list A, vl l + ~vl l.
  Proof.
    
    induction l.
    left. unfold vl. eexists.
    intros c d Hc Hd; inversion Hc.

    (* l := a :: l *)
    pose proof (validity_after_remove_cand l a).
    destruct IHl.
    (* if P a a or ~ P a a *)
    pose proof (Pdec a a).
    (* I can not destruct H0 of type Prop because goal is of type Set. 
       We need to probably change the Pdec to forall c d, {P c d} + {~ P c d} ? *)
    (* After this proof is very easy. 
       If P a a then we can not construct the valid (a :: l) from vl and go right. 
       If ~P a a then we can construct the the valid (a :: l) from vl. 
       In (f a) (map f l) + ~ In (f a) (map f l). 
       If In (f a) (map f l) then we there is some element, a0, in l such that 
       f a = f a0 and we can  discharge existential 
       If ~In (f a) (map f l) then we can split the l into two sorted list, l1 , l2
       and discharge forall x, In x l -> P a x \/ P x a *)
    
    
    (* if ~vl l then adding candidate would also not make it valid 
       got for right *)
    admit.
    right. unfold not. intros.
    destruct n. firstorder.
    Admitted.
    

    
  Definition valid := exists (f : A -> nat), forall (c d : A), P c d <-> (f c < f d)%nat.

  Lemma from_vl_to_valid : forall (l : list A), ((forall a : A, In a l) -> valid <-> vl l).
  Proof. 
    intros l Ha. split; intros.
    unfold valid in H.
    unfold vl.
    destruct H as [f H].
    firstorder.
    unfold vl in H. unfold valid.
    destruct H as [f H].
    exists f. split; intros.
    apply H; auto.
    apply H; auto.
  Qed.
  
    
  Lemma decidable_valid : finite -> {valid} + {~valid}.
  Proof.
    unfold finite, valid.
    intros H. destruct H as [l Hin].

    

    
End Cand.

Check decidable_valid.



  
    
  Lemma validity_after_remove_cand :
    forall (P : A -> A -> Prop) (l : list A) (Hpdec : forall c d, P c d \/ ~P c d),
      valid P l <->
      exists (c : A), forall (d : A), In c l /\ In d l /\  (equal_rank P c d \/ (P c d \/ c = d \/ P d c))
                            /\ valid P (remove A_dec d l).
  Proof.
    unfold valid, equal_rank.
    split; intros.
    destruct H as [f H].

    (* induction on l *)
    induction l.
    (* admit the empty case for the moment *)
    admit.
    (* a :: l and assume c = a *)
    exists a. intros d.
    (* Either d is a or d is inside the list *)
    destruct (A_dec a d).
    split. apply in_eq.
    split. firstorder.
    split. (* At this point we have a = d in assumption and 
      ~ P a d /\ ~ P d a \/ P a d \/ a = d \/ P d a in goal.
    I think a = d should mean that either they are equal_rank or a = d and 
    this should be used to discharge the goal *)
    right. firstorder.
    exists f.  split; intros. rewrite e in Hc, Hd.
    pose proof (H c d0). simpl in *. firstorder.
    rewrite e in Hc, Hd.
    pose proof (H c d0). simpl in *. firstorder.
    
    (* a <> d *)
    split. apply in_eq.
    split. pose proof (H a d (in_eq a l)). firstorder.
    split.  admit.
    (* At this point we a <> d in assumption and  
       ~ P a d /\ ~ P d a \/ P a d \/ a = d \/ P d a in goal.
      I think a <> d should mean that either P a d or P d a and this 
      should discharge the assumption
  *)
    exists f. split; intros. simpl in Hc, Hd. destruct (A_dec d a).
    symmetry in e. pose proof (n e). inversion H1.
    simpl in *. destruct Hc, Hd.  firstorder.
    pose proof (H c d0). firstorder.
    pose proof (H c d0). firstorder.
    pose proof (H c d0). firstorder.
    pose proof (H c d0). firstorder.
    
    (* reverse direction *)
    destruct H as [x H]. Check fold_left.
    pose proof (H x). destruct H0 as [H1 [H2 [H3 [f H4]]]].
    
    induction l. firstorder.

    (* either a = c or a <> c *)
    
    
  Lemma dec_now : forall (P : A -> A -> Prop),
      (forall c d, P c d \/ ~P c d) ->
      {valid P} + {~valid P}.
  Proof.
    intros P H. unfold valid.
    
