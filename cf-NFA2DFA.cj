// cf-NFA2DFA.cj
//功能：将⼀个给定的NFA转换为等价的DFA，并测试多个字符串是否被该DFA接受。
//输⼊：⼀个NFA（包括状态集、转换表、初始状态和接受状态集合）和多个测试字符串。
//输出：⽣成的DFA状态集合及其转换关系，指明每个测试字符串是否被DFA接受。
import std.collection.*
import std.core.*

// DFA 状态转换表
public class DFA{
    var start: Int64
    var accepts: HashSet<Int64>
    var transitions: HashMap<Int64, HashMap<String, Int64>>
    var states: HashSet<Int64>
    var alphabet: HashSet<String>
    public init() {
        this.start = 0
        this.accepts = HashSet()
        this.transitions = HashMap()
        this.states=HashSet()
        this.alphabet=HashSet()
    }
    public init(start: Int64,
                accepts: HashSet<Int64>,
                transitions: HashMap<Int64, HashMap<String, Int64>>,
                states: HashSet<Int64>,
                alphabet: HashSet<String>) {
        this.start = start
        this.accepts = accepts
        this.transitions = transitions
        this.states=states
        this.alphabet=alphabet
    }

    public func add_transitions(trans:HashMap<Int64, HashMap<String, Int64>>,s_from:Int64, symbol:String, s_to:Int64){
        //为指定trans再增加一个转换关系（从s_from,通过输入字母symbol，转换到状态s_to）
        if (trans.contains(s_from)){
            if(trans[s_from].contains(symbol)){
                trans[s_from][symbol]=s_to
            }else{
                trans[s_from].add(symbol, s_to)
            }
        }else{
            let map_sy_to=HashMap<String, Int64>([(symbol,s_to)])
            trans.add(s_from,map_sy_to)
        }
        return trans
    }

    public func print_dfa(){
        //打印DFA的状态转换表
        println("DFA Start State: ${this.start}")
        println("DFA Accept States: ${this.accepts}")
        println("DFA States: ${this.states}")
        println("DFA Alphabet: ${this.alphabet}")
        println("DFA Transitions:")
        for ((s_from, sy_map) in this .transitions) {
            for ((sym, s_to) in sy_map) {
                println(" ${s_from} -- ${sym} --> ${s_to}")
            }
        }
    }

}

// NFA 转 DFA 的转换器类
public class NFA2DFAConverter {
    var nfa: NFA
    var dfa: DFA

    public init(){
        this.nfa = NFA()
        this.dfa = DFA()
    }

    public init(nfa: NFA) {
        this.nfa = nfa
        this.dfa = DFA()
        this.dfa=convert()
    }

    public func esp_closure(t: Int64): HashSet<Int64> {
        //计算给定状态t的ε-闭包，即状态t经过任意条ε转换后能到达的所有状态集合
        var closure = HashSet<Int64>()
        closure.add(t)
        var stack = ArrayList<Int64>()
        stack.add(t)
        while (stack.size > 0) {
            let state = stack[stack.size - 1]
            stack.remove(at: stack.size - 1)
            if (this.nfa.transitions.contains(state) && this.nfa.transitions[state].contains(EPS)) {
                for (next_state in this.nfa.transitions[state][EPS]) {
                    if (!closure.contains(next_state)) {
                        closure.add(next_state)
                        stack.add(next_state)
                    }
                }
            }
        }

        return closure
    }

    public func esp_closure(I: HashSet<Int64>): HashSet<Int64> {
        //计算给定状态集合I的ε-闭包，即集合I中每个状态经过任意条ε转换后能到达的所有状态集合的并集
        var closure = HashSet<Int64>()
        for (state in I) {
            let state_closure = esp_closure(state)
            closure.add(all: state_closure)
        }
        return closure
    }

    public func edge(t:Int64,a:String): HashSet<Int64> {
        //计算从状态t出发，经过输入符号a能到达的所有状态集合
        var result = HashSet<Int64>()
        if (this.nfa.transitions.contains(t) && this.nfa.transitions[t].contains(a)) {
            result = this.nfa.transitions[t][a]
        }
        return result

    }

    public func edge(I:HashSet<Int64>,a:String): HashSet<Int64> {
        //计算从状态集合I出发，经过输入符号a能到达的所有状态集合的并集
        var result = HashSet<Int64>()
        for (state in I) {
            let state_edges = edge(state, a)
            result.add(all: state_edges)
        }
        return result
    }

    public func dfa_edge(T:HashSet<Int64>,a:String): HashSet<Int64> {
        //计算从状态集合T出发，经过输入符号a能到达的所有状态集合的ε-闭包
        let move_result = edge(T, a)
        let closure_result = esp_closure(move_result)
        return closure_result
    }

    // 主转换函数
    public func convert(): DFA {
        var dfa=DFA()
        var dstates=ArrayList<HashSet<Int64>>()
        dstates.add(esp_closure(this.nfa.start))//DFA的第一个状态对应NFA的起始状态的ε-闭包
        var j=0//当前正在处理的DFA状态编号
        //检查dstates中的每个状态集合
        while(j<dstates.size){
            for (a in this.nfa.alphabet){
                let e=dfa_edge(dstates[j],a)
                // 如果 e 是空集，跳过
                if (e.size == 0) {
                    continue
                }
                //检查e是否已在dstates中
                var found = false
                var idx: Int64 = -1
                for (i in 0..dstates.size){
                    if(dstates[i]==e){
                        //找到了，添加转换关系
                        found = true
                        idx = Int64(i)
                        break
                    }
                }
                if(!found){
                    //没找到，添加新状态到dstates，并添加转换关系
                    dstates.add(e)
                    idx=Int64(dstates.size - 1)
                }
                //添加DFA的转换关系
                let from_state:Int64=Int64(j)
                let to_state:Int64=idx
                dfa.add_transitions(dfa.transitions,from_state,a,to_state)
            }
            j=j+1
        }
        //设置DFA的起始状态和接受状态集合,以及状态集合和字母表
        dfa.start=0
        for (i in 0..dstates.size){
            dfa.states.add(Int64(i))
            for (nfa_accept_state in nfa.accepts){
                if(dstates[i].contains(nfa_accept_state)){
                    dfa.accepts.add(Int64(i))
                    break
                }
            }
        }
        dfa.alphabet=nfa.alphabet

        return dfa
    }
}



