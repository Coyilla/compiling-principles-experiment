
main(){
    // 词法分析
    // let examples = ["a(b|c)*d", "(a|b)*abb", "abc", "a|bc","a(b|c)*d"]
    // for( example in examples){
    //     let r2n:RegexToNFA=RegexToNFA(example)
    //     r2n.print_convert_process()
    //     let nfa:NFA=r2n.nfa
    //     let converter:NFA2DFAConverter=NFA2DFAConverter(nfa)
    //     let dfa:DFA=converter.dfa
    //     println("DFA状态转换表:")
    //     dfa.print_dfa()
    //     let minimizer:DFAminimizer=DFAminimizer(dfa)
    //     let min_dfa:DFA=minimizer.minimized_dfa
    //     println("最小化后DFA状态转换表:")
    //     min_dfa.print_dfa()
    //     println("\n")
    // }

    println("实验3.1 上下⽂⽆关⽂法左递归消去算法的实现")
    let s='''
S → Ac | c
A → Bb | b
B → Sa| a
'''
    let c:CFGleftRecursiveElimination=CFGleftRecursiveElimination(s)
    
    // c.cfg.print_grammar()
    // c.cfg_elimate_left_recursion.print_grammar()
    println("原始文法：")
    c.cfg.print_grammar_merge()
    println("左递归消去的文法")
    c.cfg_elimate_left_recursion.print_grammar_merge()
    
    println("任务3.2: 文法左公共因子提取方法及实现")
    let example_LeftCommonFactor='''
S -> apple | apply | application | ball | bat | bath | Xb
X -> ab | ac | ad'''
    let lcfe=LeftCommonFactorExtractor(example_LeftCommonFactor)
    println("原始文法：")
    lcfe.cfg.print_grammar_merge()
    println("消除左公因子后的文法：")
    lcfe.cfg_extract_left_common_factors.print_grammar_merge()
}