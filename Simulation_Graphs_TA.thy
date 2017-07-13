theory Simulation_Graphs_TA
  imports Simulation_Graphs
begin

section \<open>Instantiation of Simulation Locales\<close>

subsection \<open>Additional Lemmas on Regions\<close>

context AlphaClosure
begin

context
  fixes l l' :: 's and A :: "('a, 'c, t, 's) ta"
  assumes valid_abstraction: "valid_abstraction A X k"
begin

interpretation alpha: AlphaClosure_global _ "k l" "\<R> l" by standard (rule finite)
lemma [simp]: "alpha.cla = cla l" unfolding alpha.cla_def cla_def ..

interpretation alpha': AlphaClosure_global _ "k l'" "\<R> l'" by standard (rule finite)
lemma [simp]: "alpha'.cla = cla l'" unfolding alpha'.cla_def cla_def ..

lemma regions_poststable':
  assumes
    "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>a\<^esub> \<langle>l',Z'\<rangle>" "Z \<subseteq> V" "R' \<in> \<R> l'" "R' \<inter> Z' \<noteq> {}"
  shows "\<exists> R \<in> \<R> l. A,\<R> \<turnstile> \<langle>l,R\<rangle> \<leadsto>\<^bsub>a\<^esub> \<langle>l',R'\<rangle> \<and> R \<inter> Z \<noteq> {}"
using assms proof (induction A \<equiv> A l \<equiv> l _ _ l' \<equiv> l' _rule: step_z.induct)
  case A: (step_t_z Z)
  from \<open>R' \<inter> (Z\<^sup>\<up> \<inter> {u. u \<turnstile> inv_of A l}) \<noteq> {}\<close> obtain u d where u:
    "u \<in> Z" "u \<oplus> d \<in> R'" "u \<oplus> d \<turnstile> inv_of A l" "0 \<le> d"
    unfolding zone_delay_def by blast+
  with alpha.closure_subs[OF A(2)] obtain R where R1: "u \<in> R" "R \<in> \<R> l"
    by (simp add: cla_def) blast
  from \<open>Z \<subseteq> V\<close> \<open>u \<in> Z\<close> have "\<forall>x\<in>X. 0 \<le> u x" unfolding V_def by fastforce
  from region_cover'[OF this] have R: "[u]\<^sub>l \<in> \<R> l" "u \<in> [u]\<^sub>l" by auto
  from SuccI2[OF \<R>_def' this(2,1) \<open>0 \<le> d\<close> HOL.refl] u(2) have v'1:
    "[u \<oplus> d]\<^sub>l \<in> Succ (\<R> l) ([u]\<^sub>l)" "[u \<oplus> d]\<^sub>l \<in> \<R> l"
    by auto
  from alpha.regions_closed'_spec[OF R(1,2) \<open>0 \<le> d\<close>] have v'2: "u \<oplus> d \<in> [u \<oplus> d]\<^sub>l" by simp
  from valid_abstraction have
    "\<forall>(x, m)\<in>clkp_set A l. m \<le> real (k l x) \<and> x \<in> X \<and> m \<in> \<nat>"
    by (auto elim!: valid_abstraction.cases)
  then have
    "\<forall>(x, m)\<in>collect_clock_pairs (inv_of A l). m \<le> real (k l x) \<and> x \<in> X \<and> m \<in> \<nat>"
    unfolding clkp_set_def collect_clki_def inv_of_def by fastforce
  from ccompatible[OF this, folded \<R>_def'] v'1(2) v'2 u(2,3) have
    "[u \<oplus> d]\<^sub>l \<subseteq> \<lbrace>inv_of A l\<rbrace>"
    unfolding ccompatible_def ccval_def by auto
  from
    alpha.valid_regions_distinct_spec[OF v'1(2) _ v'2 \<open>u \<oplus> d \<in> R'\<close>] \<open>R' \<in> _\<close> \<open>l = l'\<close>
    alpha.region_unique_spec[OF R1]
  have "[u \<oplus> d]\<^sub>l = R'" "[u]\<^sub>l = R" by auto
  from valid_abstraction \<open>R \<in> _\<close> \<open>_ \<in> Succ (\<R> l) _\<close> \<open>_ \<subseteq> \<lbrace>inv_of A l\<rbrace>\<close> have
    "A,\<R> \<turnstile> \<langle>l, R\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l, R'\<rangle>"
    by (auto simp: comp_def \<open>[u \<oplus> d]\<^sub>l = R'\<close> \<open>_ = R\<close>)
  with \<open>l = l'\<close> \<open>R \<in> _\<close> \<open>u \<in> R\<close> \<open>u \<in> Z\<close> show ?case by - (rule bexI[where x = R]; auto)
next
  case A: (step_a_z g a r Z)
  from A(4) obtain u v' where
    "u \<in> Z" and v': "v' = [r\<rightarrow>0]u" "u \<turnstile> g" "v' \<turnstile> inv_of A l'" "v' \<in> R'"
    unfolding zone_set_def by blast
  from \<open>u \<in> Z\<close> alpha.closure_subs[OF A(2)] A(1) obtain u' R where u':
    "u \<in> R" "u' \<in> R" "R \<in> \<R> l"
    by (simp add: cla_def) blast
  then have "\<forall>x\<in>X. 0 \<le> u x" unfolding \<R>_def by fastforce
  from region_cover'[OF this] have "[u]\<^sub>l \<in> \<R> l" "u \<in> [u]\<^sub>l" by auto
  have *:
    "[u]\<^sub>l \<subseteq> \<lbrace>g\<rbrace>" "region_set' ([u]\<^sub>l) r 0 \<subseteq> [[r\<rightarrow>0]u]\<^sub>l'"
    "[[r\<rightarrow>0]u]\<^sub>l' \<in> \<R> l'" "[[r\<rightarrow>0]u]\<^sub>l' \<subseteq> \<lbrace>inv_of A l'\<rbrace>"
  proof -
    from valid_abstraction have "collect_clkvt (trans_of A) \<subseteq> X"
      "\<forall> l g a r l' c. A \<turnstile> l \<longrightarrow>\<^bsup>g,a,r\<^esup> l' \<and> c \<notin> set r \<longrightarrow> k l' c \<le> k l c"
      by (auto elim: valid_abstraction.cases)
    with A(1) have "set r \<subseteq> X" "\<forall>y. y \<notin> set r \<longrightarrow> k l' y \<le> k l y"
      unfolding collect_clkvt_def by (auto 4 8)
    with
      region_set_subs[
        of _ X "k l" _ 0, where k' = "k l'", folded \<R>_def, OF \<open>[u]\<^sub>l \<in> \<R> l\<close> \<open>u \<in> [u]\<^sub>l\<close> finite
        ]
    show "region_set' ([u]\<^sub>l) r 0 \<subseteq> [[r\<rightarrow>0]u]\<^sub>l'" "[[r\<rightarrow>0]u]\<^sub>l' \<in> \<R> l'" by auto
    from valid_abstraction have *:
      "\<forall>l. \<forall>(x, m)\<in>clkp_set A l. m \<le> real (k l x) \<and> x \<in> X \<and> m \<in> \<nat>"
      by (fastforce elim: valid_abstraction.cases)+
    with A(1) have "\<forall>(x, m)\<in>collect_clock_pairs g. m \<le> real (k l x) \<and> x \<in> X \<and> m \<in> \<nat>"
      unfolding clkp_set_def collect_clkt_def by fastforce
    from \<open>u \<in> [u]\<^sub>l\<close> \<open>[u]\<^sub>l \<in> \<R> l\<close> ccompatible[OF this, folded \<R>_def] \<open>u \<turnstile> g\<close> show "[u]\<^sub>l \<subseteq> \<lbrace>g\<rbrace>"
      unfolding ccompatible_def ccval_def by blast
    have **: "[r\<rightarrow>0]u \<in> [[r\<rightarrow>0]u]\<^sub>l'"
      using \<open>R' \<in> \<R> l'\<close> \<open>v' \<in> R'\<close> alpha'.region_unique_spec v'(1) by blast
    from * have
      "\<forall>(x, m)\<in>collect_clock_pairs (inv_of A l'). m \<le> real (k l' x) \<and> x \<in> X \<and> m \<in> \<nat>"
      unfolding inv_of_def clkp_set_def collect_clki_def by fastforce
    from ** \<open>[[r\<rightarrow>0]u]\<^sub>l' \<in> \<R> l'\<close> ccompatible[OF this, folded \<R>_def] \<open>v' \<turnstile> _\<close> show
      "[[r\<rightarrow>0]u]\<^sub>l' \<subseteq> \<lbrace>inv_of A l'\<rbrace>"
      unfolding ccompatible_def ccval_def \<open>v' = _\<close> by blast
  qed
  from * \<open>v' = _\<close> \<open>u \<in> [u]\<^sub>l\<close> have "v' \<in> [[r\<rightarrow>0]u]\<^sub>l'" unfolding region_set'_def by auto
  from alpha'.valid_regions_distinct_spec[OF *(3) \<open>R' \<in> \<R> l'\<close> \<open>v' \<in> [[r\<rightarrow>0]u]\<^sub>l'\<close> \<open>v' \<in> R'\<close>]
  have "[[r\<rightarrow>0]u]\<^sub>l' = R'" .
  from alpha.region_unique_spec[OF u'(1,3)] have "[u]\<^sub>l = R" by auto
  from A valid_abstraction \<open>R \<in> _\<close> * have "A,\<R> \<turnstile> \<langle>l, R\<rangle> \<leadsto>\<^bsub>\<upharpoonleft>a\<^esub> \<langle>l', R'\<rangle>"
    by (auto simp: comp_def \<open>_ = R'\<close> \<open>_ = R\<close>)
  with \<open>R \<in> _\<close> \<open>u \<in> R\<close> \<open>u \<in> Z\<close> show ?case by - (rule bexI[where x = R]; auto)
qed

end (* End of context for fixed locations *)


text \<open>
  Poststability of Closures:
  For every transition in the zone graph and each region in the closure of the resulting zone,
  there exists a similar transition in the region graph.
\<close>
lemma regions_poststable:
  assumes valid_abstraction: "valid_abstraction A X k"
  and A:
    "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l',Z'\<rangle>" "A \<turnstile> \<langle>l', Z'\<rangle> \<leadsto>\<^bsub>\<upharpoonleft>a\<^esub> \<langle>l'',Z''\<rangle>"
    "Z \<subseteq> V" "R'' \<in> \<R> l''" "R'' \<inter> Z'' \<noteq> {}"
  shows "\<exists> R \<in> \<R> l. A,\<R> \<turnstile> \<langle>l,R\<rangle> \<leadsto>\<^sub>a \<langle>l'',R''\<rangle> \<and> R \<inter> Z \<noteq> {}"
proof -
  from A(1) \<open>Z \<subseteq> V\<close> have "Z' \<subseteq> V" by (rule step_z_V)
  from A(1) have [simp]: "l' = l" by auto
  from regions_poststable'[OF valid_abstraction A(2) \<open>Z' \<subseteq> V\<close> \<open>R'' \<in> _\<close> \<open>R'' \<inter> Z'' \<noteq> {}\<close>] obtain R'
    where R': "R'\<in>\<R> l'" "A,\<R> \<turnstile> \<langle>l', R'\<rangle> \<leadsto>\<^bsub>\<upharpoonleft>a\<^esub> \<langle>l'', R''\<rangle>" "R' \<inter> Z' \<noteq> {}"
    by auto
  from regions_poststable'[OF valid_abstraction A(1) \<open>Z \<subseteq> V\<close> R'(1,3)] obtain R where
    "R \<in> \<R> l" "A,\<R> \<turnstile> \<langle>l, R\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l, R'\<rangle>" "R \<inter> Z \<noteq> {}"
    by auto
  with R'(2) show ?thesis by - (rule bexI[where x = "R"]; auto intro: step_r'.intros)
qed

lemma closure_regions_poststable:
  assumes valid_abstraction: "valid_abstraction A X k"
  and A:
    "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l',Z'\<rangle>" "A \<turnstile> \<langle>l', Z'\<rangle> \<leadsto>\<^bsub>\<alpha>(\<upharpoonleft>a)\<^esub> \<langle>l'',Z''\<rangle>"
    "Z \<subseteq> V" "R'' \<in> \<R> l''" "R'' \<subseteq> Z''"
  shows "\<exists> R \<in> \<R> l. A,\<R> \<turnstile> \<langle>l,R\<rangle> \<leadsto>\<^sub>a \<langle>l'',R''\<rangle> \<and> R \<inter> Z \<noteq> {}"
  using A(2) regions_poststable[OF valid_abstraction A(1) _ A(3,4)] A(4,5)
  apply cases
  unfolding cla_def
  apply auto
    oops



end (* End of Alpha Closure *)

context Regions
begin

inductive step_z_beta' ::
  "('a, 'c, t, 's) ta \<Rightarrow> 's \<Rightarrow> ('c, t) zone \<Rightarrow> 'a \<Rightarrow> 's \<Rightarrow> ('c, t) zone \<Rightarrow> bool"
("_ \<turnstile>' \<langle>_, _\<rangle> \<leadsto>\<^bsub>\<beta>(_)\<^esub> \<langle>_, _\<rangle>" [61,61,61,61] 61)
where
  "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l'', Z''\<rangle>" if
  "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l', Z'\<rangle>" "A \<turnstile> \<langle>l', Z'\<rangle> \<leadsto>\<^bsub>\<beta>(\<upharpoonleft>a)\<^esub> \<langle>l'', Z''\<rangle>"

lemma closure_parts_mono:
  "{R \<in> \<R> l. R \<inter> Z \<noteq> {}} \<subseteq> {R \<in> \<R> l. R \<inter> Z' \<noteq> {}}" if
  "Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z \<subseteq> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z'"
proof (clarify, goal_cases)
  case prems: (1 R)
  with that have "R \<subseteq> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z'"
    unfolding cla_def by auto
  from \<open>_ \<noteq> {}\<close> obtain u where "u \<in> R" "u \<in> Z" by auto
  with \<open>R \<subseteq> _\<close> obtain R' where "R' \<in> \<R> l" "u \<in> R'" "R' \<inter> Z' \<noteq> {}" unfolding cla_def by force
  from \<R>_regions_distinct[OF \<R>_def' this(1,2) \<open>R \<in> _\<close>] \<open>u \<in> R\<close> have "R = R'" by auto
  with \<open>R' \<inter> Z' \<noteq> {}\<close> \<open>R \<inter> Z' = {}\<close> show ?case by simp
qed

lemma closure_parts_id:
  "{R \<in> \<R> l. R \<inter> Z \<noteq> {}} = {R \<in> \<R> l. R \<inter> Z' \<noteq> {}}" if
  "Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z = Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z'"
  using closure_parts_mono that by blast

(* XXX All of these should be considered for moving into the locales for global sets of regions *)
context
  fixes l' :: 's and A :: "('a, 'c, t, 's) ta"
  assumes valid_abstraction: "valid_abstraction A X k"
begin

interpretation regions: Regions_global _ _ _ "k l'"
  by standard (rule finite clock_numbering not_in_X non_empty)+

lemmas regions_poststable = regions_poststable[OF valid_abstraction]

lemma clkp_set_clkp_set1:
  "\<exists> l. (c, x) \<in> clkp_set A l" if "(c, x) \<in> Timed_Automata.clkp_set A"
  using that
  unfolding Timed_Automata.clkp_set_def Closure.clkp_set_def
  unfolding Timed_Automata.collect_clki_def Closure.collect_clki_def
  unfolding Timed_Automata.collect_clkt_def Closure.collect_clkt_def
  by fastforce

lemma clkp_set_clkp_set2:
  "(c, x) \<in> Timed_Automata.clkp_set A" if "(c, x) \<in> clkp_set A l" for l
  using that
  unfolding Timed_Automata.clkp_set_def Closure.clkp_set_def
  unfolding Timed_Automata.collect_clki_def Closure.collect_clki_def
  unfolding Timed_Automata.collect_clkt_def Closure.collect_clkt_def
  by fastforce

lemma clock_numbering_le: "\<forall>c\<in>clk_set A. v c \<le> n"
proof
  fix c assume "c \<in> clk_set A"
  then have "c \<in> X"
  proof (safe, clarsimp, goal_cases)
    case (1 x)
    then obtain l where "(c, x) \<in> clkp_set A l" by (auto dest: clkp_set_clkp_set1)
    with valid_abstraction show "c \<in> X" by (auto elim!: valid_abstraction.cases)
  next
    case 2
    with valid_abstraction show "c \<in> X" by (auto elim!: valid_abstraction.cases)
  qed
  with clock_numbering show "v c \<le> n" by auto
qed

lemma beta_alpha_step:
  "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<alpha>(a)\<^esub> \<langle>l', Closure\<^sub>\<alpha>\<^sub>,\<^sub>l' Z'\<rangle>" if
  "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>" "Z \<in> V'"
proof -
  from that obtain Z1' where Z1': "Z' = Approx\<^sub>\<beta> l' Z1'" "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>a\<^esub> \<langle>l', Z1'\<rangle>"
    by (clarsimp elim!: step_z_beta.cases)
  with \<open>Z \<in> V'\<close> have "Z1' \<in> V'"
    using valid_abstraction clock_numbering_le by (auto intro: step_z_V')
  let ?alpha = "Closure\<^sub>\<alpha>\<^sub>,\<^sub>l' Z1'" and ?beta = "Closure\<^sub>\<alpha>\<^sub>,\<^sub>l' (Approx\<^sub>\<beta> l' Z1')"
  have "?beta \<subseteq> ?alpha"
    using regions.approx_\<beta>_closure_\<alpha>'[OF \<open>Z1' \<in> V'\<close>] regions.alpha_interp.closure_involutive
    by (auto 4 3 dest: regions.alpha_interp.cla_mono)
  moreover have "?alpha \<subseteq> ?beta"
    by (intro regions.alpha_interp.cla_mono[simplified] regions.beta_interp.apx_subset)
  ultimately have "?beta = ?alpha" ..
  with Z1' show ?thesis by auto
qed

lemma beta_alpha_region_step:
  "\<exists> R \<in> \<R> l. R \<inter> Z \<noteq> {} \<and> A,\<R> \<turnstile> \<langle>l, R\<rangle> \<leadsto>\<^sub>a \<langle>l', R'\<rangle>" if
  "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>" "Z \<in> V'" "R' \<in> \<R> l'" "R' \<inter> Z' \<noteq> {}"
proof -
  from that(1) obtain l'' Z'' where steps:
    "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l'', Z''\<rangle>" "A \<turnstile> \<langle>l'', Z''\<rangle> \<leadsto>\<^bsub>\<beta>(\<upharpoonleft>a)\<^esub> \<langle>l', Z'\<rangle>"
    by (auto elim!: step_z_beta'.cases)
  with \<open>Z \<in> V'\<close> steps(1) have "Z'' \<in> V'"
    using valid_abstraction clock_numbering_le by (blast intro: step_z_V')
  from beta_alpha_step[OF steps(2) this] have "A \<turnstile> \<langle>l'', Z''\<rangle> \<leadsto>\<^bsub>\<alpha>\<upharpoonleft>a\<^esub> \<langle>l', Closure\<^sub>\<alpha>\<^sub>,\<^sub>l'(Z')\<rangle>" .
  from step_z_alpha.cases[OF this] obtain Z1 where Z1:
    "A \<turnstile> \<langle>l'', Z''\<rangle> \<leadsto>\<^bsub>\<upharpoonleft>a\<^esub> \<langle>l', Z1\<rangle>" "Closure\<^sub>\<alpha>\<^sub>,\<^sub>l'(Z') = Closure\<^sub>\<alpha>\<^sub>,\<^sub>l'(Z1)"
    by metis
  from closure_parts_id[OF this(2)] that(3,4) have "R' \<inter> Z1 \<noteq> {}" by blast
  from regions_poststable[OF steps(1) Z1(1) _ \<open>R' \<in> _\<close> this] \<open>Z \<in> V'\<close> show ?thesis
    by (auto dest: V'_V)
qed

lemma step_z_beta'_steps_z_beta:
  "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^sub>\<beta>* \<langle>l', Z'\<rangle>" if "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>"
  using that by (blast elim: step_z_beta'.cases)

lemma step_z_beta'_V':
  "Z' \<in> V'" if "Z \<in> V'" "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>"
  using that(2)
  by (blast intro:
      step_z_beta'_steps_z_beta steps_z_beta_V'[OF _ valid_abstraction clock_numbering_le that(1)]
      )

end (* End of context for fixed location *)

end (* End of Regions *)


subsection \<open>Instantiation of Double Simulation\<close>

definition state_set :: "('a, 'c, 'time, 's) ta \<Rightarrow> 's set" where
  "state_set A \<equiv> fst ` (fst A) \<union> (snd o snd o snd o snd) ` (fst A)"

lemma finite_trans_of_finite_state_set:
  "finite (state_set A)" if "finite (trans_of A)"
  using that unfolding state_set_def trans_of_def by auto

context Regions
begin

lemma step_z_beta'_state_set:
  "l' \<in> state_set A" if "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>"
  using that by (force elim!: step_z_beta'.cases simp: state_set_def trans_of_def)

context
  fixes l' :: 's
begin

interpretation regions: Regions_global _ _ _ "k l'"
  by standard (rule finite clock_numbering not_in_X non_empty)+

lemma apx_finite:
  "finite {Approx\<^sub>\<beta> l' Z | Z. Z \<subseteq> V}" (is "finite ?S")
proof -
  have "finite regions.\<R>\<^sub>\<beta>"
    by (simp add: regions.beta_interp.finite_\<R>)
  then have "finite {S. S \<subseteq> regions.\<R>\<^sub>\<beta>}"
    by auto
  then have "finite {\<Union> S | S. S \<subseteq> regions.\<R>\<^sub>\<beta>}"
    by auto
  moreover have "?S \<subseteq> {\<Union> S | S. S \<subseteq> regions.\<R>\<^sub>\<beta>}"
    by (auto dest!: regions.beta_interp.apx_in)
  ultimately show ?thesis by (rule finite_subset[rotated])
qed

lemmas apx_subset = regions.beta_interp.apx_subset

lemma step_z_beta'_empty:
  "Z' = {}" if "A \<turnstile>' \<langle>l, {}\<rangle> \<leadsto>\<^bsub>\<beta>a\<^esub> \<langle>l', Z'\<rangle>"
  using that
  by (auto
      elim!: step_z_beta'.cases step_z.cases
      simp: regions.beta_interp.apx_empty zone_delay_def zone_set_def
     )

end (* Global Set of Regions *)

end (* Regions *)


locale Regions_TA = Regions X _ _  k for X :: "'c set" and k :: "'s \<Rightarrow> 'c \<Rightarrow> nat" +
  fixes A :: "('a, 'c, t, 's) ta"
  assumes valid_abstraction: "valid_abstraction A X k"
    and finite_state_set: "finite (state_set A)"
begin

definition "R_of lR = snd ` lR"

definition "from_R l R = {(l, u) | u. u \<in> R}"

lemma from_R_fst:
  "\<forall>x\<in>from_R l R. fst x = l"
  unfolding from_R_def by auto

lemma R_of_from_R [simp]:
  "R_of (from_R l R) = R"
  unfolding R_of_def from_R_def image_def by auto

(* XXX Bundle this? *)
no_notation Regions_Beta.part ("[_]\<^sub>_" [61,61] 61)
notation part'' ("[_]\<^sub>_" [61,61] 61)

definition "C \<equiv> \<lambda> (l, u) (l', u'). A \<turnstile>' \<langle>l, u\<rangle> \<rightarrow> \<langle>l', u'\<rangle>"

definition
  "A1 \<equiv> \<lambda> lR lR'.
    \<exists> l l'. (\<forall> x \<in> lR. fst x = l) \<and> (\<forall> x \<in> lR'. fst x = l')
    \<and> (\<exists> a. A,\<R> \<turnstile> \<langle>l, R_of lR\<rangle> \<leadsto>\<^sub>a \<langle>l', R_of lR'\<rangle>)"

definition
  "A2 \<equiv> \<lambda> lZ lZ'. \<exists> l l'.
      (\<forall> x \<in> lZ. fst x = l) \<and> (\<forall> x \<in> lZ'. fst x = l') \<and> R_of lZ \<in> V' \<and> R_of lZ' \<noteq> {}
    \<and> (\<exists> a. A \<turnstile>' \<langle>l, R_of lZ\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', R_of lZ'\<rangle>)"

definition
  "P1 \<equiv> \<lambda> lR. \<exists> l. (\<forall> x \<in> lR. fst x = l) \<and> l \<in> state_set A \<and> R_of lR \<in> \<R> l"

definition
  "P2 \<equiv> \<lambda> lZ. (\<exists> l \<in> state_set A. \<forall> x \<in> lZ. fst x = l) \<and> R_of lZ \<in> V' \<and> R_of lZ \<noteq> {}"

lemmas sim_defs = C_def A1_def A2_def P1_def P2_def

sublocale sim: Double_Simulation
  C  -- "Concrete step relation"
  A1 -- "Step relation for the first abstraction layer"
  P1 -- "Valid states of the first abstraction layer"
  A2 -- "Step relation for the second abstraction layer"
  P2 -- "Valid states of the second abstraction layer"
proof (standard, goal_cases)
  case (1 S T)
  then show ?case
    unfolding sim_defs
    by (force dest!: bspec step_r'_sound simp: split_beta R_of_def elim!: step'.cases)
next
  case prems: (2 lR' lZ' lZ)
  from prems(1) guess l' unfolding sim_defs Double_Simulation_Defs.closure_def by clarsimp
  note l' = this
  from prems(2) guess l l2 a unfolding sim_defs by clarsimp
  note guessed = this
  with l' have [simp]: "l2 = l'" by auto
  note guessed = guessed[unfolded \<open>l2 = l'\<close>]
  from l'(1,2) guessed(2) have "R_of lR' \<inter> R_of lZ' \<noteq> {}"
    unfolding R_of_def by auto
  from beta_alpha_region_step[OF valid_abstraction, OF guessed(5) \<open>_ \<in> V'\<close> \<open>_ \<in> \<R> l'\<close> this] l'(1)
  obtain R where "R \<in> \<R> l" "R \<inter> R_of lZ \<noteq> {}" "A,\<R> \<turnstile> \<langle>l, R\<rangle> \<leadsto>\<^sub>a \<langle>l', R_of lR'\<rangle>"
    by auto
  then show ?case
    unfolding Double_Simulation_Defs.closure_def sim_defs
    apply -
    apply (rule bexI[where x = "from_R l R"])
     apply (inst_existentials l l' a)
    subgoal
      by (rule from_R_fst)
    subgoal
      by (rule l')
    subgoal
      by simp
    subgoal
      apply safe
       apply (inst_existentials l)
         apply (rule from_R_fst; fail)
      subgoal
        apply (auto elim!: step_r'.cases)
        by (auto 4 4 intro!: bexI[rotated] simp: state_set_def trans_of_def image_def)
       apply (simp; fail)
      subgoal
        using guessed(1) by (auto 4 3 simp: from_R_def image_def R_of_def)
      done
    done
next
  case prems: (3 x y)
  from prems(1) guess lx unfolding P1_def by safe
  note lx = this
  from prems(2) guess ly unfolding P1_def by safe
  note ly = this
  show ?case
  proof (cases "lx = ly")
    case True
    have "R_of x \<noteq> R_of y"
    proof (rule ccontr, simp)
      assume A: "R_of x = R_of y"
      with lx(1) ly(1) \<open>lx = ly\<close> have "x = y"
        by - (rule prod_set_fst_id; auto simp: R_of_def)
      with \<open>x \<noteq> y\<close> show False ..
    qed
    from \<R>_regions_distinct[OF \<R>_def' \<open>R_of x \<in> _\<close> _ \<open>R_of y \<in> _\<close>[folded True] this] have
      "R_of x \<inter> R_of y = {}"
      by auto
    with lx ly \<open>lx = ly\<close> show ?thesis
      by (auto simp: R_of_def)
  next
    case False
    with lx ly show ?thesis by auto
  qed
next
  case 4
  have "finite (\<R> l)" for l
    unfolding \<R>_def by (intro finite_\<R> finite)
  have *: "finite {x. (\<forall> y \<in> x. fst y = l) \<and> R_of x \<in> \<R> l}" (is "finite ?S") for l
  proof -
    have "?S = (\<lambda> y. (\<lambda> x. (l, x)) ` y) ` \<R> l"
      unfolding R_of_def
      apply safe
      subgoal for x
        unfolding image_def by safe (erule bexI[rotated]; force)
      unfolding image_def by auto
    with \<open>finite _\<close> show ?thesis by auto
  qed
  have
    "{x. \<exists>l. (\<forall>x\<in>x. fst x = l) \<and> l \<in> state_set A \<and> R_of x \<in> \<R> l} =
    (\<Union> l \<in> state_set A. ({x. (\<forall> y \<in> x. fst y = l) \<and> R_of x \<in> \<R> l}))"
    by auto
  also have "finite \<dots>" by (blast intro: finite_state_set *)
  finally show ?case unfolding P1_def .
next
  case (5 a)
  then guess l unfolding sim_defs by clarsimp
  note l = this
  from \<open>R_of a \<noteq> {}\<close> obtain u where "u \<in> R_of a" by blast
  with region_cover'[of u] V'_V[OF \<open>_ \<in> V'\<close>] have "u \<in> [u]\<^sub>l" "[u]\<^sub>l \<in> \<R> l"
    unfolding V_def by auto
  with l(1,2) \<open>u \<in> R_of a\<close> show ?case
    by (inst_existentials "(\<lambda> x. (l, x)) ` ([u]\<^sub>l)" l) (force simp: sim_defs R_of_def image_def)+
qed

sublocale Graph_Start_Defs
  "\<lambda> (l, Z) (l', Z'). \<exists> a. A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle> \<and> Z' \<noteq> {}" "(l\<^sub>0, Z\<^sub>0)" .

lemmas step_z_beta'_V' = step_z_beta'_V'[OF valid_abstraction]

inductive
  steps_z_beta' :: "('a, 'c, t, 's) ta \<Rightarrow> 's \<Rightarrow> ('c, t) zone \<Rightarrow> 's \<Rightarrow> ('c, t) zone \<Rightarrow> bool"
("_ \<turnstile>' \<langle>_, _\<rangle> \<leadsto>\<^sub>\<beta>* \<langle>_, _\<rangle>" [61,61,61] 61)
where
  init: "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^sub>\<beta>* \<langle>l', Z'\<rangle>" if "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>" |
  step: "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^sub>\<beta>* \<langle>l', Z'\<rangle>" if "A \<turnstile>' \<langle>l', Z'\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l'', Z''\<rangle>" "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^sub>\<beta>* \<langle>l', Z'\<rangle>"

lemma steps_sim_Steps:
  "sim.Steps (map (\<lambda> (l, Z). from_R l Z) ((l, Z) # xs))" if "steps ((l, Z) # xs)" "Z \<in> V'"
using that proof (induction "(l, Z) # xs" arbitrary: l Z xs)
  case Single
  then show ?case by (auto intro: Graph_Defs.steps.intros)
next
  case (Cons lZ' xs l Z)
  obtain l' Z' where [simp]: "lZ' = (l', Z')" by (metis prod.exhaust)
  from Cons have "Z' \<in> V'"
    by (auto intro: step_z_beta'_V')
  from Cons.prems Cons.hyps(1,2) Cons.hyps(3)[OF \<open>lZ' = _\<close>] show ?case
    apply simp
    apply (rule Graph_Defs.steps.intros)
    by (auto simp: from_R_fst sim_defs intro: step_z_beta'_V')
qed

lemma sim_Steps_steps:
  "steps ((l, Z) # xs)" if "sim.Steps (map (\<lambda> (l, Z). from_R l Z) ((l, Z) # xs))" "Z \<in> V'"
using that proof (induction "map (\<lambda> (l, Z). from_R l Z) ((l, Z) # xs)" arbitrary: l Z xs)
  case (Single x)
  then show ?case by (auto intro: Graph_Defs.steps.intros)
next
  case (Cons x y xs l Z xs')
  then obtain l' Z' ys where [simp]:
    "xs' = (l', Z') # ys" "x = from_R l Z" "y = from_R l' Z'"
    by (cases xs') auto
  with \<open>x # y # _ = _\<close> have "y # xs = map (\<lambda>(x, y). from_R x y) ((l', Z') # ys)" by simp
  from \<open>A2 x y\<close> obtain a where "A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>a\<^esub> \<langle>l', Z'\<rangle> \<and> Z' \<noteq> {}"
      by atomize_elim (simp add: A2_def; auto dest: step_z_beta'_empty simp: from_R_def)
  moreover with Cons.prems step_z_beta'_V' have "Z' \<in> V'" by blast
  moreover from Cons.hyps(3)[OF \<open>y # xs = _\<close> \<open>Z' \<in> V'\<close>] have "steps ((l', Z') # ys)" .
  ultimately show ?case unfolding \<open>xs' = _\<close> by - (rule steps.intros; auto)
qed

lemma sim_steps_equiv:
  "steps ((l, Z) # xs) \<longleftrightarrow> sim.Steps (map (\<lambda> (l, Z). from_R l Z) ((l, Z) # xs))" if "Z \<in> V'"
  using that sim_Steps_steps steps_sim_Steps by fast

text \<open>
  Infinite runs in the simulation graph yield infinite concrete runs, which pass through the same
  closures. However, this lemma is not strong enough for Büchi runs.
\<close>
lemma beta_steps_run_cycle:
  assumes assms: "steps ((l, Z) # xs @ [(l, Z)])" "Z \<in> V'" "Z \<noteq> {}" "l \<in> state_set A"
  shows "\<exists> ys.
    sim.run ys \<and>
    (\<forall>x\<in>sset ys. \<exists> (l, Z) \<in> set xs \<union> {(l, Z)}. fst x = l \<and> snd x \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z) \<and>
    fst (shd ys) = l \<and> snd (shd ys) \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z"
proof -
  have steps: "sim.Steps (from_R l Z # map (\<lambda>(l, Z). from_R l Z) xs @ [from_R l Z])"
    using steps_sim_Steps[OF assms(1,2)] by simp
  from sim.Steps_run_cycle[OF this] obtain ys where ys:
    "sim.run ys"
    "\<forall>x\<in>sset ys. \<exists>a\<in>set (map (\<lambda>(l, Z). from_R l Z) xs) \<union> {from_R l Z}. x \<in> \<Union>sim.closure a"
    "shd ys \<in> \<Union>sim.closure (from_R l Z)"
    using assms(2-) by atomize_elim (auto simp: V'_def from_R_fst sim_defs)
  have *: "fst lu = l" "snd lu \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z" if "lu \<in> \<Union>sim.closure (from_R l Z)" for lu
    using that
      unfolding from_R_def sim_defs sim.closure_def Double_Simulation_Defs.closure_def
     apply safe
    subgoal
      by auto
    unfolding cla_def
    by auto (metis IntI R_of_def empty_iff fst_conv image_subset_iff order_refl snd_conv)
  from ys(3) have "fst (shd ys) = l" "snd (shd ys) \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z" by (auto 4 3 intro: *)
  moreover from ys(2) have
    "\<forall>x\<in>sset ys. \<exists> (l, Z) \<in> set xs \<union> {(l, Z)}. fst x = l \<and> snd x \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z"
    apply safe
    apply (drule bspec, assumption)
    apply safe
    unfolding set_map
     apply safe
    subgoal for a b aa X l2 Z2
      apply (rule bexI[where x = "(l2, Z2)"])
       apply safe
      subgoal
        by (auto 4 3 simp: from_R_def sim.closure_def Double_Simulation_Defs.closure_def sim_defs)
           (metis fst_conv)
      unfolding from_R_def sim.closure_def Double_Simulation_Defs.closure_def cla_def sim_defs
      by auto (metis IntI R_of_def empty_iff fst_conv image_subset_iff order_refl snd_conv)
    using * by force
  ultimately show ?thesis using \<open>sim.run ys\<close> by (inst_existentials ys) auto
qed

end (* Regions TA *)


context Regions_TA
begin

lemma sim_closure_from_R:
  "sim.closure (from_R l Z) = {from_R l Z' | Z'. l \<in> state_set A \<and> Z' \<in> \<R> l \<and> Z \<inter> Z' \<noteq> {}}"
  unfolding sim.closure_def
  unfolding from_R_def P1_def R_of_def
  apply auto
  subgoal premises prems for x l' u
  proof -
    from prems have [simp]: "l' = l" by auto
    from prems show ?thesis by force
  qed
  subgoal
    unfolding image_def by auto
  done

lemma from_R_loc:
  "l' = l" if "(l', u) \<in> from_R l Z"
  using that unfolding from_R_def by auto

lemma from_R_val:
  "u \<in> Z" if "(l', u) \<in> from_R l Z"
  using that unfolding from_R_def by auto

lemma from_R_R_of:
  "from_R l (R_of S) = S" if "\<forall> x \<in> S. fst x = l"
  using that unfolding from_R_def R_of_def by force

lemma run_map_from_R:
  "map (\<lambda>(x, y). from_R x y) (map (\<lambda> lR. ((THE l. \<forall> x \<in> lR. fst x = l), R_of lR)) xs) = xs"
  if "sim.Steps (x # xs)"
  using that
proof (induction "x # xs" arbitrary: x xs)
  case Single
  then show ?case by simp
next
  case (Cons x y xs)
  then show ?case
    apply (subst (asm) A2_def)
    apply simp
    apply clarify
    apply (rule from_R_R_of)
    apply (rule theI)
    unfolding R_of_def by force+
qed

end (* Regions TA *)



locale Regions_TA_Start_State = Regions_TA _ _ _ _ _ A for A :: "('a, 'c, t, 's) ta" +
  fixes l\<^sub>0 :: "'s" and Z\<^sub>0 :: "('c, t) zone"
  assumes start_state: "l\<^sub>0 \<in> state_set A" "Z\<^sub>0 \<in> V'" "Z\<^sub>0 \<noteq> {}"
begin

definition "a\<^sub>0 = from_R l\<^sub>0 Z\<^sub>0"

lemma step_z_beta'_complete:
  assumes "A \<turnstile>' \<langle>l, u\<rangle> \<rightarrow> \<langle>l', u'\<rangle>" "u \<in> Z" "Z \<subseteq> V"
  shows "\<exists> Z' a. A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>a\<^esub> \<langle>l', Z'\<rangle> \<and> u' \<in> Z'"
proof -
  from assms(1) obtain l'' u'' d a where steps:
    "A \<turnstile> \<langle>l, u\<rangle> \<rightarrow>\<^bsup>d\<^esup> \<langle>l'', u''\<rangle>" "A \<turnstile> \<langle>l'', u''\<rangle> \<rightarrow>\<^bsub>a\<^esub> \<langle>l', u'\<rangle>"
    by (force elim!: step'.cases)
  then obtain Z'' where
    "A \<turnstile> \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<tau>\<^esub> \<langle>l'', Z''\<rangle>" "u'' \<in> Z''"
    by (meson \<open>u \<in> Z\<close> step_t_z_complete)
  moreover with steps(2) obtain Z' where
    "A \<turnstile> \<langle>l'', Z''\<rangle> \<leadsto>\<^bsub>\<upharpoonleft>a\<^esub> \<langle>l', Z'\<rangle>" "u' \<in> Z'"
    by (meson \<open>u'' \<in> Z''\<close> step_a_z_complete)
  ultimately show ?thesis using \<open>Z \<subseteq> V\<close>
    by (inst_existentials "Approx\<^sub>\<beta> l' Z'" a)
       ((rule, assumption)+, (drule step_z_V, assumption)+, rule apx_subset)
qed

lemma R_ofI[intro]:
  "Z \<in> R_of S" if "(l, Z) \<in> S"
  using that unfolding R_of_def by force

lemma from_R_I[intro]:
  "(l', u') \<in> from_R l' Z'" if "u' \<in> Z'"
  using that unfolding from_R_def by auto

sublocale sim_complete: Double_Simulation_Finite_Complete
  C  -- "Concrete step relation"
  A1 -- "Step relation for the first abstraction layer"
  P1 -- "Valid states of the first abstraction layer"
  A2 -- "Step relation for the second abstraction layer"
  P2 -- "Valid states of the second abstraction layer"
  a\<^sub>0 -- "Start state"
proof (standard, goal_cases)
  case (1 x y S)
  -- Completeness
  then show ?case
    unfolding sim_defs
    apply clarsimp
    apply (drule step_z_beta'_complete[rotated 2, OF V'_V], assumption)
     apply force
    apply clarify
    subgoal for l u l' u' l'' Z'
      apply (inst_existentials "from_R l' Z'")
       apply (inst_existentials l)
      by (auto intro!: from_R_fst)
    done
next
  case 2
  -- Finiteness
  have "{a. A2\<^sup>*\<^sup>* a\<^sub>0 a} \<subseteq> {from_R l Z | l Z. l \<in> state_set A \<and> Z \<in> {Approx\<^sub>\<beta> l Z | Z. Z \<subseteq> V}} \<union> {a\<^sub>0}"
    apply clarsimp
    subgoal for x
    proof (induction a\<^sub>0 _ rule: rtranclp.induct)
      case rtrancl_refl
      then show ?case by simp
    next
      case prems: (rtrancl_into_rtrancl b c)
      have *: "\<exists>l Z. c = from_R l Z \<and> l \<in> state_set A \<and> (\<exists>Za. Z = Approx\<^sub>\<beta> l Za \<and> Za \<subseteq> V)"
        if "A2 b c" for b
        using that
        unfolding A2_def
        apply clarify
        subgoal for l l'
          apply (inst_existentials l' "R_of c")
            apply (simp add: from_R_R_of; fail)
           apply (rule step_z_beta'_state_set; assumption)
          by (auto dest!: V'_V step_z_V elim!: step_z_beta'.cases)
        done
      from prems show ?case
        by (cases "b = a\<^sub>0"; intro *)
    qed
    done
  also have "finite \<dots>" (is "finite ?S")
  proof -
    have "?S = {a\<^sub>0} \<union>
      (\<lambda> (l, Z). from_R l Z) ` \<Union> ((\<lambda> l. (\<lambda> Z. (l, Z)) ` {Approx\<^sub>\<beta> l Z | Z. Z \<subseteq> V}) ` (state_set A))"
      by auto
    also have "finite \<dots>"
      by (blast intro: apx_finite finite_state_set)
    finally show ?thesis .
  qed
  finally show ?case .
next
  case prems: (3 a a')
  -- \<open>Preservation of Well-Formedness\<close>
  with sim.P2_cover[OF prems(1)] show ?case
    unfolding sim_defs
    by (auto intro: step_z_beta'_state_set; auto dest!: step_z_beta'_V'[rotated] dest: V'_V)
next
  case 4
  from start_state show ?case unfolding a\<^sub>0_def by (auto simp: sim_defs from_R_fst)
qed

lemma (in Double_Simulation) P1_closure_id:
  "closure R = {R}" if "P1 R" "R \<noteq> {}"
  unfolding closure_def using that P1_distinct by blast

context
  fixes \<phi> :: "'s \<times> ('c \<Rightarrow> real) \<Rightarrow> bool" -- "The property we want to check"
  assumes \<phi>_closure_compatible: "x \<in> a \<Longrightarrow> \<phi> x \<longleftrightarrow> (\<forall> x \<in> \<Union> sim.closure a. \<phi> x)"
      and sim_closure: "\<Union>sim.closure a\<^sub>0 = a\<^sub>0"
begin

lemma infinite_buechi_run_cycle_iff':
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> sim.run (x\<^sub>0 ## xs) \<and> alw (ev (holds \<phi>)) (x\<^sub>0 ## xs))
  \<longleftrightarrow> (\<exists> as a bs. sim.Steps (a\<^sub>0 # as @ a # bs @ [a]) \<and> (\<forall> x \<in> \<Union> sim.closure a. \<phi> x))"
  using sim_complete.infinite_buechi_run_cycle_iff[OF \<phi>_closure_compatible, OF _ sim_closure] .

theorem infinite_buechi_run_cycle_iff:
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> sim.run (x\<^sub>0 ## xs) \<and> alw (ev (holds \<phi>)) (x\<^sub>0 ## xs))
  \<longleftrightarrow> (\<exists> as l Z bs. steps ((l\<^sub>0, Z\<^sub>0) # as @ (l, Z) # bs @ [(l, Z)]) \<and> (\<forall> x \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z. \<phi> (l, x)))"
  unfolding infinite_buechi_run_cycle_iff' sim_steps_equiv[OF start_state(2)]
  apply (simp add: a\<^sub>0_def)
proof (safe, goal_cases)
  case prems: (1 as a bs)
  let ?l = "(THE l. \<forall>la\<in>a. fst la = l)"
  from prems(2) obtain a1 where "A2 a1 a"
    apply atomize_elim
    apply (cases as)
     apply (auto elim: sim.Steps_cases)
    by (metis append_Cons list.discI list.sel(1) sim.Steps.steps_decomp)
  then have "a \<noteq> {}" unfolding A2_def R_of_def by auto
  with \<open>A2 a1 a\<close> have "\<forall> x \<in> a. fst x = ?l"
    unfolding A2_def by - ((erule exE conjE)+, (rule theI; force))
  moreover with \<open>A2 a1 a\<close> \<open>a \<noteq> {}\<close> have "?l \<in> state_set A" unfolding A2_def
    by (fastforce intro: step_z_beta'_state_set)
  ultimately have "\<forall>x\<in>Closure\<^sub>\<alpha>\<^sub>,\<^sub>?l R_of a. \<phi> (?l, x)"
    unfolding cla_def
  proof (clarify, goal_cases)
    case prems2: (1 x X)
    then have P1_l_X: "P1 (from_R (THE l. \<forall>la\<in>a. fst la = l) X)"
      unfolding P1_def
      apply (inst_existentials ?l)
        apply (rule from_R_fst; fail)
      by (simp only: R_of_from_R; fail)+
    from prems prems2 show ?case
      unfolding sim.closure_def
      apply rotate_tac
      apply (drule bspec[where x = "from_R ?l X"])
      subgoal
        using P1_l_X
        apply clarify
        subgoal premises prems
        proof -
          from \<open>X \<inter> _ \<noteq> {}\<close> obtain l u where "u \<in> X" "(l, u) \<in> a"
            unfolding R_of_def from_R_def by auto
          moreover with prems have "l = ?l" by fastforce
          ultimately show ?thesis using prems(8) by auto
        qed
        done
      apply (subst \<phi>_closure_compatible[of _ "from_R ?l X"])
       apply blast
      by (subst sim.P1_closure_id; blast intro: P1_l_X)
  qed
  with prems(2) run_map_from_R[OF prems(2)] show ?case
    by (inst_existentials
        "map (\<lambda>lR. (THE l. \<forall>x\<in>lR. fst x = l, R_of lR)) as"
        ?l "R_of a"
        "map (\<lambda>lR. (THE l. \<forall>x\<in>lR. fst x = l, R_of lR)) bs"
        ) auto
next
  case (2 as l Z bs)
  then show ?case
    by (inst_existentials "map (\<lambda>(x, y). from_R x y) as")
       (force simp: sim_closure_from_R cla_def dest: from_R_loc from_R_val)
qed

theorem infinite_buechi_run_cycle_iff1:
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> sim.run (x\<^sub>0 ## xs) \<and> alw (ev (holds \<phi>)) (x\<^sub>0 ## xs))
  \<longleftrightarrow> (\<exists> l Z. reachable (l, Z) \<and> reaches1 (l, Z) (l, Z) \<and> (\<forall> x \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z. \<phi> (l, x)))"
  unfolding infinite_buechi_run_cycle_iff
  apply safe
  subgoal for as l Z bs
    using reachable_cycle_iff[of "(l, Z)"] by auto
  subgoal for l Z
    using reachable_cycle_iff[of "(l, Z)"] by auto
  done

end (* Context for Formula *)

end (* Regions TA with Start State*)

end (* Theory *)