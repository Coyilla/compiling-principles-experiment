
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
    let result = test_grammar()
    
    
    // 语法分析
}