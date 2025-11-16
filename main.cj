
main(){
    let regex:String="a(b|c)*d"
    let regex_to_nfa:RegexToNFA=RegexToNFA(regex)

    println("\n单元测试:")
    let examples = ["a(b|c)*d", "(a|b)*abb", "abc", "a|bc","a(b|c)*d"]
    for( example in examples){
        let r2n:RegexToNFA=RegexToNFA(example)
        r2n.print_convert_process()
    }
}