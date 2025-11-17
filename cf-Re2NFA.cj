//cf-Re2NFA.cj
//词法分析-基本表达转NFA
//输⼊：正规表达式和多个测试字符串。
//输出：⽣成的NFA状态集合及其转换关系，指明每个测试字符串是否被NFA接受。
import std.collection.{ArrayList, HashMap, HashSet}
import std.core

let EPS:String="ε" //ε转换符号

//全局状态计数器
public class counter{
    var count:Int64

    public init(){
        this.count=Int64(0)
    }

    public func next():Int64{
        let current= this.count
        this.count += Int64(1)
        return current
    }
}
// let state_counter:counter=counter()
//NFA状态转换表
public class NFA{
    var start:Int64 //起始状态
    var accepts: HashSet<Int64> //接受状态集合
    // transitions: state -> symbol -> set(next_states)
    var transitions: HashMap<Int64, HashMap<String, HashSet<Int64>>> //状态转换表
    var alphabet: HashSet<String> //输入符号集合
    var states: HashSet<Int64> //状态集合

    public init(){
        this.start = Int64(0)
        this.accepts= HashSet<Int64>()
        this.transitions= HashMap<Int64, HashMap<String, HashSet<Int64>>>()
        this.alphabet= HashSet<String>()
        this.states= HashSet<Int64>()
    }

    public init(start:Int64,
                accepts: HashSet<Int64>,
                transitions: HashMap<Int64, HashMap<String, HashSet<Int64>>>,
                alphabet: HashSet<String>,
                states: HashSet<Int64>) {
        this.start = start
        this.accepts= accepts
        this.transitions= transitions
        this.alphabet= alphabet
        this.states= states
    }

    public func add_transitions(trans:HashMap<Int64, HashMap<String, HashSet<Int64>>>,s_from:Int64, symbol:String, s_to:HashSet<Int64>){
        //为指定trans再增加一个转换关系（从s_from,通过输入字母symbol，转换到状态s_to）
        if (trans.contains(s_from)){
            if(trans[s_from].contains(symbol)){
                trans[s_from][symbol].add(all:s_to)
            }else{
                trans[s_from].add(symbol, s_to)
            }
        }else{
            let map_sy_to=HashMap<String, HashSet<Int64>>([(symbol,s_to)])
            trans.add(s_from,map_sy_to)
        }
        return trans
    }

    public func merge_nfa(accepts:HashSet<Int64>,transitions:HashMap<Int64, HashMap<String, HashSet<Int64>>>,alphabet:HashSet<String>,states:HashSet<Int64>){
        //合并另一个NFA到当前NFA中
        for ((s,sy_sets) in transitions) {
            for ((sym,sets) in sy_sets) {
                //this.transitions[s][sym].add(all:sets)
                this.transitions=add_transitions(this.transitions,s,sym,sets)
                this.states.add(s)
                this.states.add(all:sets)
                if (sym != EPS) {
                    this.alphabet.add(sym)
                }
            }
        }
        //this.start = start
        this.states.add(all:states)
        this.alphabet.add(all:alphabet)
        this.accepts.add(all:accepts)
    }

    public func print_nfa(){
        //打印NFA的状态转换表
        println("NFA Start State: " + this.start.toString())
        println("NFA Accept States: " + this.accepts.toString())
        println("NFA States: " + this.states.toString())
        println("NFA Alphabet: " + this.alphabet.toString())
        println("NFA Transitions:")
        for ((s,sy_sets) in this.transitions) {
            for ((sy,sets) in sy_sets) {
                for (t in sets){
                    println("  " + s.toString() + " -- " + sy + " --> " + t.toString())
                }
            }
        }
    }

}


public class RegexToNFA{
    var regex:String="" //原始正则表达式
    var processed_regex:String="" //处理后的正则表达式
    var postfix_expr:String="" //后缀表达式
    var nfa:NFA=NFA() //生成的NFA
    let state_counter:counter=counter()
    
    public init(){
        //默认构造函数
    }

    public init(regex:String){
        //初始化正则表达式
        this.regex = regex
        this.processed_regex = add_concatenation_operator(regex)
        this.postfix_expr = convert_postfix_expr(this.processed_regex)
        this.nfa=postfix_to_nfa(this.postfix_expr)
    }

    public func add_concatenation_operator(regex:String):String{
        //在适当位置添加显式连接符
        var result:String =""
        let length =regex.size
        
        for (i in 0..(length - 1)) {
            let current_char= Rune(regex[i]).toString()
            let next_char = Rune(regex[i+1]).toString()
            
            if (current_char != "(" && current_char != "|" && 
               next_char != ")" && next_char != "|" && next_char != "*") {
                result = result + current_char + "."
            } else {
                result = result + current_char
            }
        }
        
        return result + Rune(regex[length - 1]).toString()
    }

    public func convert_postfix_expr(infix_expr: String): String {
        // 使用仓颉的集合类型实现Shunting Yard算法
        let prec: HashMap<String, Int64> = HashMap<String, Int64>()
        prec.add("*", 3)
        prec.add(".", 2) 
        prec.add("|", 1)
        let assoc: HashMap<String, String> = HashMap<String, String>()
        assoc.add("*", "right")
        assoc.add(".", "left")
        assoc.add("|", "left")
        
        var stack: ArrayList<String> = ArrayList<String>()
        var output: ArrayList<String> = ArrayList<String>()
        
        for (token in infix_expr.split("")) {
            if (token=='('){
                stack.add(token)
            }else if(token==')'){
                // 弹出直到 '('
                while ( stack.size > 0 && stack[stack.size - 1] != "(") {
                    output.add(stack[stack.size - 1])
                    stack.remove(at:stack.size - 1)
                }

                if (stack.size > 0 && stack[stack.size - 1] == "(") {
                    stack.remove(at:stack.size - 1) // 弹出 '('
                }
            }else if(prec.contains(token)){
                // 运算符处理
                // 根据优先级和结合性决定是否弹栈
                while (stack.size > 0 && stack[stack.size - 1] != "(") {
                    let top_op = stack[stack.size - 1]
                    if ((assoc.get(token) == "left") && ( prec[token] <= prec[top_op]) ||
                        (assoc.get(token) == "right") && ( prec[token] < prec[top_op])) {
                        output.add(stack[stack.size - 1])
                        stack.remove(at:stack.size - 1)
                    }else{
                        break
                    }
                }
                stack.add(token)
            }else{
                // 操作数直接加入输出
                output.add(token)
            }
        }
        // 剩下的操作符弹栈
        while (stack.size > 0) {
            let op = stack[stack.size - 1]
            stack.remove(at:stack.size - 1)
            if ( op =="(" || op == ")") {
                // 错误处理：括号不匹配
                println("Error: Mismatched parentheses")
                return ""
            }
            output.add(op)
        }
        let postifix_expr =String.join(output.toArray(), delimiter:"")
        return postifix_expr
    }

    public func make_basic_nfa_fragment(char:String){
        //生成新的基本的nfa片段（子nfa的内容）
        let s=this.state_counter.next()
        let t=this.state_counter.next()
        var trans=HashMap<Int64, HashMap<String, HashSet<Int64>>>()
        trans=this.nfa.add_transitions(trans,s,char,HashSet([t]))
        let states=HashSet([s,t])
        let alphabet=HashSet([char])
        return (s,HashSet([t]),trans,alphabet,states)
    }

    public func postfix_to_nfa(postfix_expr:String){
        // 依据后缀式用 Thompson 规则构建 NFA
        var nfa=NFA()
        // 放先后生成的nfa表[(s_old,ac_old,trans_old,alphabet,states)]
        var stack:ArrayList<(Int64, HashSet<Int64>, HashMap<Int64, HashMap<String, HashSet<Int64>>>,HashSet<String>,HashSet<Int64>)> = ArrayList<(Int64, HashSet<Int64>, HashMap<Int64, HashMap<String, HashSet<Int64>>>,HashSet<String>,HashSet<Int64>)>()
        for (token in postfix_expr.split("")) {
            // 使用Thompson构造法
            if (token == "*") {
                //闭包操作
                let (s_old, ac_old,trans_old,alphabet_old,states_old)= stack[stack.size - 1]
                stack.remove(at:stack.size - 1)
                let s_new=this.state_counter.next()
                let t_new=this.state_counter.next()
                var trans=HashMap<Int64, HashMap<String, HashSet<Int64>>>()
                var alphabet:HashSet<String>=alphabet_old
                var states:HashSet<Int64>=states_old

                //先复制旧的   
                for((s,sy_sets) in trans_old){
                    for((sy,sets) in sy_sets){
                        trans=this.nfa.add_transitions(trans,s,sy,sets)
                    }
                }
                // new start -> old start & new accept (空串)
                trans=this.nfa.add_transitions(trans,s_new,EPS,HashSet([s_old]))
                trans=this.nfa.add_transitions(trans,s_new,EPS,HashSet([t_new]))
                // old accepts -> old start (loop) and -> new accept
                for (a in ac_old){
                    trans=this.nfa.add_transitions(trans,a,EPS,HashSet([s_old]))
                    trans=this.nfa.add_transitions(trans,a,EPS,HashSet([t_new]))
                }
                states.add(s_new)
                states.add(t_new)
                stack.add((s_new, HashSet([t_new]), trans,alphabet,states))
            }else if(token=="."){
                //连接运算

                let (s1,ac1,trans1,alphabet1,states1)= stack[stack.size - 2]
                let (s2,ac2,trans2,alphabet2,states2)= stack[stack.size - 1]
                stack.remove(at:stack.size - 1)
                stack.remove(at:stack.size - 1)
                var trans=HashMap<Int64, HashMap<String, HashSet<Int64>>>()
                for ((s,sy_sets) in trans1){
                    for((sy,sets) in sy_sets){
                        trans=this.nfa.add_transitions(trans,s,sy,sets)
                    }
                }
                for ((s,sy_sets) in trans2){
                    for((sy,sets) in sy_sets){
                        trans=this.nfa.add_transitions(trans,s,sy,sets)
                    }
                }
                // 连接: accepts1 -> ε -> s2
                for (a in ac1){
                    trans=this.nfa.add_transitions(trans,a,EPS,HashSet([s2]))
                }
                var alphabet:HashSet<String>=alphabet1
                alphabet.add(all:alphabet2)
                var states=states1
                states.add(all:states2)
                stack.add((s1, ac2, trans,alphabet,states))
            }else if(token=="|"){
                //或运算
                let (s1,ac1,trans1,alphabet1,states1)= stack[stack.size - 2]
                let (s2,ac2,trans2,alphabet2,states2)= stack[stack.size - 1]
                stack.remove(at:stack.size - 1)
                stack.remove(at:stack.size - 1)
                var trans=HashMap<Int64, HashMap<String, HashSet<Int64>>>()
                let s_new=this.state_counter.next()
                let t_new=this.state_counter.next()
                for ((s,sy_sets) in trans1){
                    for((sy,sets) in sy_sets){
                        trans=this.nfa.add_transitions(trans,s,sy,sets)
                    }
                }
                for ((s,sy_sets) in trans2){
                    for((sy,sets) in sy_sets){
                        trans=this.nfa.add_transitions(trans,s,sy,sets)
                    }
                }
                // new start -> s1 , s2
                trans=this.nfa.add_transitions(trans,s_new,EPS,HashSet([s1]))
                trans=this.nfa.add_transitions(trans,s_new,EPS,HashSet([s2]))
                // accepts -> new accept
                for (a in ac1){
                    trans=this.nfa.add_transitions(trans,a,EPS,HashSet([t_new]))
                }
                for (a in ac2){
                    trans=this.nfa.add_transitions(trans,a,EPS,HashSet([t_new]))
                }
                var alphabet:HashSet<String>=alphabet1
                alphabet.add(all:alphabet2)
                var states=states1
                states.add(all:states2)
                states.add(s_new)
                states.add(t_new)
                stack.add((s_new, HashSet([t_new]), trans,alphabet,states) )
            }else{
                //普通字符
                let frag=make_basic_nfa_fragment(token)
                stack.add(frag)
            }
        }
        if (stack.size!=1){
            println("Error: Invalid postfix expression")
            return nfa
        }
        let (start,accepts,transitions,alphabet,states)= stack[stack.size - 1]
        nfa.merge_nfa(accepts, transitions,alphabet,states)
        nfa.start=start
        nfa.accepts=accepts
        nfa.alphabet=alphabet
        nfa.states=states
        return nfa
    }

    func test(code:Int64){
        //测试函数
        if(code==1){
            //测试添加连接符函数
            let examples = ["ab", "a(b|c)", "(a|b)*abb", "a*b", "a(b)c"]
            for (example in examples) {
                let processed = add_concatenation_operator(example)
                println("Original: " + example + " -> Processed: " + processed)
            }
        }else if(code==2){
            //测试中缀转后缀函数
            let examples = ["a.b.c", "a|b.c", "(a.b)|c", "a.b*|c"]
            for (example in examples) {
                let postfix = convert_postfix_expr(example)
                println("Infix: " + example + " -> Postfix: " + postfix)
            }
        }else if(code==3){
            //测试后缀转NFA函数
            let examples = ["a.b.c", "a|b.c", "(a.b)|c", "a.b*|c"]
            for (example in examples) {
                let nfa=postfix_to_nfa(convert_postfix_expr(example))
                nfa.print_nfa()
            }
        }else if(code==4){
            //测试整体流程
            let examples = ["a(b|c)*d", "(a|b)*abb", "abc", "a|bc","a(b|c)*d"]
            for( example in examples){
                let r2n:RegexToNFA=RegexToNFA(example)
                r2n.print_convert_process()
            }
        }else{
            println("Invalid test code")
        }
    }
    public func print_convert_process(){
        println("Infix Regex: " + this.regex)
        println("Processed Regex: " + this.processed_regex)
        println("Postfix Expression: " + this.postfix_expr)
        println("Generated NFA:")
        this.nfa.print_nfa()
    }
} 

// main(){
//     let regex:String="a(b|c)*d"
//     let regex_to_nfa:RegexToNFA=RegexToNFA(regex)
//     println("整体测试:")
//     regex_to_nfa.test(4)

//     println("\n单元测试:")
//     let examples = ["a(b|c)*d", "(a|b)*abb", "abc", "a|bc","a(b|c)*d"]
//     for( example in examples){
//         let r2n:RegexToNFA=RegexToNFA(example)
//         r2n.print_convert_process()
//     }
// }