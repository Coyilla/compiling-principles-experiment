
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

    // 语法分析
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
    
    println("\n任务3.2 文法左公共因子提取方法及实现")
    let example_LeftCommonFactor='''
S -> apple | apply | application | ball | bat | bath | Xb
X -> ab | ac | ad'''
    let lcfe=LeftCommonFactorExtractor(example_LeftCommonFactor)
    println("原始文法：")
    lcfe.cfg.print_grammar_merge()
    println("消除左公因子后的文法：")
    lcfe.cfg_extract_left_common_factors.print_grammar_merge()

    println("\n3.3 上下⽂⽆关⽂法FIRST集和FOLLOW集求解及实现")
    let example_faf='''
S→MH | a
H→LSo |ε
K→dML | ε
L→eHf
M→K | bLM
'''
    let faf=FIRSTandFOLLOW(Grammar(example_faf))
    faf.cfg.print_grammar()
    faf.print_first()
    faf.print_follow()

    println("\n3.4 LL(1)文法判定与预测分析器设计及实现")
    let example_ll1='''
S → AB
A → aA | ε
B → b
'''
    let ll1=LL1(example_ll1)
    ll1.print()
    println(ll1.predictive_parser("aaaab"))
}