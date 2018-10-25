theory Simple_Network_Language_Model_Checking
  imports Simple_Network_Language_Impl_Refine
begin

section \<open>Product Bisimulation\<close>

text \<open>
  We have proved the necessary theorems already but we need to lift it to
  the case where delay and action transitions are strictly alternating.
\<close>
inductive step_u' ::
  "('a, 's, 'c, 't :: time, 'x, 'v :: linorder) nta \<Rightarrow> 's list \<Rightarrow> ('x \<rightharpoonup> 'v) \<Rightarrow> ('c, 't) cval
  \<Rightarrow> 's list \<Rightarrow> ('x \<rightharpoonup> 'v) \<Rightarrow> ('c, 't) cval \<Rightarrow> bool"
("_ \<turnstile> \<langle>_, _, _\<rangle> \<rightarrow> \<langle>_, _, _\<rangle>" [61,61,61,61] 61) where
  "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L'', s'', u''\<rangle>" if
  "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow>\<^bsub>Del\<^esub> \<langle>L', s', u'\<rangle>"
  "a \<noteq> Del"
  "A \<turnstile> \<langle>L', s', u'\<rangle> \<rightarrow>\<^bsub>a\<^esub> \<langle>L'', s'', u''\<rangle>"

inductive_cases step'_elims: "A \<turnstile>' \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>"

inductive_cases step_u'_elims: "A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>"

theorem Bisimulation_Invariant_strong_intro:
  fixes A :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
    and P :: "'a \<Rightarrow> bool"
    and B :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
  assumes "\<And>a b. A a b \<Longrightarrow> P a \<Longrightarrow> B a b"
    and "\<And>a b. B a b \<Longrightarrow> P a \<Longrightarrow> A a b"
    and "\<And>a b. P a \<Longrightarrow> A a b \<Longrightarrow> P b"
  shows "Bisimulation_Invariant A B (=) P P"
  apply standard
  subgoal A for a b a'
    by (blast intro: assms)
  subgoal B for a b a'
    by (blast intro: assms)
  subgoal C for a b
    by (rule assms)
  subgoal D for a b
    by (rule C, assumption) (rule assms)
  done

context Prod_TA
begin

definition
  "all_prop L s = (L \<in> states \<and> bounded bounds s)"

lemma all_prop_boundedD[dest]:
  "bounded bounds s" if "all_prop L s"
  using that unfolding all_prop_def ..

lemma all_prop_statesD[dest]:
  "L \<in> states" if "all_prop L s"
  using that unfolding all_prop_def ..

lemma prod_action_step_not_eq_delay:
  "a \<noteq> Del" if "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow>\<^bsub>a\<^esub> \<langle>(L', s'), u'\<rangle>"
  using that
  apply cases
  unfolding trans_of_def
  unfolding prod_ta_def trans_prod_def
  by (auto simp: trans_int_def trans_bin_def trans_broad_def)

lemma prod_all_prop_inv:
  "all_prop L' s'" if "all_prop L s" "prod_ta \<turnstile> \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>"
  using that unfolding all_prop_def
  by (auto elim: bounded_inv states_inv simp: step_iff[symmetric])

interpretation prod_bisim:
  Bisimulation_Invariant
  "(\<lambda> (L, s, u) (L', s', u'). prod_ta \<turnstile>' \<langle>(L, s), u\<rangle> \<rightarrow> \<langle>(L', s'), u'\<rangle>)"
  "(\<lambda> (L, s, u) (L', s', u'). A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>)"
  "(=)"
  "(\<lambda> (L, s, u). all_prop L s)"
  "(\<lambda> (L, s, u). all_prop L s)"
  apply (rule Bisimulation_Invariant_strong_intro; clarsimp)
  subgoal
    by (auto intro: step_u'.intros
             dest: action_sound prod_action_step_not_eq_delay delay_sound elim!: step'_elims)
  subgoal
    by (auto 4 4 dest: prod_all_prop_inv action_complete elim: delay_complete elim!: step_u'_elims)
  subgoal
    by (auto intro: prod_all_prop_inv elim!: step'_elims)
  done

lemmas prod_bisim_intro = prod_bisim.Bisimulation_Invariant_axioms

end (* Prod TA *)


section \<open>The final semantics\<close>

text \<open>State formulas\<close>
datatype ('s, 'a, 'b) sexp =
  \<comment> \<open>Boolean connectives\<close>
  not "('s, 'a, 'b) sexp" | "and" "('s, 'a, 'b) sexp" "('s, 'a, 'b) sexp" |
  or "('s, 'a, 'b) sexp" "('s, 'a, 'b) sexp" | imply "('s, 'a, 'b) sexp" "('s, 'a, 'b) sexp" |
  \<comment> \<open>Does var \<open>a\<close> equal \<open>x\<close>?\<close>
  eq 'a 'b |
  le 'a 'b |
  lt 'a 'b |
  ge 'a 'b |
  gt 'a 'b |
  \<comment> \<open>Is procces \<open>i\<close> in location \<open>l\<close>?\<close>
  loc nat 's

datatype ('s, 'a, 'b) formula =
  EX "('s, 'a, 'b) sexp" | EG "('s, 'a, 'b) sexp" | AX "('s, 'a, 'b) sexp" | AG "('s, 'a, 'b) sexp"
| Leadsto "('s, 'a, 'b) sexp" "('s, 'a, 'b) sexp"

fun check_sexp :: "'s list \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> ('s, 'a, 'b :: linorder) sexp \<Rightarrow> bool" where
  "check_sexp L s (not e) \<longleftrightarrow> \<not> check_sexp L s e" |
  "check_sexp L s (and e1 e2) \<longleftrightarrow> check_sexp L s e1 \<and> check_sexp L s e2" |
  "check_sexp L s (sexp.or e1 e2) \<longleftrightarrow> check_sexp L s e1 \<or> check_sexp L s e2" |
  "check_sexp L s (imply e1 e2) \<longleftrightarrow> check_sexp L s e1 \<longrightarrow> check_sexp L s e2" |
  "check_sexp L s (eq i x) \<longleftrightarrow> s i = x" |
  "check_sexp L s (le i x) \<longleftrightarrow> s i \<le> x" |
  "check_sexp L s (lt i x) \<longleftrightarrow> s i < x" |
  "check_sexp L s (ge i x) \<longleftrightarrow> s i \<ge> x" |
  "check_sexp L s (gt i x) \<longleftrightarrow> s i > x" |
  "check_sexp L s (loc i x) \<longleftrightarrow> L ! i = x"

definition models ("_,_ \<Turnstile>\<^sub>_ _" [61,61] 61) where
  "A,a\<^sub>0 \<Turnstile>\<^sub>n \<Phi> \<equiv> (case \<Phi> of
    formula.EX \<phi> \<Rightarrow>
      Graph_Defs.Ex_ev
        (\<lambda> (L, s, u) (L', s', u'). A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>)
        (\<lambda> (L, s, _). check_sexp L s \<phi>)
  | formula.EG \<phi> \<Rightarrow>
      Graph_Defs.Ex_alw
        (\<lambda> (L, s, u) (L', s', u'). A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>)
        (\<lambda> (L, s, _). check_sexp L s \<phi>)
  | formula.AX \<phi> \<Rightarrow>
      Graph_Defs.Alw_ev
        (\<lambda> (L, s, u) (L', s', u'). A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>)
        (\<lambda> (L, s, _). check_sexp L s \<phi>)
  | formula.AG \<phi> \<Rightarrow>
      Graph_Defs.Alw_alw
        (\<lambda> (L, s, u) (L', s', u'). A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>)
        (\<lambda> (L, s, _). check_sexp L s \<phi>)
  | formula.Leadsto \<phi> \<psi> \<Rightarrow>
      Graph_Defs.leadsto
        (\<lambda> (L, s, u) (L', s', u'). A \<turnstile> \<langle>L, s, u\<rangle> \<rightarrow> \<langle>L', s', u'\<rangle>)
        (\<lambda> (L, s, _). check_sexp L s \<phi>)
        (\<lambda> (L, s, _). check_sexp L s \<psi>)
  ) a\<^sub>0
  "

lemmas models_iff = models_def[unfolded Graph_Defs.Ex_alw_iff Graph_Defs.Alw_alw_iff]

print_locale Reachability_Problem_Impl

section \<open>Instantiating the Model Checking Locale\<close>

text \<open>This locale certifies that a given local clock ceiling is correct.\<close>
locale Simple_Network_Impl_nat_ceiling =
  Simple_Network_Impl_nat +
  fixes k :: "nat list list list"
  assumes k_ceiling:
    "\<forall>i < n_ps. \<forall>(l, g) \<in> set ((snd o snd) (automata ! i)).
      \<forall>(x, m) \<in> collect_clock_pairs g. m \<le> int (k ! i ! l ! x)"
    "\<forall>i < n_ps. \<forall>(l, g, _) \<in> set ((fst o snd) (automata ! i)).
      (\<forall>(x, m) \<in> collect_clock_pairs g. m \<le> int (k ! i ! l ! x))"
  and k_resets:
    "\<forall> i < n_ps. \<forall> (l, g, a, upd, r, l') \<in> set ((fst o snd) (automata ! i)).
       \<forall> c \<in> {0..<m+1} - set r. k ! i ! l' ! c \<le> k ! i ! l ! c"
  and k_length:
    "length k = n_ps" "\<forall> i < n_ps. length (k ! i) = length ((fst o snd) (automata ! i))"
    "\<forall> xs \<in> set k. \<forall> xxs \<in> set xs. length xxs = m + 1"
  and k_0:
    "\<forall> i < n_ps. \<forall> l < length ((fst o snd) (automata ! i)). k ! i ! l ! 0 = 0"
begin

text \<open>
The ceiling \<open>k\<close> is correct for each individual automaton in the network.
We now construct a ceiling for the product automaton:
\<close>
definition "k_fun l c \<equiv> Max {k ! i ! (fst l ! i) ! c | i . i < n_ps}"

lemma inv_unambiguous:
  "\<forall>(_, _, inv) \<in> set automata. distinct (map fst inv)"
  sorry

lemma (in -) default_map_of_distinct:
  "(k, default_map_of x xs k) \<in> set xs \<union> {(k, x)}" if "distinct (map fst xs)"
  unfolding default_map_of_alt_def by clarsimp (simp add: map_of_eq_Some_iff[OF that])

lemma N_inv:
  "(L ! i, inv (N i) (L ! i)) \<in> set ((snd o snd) (automata ! i)) \<union> {(L ! i, [])}"
  if "i < n_ps" "L \<in> states"
  unfolding N_def comp_def fst_conv snd_conv inv_def
  using that
  apply (subst nth_map)
   apply (simp add: n_ps_def)
  apply (clarsimp split: prod.split simp: automaton_of_def)
  subgoal for _ _ xs
    using default_map_of_distinct[of xs "L ! i" "[]"] inv_unambiguous that(1)
    by (auto dest!: nth_mem simp: n_ps_def)
  done

lemma (in -) subset_nat_0_atLeastLessThan_conv:
  "S \<subseteq> {0..<n::nat} \<longleftrightarrow> (\<forall> x \<in> S. x < n)"
  by auto

lemma k_ceiling_1:
  "\<forall>l \<in> states'. \<forall>(x,m) \<in> clkp_set prod_ta l. m \<le> k_fun l x"
proof safe
  fix L s c x
  assume \<open>(L, s) \<in> states'\<close> \<open>(c, x) \<in> Closure.clkp_set prod_ta (L, s)\<close>
   have "0 < c" "c \<le> m"
  proof -
    from \<open>(c, x) \<in> _\<close> have "(c, x) \<in> Timed_Automata.clkp_set prod_ta"
      unfolding TA_clkp_set_unfold by auto
    with clock_range show "0 < c" "c \<le> m"
      by auto
  qed
  from \<open>_ \<in> states'\<close> have \<open>L \<in> states\<close>
    by auto
  have Max_aux: "x \<le> int (Max {k ! i ! (L ! i) ! c |i. i < n_ps})"
    if "x \<le> int (k ! p ! (L ! p) ! c)" "p < n_ps" for p
  proof -
    from \<open>p < n_ps \<close> have "k ! p ! (L ! p) ! c \<le> Max {k ! i ! (L ! i) ! c |i. i < n_ps}"
      by (intro Max_ge) auto
    with \<open>x \<le> _\<close> show ?thesis
      by simp
  qed
  from \<open>(c, x) \<in> _\<close> show \<open>x \<le> k_fun (L, s) c\<close>
    unfolding clkp_set_def
  proof safe
    assume \<open>(c, x) \<in> Closure.collect_clki (inv_of prod_ta) (L, s)\<close>
    then show \<open>x \<le> k_fun (L, s) c\<close>
      using k_ceiling(1) unfolding collect_clki_def
      by (force intro: Max_aux dest: N_inv[OF _ \<open>_ \<in> states\<close>]
          simp: prod_inv_def collect_clock_pairs_def k_fun_def
          )
  next
    assume \<open>(c, x) \<in> Closure.collect_clkt (trans_of prod_ta) (L, s)\<close>
    then show \<open>x \<le> k_fun (L, s) c\<close>
      unfolding collect_clkt_def
      apply (clarsimp simp: trans_prod_def collect_clock_pairs_def k_fun_def)
      apply safe
      subgoal
        using k_ceiling(2) unfolding trans_int_def
        apply (clarsimp simp: mem_trans_N_iff L_len subset_nat_0_atLeastLessThan_conv)
        apply (fastforce intro!: Max_aux simp: collect_clock_pairs_def)
        done
      subgoal
        using k_ceiling(2) unfolding trans_bin_def
        apply (clarsimp simp: mem_trans_N_iff L_len subset_nat_0_atLeastLessThan_conv)
        apply (erule disjE)
         apply (force intro!: Max_aux simp: collect_clock_pairs_def)+
        done
      subgoal
        using k_ceiling(2) unfolding trans_broad_def
        apply (clarsimp simp: mem_trans_N_iff L_len subset_nat_0_atLeastLessThan_conv)
        apply (erule disjE)
         apply (fastforce intro!: Max_aux simp: collect_clock_pairs_def)
        apply (erule bexE)
        apply (force intro!: Max_aux simp: collect_clock_pairs_def)
        done
      done
  qed
qed

lemma k_fun_mono:
  "k_fun (L, s) c \<le> k_fun (L', s') c" if "\<forall>i < n_ps. k ! i ! (L ! i) ! c \<le> k ! i ! (L' ! i) ! c"
  unfolding k_fun_def
  apply (cases "n_ps = 0")
   apply (simp; fail)
  apply (rule Max.boundedI)
    apply (simp; fail)
   apply blast
  apply safe
  subgoal for _ i
    using that by - (rule order.trans[where b = "k ! i ! (L' ! i) ! c"], auto intro: Max_ge)
  done

lemma (in -) fold_upds_aux1:
  "fold (\<lambda>p L. L[p := g p]) ps xs ! i = xs ! i" if \<open>i \<notin> set ps\<close>
  using that by (induction ps arbitrary: xs) auto

lemma (in -) fold_upds_aux2:
  "fold (\<lambda>p L. L[p := g p]) ps xs ! i = g i" if \<open>distinct ps\<close> \<open>i \<in> set ps\<close> \<open>i < length xs\<close>
  using that by (induction ps arbitrary: xs) (auto simp: fold_upds_aux1)

lemma (in -) fold_upds_aux_length:
  "length (fold (\<lambda>p L. L[p := g p]) ps xs) = length xs"
  by (induction ps arbitrary: xs) auto

lemma k_ceiling_2:
  "\<forall>l g a r l'. \<forall> c \<le> m. prod_ta \<turnstile> l \<longrightarrow>\<^bsup>g,a,r\<^esup> l' \<and> c \<notin> set r \<longrightarrow> k_fun l' c \<le> k_fun l c"
proof safe
  fix L s g a r L' s' c
  assume \<open>c \<le> m\<close> \<open>prod_ta \<turnstile> (L, s) \<longrightarrow>\<^bsup>g,a,r\<^esup> (L', s')\<close> \<open>c \<notin> set r\<close>
  then show \<open>k_fun (L', s') c \<le> k_fun (L, s) c\<close>
    apply simp
    unfolding trans_prod_def
    apply auto
    subgoal
      using k_resets
      unfolding trans_int_def
      apply clarsimp
      apply (rule k_fun_mono)
      apply (clarsimp simp: mem_trans_N_iff L_len subset_nat_0_atLeastLessThan_conv)
      subgoal for f p aa l' i
        by (cases "p = i"; force simp add: L_len)
      done
    subgoal
      using k_resets
      unfolding trans_bin_def
      apply clarsimp
      apply (rule k_fun_mono)
      apply (clarsimp simp: mem_trans_N_iff L_len subset_nat_0_atLeastLessThan_conv)
      subgoal for _ _ p q g1 f1 r1 l1' g2 f2 r2 l2' i
        by (cases "p = i"; cases "q = i"; force simp add: L_len)
      done
    subgoal
      using k_resets
      unfolding trans_broad_def
      apply clarsimp
      apply (rule k_fun_mono)
      apply (clarsimp simp: mem_trans_N_iff L_len subset_nat_0_atLeastLessThan_conv)
      subgoal premises prems for s'a aa p ga f ra l' gs fs rs ls' ps i
      proof (cases "p = i")
        case True
        with \<open>p \<notin> _\<close> \<open>i < _\<close> \<open>L \<in> states\<close> have "fold (\<lambda>p L. L[p := ls' p]) ps L[p := l'] ! i = l'"
          by (simp add: L_len fold_upds_aux_length)
        with prems \<open>p = i\<close> show ?thesis
          by (fastforce simp add: L_len)
      next
        case False
        then have *: "fold (\<lambda>p L. L[p := ls' p]) ps L[p := l'] ! i
          = fold (\<lambda>p L. L[p := ls' p]) ps L ! i"
          by simp
        show ?thesis
        proof (cases "i \<in> set ps")
          case True
          then have **: "fold (\<lambda>p L. L[p := ls' p]) ps L ! i = ls' i"
            using \<open>distinct ps\<close> \<open>i < n_ps\<close> \<open>L \<in> states\<close> by (auto simp: fold_upds_aux2)
          moreover have
            "(L ! i, gs i, In aa, fs i, rs i, ls' i) \<in> set (fst (snd (automata ! i)))"
            using \<open>p \<noteq> i\<close> True prems by fast
          moreover have "c\<in>{0..<Suc m} - set (rs i)"
            using \<open>p \<noteq> i\<close> True prems by force
          ultimately show ?thesis
            using prems(2) \<open>i < n_ps\<close> by (auto 4 3 simp add: *)
        next
          case False
          with \<open>p \<noteq> i\<close> show ?thesis
            by (simp add: fold_upds_aux1)
        qed
      qed
      done
    done
qed






print_locale Reachability_Problem_Defs

sublocale reach: Reachability_Problem_Defs
  l\<^sub>0
  F
  m
  prod_ta
  k
  by standard

print_locale Reachability_Problem

sublocale reach1: Reachability_Problem
  l\<^sub>0
  F
  m
  prod_ta
  k
  apply standard
  subgoal
    sorry
subgoal
    sorry
subgoal
    sorry
subgoal
    sorry
  done


lemma transition_rel_anti_mono:
  "transition_rel S \<subseteq> transition_rel R" if "R \<subseteq> S"
  using that unfolding transition_rel_def by auto

lemma inv_rel_anti_mono:
  "inv_rel A S \<subseteq> inv_rel A R" if "R \<subseteq> S"
  using that unfolding inv_rel_def fun_rel_def b_rel_def by auto

lemma states'_alt_def:
  "states' = {(L, s). L \<in> states \<and> bounded bounds s}"
  unfolding states'_def bounded_def dom_bounds_eq by auto

lemma states'_superset:
  "{l\<^sub>0} \<union> Normalized_Zone_Semantics_Impl_Refine.state_set trans_prod \<subseteq> states'"
  (is "{l\<^sub>0} \<union> ?S \<subseteq> states'")
proof -
  have "?S \<subseteq> states'"
  proof clarsimp
    fix L s
    assume "(L, s) \<in> ?S"
    then have "L \<in> states"
      using state_set_states[unfolded trans_of_prod] by blast
    moreover have "bounded bounds s"
      using \<open>(L, s) \<in> _\<close>
      unfolding state_set_def
      unfolding trans_prod_def
      unfolding trans_int_def trans_bin_def trans_broad_def
      by auto
    ultimately show "(L, s) \<in> states'"
      by (auto simp: states'_alt_def)
  qed
  moreover have "l\<^sub>0 \<in> states'"
    sorry
  ultimately show ?thesis
    by simp
qed










sublocale impl: Reachability_Problem_Impl
  trans_from
  inv_fun
  "\<lambda>_. True"
  some_ceiling
  l\<^sub>0i
  prod_ta
  l\<^sub>0
  F
  m
  k
  trans_impl loc_rel
  apply standard

(* trans_from *)
  subgoal
    unfolding trans_of_prod
    apply (rule set_mp[of "transition_rel states'", OF _ trans_from_correct])
    apply (rule transition_rel_anti_mono)
    apply (rule states'_superset)
    done

(* trans_impl *)
  subgoal
    apply (rule trans_from_refine)
    done

(* inv_fun *)
  subgoal
    unfolding trans_of_prod
    thm set_mp[OF _ inv_fun_inv_of']
    term inv_fun
    apply (rule set_mp[OF _ inv_fun_inv_of'[where R = loc_rel and S = "{(s, s'). state_rel s' s}"]])
     apply (rule inv_rel_anti_mono[OF states'_superset])
    unfolding loc_rel_def by auto

(* F_fun *)
  subgoal
    sorry

(* ceiling *)
  subgoal
    sorry

(* loc_rel *)
  subgoal
    sorry

  subgoal for l li li'
    unfolding trans_of_prod
    apply (drule set_mp[OF states'_superset])
    by (rule state_rel_left_unique)

  subgoal for l l' li
    unfolding trans_of_prod
    apply (rule state_rel_right_unique)
       apply (rule set_mp[OF states'_superset] | assumption)+
    done
  done

end (* Simple_Network_Impl_nat *)

end (* Theory *)