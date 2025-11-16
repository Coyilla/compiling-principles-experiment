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

}

// NFA 转 DFA 的转换器类
public class NFA2DFAConverter {
    var nfa: NFA= NFA()
    var dfa: DFA = DFA()
    var stateIdCounter: counter =counter()

    public init(nfa: NFA) {
        this.nfa = nfa
        this.dfa = convert(this.nfa)
    }

    public func esp_closure(t: Int64): HashSet<Int64> {
        //计算给定状态t的ε-闭包，即状态t经过任意条ε转换后能到达的所有状态集合
        var closure = HashSet<Int64>(t)
        var stack = ArrayList<Int64>(t)

        return closure
    }

    // 主转换函数
    public func convert(nfa:NFA): DFA {
        var dstates=ArrayList<HashSet<Int64>>()
        dstates[1]=esp_closure(nfa.start)
        var p=1
        var j=1
        while(j<=p){

        }
        return DFA()

  
    }
}

