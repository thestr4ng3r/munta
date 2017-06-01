theory Simulation_Graphs
  imports
    Stream_More
    (* "~/Isabelle/cava/Basic/Sequence" *)
    "~~/src/HOL/Library/Rewrite"
    Instantiate_Existentials
    "~~/src/HOL/Library/BNF_Corec"
    Normalized_Zone_Semantics
begin

text \<open>
  A directed graph where every node has at least one ingoing edge, contains a directed cycle.
\<close>
lemma directed_graph_indegree_ge_1_cycle:
  assumes "finite S" "S \<noteq> {}" "\<forall> y \<in> S. \<exists> x \<in> S. E x y"
  shows "\<exists> x \<in> S. \<exists> y. E x y \<and> E\<^sup>*\<^sup>* y x"
  using assms
proof (induction arbitrary: E rule: finite_ne_induct)
  case (singleton x)
  then show ?case by auto
next
  case (insert x S E)
  from insert.prems obtain y where "y \<in> insert x S" "E y x"
    by auto
  show ?case
  proof (cases "y = x")
    case True
    with \<open>E y x\<close> show ?thesis by auto
  next
    case False
    with \<open>y \<in> _\<close> have "y \<in> S" by auto
    define E' where "E' a b \<equiv> E a b \<or> (a = y \<and> E x b)" for a b
    have E'_E: "\<exists> c. E a c \<and> E\<^sup>*\<^sup>* c b" if "E' a b" for a b
      using that \<open>E y x\<close> unfolding E'_def by auto
    have [intro]: "E\<^sup>*\<^sup>* a b" if "E' a b" for a b
      using that \<open>E y x\<close> unfolding E'_def by auto
    have [intro]: "E\<^sup>*\<^sup>* a b" if "E'\<^sup>*\<^sup>* a b" for a b
      using that by (induction; blast intro: rtranclp_trans)
    have "\<forall>y\<in>S. \<exists>x\<in>S. E' x y"
    proof (rule ballI)
      fix b assume "b \<in> S"
      with insert.prems obtain a where "a \<in> insert x S" "E a b"
        by auto
      show "\<exists>a\<in>S. E' a b"
      proof (cases "a = x")
        case True
        with \<open>E a b\<close> have "E' y b" unfolding E'_def by simp
        with \<open>y \<in> S\<close> show ?thesis ..
      next
        case False
        with \<open>a \<in> _\<close> \<open>E a b\<close> show ?thesis unfolding E'_def by auto
      qed
    qed
    from insert.IH[OF this] guess x y by safe
    then show ?thesis by (blast intro: rtranclp_trans dest: E'_E)
    qed
  qed

locale Graph_Defs =
  fixes C :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
begin

inductive steps where
  Single: "steps [x]" |
  Cons: "steps (x # y # xs)" if "C x y" "steps (y # xs)"

lemmas [intro] = steps.intros

lemma steps_append:
  "steps (xs @ tl ys)" if "steps xs" "steps ys" "last xs = hd ys"
  using that by induction (auto 4 4 elim: steps.cases)

coinductive run where
  "run (x ## y ## xs)" if "C x y" "run xs"

lemmas [intro] = run.intros

lemma steps_appendD1:
  "steps xs" if "steps (xs @ [x])" "xs \<noteq> []"
  using that proof (induction xs)
  case Nil
  then show ?case by (auto elim!: steps.cases)
next
  case prems: (Cons a xs)
  then show ?case by - (cases xs; auto elim: steps.cases)
qed

lemma steps_appendD2:
  "steps (xs @ [x]) \<and> C x y" if "steps (xs @ [x, y])"
  using that proof (induction xs)
  case Nil
  then show ?case by (auto elim!: steps.cases)
next
  case prems: (Cons a xs)
  then show ?case by (cases xs) (auto elim: steps.cases)
qed

lemma steps_alt_induct[consumes 1, case_names Single Snoc]:
  assumes
    "steps x" "(\<And>x. P [x])"
    "\<And>y x xs. C y x \<Longrightarrow> steps (xs @ [y]) \<Longrightarrow> P (xs @ [y]) \<Longrightarrow> P (xs @ [y,x])"
  shows "P x"
  using assms(1)
  proof (induction rule: rev_induct)
    case Nil
    then show ?case by (auto elim: steps.cases)
  next
    case prems: (snoc x xs)
    then show ?case by (cases xs rule: rev_cases) (auto intro: assms(2,3) dest!: steps_appendD2)
  qed

(* XXX First generalize all step lemmas over the two types of steps *)
lemma steps_appendI:
  "steps (xs @ [x, y])" if "steps (xs @ [x])" "C x y"
  using that
proof (induction xs)
  case Nil
  then show ?case by auto
next
  case (Cons a xs)
  then show ?case by (cases xs; auto elim: steps.cases)
qed

end

locale Simulation_Graph_Defs = Graph_Defs C for C :: "'a \<Rightarrow> 'a \<Rightarrow> bool" +
  fixes A :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool"
begin

sublocale Steps: Graph_Defs A .

abbreviation "Steps \<equiv> Steps.steps"
abbreviation "Run \<equiv> Steps.run"

lemmas Steps_appendD1 = Steps.steps_appendD1

lemmas Steps_appendD2 = Steps.steps_appendD2

lemmas steps_alt_induct = Steps.steps_alt_induct

lemmas Steps_appendI = Steps.steps_appendI

lemmas Steps_cases = Steps.steps.cases

end (* Simulation Graph *)


lemma list_all2_set1:
  "\<forall>x\<in>set xs. \<exists>xa\<in>set as. P x xa" if "list_all2 P xs as"
  using that
proof (induction xs arbitrary: as)
  case Nil
  then show ?case by auto
next
  case (Cons a xs as)
  then show ?case by (cases as) auto
qed

lemma list_all2_swap:
  "list_all2 P xs ys \<longleftrightarrow> list_all2 (\<lambda> x y. P y x) ys xs"
  unfolding list_all2_iff by (fastforce simp: in_set_zip)+

lemma list_all2_set2:
  "\<forall>x\<in>set as. \<exists>xa\<in>set xs. P xa x" if "list_all2 P xs as"
  using that by - (rule list_all2_set1, subst (asm) list_all2_swap)

locale Simulation_Graph_Poststable = Simulation_Graph_Defs +
  assumes poststable: "A S T \<Longrightarrow> \<forall> s' \<in> T. \<exists> s \<in> S. C s s'"
begin

lemma Steps_poststable:
  "\<exists> xs. steps xs \<and> list_all2 (op \<in>) xs as \<and> last xs = x" if "Steps as" "x \<in> last as"
  using that
proof induction
  case (Single a)
  then show ?case by auto
next
  case (Cons a b as)
  then guess xs by clarsimp
  then have "hd xs \<in> b" by (cases xs) auto
  with poststable[OF \<open>A a b\<close>] obtain y where "y \<in> a" "C y (hd xs)" by auto
  with \<open>list_all2 _ _ _\<close> \<open>steps _\<close> \<open>x = _\<close> show ?case by (cases xs) auto
qed

lemma Steps_steps_cycle:
  "\<exists> x xs. steps (x # xs @ [x]) \<and> (\<forall> x \<in> set xs. \<exists> a \<in> set as \<union> {a}. x \<in> a) \<and> x \<in> a"
  if assms: "Steps (a # as @ [a])" "finite a" "a \<noteq> {}"
proof -
  define E where
    "E x y = (\<exists> xs. steps (x # xs @ [y]) \<and> (\<forall> x \<in> set xs \<union> {x, y}. \<exists> a \<in> set as \<union> {a}. x \<in> a))"
    for x y
  from assms(2-) have "\<exists> x. E x y \<and> x \<in> a" if "y \<in> a" for y
    using that unfolding E_def
    apply simp
    apply (drule Steps_poststable[OF assms(1), simplified])
    apply clarify
    subgoal for xs
      apply (inst_existentials "hd xs" "tl (butlast xs)")
      subgoal by (cases xs) auto
      subgoal by (auto elim: steps.cases dest!: list_all2_set1)
      subgoal by (drule list_all2_set1) (cases xs, auto dest: in_set_butlastD)
      by (cases xs) auto
    done
  with \<open>finite a\<close> \<open>a \<noteq> {}\<close> obtain x y where cycle: "E x y" "E\<^sup>*\<^sup>* y x" "x \<in> a"
    by (force dest!: directed_graph_indegree_ge_1_cycle[where E = E])
  have trans[intro]: "E x z" if "E x y" "E y z" for x y z
    using that unfolding E_def
    apply safe
    subgoal for xs ys
      apply (inst_existentials "xs @ y # ys")
       apply (drule steps_append, assumption; simp; fail)
      by (cases ys, auto dest: list.set_sel(2)[rotated] elim: steps.cases)
    done
  have "E x z" if "E\<^sup>*\<^sup>* y z" "E x y" "x \<in> a" for x y z
  using that proof induction
    case base
    then show ?case unfolding E_def by force
  next
    case (step y z)
    then show ?case by auto
  qed
  with cycle have "E x x" by blast
  with \<open>x \<in> a\<close> show ?thesis unfolding E_def by auto
qed

(* XXX Unused *)
lemma Steps_steps_cycle':
  "\<exists> xs. steps xs \<and> hd xs = last xs \<and> (\<forall> x \<in> set xs. \<exists> a \<in> set as. x \<in> a) \<and> hd xs \<in> hd as"
  if assms: "Steps as" "hd as = last as" "finite (hd as)" "hd as \<noteq> {}"
proof -
  define E where
    "E x y = (\<exists> xs. steps xs \<and> hd xs = x \<and> last xs = y \<and> (\<forall> x \<in> set xs. \<exists> a \<in> set as. x \<in> a))"
    for x y
  from assms(2-) have "\<exists> x. E x y \<and> x \<in> hd as" if "y \<in> hd as" for y
    using that unfolding E_def
    apply simp
    apply (drule Steps_poststable[OF assms(1)])
    apply clarify
    subgoal for xs
      apply (inst_existentials "hd xs" xs)
        apply ((assumption | rule HOL.refl); fail)+
       apply (blast intro!: list_all2_set1)
      by (metis list.rel_sel list.simps(3) steps.cases)
    done
  with \<open>finite (hd as)\<close> \<open>hd as \<noteq> {}\<close> obtain x y where cycle: "E x y" "E\<^sup>*\<^sup>* y x" "x \<in> hd as"
    by (force dest!: directed_graph_indegree_ge_1_cycle[where E = E])
  from assms have "as \<noteq> []" by cases auto
  have trans[intro]: "E x z" if "E x y" "E y z" for x y z
    using that unfolding E_def
    apply safe
    subgoal for xs ys
      apply (inst_existentials "xs @ tl ys")
         apply (rule steps_append; assumption)
      by (cases ys, auto dest: list.set_sel(2)[rotated] elim: steps.cases)
    done
  have "E x y" if "E\<^sup>*\<^sup>* x y" "x \<in> hd as" for x y
  using that proof induction
    case base
    with \<open>as \<noteq> []\<close> show ?case unfolding E_def by force
  next
    case (step y z)
    then show ?case by auto
  qed
  with cycle have "E x x" by blast
  with \<open>x \<in> hd as\<close> show ?thesis unfolding E_def by auto
qed

end (* Simulation Graph Poststable *)


locale Simulation_Graph_Prestable = Simulation_Graph_Defs +
  assumes prestable: "A S T \<Longrightarrow> \<forall> s \<in> S. \<exists> s' \<in> T. C s s'"
begin

(* XXX Unused *)
lemma Steps_prestable:
  "\<exists> xs. steps (x # xs) \<and> list_all2 (op \<in>) (x # xs) as" if "Steps as" "x \<in> hd as"
  using that
proof (induction arbitrary: x)
  case (Single a)
  then show ?case by auto
next
  case (Cons a b as)
  from prestable[OF \<open>A a b\<close>] \<open>x \<in> _\<close> obtain y where "y \<in> b" "C x y" by auto
  with Cons.IH[of y] guess xs by clarsimp
  with \<open>x \<in> _\<close> show ?case by auto
qed

lemma Steps_cycle_every_prestable':
  "\<exists> b y. C x y \<and> y \<in> b \<and> b \<in> set as \<union> {a}"
  if assms: "Steps (as @ [a])" "x \<in> b" "b \<in> set as"
  using assms
proof (induction "as @ [a]" arbitrary: as)
  case Single
  then show ?case by simp
next
  case (Cons a c xs)
  show ?case
  proof (cases "a = b")
    case True
    with prestable[OF \<open>A a c\<close>] \<open>x \<in> b\<close> obtain y where "y \<in> c" "C x y"
      by auto
    with \<open>a # c # _ = _\<close> show ?thesis
      apply (inst_existentials c y)
    proof (assumption+, cases as, goal_cases)
      case (2 a list)
      then show ?case by (cases list) auto
    qed simp
  next
    case False
    with Cons.hyps(3)[of "tl as"] Cons.prems Cons.hyps(1,2,4-) show ?thesis by (cases as) auto
  qed
qed

lemma Steps_cycle_first_prestable:
  "\<exists> b y. C x y \<and> x \<in> b \<and> b \<in> set as \<union> {a}" if assms: "Steps (a # as @ [a])" "x \<in> a"
  using assms
proof (cases as)
  case Nil
  with assms show ?thesis by (auto elim!: Steps_cases dest: prestable)
next
  case (Cons b as)
  with assms show ?thesis by (auto 4 4 elim: Steps_cases dest: prestable)
qed

lemma Steps_cycle_every_prestable:
  "\<exists> b y. C x y \<and> y \<in> b \<and> b \<in> set as \<union> {a}"
  if assms: "Steps (a # as @ [a])" "x \<in> b" "b \<in> set as \<union> {a}"
  using assms Steps_cycle_every_prestable'[of "a # as" a] Steps_cycle_first_prestable by auto

text \<open>Abstract cycles lead to concrete infinite runs.\<close>
lemma Steps_run_cycle:
  "\<exists> xs. run xs \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> a) \<and> shd xs \<in> a"
  if assms: "Steps (a # as @ [a])" "a \<noteq> {}"
proof -
  from assms(2) obtain x where "x \<in> a" by auto
  with assms(1) have *: "\<exists> a \<in> set as \<union> {a}. x \<in> a" by (fastforce elim: Steps_cases)
  note C = Steps_cycle_every_prestable[OF assms(1)]
  let ?f = "\<lambda> x. SOME y. C x y \<and> (\<exists> a \<in> set as \<union> {a}. y \<in> a)"
  define xs where "xs = siterate ?f x"
  (* XXX Proof Duplication *)
  from * \<open>xs = _\<close> have "stream_all (\<lambda> x. \<exists> a \<in> set as \<union> {a}. x \<in> a) xs"
  proof (coinduction arbitrary: x xs)
    case (step x xs)
    obtain y ys where
      "xs = x ## ys"
      "y = ?f x"
      "ys = siterate ?f y"
      unfolding step(2)
      apply atomize_elim
      apply (subst stream.collapse[symmetric])
      by simp
    from C[of x] step(1) have "\<exists>y. C x y \<and> (\<exists> b \<in> set as \<union> {a}. y \<in> b)" by auto
    from someI_ex[OF this] have "C x y" "\<exists>b\<in>set as \<union> {a}. y \<in> b" unfolding \<open>y = _\<close> by auto
    with \<open>xs = x ## _\<close> \<open>ys = _\<close> step(1) show ?case by auto
  qed
  then have "\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> a"
    unfolding stream_all_iff by blast
  moreover from * \<open>xs = _\<close> have "run xs"
  proof (coinduction arbitrary: x xs)
    case (run x xs)
    obtain y ys where
      "xs = x ## y ## ys"
      "y = ?f x"
      "ys = siterate ?f (?f y)"
      unfolding run(2)
      apply atomize_elim
      apply (subst stream.collapse[symmetric])
      apply (subst (3) stream.collapse[symmetric])
      by simp
    from C[of x] run(1) have "\<exists>y. C x y \<and> (\<exists> b \<in> set as \<union> {a}. y \<in> b)" by auto
    from someI_ex[OF this] have "C x y" "\<exists>b\<in>set as \<union> {a}. y \<in> b" unfolding \<open>y = _\<close> by auto
    with C[of y] have "\<exists>z. C y z \<and> (\<exists> b \<in> set as \<union> {a}. z \<in> b)" by auto
    from someI_ex[OF this] have "\<exists> a \<in> set as \<union> {a}. ?f y \<in> a" by auto
    with \<open>C x y\<close> \<open>xs = x ## _\<close> \<open>ys = _\<close> show ?case
      by (inst_existentials x y ys) auto
  qed
  moreover have "shd xs \<in> a" using \<open>x \<in> _\<close> unfolding xs_def by auto
  ultimately show ?thesis by blast
qed

end (* Simulation Graph Prestable *)



locale Double_Simulation_Defs =
  fixes C :: "'a \<Rightarrow> 'a \<Rightarrow> bool" -- "Concrete step relation"
    and A1 :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool" -- "Step relation for the first abstraction layer"
    and P1 :: "'a set \<Rightarrow> bool" -- "Valid states of the first abstraction layer"
    and A2 :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool" -- "Step relation for the second abstraction layer"
    and P2 :: "'a set \<Rightarrow> bool" -- "Valid states of the second abstraction layer"
begin

sublocale Simulation_Graph_Defs C A2 .

sublocale pre_defs: Simulation_Graph_Defs C A1 .

definition "closure a = {x. P1 x \<and> a \<inter> x \<noteq> {}}"

definition "A2' a b \<equiv> \<exists> x y. a = closure x \<and> b = closure y \<and> A2 x y"

sublocale post_defs: Simulation_Graph_Defs A1 A2' .

end (* Double Simulation Graph Defs *)

locale Double_Simulation = Double_Simulation_Defs +
  assumes prestable: "A1 S T \<Longrightarrow> \<forall> s \<in> S. \<exists> s' \<in> T. C s s'"
      and closure_poststable: "s' \<in> closure y \<Longrightarrow> A2 x y \<Longrightarrow> \<exists>s\<in>closure x. A1 s s'"
      and P1_distinct: "P1 x \<Longrightarrow> P1 y \<Longrightarrow> x \<noteq> y \<Longrightarrow> x \<inter> y = {}"
      and P1_finite: "finite {x. P1 x}"
      and P2_cover: "P2 a \<Longrightarrow> \<exists> x. P1 x \<and> x \<inter> a \<noteq> {}"
begin

sublocale post: Simulation_Graph_Poststable A1 A2'
  unfolding A2'_def by standard (auto dest: closure_poststable)

sublocale pre: Simulation_Graph_Prestable C A1 by standard (rule prestable)

lemma closure_involutive:
  "closure (\<Union> closure x) = closure x"
  unfolding closure_def by (auto dest: P1_distinct)

lemma closure_finite:
  "finite (closure x)"
  using P1_finite unfolding closure_def by auto

lemma closure_non_empty:
  "closure x \<noteq> {}" if "P2 x"
  using that unfolding closure_def by (auto dest!: P2_cover)

lemma A2'_A2_closure:
  "A2' (closure x) (closure y)" if "A2 x y"
  using that unfolding A2'_def by auto

lemma Steps_Union:
  "\<exists> as. post_defs.Steps (a # as) \<and> list_all2 (\<lambda> x a. a = closure x) (x # xs) (a # as)"
  if "Steps (x # xs)" "a = closure x"
using that proof (induction xs rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc y xs)
  from snoc.prems(1) Steps_appendD1[of "x # xs" y] have "Steps (x # xs)" by simp
  from snoc.IH[OF this snoc.prems(2-)] guess as by safe
  note guessed = this
  show ?case
  proof (cases xs rule: rev_cases)
    case Nil
    with snoc.prems have "A2 x y" by (auto elim: Steps_cases)
    with guessed \<open>xs = _\<close> show ?thesis by (auto dest!: A2'_A2_closure)
  next
    case (snoc ys z)
    with snoc.prems have "A2 z y"
      by (metis Steps_appendD2 append_Cons append_assoc append_self_conv2)
    with snoc guessed obtain as' where [simp]: "as = as' @ [closure z]"
      by (auto simp add: list_all2_append1 list_all2_Cons1)
    with \<open>A2 z y\<close> have "A2' (closure z) (closure y)" by (auto dest!: A2'_A2_closure)
    then show ?thesis
      apply (inst_existentials "as' @ [closure z, closure y]")
      using guessed post_defs.Steps_appendI[of "a # as'" "closure z" "closure y"] apply force
      using guessed
      apply safe
      unfolding list_all2_append1
      apply (inst_existentials "as' @ [closure z]" "[closure y]")
      by (auto dest: list_all2_lengthD)
  qed
qed

(* XXX Unused? *)
lemma post_Steps_P1:
  "P1 x" if "post_defs.Steps (a # as)" "x \<in> b" "b \<in> set as"
  using that
proof (induction "a # as" arbitrary: a as)
  case Single
  then show ?case by auto
next
  case (Cons a c as)
  then show ?case by (auto simp: A2'_def closure_def)
qed

lemma post_Steps_non_empty:
  "x \<noteq> {}" if "post_defs.Steps (a # as)" "x \<in> b" "b \<in> set as"
  using that
proof (induction "a # as" arbitrary: a as)
  case Single
  then show ?case by auto
next
  case (Cons a c as)
  then show ?case by (auto simp: A2'_def closure_def)
qed

lemma Steps_run_cycle':
  "\<exists> xs. run xs \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> \<Union> a) \<and> shd xs \<in> \<Union> a"
  if assms: "post_defs.Steps (a # as @ [a])" "finite a" "a \<noteq> {}"
proof -
  from post.Steps_steps_cycle[OF assms] guess a1 as1 by safe
  note guessed = this
  from assms(1) \<open>a1 \<in> a\<close> have "a1 \<noteq> {}" by (auto dest!: post_Steps_non_empty)
  with guessed pre.Steps_run_cycle[of a1 as1] obtain xs where
    "run xs" "\<forall>x\<in>sset xs. \<exists>a\<in>set as1 \<union> {a1}. x \<in> a" "shd xs \<in> a1"
    by atomize_elim auto
  with guessed(2,3) show ?thesis
    by (inst_existentials xs) (metis Un_iff UnionI empty_iff insert_iff)+
qed

lemma Steps_run_cycle:
  "\<exists> xs. run xs \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> \<Union> closure a) \<and> shd xs \<in> \<Union> closure a"
  if assms: "Steps (a # as @ [a])" "P2 a"
proof -
  from Steps_Union[OF assms(1) HOL.refl] guess as1 by safe
  note as1 = this
  obtain as1 where
    "post_defs.Steps (closure a # as1 @ [closure a])"
    "list_all2 (\<lambda>x a. a = closure x) (a # as @ [a]) (closure a # as1 @ [closure a])"
  proof (atomize_elim, cases "as = []", goal_cases)
    case 1
    with as1 have "post_defs.Steps [closure a, closure a]" by (simp add: list_all2_Cons1)
    with \<open>as = []\<close> show ?case by - (rule exI[where x = "[]"]; simp)
  next
    case 2
    with as1 obtain as2 where "as1 = as2 @ [closure a]"
      by (auto simp: list_all2_append1 list_all2_Cons1)
    with as1 show ?case by auto
  qed
  from Steps_run_cycle'[OF this(1) closure_finite closure_non_empty[OF \<open>P2 a\<close>]] this(2)
  show ?thesis by (force dest: list_all2_set2)
qed

end (* Double Simulation Graph *)

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

lemma clock_numbering_le: "\<forall>c\<in>clk_set A. v c \<le> n"
  using clock_numbering valid_abstraction
  apply (auto elim!: valid_abstraction.cases)
  unfolding Timed_Automata.clkp_set_def Closure.clkp_set_def
  unfolding Timed_Automata.collect_clki_def Closure.collect_clki_def
  unfolding Timed_Automata.collect_clkt_def Closure.collect_clkt_def
  sorry

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


(* XXX Move? *)
lemma prod_set_fst_id:
  "x = y" if "\<forall> a \<in> x. fst a = b" "\<forall> a \<in> y. fst a = b" "snd ` x = snd ` y"
  using that by (auto 4 6 simp: fst_def snd_def image_def split: prod.splits)

definition state_set :: "('a, 'c, 'time, 's) ta \<Rightarrow> 's set" where
  "state_set A \<equiv> fst ` (fst A) \<union> (snd o snd o snd o snd) ` (fst A)"

lemma finite_trans_of_finite_state_set:
  "finite (state_set A)" if "finite (trans_of A)"
  using that unfolding state_set_def trans_of_def by auto

locale Regions_TA = Regions X _ _  k for X :: "'c set" and k :: "'s \<Rightarrow> 'c \<Rightarrow> nat" +
  fixes A :: "('a, 'c, t, 's) ta"
  assumes valid_abstraction: "valid_abstraction A X k"
    and finite_state_set: "finite (state_set A)"
begin

(* XXX Remove *)
(* definition "l_of lR = (THE l. \<forall> x \<in> lR. fst x = l)" *)

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

sublocale sim: Double_Simulation
  "\<lambda> (l, u) (l', u'). A \<turnstile>' \<langle>l, u\<rangle> \<rightarrow> \<langle>l', u'\<rangle>" -- "Concrete step relation"
  (* "\<lambda> lR lR'. lR' = {(l', R'). \<exists> l R. (l, R) \<in> lR \<and> A,(\<R> l) \<turnstile> \<langle>l, R\<rangle> \<leadsto> \<langle>l', R'\<rangle>}" *)
  "\<lambda> lR lR'.
    \<exists> l l'. (\<forall> x \<in> lR. fst x = l) \<and> (\<forall> x \<in> lR'. fst x = l')
    \<and> (\<exists> a. A,\<R> \<turnstile> \<langle>l, R_of lR\<rangle> \<leadsto>\<^sub>a \<langle>l', R_of lR'\<rangle>)"
  -- "Step relation for the first abstraction layer"
  "\<lambda> lR. \<exists> l. (\<forall> x \<in> lR. fst x = l) \<and> l \<in> state_set A \<and> R_of lR \<in> \<R> l"
  -- "Valid states of the first abstraction layer"
  "\<lambda> lZ lZ'. \<exists> l l'. (\<forall> x \<in> lZ. fst x = l) \<and> (\<forall> x \<in> lZ'. fst x = l') \<and> R_of lZ \<in> V'
    \<and> (\<exists> a. A \<turnstile>' \<langle>l, R_of lZ\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', R_of lZ'\<rangle>)"
  -- "Step relation for the second abstraction layer"
  "\<lambda> lZ. (\<exists> l \<in> state_set A. \<forall> x \<in> lZ. fst x = l) \<and> R_of lZ \<subseteq> V \<and> R_of lZ \<noteq> {}"
  -- "Valid states of the second abstraction layer"
proof (standard, goal_cases)
  case (1 S T)
  then show ?case
    by (force dest!: bspec step_r'_sound simp: split_beta R_of_def)
next
  case prems: (2 lR' lZ' lZ)
  from prems(1) guess l' unfolding Double_Simulation_Defs.closure_def by clarsimp
  note l' = this
  from prems(2) guess l l2 a by clarsimp
  note guessed = this
  with l' have [simp]: "l2 = l'" by auto
  note guessed = guessed[unfolded \<open>l2 = l'\<close>]
  from l'(1,2) guessed(2) have "R_of lR' \<inter> R_of lZ' \<noteq> {}"
    unfolding R_of_def by auto
  from beta_alpha_region_step[OF valid_abstraction, OF guessed(4) \<open>_ \<in> V'\<close> \<open>_ \<in> \<R> l'\<close> this] l'(1)
  obtain R where "R \<in> \<R> l" "R \<inter> R_of lZ \<noteq> {}" "A,\<R> \<turnstile> \<langle>l, R\<rangle> \<leadsto>\<^sub>a \<langle>l', R_of lR'\<rangle>"
    by auto
  then show ?case
    unfolding Double_Simulation_Defs.closure_def
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
  from prems(1) guess lx by safe
  note lx = this
  from prems(2) guess ly by safe
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
  finally show ?case .
next
  case (5 a)
  then guess l by clarsimp
  note l = this
  from \<open>R_of a \<noteq> {}\<close> obtain u where "u \<in> R_of a" by blast
  with region_cover'[of u] \<open>_ \<subseteq> V\<close> have "u \<in> [u]\<^sub>l" "[u]\<^sub>l \<in> \<R> l"
    unfolding V_def by auto
  with l(1,2) \<open>u \<in> R_of a\<close> show ?case
    by (inst_existentials "(\<lambda> x. (l, x)) ` ([u]\<^sub>l)" l) (force simp: R_of_def image_def)+
qed

sublocale Graph_Defs "\<lambda> (l, Z) (l', Z'). \<exists> a. A \<turnstile>' \<langle>l, Z\<rangle> \<leadsto>\<^bsub>\<beta>(a)\<^esub> \<langle>l', Z'\<rangle>" .

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
    by (auto intro: step_z_beta'_V'[OF valid_abstraction])
  from Cons.prems Cons.hyps(1,2) Cons.hyps(3)[OF \<open>lZ' = _\<close>] show ?case
    apply simp
    apply (rule Graph_Defs.steps.intros)
    by (auto simp: from_R_fst intro: step_z_beta'_V'[OF valid_abstraction])
qed

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
    using assms(2-) by atomize_elim (auto simp: V'_def from_R_fst)
  have *: "fst lu = l" "snd lu \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z" if "lu \<in> \<Union>sim.closure (from_R l Z)" for lu
    using that
     apply safe
    subgoal
      by (auto 4 3 simp: from_R_def sim.closure_def)
    unfolding from_R_def sim.closure_def cla_def
    by auto (metis IntI R_of_def empty_iff fst_conv image_subset_iff order_refl snd_conv)
  from ys(3) have "fst (shd ys) = l" "snd (shd ys) \<in> Closure\<^sub>\<alpha>\<^sub>,\<^sub>l Z" by (auto intro: *)
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
        by (auto 4 3 simp: from_R_def sim.closure_def) (metis fst_conv)
      unfolding from_R_def sim.closure_def cla_def
      by auto (metis IntI R_of_def empty_iff fst_conv image_subset_iff order_refl snd_conv)
    using * by force
  ultimately show ?thesis using \<open>sim.run ys\<close> by (inst_existentials ys) auto
qed

end (* Regions TA *)

end (* Theory *)