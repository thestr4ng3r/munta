theory Word
  imports AbsInt PowerBool Toption
begin

section \<open>Abstraction of Machine Words\<close>
text \<open>More specifically, abstraction for @{type val}, @{type reg} and @{type addr}\<close>

class absword = bounded_semilattice_sup_bot + order_top

locale AbsWord =
fixes \<gamma>_word :: "('a::absword) \<Rightarrow> int set"
  and contains :: "'a \<Rightarrow> int \<Rightarrow> bool"
  and make :: "int \<Rightarrow> 'a"
  and concretize :: "'a \<Rightarrow> int set toption" \<comment> \<open>Finite overapproximation of \<gamma>_word if existing\<close>
  and aplus :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"
  and lt :: "'a \<Rightarrow> 'a \<Rightarrow> power_bool"
  and le :: "'a \<Rightarrow> 'a \<Rightarrow> power_bool"
  and eq :: "'a \<Rightarrow> 'a \<Rightarrow> power_bool"
assumes mono_gamma: "a \<le> b \<Longrightarrow> \<gamma>_word a \<le> \<gamma>_word b"
  and gamma_Top[simp]: "\<gamma>_word \<top> = \<top>"
  and contains_correct: "contains a x \<longleftrightarrow> x \<in> \<gamma>_word a"
  and make_correct: "v \<in> \<gamma>_word (make v)"
  and concretize_correct: "concretize a = Minor vs \<Longrightarrow> \<gamma>_word a \<subseteq> vs"
  and concretize_finite: "concretize a = Minor vs \<Longrightarrow> finite vs"
  and plus_correct: "x \<in> \<gamma>_word a \<Longrightarrow> y \<in> \<gamma>_word b \<Longrightarrow> (x + y) \<in> \<gamma>_word (aplus a b)"
  and lt_correct: "lt a b = (     if \<forall>x y. x \<in> \<gamma>_word a \<longrightarrow> y \<in> \<gamma>_word b \<longrightarrow> x < y then BTrue
                             else if \<exists>x y. x \<in> \<gamma>_word a \<longrightarrow> y \<in> \<gamma>_word b \<longrightarrow> x < y then BBoth
                             else BFalse)"
  and le_correct: "le a b = (     if \<forall>x y. x \<in> \<gamma>_word a \<longrightarrow> y \<in> \<gamma>_word b \<longrightarrow> x \<le> y then BTrue
                             else if \<exists>x y. x \<in> \<gamma>_word a \<longrightarrow> y \<in> \<gamma>_word b \<longrightarrow> x \<le> y then BBoth
                             else BFalse)"
  and eq_correct: "eq a b = (     if \<forall>x y. x \<in> \<gamma>_word a \<longrightarrow> y \<in> \<gamma>_word b \<longrightarrow> x = y then BTrue
                             else if \<exists>x y. x \<in> \<gamma>_word a \<longrightarrow> y \<in> \<gamma>_word b \<longrightarrow> x = y then BBoth
                             else BFalse)"

end