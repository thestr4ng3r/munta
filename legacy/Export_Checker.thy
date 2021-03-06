theory Export_Checker
  imports
    Uppaal_Networks.UPPAAL_Model_Checking UPPAAL_State_Networks_Impl_Refine_Calc
    Deadlock.Deadlock_Checking
    "../library/OCaml_Diff_Array_Impl" "../library/OCaml_Code_Printings"
begin

(* XXX Add this fix to IArray theory *)
code_printing
  constant IArray.sub' \<rightharpoonup> (SML) "(Vector.sub o (fn (a, b) => (a, IntInf.toInt b)))"

(* For debugging purposes only *)
definition
  "bounded_int bounds (s :: int list) \<equiv>
   length s = length bounds \<and> (\<forall> i < length s. fst (bounds ! i) < s ! i \<and> s ! i < snd (bounds ! i))"

code_thms UPPAAL_Reachability_Problem_precompiled_start_state

definition
  "pre_checks \<equiv> \<lambda> p m inv pred trans prog.
  [
    (STR ''Length of invariant is p'', length inv = p),
    (STR ''Length of transitions is p'', length trans = p),
    (STR ''Length of predicate is p'',
      \<forall>i<p. length (pred ! i) = length (trans ! i) \<and> length (inv ! i) = length (trans ! i)
    ),
    (STR ''Transitions, predicates, and invariants are of the right length per process'',
     \<forall>i<p. length (pred ! i) = length (trans ! i) \<and> length (inv ! i) = length (trans ! i)
    ),
    (STR ''Edge targets are in bounds'',
     \<forall>T\<in>set trans. \<forall>xs\<in>set T. \<forall>(_, _, _, l)\<in>set xs. l < length T
    ),
    (STR ''p > 0'', p > 0),
    (STR ''m > 0'', m > 0),
    (STR ''Every process has at least one transition'', \<forall>i<p. trans ! i \<noteq> []),
    (STR ''The initial state of each process has a transition'', \<forall>q<p. trans ! q ! 0 \<noteq> []),
    (STR ''Clocks >= 0'',
      \<forall>(_, d)\<in>UPPAAL_Reachability_Problem_precompiled_defs.clkp_set' inv prog. 0 \<le> d
    ),
    (STR ''Set of clocks is {1..m}'',
      UPPAAL_Reachability_Problem_precompiled_defs.clk_set' inv prog = {1..m}
    ),
    (STR ''Resets correct'', UPPAAL_Reachability_Problem_precompiled_defs.check_resets prog)
  ]"

definition
  "start_checks \<equiv> \<lambda> p max_steps trans prog bounds pred s\<^sub>0.
  [
    (STR ''Termination of predicates'', init_pred_check p prog max_steps pred s\<^sub>0),
    (STR ''Boundedness'', bounded bounds s\<^sub>0),
    (STR ''Predicates are independent of time'', time_indep_check1 pred prog max_steps),
    (STR ''Updates are independent of time'', time_indep_check2 trans prog max_steps),
    (STR ''Conjunction check'', conjunction_check2 trans prog max_steps)
  ]"

definition
  "ceiling_checks \<equiv> \<lambda> p m max_steps inv trans prog k.
  [
    (STR ''Length of ceilig'', length k = p),
    (STR ''1'', \<forall>i<p. \<forall>l<length (trans ! i).
       \<forall>(x, m)\<in>UPPAAL_Reachability_Problem_precompiled_defs.clkp_set'' max_steps inv trans prog i l.
        m \<le> int (k ! i ! l ! x)
    ),
    (STR ''2'', \<forall>i<p. \<forall>l<length (trans ! i).
     \<forall>(x, m)\<in>collect_clock_pairs (inv ! i ! l). m \<le> int (k ! i ! l ! x)
    ),
    (STR ''3'', \<forall>i<p. \<forall>l<length (trans ! i).
      \<forall>(g, a, r, l')\<in>set (trans ! i ! l).
         \<forall>c\<in>{0..<m + 1} -
             fst ` UPPAAL_Reachability_Problem_precompiled_defs.collect_store'' prog r.
            k ! i ! l' ! c \<le> k ! i ! l ! c
    ),
    (STR ''4'', \<forall>i<p. length (k ! i) = length (trans ! i)),
    (STR ''5'', \<forall>xs\<in>set k. \<forall>xxs\<in>set xs. length xxs = m + 1),
    (STR ''6'', \<forall>i<p. \<forall>l<length (trans ! i). k ! i ! l ! 0 = 0),
    (STR ''7'', \<forall>i<p. \<forall>l<length (trans ! i).
                   \<forall>(g, a, r, l')\<in>set (trans ! i ! l). guaranteed_execution_cond prog r max_steps)
  ]
  "

definition
  "more_checks \<equiv> \<lambda> (trans :: (nat \<times> nat act \<times> nat \<times> nat) list list list) na. [
    (STR ''Legal actions'', \<forall>T\<in>set trans. \<forall>xs\<in>set T. \<forall>(_, a, _)\<in>set xs. pred_act (\<lambda>a. a < na) a)
  ]"

(*
export_code
  precond_mc
  precond_dc
  integer_of_nat nat_of_integer int_of_integer integer_of_int
  acconstraint.LT LT INSTR In loc formula.EX
  map_option
  UPPAAL_Reachability_Problem_precompiled_defs.k
  pre_checks start_checks ceiling_checks more_checks
  in SML_imp module_name Model_Checker
  file "ML/UPPAAL_Model_Checker_imp.sml"
*)

export_code
  precond_dc
  precond_mc
  integer_of_nat nat_of_integer int_of_integer integer_of_int
  acconstraint.LT LT INSTR In loc formula.EX
  map_option
  UPPAAL_Reachability_Problem_precompiled_defs.k
  pre_checks start_checks ceiling_checks more_checks
  in SML module_name Model_Checker
  file "ML/UPPAAL_Model_Checker.sml"

(* ML_file "ML/UPPAAL_Model_Checker_imp.sml" *)

ML_file_debug "ML/UPPAAL_Model_Checker.sml"

ML \<open>
  open Model_Checker;;
\<close>

text \<open>Compile with \<open>nums.cmxa\<close>\<close>
export_code
  precond_dc
  precond_mc
  integer_of_nat nat_of_integer int_of_integer integer_of_int
  acconstraint.LT LT INSTR In loc formula.EX
  map_option
  UPPAAL_Reachability_Problem_precompiled_defs.k
  pre_checks start_checks ceiling_checks more_checks
  in OCaml module_name Model_Checker
  file "ML/UPPAAL_Model_Checker.ml"

end (* End of Theory *)
