//yf-FIRSTandFOLLOW.cj
//输⼊⼀个上下⽂⽆关⽂法，包括⾮终结符、终结符和产⽣式。
//输出每个⾮终结符的FIRST集和FOLLOW集。
import std.collection.{ArrayList, HashMap, HashSet}
import std.core

public class FIRSTandFOLLOW{
    var cfg:Grammar
    var FIRST:HashMap<String, HashSet<Symbol>>
    var FOLLOW:HashMap<String, HashSet<Symbol>>

    public init(){
        this.cfg=Grammar()
        this.FIRST=HashMap<String, HashSet<Symbol>>()
        this.FOLLOW=HashMap<String, HashSet<Symbol>>()
    }

    public init(g:Grammar){
        this.cfg=g
        this.FIRST=HashMap<String, HashSet<Symbol>>()
        this.FOLLOW=HashMap<String, HashSet<Symbol>>()
        this.FIRST=buildFIRST(g)
        this.FOLLOW=buildFOLLOW(g)
    }

    func buildFIRST(g:Grammar){
        var new_first=HashMap<String, HashSet<Symbol>>()
        //设置终结符号的FIRST(自身)
        for (terminal in g.terminals){
            new_first.add(terminal,HashSet<Symbol>([Symbol.TERMINAL(terminal)]))
        }
        //设置非终结符号的FIRST
        //先设空
        for (non_terminal in g.non_terminals){
            new_first.add(non_terminal,HashSet<Symbol>())
        }
        //逐一遍历
        for (non_terminal in g.non_terminals){
            new_first[non_terminal].add(all:find_first(non_terminal))
        }
        return new_first
    }

    func buildFOLLOW(g:Grammar){
        var new_follow=HashMap<String,HashSet<Symbol>>()
        //先设空
        for (terminal in g.terminals){
            new_follow.add(terminal,HashSet<Symbol>())
        } 
        for (non_terminal in g.non_terminals){
            new_follow.add(non_terminal,HashSet<Symbol>())
        }
        //对于开始符号 ,$加入
        new_follow[g.start_symbol].add(Symbol.TERMINAL("$"))

        //迭代计算过程
        var changed:Bool
        do {
            changed=false
            // 遍历每个产生式 A → αBβ
            for(production in g.productions){
                let A=production.left

                for(sentence in production.right){
                    // 遍历句子中的每个符号，寻找非终结符B
                    for(i in 0..sentence.sentence.size){
                        let current_symbol = sentence.sentence[i]
                        //当前符号为非终结符，则为B
                        if(current_symbol.is_NON_TERMINAL()){
                            var follow_B=new_follow[current_symbol.get_value()]
                            var changed_B=false

                            // 检查β是否存在（即B后面还有符号）
                            if(i+1<sentence.sentence.size){
                                // β不为空，计算FIRST(β)
                                let beta = ArrayList<Symbol>()
                                for(j in (i+1)..sentence.sentence.size){
                                    beta.add(sentence.sentence[j])
                                }
                                let first_beta = get_first_of_sequence(beta, this.FIRST) //求得FIRST(β)
                                // //------print first_beta---------
                                // print("FIRST(")
                                // for(b in beta){
                                //     print(b.get_value())
                                // }
                                // print(")={")
                                // for(syb in first_beta){
                                //     print(syb.get_value()+" ")
                                // }
                                // println("}")

                                // 将FIRST(β)中的所有符号（除去ε）加入FOLLOW(B)
                                for (symbol in first_beta) {
                                    if (symbol.get_value()!="ε") {
                                        if (!follow_B.contains(symbol)) {
                                            follow_B.add(symbol)
                                            changed_B = true
                                        }
                                    }
                                
                                }
                                // 如果ε在FIRST(β)中，将FOLLOW(A)加入FOLLOW(B)
                                if (first_beta.contains(Symbol.TERMINAL("ε"))) {
                                    let follow_A = new_follow.get(A).getOrThrow()
                                    for (symbol in follow_A) {
                                        if(!follow_B.contains(symbol)){
                                            follow_B.add(symbol) 
                                            changed_B = true
                                        }
                                    }
                                }
                            }else {
                                // β为空，即产生式为 A → αB，将FOLLOW(A)加入FOLLOW(B)
                                let follow_A = new_follow.get(A).getOrThrow()
                                for (symbol in follow_A) {
                                    if (!follow_B.contains(symbol)) {
                                        follow_B.add(symbol)
                                        changed_B = true
                                    }
                                }
                            }
                            if(changed_B){
                                new_follow.add(current_symbol.get_value(), follow_B)
                                changed = true
                            }
                        }

                        
                    }
                }
            }
            
        } while (changed)

        return new_follow
    }

    //递归寻找first
    func find_first(non_terminal:String):HashSet<Symbol>{
        let new_first=HashSet<Symbol>()
        for(sen in this.cfg.find_sentences(non_terminal)){
            //终结符号
            if(!sen.sentence[0].is_NON_TERMINAL()){
                new_first.add(all:HashSet([sen.sentence[0]]))
            }else{
                //非终结符号
                var i=0
                var last_non_terminal_first_set=HashSet<Symbol>()
                var has_esp=true
                while(has_esp){
                    var last_non_terminal_first=find_first(sen.sentence[i].get_value()).clone()
                    last_non_terminal_first_set.add(all:last_non_terminal_first)
                    has_esp=false
                    if(last_non_terminal_first.contains(Symbol.TERMINAL("ε"))){
                        if(sen.sentence.size>i+1){
                            last_non_terminal_first_set.remove(Symbol.TERMINAL("ε"))
                            i=i+1
                            has_esp=true
                        }
                    }
                }
                new_first.add(all:last_non_terminal_first_set)
            }
        }
        return new_first

    }




    func print_first(){
        println("FIRST集")
        for(non_terminal in this.cfg.non_terminals){
            var is_first=true
            print("FIRST[${non_terminal}]={")
            for(s in this.FIRST[non_terminal]){
                if(is_first){
                    print("${s.get_value()}")
                    is_first=false
                }else{
                    print(",${s.get_value()}")
                }
                
            }
            println("}")
        }
    }

    func get_first_of_sequence(symbols: ArrayList<Symbol>, first_sets: HashMap<String, HashSet<Symbol>>): HashSet<Symbol> {
        var result = HashSet<Symbol>()
        
        if (symbols.isEmpty()) {
            return result
        }
        
        var all_contain_epsilon = true//只含ε
        
        for (symbol in symbols) {
            if(symbol.is_TERMINAL()){
                //终结符
                result.add(all:first_sets[symbol.get_value()])
                all_contain_epsilon = false
                break
            }else{
                //非终结符
                let first_B = first_sets.get(symbol.get_value()).getOrThrow()
                //结果为FIRST[B]（排除ε）
                for (sym in first_B) {
                    if (sym.get_value() !="ε") {
                        result.add(sym)
                    }
                }
                    
                if (!first_B.contains(Symbol.TERMINAL("ε"))) {
                    all_contain_epsilon = false
                    break
                }

            }
            
        }
        
        if (all_contain_epsilon) {
            result.add(Symbol.TERMINAL("ε"))
        }
        
        return result
    }

    func print_follow(){
        println("FOLLOW集")
        for(non_terminal in this.cfg.non_terminals){
            var is_first=true
            print("FOLLOW[${non_terminal}]={")
            for(s in this.FOLLOW[non_terminal]){
                if(is_first){
                    print("${s.get_value()}")
                    is_first=false
                }else{
                    print(",${s.get_value()}")
                }
                
            }
            println("}")
        }
    }

    

}