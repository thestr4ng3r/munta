theory Stream_More
  imports
    "~~/src/HOL/Library/Stream"
    "~~/src/HOL/Library/Linear_Temporal_Logic_on_Streams"
    "~~/src/HOL/Library/Rewrite"
begin

lemma stream_all_coinduct[consumes 1, case_names step, coinduct pred: stream_all]:
  assumes "P xs" "\<And> xs. P xs \<Longrightarrow> R (shd xs) \<and> P (stl xs)"
  shows "stream_all R xs"
  unfolding stream_all_def
  apply (rule allI)
  subgoal for n
    using assms(1)
    by (induction n arbitrary: xs) (auto dest: assms(2))
  done

lemma set_sset_stake[intro]:
  "set (stake n xs) \<subseteq> sset xs"
  by (rewrite in \<open>_ \<subseteq> \<hole>\<close> stake_sdrop[of n, symmetric]) auto

(* XXX Unused here, move to distribution? *)
lemma sset_sdrop:
  "sset (sdrop n xs) \<subseteq> sset xs"
  by (rewrite in \<open>_ \<subseteq> \<hole>\<close> stake_sdrop[of n, symmetric]) auto

lemma finite_sset_decomp:
  assumes "finite (sset xs)"
  obtains x ws ys zs where "xs = ws @- x ## ys @- x ## zs"
proof -
  let ?n = "card (sset xs) + 1"
  let ?ys = "stake ?n xs"
  have "set ?ys \<subseteq> sset xs" ..
  then have "card (set ?ys) \<le> card (sset xs)"
    using assms card_mono by blast
  then have "card (set ?ys) < ?n" by auto
  also have "?n = length ?ys" by auto
  finally have "\<not> distinct ?ys"
    using distinct_card by fastforce
  then obtain x ws ys zs where "?ys = ws @ x # ys @ x # zs"
    using not_distinct_decomp by fastforce
  from this[symmetric] have "xs = \<dots> @- sdrop ?n xs"
    by (simp only: stake_sdrop)
  then show ?thesis
    by (auto intro: that)
qed

lemma append_single_shift:
  "(xs @ [x]) @- ys = xs @- x ## ys"
  by simp


primcorec sgenerate where
  "shd (sgenerate f x ys) = x"
| "stl (sgenerate f x ys) = sgenerate f (f x (shd ys)) (stl ys)"

lemma sgenerate_Cons:
  "sgenerate f x (y ## ys) = x ## sgenerate f (f x y) ys"
  by (subst sgenerate.ctr) simp

end (* Theory *)