theory State_Networks
  imports Networks Normalized_Zone_Semantics_Impl
    "~/Formalizations/Experiments/Reordering_Quantifiers"
begin

(* XXX Move *)
lemma finite_Collect_bounded_ex_2 [simp]:
  assumes "finite {(a,b). P a b}"
  shows
    "finite {x. \<exists>a b. P a b \<and> Q x a b}
    \<longleftrightarrow> (\<forall> a b. P a b \<longrightarrow> finite {x. Q x a b})"
  using assms finite_Collect_bounded_ex[OF assms, where Q = "\<lambda> x. \<lambda> (a, b). Q x a b"]
  by clarsimp (* force, simp *)

lemma finite_Collect_bounded_ex_7 [simp]:
  assumes "finite {(a,b,c,d,e,f,g) . P a b c d e f g}"
  shows
    "finite {x. \<exists>a b c d e f g. P a b c d e f g \<and> Q x a b c d e f g}
    \<longleftrightarrow> (\<forall> a b c d e f g. P a b c d e f g \<longrightarrow> finite {x. Q x a b c d e f g})"
  using assms finite_Collect_bounded_ex
    [OF assms, where Q = "\<lambda> x. \<lambda> (a, b, c, d, e, f, g). Q x a b c d e f g"]
  by clarsimp (* force, simp *)

lemma finite_Collect_bounded_ex_8 [simp]:
  assumes "finite {(a,b,c,d,e,f,g,h) . P a b c d e f g h}"
  shows
    "finite {x. \<exists>a b c d e f g h. P a b c d e f g h \<and> Q x a b c d e f g h}
    \<longleftrightarrow> (\<forall> a b c d e f g h. P a b c d e f g h \<longrightarrow> finite {x. Q x a b c d e f g h})"
  using assms finite_Collect_bounded_ex
    [OF assms, where Q = "\<lambda> x. \<lambda> (a, b, c, d, e, f, g, h). Q x a b c d e f g h"]
  by clarsimp (* force, simp *)

lemma finite_Collect_bounded_ex_9 [simp]:
  assumes "finite {(a,b,c,d,e,f,g,h,i) . P a b c d e f g h i}"
  shows
    "finite {x. \<exists>a b c d e f g h i. P a b c d e f g h i \<and> Q x a b c d e f g h i}
    \<longleftrightarrow> (\<forall> a b c d e f g h i. P a b c d e f g h i \<longrightarrow> finite {x. Q x a b c d e f g h i})"
  using assms finite_Collect_bounded_ex
    [OF assms, where Q = "\<lambda> x. \<lambda> (a, b, c, d, e, f, g, h, i). Q x a b c d e f g h i"]
  by clarsimp (* force, simp *)

lemma finite_Collect_bounded_ex_10 [simp]:
  assumes "finite {(a,b,c,d,e,f,g,h,i,j) . P a b c d e f g h i j}"
  shows
    "finite {x. \<exists>a b c d e f g h i j. P a b c d e f g h i j \<and> Q x a b c d e f g h i j}
    \<longleftrightarrow> (\<forall> a b c d e f g h i j. P a b c d e f g h i j \<longrightarrow> finite {x. Q x a b c d e f g h i j})"
  using assms finite_Collect_bounded_ex
    [OF assms, where Q = "\<lambda> x. \<lambda> (a, b, c, d, e, f, g, h, i, j). Q x a b c d e f g h i j"]
  by clarsimp (* force, simp *)

no_notation Ref.update ("_ := _" 62)

section \<open>Networks of Timed Automata with Shared State\<close>

subsection \<open>Syntax and Operational Semantics\<close>

(* XXX Update text *)
text \<open>
  We extend Networks of Timed Automata with arbitrary shared (global) state.
  Syntactically, this extension is very simple.
  We can just use the free action label slot to annotate edges with a guard
  and an update function on discrete states.
  The slightly more clumsy part is adding invariants for discrete states
  by directly specifying an invariant annotating function.
\<close>

type_synonym
  ('a, 'c, 'time, 's, 'st) transition =
  "'s * ('st \<Rightarrow> ('c, 'time) cconstraint) * 'a * ('st \<Rightarrow> 'c list) * 's"

type_synonym
  ('a, 'c, 'time, 's, 'st) sta = "('a, 'c, 'time, 's, 'st) transition set * ('c, 'time, 's) invassn"

type_synonym
  ('a, 'c, 't, 's, 'st) snta =
  "('a act \<times> ('st \<Rightarrow> bool) \<times> ('st \<Rightarrow> 'st option), 'c, 't, 's, 'st) sta list \<times> ('s \<Rightarrow> 'st \<Rightarrow> bool) list"

(*
type_synonym
  ('a, 'c, 'time, 's) unta = "programc \<times> ('a act, 'c, 'time, 's) uta list"

type_synonym
  ('a, 'c, 't, 's, 'st) snta =
  "('a, ('st \<Rightarrow> bool) \<times> ('st \<Rightarrow> 'st), 'c, 't, 's) nta \<times> ('s \<Rightarrow> 'st \<Rightarrow> bool) list"
*)

text \<open>
  Semantic states now consist of three things:
  a list of process locations, the shared state, and a clock valuation.
  The semantic extension then is also obvious: we can take the same transitions
  as in the network without shared state, however we have to add state updates
  and checks for guards on the shared state.
  The updates on discrete state for synchronizing transitions are in the same order as in UPPAAL
  (output before input).
\<close>

inductive step_sn ::
  "('a, 'c, 't, 's, 'st) snta \<Rightarrow> 's list \<Rightarrow> 'st \<Rightarrow> ('c, ('t::time)) cval
  \<Rightarrow> 's list \<Rightarrow> 'st \<Rightarrow> ('c, 't) cval \<Rightarrow> bool"
  ("_ \<turnstile> \<langle>_, _, _\<rangle> \<rightarrow> \<langle>_, _, _\<rangle>" [61,61,61] 61)
where
  step_sn_t:
    "(N, I) \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L, s, u \<oplus> d\<rangle>"
    if "\<forall> p \<in> {..<length N}. u \<turnstile> snd (N ! p) (L ! p)"
       "\<forall> p \<in> {..<length N}. u \<oplus> d \<turnstile> snd (N ! p) (L ! p)"
       "d \<ge> 0" "length N = length I" |
  step_sn_i:
    "(N, I) \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"
    if "(l, g, (Sil a, c, m), f, l') \<in> fst (N!p)"
       "u \<turnstile> g s" "\<forall> p \<in> {..<length N}. u' \<turnstile> snd (N!p) (L'!p)"
       "r = f s"
       "L!p = l" "p < length L" "L' = L[p := l']" "u' = [r\<rightarrow>0]u"
       "c s" "\<forall> p < length I. (I ! p) (L' ! p) s'" "Some s' = m s"
       "length N = length I" |
  step_sn_s:
    "(N, I) \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"
    if "(l1, g1, (In a, ci, mi), f1, l1') \<in> fst (N!p)"
       "(l2, g2, (Out a, co, mo), f2, l2') \<in> fst (N!q)" "u \<turnstile> g1 s" "u \<turnstile> g2 s"
       "\<forall> p \<in> {..<length N}. u' \<turnstile> snd (N!p) (L'!p)"
       "r1 = f1 s" "r2 = f2 s"
       "L!p = l1" "L!q = l2" "p < length L" "q < length L" "p \<noteq> q"
       "L' = L[p := l1', q := l2']" "u' = [(r1 @ r2)\<rightarrow>0]u"
       "ci s" "co s" "\<forall> p < length I. (I ! p) (L' ! p) s'"
       "Some so = mo s" "Some s' = mi so" "length N = length I"

inductive_cases[elim!]: "N \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"

inductive steps_sn ::
  "('a, 'c, 't, 's, 'st) snta \<Rightarrow> 's list \<Rightarrow> 'st \<Rightarrow> ('c, ('t::time)) cval
  \<Rightarrow> 's list \<Rightarrow> 'st \<Rightarrow> ('c, 't) cval \<Rightarrow> bool"
("_ \<turnstile> \<langle>_, _, _\<rangle> \<rightarrow>* \<langle>_, _, _\<rangle>" [61, 61, 61,61,61] 61)
where
  refl: "N \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L, s, u\<rangle>" |
  step: "N \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L', s', u'\<rangle> \<Longrightarrow> N \<turnstile> \<langle>L', s', u'\<rangle> \<rightarrow> \<langle>L'', s'', u''\<rangle>
        \<Longrightarrow> N \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L'', s'', u''\<rangle>"

declare steps_sn.intros[intro]

lemma stepI2:
  "N \<turnstile> \<langle>l, s, u\<rangle> \<rightarrow>* \<langle>l'', s'', u''\<rangle>" if
  "N \<turnstile> \<langle>l', s', u'\<rangle> \<rightarrow>* \<langle>l'', s'', u''\<rangle>" "N \<turnstile> \<langle>l, s, u\<rangle> \<rightarrow> \<langle>l', s', u'\<rangle>"
  using that
  apply induction
   apply rule
    apply (rule refl)
   apply assumption
  apply simp
  by (rule; assumption)

abbreviation state_set :: "('a, 'c, 't, 's, 'st) transition set \<Rightarrow> 's set" where
  "state_set T \<equiv> fst ` T \<union> (snd o snd o snd o snd) ` T"

subsection \<open>Product Automaton\<close>

(*
abbreviation state_set :: "('a, 'c, 'time, 's) transition set \<Rightarrow> 's set" where
  "state_set T \<equiv> fst ` T \<union> (snd o snd o snd o snd) ` T"
*)

locale Prod_TA_Defs =
  fixes A :: "('a, 'c, 't, 's, 'st) snta"
begin

definition
  "T_s p s = {(l, g s, a, f s, l') | l g a f l'. (l, g, a, f, l') \<in> fst (fst A ! p)}"

definition
  "N_s s = map (\<lambda> p. (T_s p s, snd (fst A ! p))) [0..<length (fst A)]"

term Product_TA_Defs.product_ta

(* sublocale Product_TA_Defs "N_s s" . *)

term product_ta

print_theorems

abbreviation "P \<equiv> snd A"

definition "p \<equiv> length (fst A)"

abbreviation "product s \<equiv> Product_TA_Defs.product_ta (N_s s)"

abbreviation "T' s \<equiv> trans_of (product s)"
abbreviation "I' s \<equiv> inv_of (product s)"

definition
  "prod_trans_i =
    {((L, s), g, a, r, (L', s')) | L s g c a r m L' s'.
     (\<forall> q < p. (P ! q) (L ! q) s) \<and> (\<forall> q < p. (P ! q) (L' ! q) s')
     \<and> (L, g, (a, Act (c, m)), r, L') \<in> T' s \<and> c s \<and> Some s' = m s}"

definition
    "prod_trans_s =
      {((L, s), g, a, r, (L', s')) | L s g ci co a r mi mo L' s' so.
        ci s \<and> co s
        \<and> (\<forall> q < p. (P ! q) (L ! q) s) \<and> (\<forall> q < p. (P ! q) (L' ! q) s')
        \<and> (L, g, (a, Syn (ci, mi) (co, mo)), r, L') \<in> T' s
        \<and> Some so = mo s
        \<and> Some s' = mi so
      }"

  definition
    "prod_trans \<equiv> prod_trans_i \<union> prod_trans_s"

  term Product_TA_Defs.product_invariant

  definition
    "prod_invariant \<equiv> \<lambda> (L, s). I' s L"

  definition prod_ta :: "('a, 'c, 't, 's list \<times> 'st) ta" where
    "prod_ta \<equiv> (prod_trans, prod_invariant)"

  lemma prod_ta_cases:
    assumes "prod_ta \<turnstile> L \<longrightarrow>\<^bsup>g,a,r\<^esup> L'"
    shows "(L, g, a, r, L') \<in> prod_trans_i \<or> (L, g, a, r, L') \<in> prod_trans_s"
    using assms unfolding prod_ta_def trans_of_def prod_trans_def by auto

  lemma inv_of_simp:
    "inv_of prod_ta (L, s) = I' s L"
    unfolding inv_of_def prod_ta_def prod_invariant_def by simp

lemma I'_simp:
  "I' s L = I' s' L"
  unfolding Product_TA_Defs.product_ta_def inv_of_def Product_TA_Defs.product_invariant_def N_s_def
  apply simp
  apply (rule arg_cong[where f = concat])
  by simp


term A

  lemma collect_clki_prod_invariant:
    "collect_clki prod_invariant = collect_clki (I' s)"
    unfolding prod_invariant_def
    collect_clki_def

    using I'_simp
    oops

  (*
  lemma states_length:
    assumes "L \<in> states"
    shows "length L = length N"
    using assms unfolding states_def by auto
    *)

    (*
  lemma collect_clkt_prod_trans_subs:
    "collect_clkt prod_trans \<subseteq> collect_clkt T'"
    unfolding collect_clkt_def prod_trans_def prod_trans_i_def prod_trans_s_def by fastforce

  lemma collect_clkvt_prod_trans_subs:
    "collect_clkvt prod_trans \<subseteq> collect_clkvt T'"
    unfolding collect_clkvt_def prod_trans_def prod_trans_i_def prod_trans_s_def by fastforce
*)

term N term P

lemma T_simp:
  "T ! q = trans_of (N ! q)" if "q < length N"
  using that oops

  (*
lemma prod_state_set_subs:
  assumes "l \<in> state_set T'" "q < p"
  shows "l ! q \<in> state_set (trans_of (N ! q))"
  using assms
  apply (simp only: T_simp[symmetric] p_def)
  by (rule product_state_set_subs; simp add: product_ta_def trans_of_def)
*)

abbreviation "N \<equiv> fst A"

context
  assumes finite_state:
    "\<forall> q < p. \<forall> l. finite {s. (P ! q) l s}"
      and finite_trans: "\<forall> A \<in> set N. finite (fst A)"
      and p_gt_0: "p > 0"
begin

  lemma finite_state':
    "finite {s. \<forall>q<p. (P ! q) (L ! q) s}" (is "finite ?S")
  proof -
    from p_gt_0 obtain q where "q < p" by blast
    then have "?S \<subseteq> {s. (P ! q) (L ! q) s}" by auto
    moreover have "finite \<dots>" using finite_state \<open>q < p\<close> by auto
    ultimately show ?thesis by (rule finite_subset)
  qed

  lemma finite_trans':
    "\<forall>A\<in>set (N_s s). finite (trans_of A)"
  unfolding N_s_def apply auto
    unfolding trans_of_def T_s_def
    apply simp
    apply (drule nth_mem)
    using finite_trans
    using [[simproc add: finite_Collect]]
    apply auto
    apply (rule finite_imageI)
    apply (rule finite_vimageI)
     apply simp
    unfolding inj_on_def by auto

  lemma
    "finite (Product_TA_Defs.states (N_s s))"
    using finite_trans' by (rule Product_TA_Defs.finite_states)

  lemma
    "finite (T' s)"
    using finite_trans' by (rule Product_TA_Defs.finite_trans_of_product)

  lemma
    "finite {t. \<exists> N s. N \<in> set (N_s s) \<and> t \<in> fst N \<and> (P ! p) (fst t) s}"
  proof -
    have "finite {t. \<exists>p s. t \<in> T_s p s \<and> p < length N \<and> (P ! p) (fst t) s}"
    unfolding N_s_def
    using [[simproc add: finite_Collect]]
    unfolding T_s_def
    using finite_state finite_trans
    apply auto
    sorry
    then have "finite {t. \<exists> N s. N \<in> set (N_s s) \<and> t \<in> fst N \<and> (P ! p) (fst t) s}"
      unfolding N_s_def apply auto
      using [[simproc add: finite_Collect]]
      sorry
    then show ?thesis .
  qed

  lemma finite_product_1:
    "finite (trans_of (product s))"
    unfolding product_def
    unfolding trans_of_def Product_TA_Defs.product_ta_def
    apply simp
    unfolding Product_TA_Defs.product_trans_def
    apply safe
    unfolding Product_TA_Defs.product_trans_i_def
    unfolding N_s_def T_s_def
    sorry

  lemma
    "finite (N_s ` UNIV)"
    unfolding N_s_def oops

  lemma finite_range_product:
    "finite (trans_of ` range product)"
    unfolding product_def
    unfolding trans_of_def Product_TA_Defs.product_ta_def
    unfolding image_def
    apply auto
    oops
    (*
    apply simp
    unfolding Product_TA_Defs.product_trans_def
    apply safe
    unfolding Product_TA_Defs.product_trans_i_def
    unfolding N_s_def T_s_def
    apply forc
    apply aut
    oops
*)

  lemma
    "finite {s. T' s \<noteq> {}}"
    unfolding trans_of_def Product_TA_Defs.product_ta_def
    apply simp
    unfolding N_s_def
    unfolding T_s_def
    oops

    (*
  lemma finite_state':
    "\<forall> q < p. \<forall> l \<in> state_set T'. finite {s. (P ! q) (l ! q) s}"
    using finite_state prod_state_set_subs by simp

  lemma finite_state'':
    "finite {s. \<forall> q < p. (P ! q) (l ! q) s}" if \<open>p > 0\<close> \<open>l \<in> state_set T'\<close>
  proof -
    from \<open>p > 0\<close> obtain q where "q < p" by auto
    with finite_state' \<open>l \<in> _\<close> have "finite {s. (P ! q) (l ! q) s}" by auto
    then show ?thesis by (rule rev_finite_subset) (auto intro: \<open>q < p\<close>)
  qed
*)

  thm prod_trans_i_def

  lemma prod_trans_i_alt_def:
    "prod_trans_i =
      {((L, s), g, a, r, (L', m s)) | L s g c a r m L'.
       (L, g, (a, Act (c, m)), r, L') \<in> T' s \<and>
       (\<forall> q < p. (P ! q) (L ! q) s) \<and> (\<forall> q < p. (P ! q) (L' ! q) (m s))
       \<and> c s}"
    unfolding prod_trans_i_def by (safe; metis)

  term case_prod

  lemma Collect_case_prod_rewr:
    "{(a, b). Q a b} = {x. \<exists> a b. x = (a, b) \<and> Q a b}"
    by auto

  lemma  bla:
    "finite {(a, b) | a b. Q (f a b)}" if "inj f" "finite {x. Q x}"
    using that apply auto
    using [[simproc add: finite_Collect]]
    oops

  lemma finite_prod_trans:
    "finite prod_trans" if "p > 0"
    unfolding prod_trans_def prod_trans_i_alt_def prod_trans_s_def
    apply safe
    subgoal
      using finite_state' finite_product_1
      apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
      apply (subst finite_Collect_bounded_ex_8)
       apply auto
      unfolding trans_of_def
      apply (simp split: prod.split_asm add: Collect_case_prod_rewr)
      sorry
    subgoal
      apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
      apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
      apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
      apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
      apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
      apply simp
      apply (subst finite_Collect_bounded_ex_10)
       apply auto
      using finite_product_1
      unfolding trans_of_def sorry
    done

end (* End of context for finiteness of automaton *)

(*
context
  assumes finite_state:
    "\<forall> q < p. \<forall> l \<in> state_set (fst (N ! q)). finite {s. (P ! q) l s}"
      and finite_trans: "\<forall> A \<in> set N. finite (fst A)"
begin

thm Product_TA_Defs.finite_states

lemma finite_trans':
  "\<forall>A\<in>set (N_s s). finite (trans_of A)"
unfolding N_s_def apply auto
  unfolding trans_of_def T_s_def
  apply simp
  apply (drule nth_mem)
  using finite_trans
  using [[simproc add: finite_Collect]]
  apply auto
  apply (rule finite_imageI)
  apply (rule finite_vimageI)
   apply simp
  unfolding inj_on_def by auto

lemma
  "finite (Product_TA_Defs.states (N_s s))"
  using finite_trans' by (rule Product_TA_Defs.finite_states)

lemma
  "finite (T' s)"
  using finite_trans' by (rule Product_TA_Defs.finite_trans_of_product)

term "(N_s s)"

lemma
  "finite {t. \<exists> N s. N \<in> set (N_s s) \<and> t \<in> fst N \<and> (P ! p) (fst t) s}"
proof -
  have "finite {t. \<exists>p s. t \<in> T_s p s \<and> p < length N \<and> (P ! p) (fst t) s}"
  unfolding N_s_def
  using [[simproc add: finite_Collect]]
  unfolding T_s_def
  using finite_state finite_trans
  apply auto
  sorry
  then have "finite {t. \<exists> N s. N \<in> set (N_s s) \<and> t \<in> fst N \<and> (P ! p) (fst t) s}"
    unfolding N_s_def apply auto
    using [[simproc add: finite_Collect]]
    sorry
  then show ?thesis .
qed



term "trans_of (product s)"
lemma finite_product_1:
  "finite (trans_of (product s))"
  unfolding product_def
  unfolding trans_of_def Product_TA_Defs.product_ta_def
  apply simp
  unfolding Product_TA_Defs.product_trans_def
  apply safe
  unfolding Product_TA_Defs.product_trans_i_def
  unfolding N_s_def T_s_def
  sorry

lemma
  "finite (N_s ` UNIV)"
  unfolding N_s_def oops

lemma finite_range_product:
  "finite (trans_of ` range product)"
  unfolding product_def
  unfolding trans_of_def Product_TA_Defs.product_ta_def
  unfolding image_def
  apply auto
  apply simp
  unfolding Product_TA_Defs.product_trans_def
  apply safe
  unfolding Product_TA_Defs.product_trans_i_def
  unfolding N_s_def T_s_def
  apply forc
  apply aut
  oops

lemma
  "" " \<turnstile> L \<longrightarrow>\<^bsup>g,(a, Act (c, m)),r\<^esup> L'"

lemma
  "finite {s. T' s \<noteq> {}}"
  unfolding trans_of_def Product_TA_Defs.product_ta_def
  apply simp
  unfolding N_s_def
  unfolding T_s_def
  oops

term state_set

lemma finite_state':
  "\<forall> q < p. \<forall> l \<in> state_set T'. finite {s. (P ! q) (l ! q) s}"
  using finite_state prod_state_set_subs by simp

lemma finite_state'':
  "finite {s. \<forall> q < p. (P ! q) (l ! q) s}" if \<open>p > 0\<close> \<open>l \<in> state_set T'\<close>
proof -
  from \<open>p > 0\<close> obtain q where "q < p" by auto
  with finite_state' \<open>l \<in> _\<close> have "finite {s. (P ! q) (l ! q) s}" by auto
  then show ?thesis by (rule rev_finite_subset) (auto intro: \<open>q < p\<close>)
qed

thm prod_trans_i_def

lemma prod_trans_i_alt_def:
  "prod_trans_i =
    {((L, s), g, a, r, (L', m s)) | L s g c a r m L'.
     (L, g, (a, Act (c, m)), r, L') \<in> T' s \<and>
     (\<forall> q < p. (P ! q) (L ! q) s) \<and> (\<forall> q < p. (P ! q) (L' ! q) (m s))
     \<and> c s}"
  unfolding prod_trans_i_def by (safe; metis)

lemma finite_prod_trans:
  "finite prod_trans" if "p > 0"
  unfolding prod_trans_def prod_trans_i_alt_def prod_trans_s_def
  apply safe
  subgoal
    apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
    using [[simproc add: ex_reorder4]]
    apply simp
    apply (subst finite_Collect_bounded_ex_7)
    subgoal
      using [[simproc add: finite_Collect]] finite_trans_of_product[OF finite_trans]
      by (auto intro!: finite_imageI finite_vimageI simp: inj_on_def)
    apply safe
    (* When unfolding regular_def
    apply (tactic \<open>defer_ex_tac @{context} 1\<close>) (* XXX *)
    *)
    apply (subst finite_Collect_bounded_ex)
    by (auto intro: finite_state'' \<open>p > 0\<close>)
  subgoal
    apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
    apply (tactic \<open>rearrange_ex_fixed_5 @{context} 1\<close>)
    apply (use [[simproc add: ex_reorder4]] in simp)
    apply (subst finite_Collect_bounded_ex_9)
    subgoal
      using [[simproc add: finite_Collect]] finite_trans_of_product[OF finite_trans]
      by (auto intro!: finite_imageI finite_vimageI simp: inj_on_def)
    apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
    apply (tactic \<open>defer_ex_tac @{context} 1\<close>, simp only: conj_assoc)
    apply safe
    apply (subst finite_Collect_bounded_ex)
    by (auto intro: finite_state'' \<open>p > 0\<close>)
  done

thm finite_product_trans_i[OF finite_trans] finite_product_trans_s[OF finite_trans]

thm finite_trans_of_product[OF finite_trans]
thm finite_states

end (* End of context for finiteness of automaton *)
*)

abbreviation "states' s \<equiv> Product_TA_Defs.states (N_s s)"

end (* End locale for product TA definition *)

locale Prod_TA_Defs' =
  Prod_TA_Defs A for A :: "('a, 'c, 't :: time, 's, 'st) snta"
begin

term N

  (* sublocale Product_TA_Defs' "N_s s". *)

  thm Networks.Product_TA_Defs'.product_invariantD

  term "step_sn A" term Product_TA_Defs.states

term N

lemma A_unfold:
  "A \<equiv> (N, P)"
  by auto

lemma network_step:
  assumes step: "(N, P) \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>" and len: "length L = p"
  obtains a where "N_s s \<turnstile>\<^sub>N \<langle>L, u\<rangle> \<rightarrow>\<^bsub>a\<^esub> \<langle>L', u'\<rangle>"
  subgoal premises prems
    using step
    apply cases
    subgoal
      apply (rule prems)
      apply simp
      apply (rule step_n_t)
      subgoal
        unfolding N_s_def by (auto simp: inv_of_def)
      apply assumption
      done
    subgoal
      apply (rule prems)
      apply (rule step_n_i)
      unfolding N_s_def T_s_def by (auto 4 0 simp: trans_of_def inv_of_def len p_def)
    subgoal
      subgoal premises A
        apply (rule prems)
        apply (rule step_n_s)
                   defer
                   defer
                   apply (rule A; fail)
                  apply (rule A(4); fail)
        subgoal
          using A unfolding N_s_def by (auto simp: inv_of_def len)
                defer
                defer
                apply (rule A; fail)
               apply (rule A(11); fail)
        using A unfolding N_s_def T_s_def by (auto 4 0 simp: trans_of_def len p_def)
      done
    done
  done

  lemma N_s_length:
    "length (N_s s) = p"
    unfolding N_s_def p_def by simp

lemma trans_of_N_s_1:
  "(fst ` trans_of (N_s s ! q)) = fst ` fst (N ! q)" if "q < p"
  using that unfolding trans_of_def N_s_def p_def T_s_def by (auto 0 7 simp: image_iff)

lemma trans_of_N_s_2:
  "((snd o snd o snd o snd) ` trans_of (N_s s ! q)) = (snd o snd o snd o snd) ` fst (N ! q)" if "q < p"
  using that unfolding trans_of_def N_s_def p_def T_s_def by force

lemma
  "fst ` trans_of (N_s s ! q) = fst ` trans_of (N_s s' ! q)" if "q < p"
  using that by (simp add: trans_of_N_s_1)

lemma states'_simp:
  "states' s = states' s'"
  unfolding Product_TA_Defs.states_def by (simp add: N_s_length trans_of_N_s_1 trans_of_N_s_2)

  lemma states_step:
    "L' \<in> states' s" if "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>" "L \<in> states' s"
  proof -
    interpret Product_TA_Defs' "N_s s" .
    from \<open>L \<in> _\<close> have "L \<in> states" .
    from \<open>L \<in> _\<close> have "length L = p" by (simp add: N_s_length states_length)
    with network_step[folded A_unfold, OF that(1)] obtain a where
      "N_s s \<turnstile>\<^sub>N \<langle>L, u\<rangle> \<rightarrow>\<^bsub>a\<^esub> \<langle>L',u'\<rangle>"
      by auto
    then show ?thesis using that(2) by (rule states_step)
  qed

  lemma states_steps:
    "L' \<in> states' s'" if "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L', s', u'\<rangle>" "L \<in> states' s"
    using that proof (induction A \<equiv> A _ _ _ _ _ _ rule: steps_sn.induct)
    case (refl L s u)
    then show ?case by assumption
  next
    case (step L s u L' s' u' L'' s'' u'')
    with states_step[of L' s' u' L'' s'' u''] states'_simp show ?case by blast
  qed

  lemma inv_step:
    "\<forall>p<length P. (P ! p) (L' ! p) s'" if
    "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>" "\<forall>p<length P. (P ! p) (L ! p) s"
    using that by (cases) auto

  lemma inv_steps:
    "\<forall>p<length P. (P ! p) (L' ! p) s'" if
    "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L', s', u'\<rangle>" "\<forall>p<length P. (P ! p) (L ! p) s"
    using that apply (induction A \<equiv> A _ _ _ _ _ _ rule: steps_sn.induct) by (auto intro: inv_step)

end

(* Network + valid start state *)
locale Prod_TA =
  Prod_TA_Defs' A for A :: "('a, 'c, 't :: time, 's, 'st) snta" +
  fixes L :: "'s list" and s :: 'st
  assumes states[intro]: "L \<in> states' s"
  assumes Len: "length N = length P"
      and inv: "\<forall>p<length P. (P ! p) (L ! p) s"
begin

  sublocale Product_TA "N_s s" L by standard rule

  lemma inv_prod_simp:
    "inv_of prod_ta (l, s') = Product_TA_Defs.product_invariant (N_s s') l" if "length l = p"
    unfolding prod_ta_def prod_invariant_def Product_TA_Defs.product_ta_def N_s_def inv_of_def
    using that by (simp add: p_def)

  lemma inv_of_N_simp:
    "map inv_of (N_s s') ! q = I ! q" if "q < p"
    using that unfolding inv_of_def N_s_def p_def by simp

  lemma product_inv_prod_simp:
    "inv_of prod_ta (l, s') = I' s l" if "length l = p"
    using that
    apply (simp add: inv_prod_simp)
    apply (simp add: N_s_length inv_of_def Product_TA_Defs.product_invariant_def)
    apply (rule arg_cong[where f = concat])
    apply (clarsimp cong: map_cong)
    by (subst inv_of_N_simp; simp)

  lemma product_inv_prod[intro]:
    "u \<turnstile> inv_of prod_ta (l, s')" if "u \<turnstile> inv_of product_ta l" "length l = p"
    using that by (simp add: product_inv_prod_simp)

  lemma A_simp[simp]:
    "N' = N" "P' = P" if "A = (N', P')"
    using that by auto

  lemma length_L[intro]:
    "length L = p"
    by (simp add: N_s_length)

  lemma prod_complete:
    assumes step: "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"
    shows "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>"
  using step proof cases
    case prems: (step_sn_t N d P)
    note [simp] = A_simp[OF prems(1)]
    from prems have "N_s s \<turnstile>\<^sub>N \<langle>L, u\<rangle> \<rightarrow>\<^bsub>Del\<^esub> \<langle>L', u'\<rangle>"
      unfolding N_s_def by (auto simp: inv_of_def intro: step_n_t)
    with prems show ?thesis
      by (auto 4 4 simp add: product_inv_prod_simp[OF length_L] elim!: product_delay_complete)
  next
    case prems: (step_sn_i l g a c m f l' N q r I)
    note [simp] = A_simp[OF prems(1)]
    from prems(13) have [simp]: "length P = p" by (simp add: p_def)
    have "N_s s \<turnstile>\<^sub>N \<langle>L, u\<rangle> \<rightarrow>\<^bsub>Act (c, m)\<^esub> \<langle>L', u'\<rangle>"
      apply (rule step_n_i)
      using prems unfolding N_s_def T_s_def by (auto 3 0 simp: trans_of_def inv_of_def N_s_length)
    with \<open>length P = p\<close> obtain b where "product_ta \<turnstile> \<langle>L, u\<rangle> \<rightarrow>\<^bsub>(b, Act (c, m))\<^esub> \<langle>L', u'\<rangle>"
      by (clarsimp elim!: product_int_complete)
    with prems inv obtain g r where step:
      "((L, s), g, b, r, (L', s')) \<in> prod_trans_i"
      "u \<turnstile> g" "[r\<rightarrow>0]u = u'" "u' \<turnstile> inv_of product_ta L'"
        apply atomize_elim
      unfolding prod_trans_i_def by - (erule step_a.cases; auto)
    then have "((L, s), g, b, r, (L', s')) \<in> trans_of prod_ta"
      by (simp add: prod_trans_def trans_of_def prod_ta_def)
    moreover have "length L' = p"
      using length_L prems(8) by auto
    ultimately show ?thesis
      apply -
      apply (rule step_a)
      apply rule
      using step(2-) by force+
  next
    case prems: (step_sn_s l1 g1 a ci mi f1 l1' N q1 l2 g2 co mo f2 l2' q2 r1 r2 I)
    note [simp] = A_simp[OF prems(1)]
    from prems(21) have [simp]: "length P = p" by (simp add: p_def)
    (* XXX Clean *)
    have "N_s s \<turnstile>\<^sub>N \<langle>L, u\<rangle> \<rightarrow>\<^bsub>Syn (ci, mi) (co, mo)\<^esub> \<langle>L', u'\<rangle>"
        apply (rule step_n_s)
                   defer
                   defer
                   apply (rule prems; fail)
                  apply (rule prems(5); fail)
        subgoal
          using prems unfolding N_s_def by (auto simp: inv_of_def)
                defer
                defer
                apply (rule prems; fail)
               apply (rule prems(12); fail)
        using prems unfolding N_s_def T_s_def by (auto 3 0 simp: trans_of_def p_def N_s_length)
    with \<open>length P = p\<close> obtain a where "product_ta \<turnstile> \<langle>L, u\<rangle> \<rightarrow>\<^bsub>(a, Syn (ci, mi) (co, mo))\<^esub> \<langle>L', u'\<rangle>"
      by (auto elim!: product_sync_complete)
    with prems inv obtain g r where step:
        "((L, s), g, a, r, (L', s')) \<in> prod_trans_s"
        "u \<turnstile> g" "[r\<rightarrow>0]u = u'" "u' \<turnstile> inv_of product_ta L'"
        apply atomize_elim
      unfolding prod_trans_s_def by - (erule step_a.cases; auto; blast) (* XXX Slow *)
        (* XXX Simproc for instantiations from equality? *)
    then have "((L, s), g, a, r, (L', s')) \<in> trans_of prod_ta"
      by (simp add: prod_trans_def trans_of_def prod_ta_def)
    moreover have "length L' = p"
      using length_L \<open>L' = _\<close> by auto
    ultimately show ?thesis
      apply -
      apply (rule step_a)
      apply rule
      using step(2-) by force+
  qed

  lemma A_unfold:
    "A = (N, P)"
    by simp

  thm states_step

  lemma prod_sound':
    assumes step: "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>"
    shows "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle> \<and> product_ta \<turnstile> \<langle>L, u\<rangle> \<rightarrow> \<langle>L', u'\<rangle>
           \<and> (\<forall>p<length P. (P ! p) (L' ! p) s')"
    using assms proof cases
    case (step_t d)
    then show ?thesis
    proof cases
      case prems: 1
      then have "product_ta \<turnstile> \<langle>L, u\<rangle> \<rightarrow>\<^bsup>d\<^esup> \<langle>L', u'\<rangle>" unfolding inv_of_simp by fast
      moreover from product_delay_sound[OF this] prems(1-3) have "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"
        apply simp
        apply (subst A_unfold)
        apply (rule step_sn_t)
        by (auto simp: N_s_def inv_of_def step_t.simps N_s_length p_def Len intro: \<open>0 \<le> d\<close>)
      ultimately show ?thesis using prems inv by fast
    qed
  next
    case (step_a a)
    from Len have [simp]: "length P = p" by (simp add: p_def)
    from step_a show ?thesis
    proof cases
      case prems: (1 g r)
      from this(1) show ?thesis
        apply -
      proof (drule prod_ta_cases, erule disjE, goal_cases)
        case 1
        then obtain c m where *:
          "Some s' = m s" "\<forall>q<p. (P ! q) (L ! q) s"
          "\<forall>q<p. (P ! q) (L' ! q) s'" "product_ta \<turnstile> L \<longrightarrow>\<^bsup>g,(a, Act (c, m)),r\<^esup> L'" "c s"
          unfolding prod_trans_i_def by auto
        with prems have "product_ta \<turnstile> \<langle>L, u\<rangle> \<rightarrow>\<^bsub>(a, Act (c, m))\<^esub> \<langle>L', u'\<rangle>"
          unfolding inv_of_simp by (metis I'_simp step_a.intros)
        moreover from product_action_sound[OF this] prems(3-4) have "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"
          apply safe
          apply (simp add: N_s_def trans_of_def N_s_length T_s_def)
          apply (simp only: ex_simps[symmetric])
          apply (erule exE, erule exE)
          apply (subst A_unfold)
          apply (rule step_sn_i)
                     apply blast
          using *(3) by (auto simp: N_s_def inv_of_def p_def \<open>Some s' = m s\<close> intro: \<open>c s\<close>)
        ultimately show ?thesis using * by auto
      next
        case 2
        then obtain ci co mi mo si where *:
          "Some s' = mi si" "Some si = mo s" "\<forall>q<p. (P ! q) (L ! q) s"
          "\<forall>q<p. (P ! q) (L' ! q) s'" "product_ta \<turnstile> L \<longrightarrow>\<^bsup>g,(a, Syn (ci, mi) (co, mo)),r\<^esup> L'"
          "ci s" "co s"
          unfolding prod_trans_s_def by auto
        with prems have "product_ta \<turnstile> \<langle>L, u\<rangle> \<rightarrow>\<^bsub>(a, Syn (ci, mi) (co, mo))\<^esub> \<langle>L', u'\<rangle>"
          unfolding inv_of_simp by (metis I'_simp step_a.intros)
        moreover from product_action_sound[OF this] prems(3-4) have "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"
          apply safe
          apply (simp add: N_s_def trans_of_def N_s_length T_s_def)
          apply (simp only: ex_simps[symmetric])
          apply (erule exE, erule exE, erule exE, erule exE)
          apply (subst A_unfold)
          apply (rule step_sn_s)
                            apply blast
                           apply blast
          using *(4) by (auto simp: N_s_def inv_of_def p_def \<open>Some s' = _\<close> \<open>Some si = _\<close> intro: *(6-)) (* Slow *)
        ultimately show ?thesis using * by auto
      qed
    qed
  qed

  lemmas prod_sound = prod_sound'[THEN conjunct1]
  lemmas prod_inv_1 = prod_sound'[THEN conjunct2, THEN conjunct1]
  lemmas prod_inv_2 = prod_sound'[THEN conjunct2, THEN conjunct2]

  lemma states_prod_step[intro]:
    "L' \<in> states" if "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>"
    using that by (intro states_product_step prod_inv_1)

  lemma inv_prod_step[intro]:
    "\<forall>p<length P. (P ! p) (L' ! p) s'" if "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>"
    using that by (intro states_product_step prod_inv_2)

  lemma prod_steps_sound:
    assumes step: "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow>* \<langle>(L', s'), u'\<rangle>"
    shows "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L', s', u'\<rangle>"
    using step states inv
  proof (induction A \<equiv> prod_ta l \<equiv> "(L, s)" _ l' \<equiv> "(L', s')" _ arbitrary: L s rule: steps.induct)
    case (refl u)
    then show ?case by blast
  next
    case prems: (step u l' u' u'' L s)
    obtain L'' s'' where "l' = (L'', s'')" by force
    interpret interp: Prod_TA A L s by (standard; rule prems Len)
    from prems(3)[OF \<open>l' = _\<close>] prems(1,2,4-) have *: "A \<turnstile> \<langle>L'', s'', u'\<rangle> \<rightarrow>* \<langle>L', s', u''\<rangle>"
      unfolding \<open>l' = _\<close>
      by (metis Prod_TA_Defs'.states'_simp interp.states_prod_step interp.inv_prod_step)
    show ?case
      apply (rule stepI2)
      using * prems by (auto simp: \<open>l' = _\<close> intro: interp.prod_sound)
  qed

  lemma prod_steps_complete:
    "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow>* \<langle>(L', s'), u'\<rangle>" if "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L', s', u'\<rangle>"
    using that states inv proof (induction A \<equiv> A L _ _ _ _ _ rule: steps_sn.induct)
    case (refl L s u)
    then show ?case by blast
  next
    case prems: (step L s u L' s' u' L'' s'' u'')
    interpret interp: Prod_TA A L' s' apply standard
      using prems by - (assumption | rule Prod_TA_Defs'.states_steps Len Prod_TA_Defs'.inv_steps)+
    from prems show ?case by - (rule steps_altI, auto intro!: interp.prod_complete)
  qed

  lemma prod_correct:
    "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow>* \<langle>(L', s'), u'\<rangle> \<longleftrightarrow> A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>* \<langle>L', s', u'\<rangle>"
    by (metis prod_steps_complete prod_steps_sound)

  end (* End context: network + valid start state *)

end (* End of theory *)