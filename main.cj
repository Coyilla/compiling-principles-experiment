
main(){
    let examples = ["a(b|c)*d", "(a|b)*abb", "abc", "a|bc","a(b|c)*d"]
    for( example in examples){
        let r2n:RegexToNFA=RegexToNFA(example)
        r2n.print_convert_process()
        let nfa:NFA=r2n.nfa
        let converter:NFA2DFAConverter=NFA2DFAConverter(nfa)
        let dfa:DFA=converter.dfa
        println("DFA状态转换表:")
        dfa.print_dfa()
        println("\n")
    }
}