theory AbsInt_Test
  imports AbsInt_Test_Setup
begin

ML\<open>
(*val _ = absint_run myprog entry_later 16 16 10*)
val _ = absint_benchmark "benchmarks/fischer_02.munta" entry_default 16 16 100
\<close>

end