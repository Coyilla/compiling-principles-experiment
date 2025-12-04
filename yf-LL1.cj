//yf-LL1.cj
//1. 输⼊上下⽂⽆关⽂法。
//2. 判断⽂法是否为LL(1)。
//3. 构造预测分析表。
//4. 实现预测分析器，能够根据输⼊串进⾏语法分析。
import std.collection.{ArrayList, HashMap, HashSet}
import std.core

public class LL1{
    var g:Grammar
    var g_after_extraction_left_common_factors:Grammar
    var g_after_eliminate_left_recursive:Grammar
    var cfg:Grammar
    var FIRST:HashMap<String, HashSet<Symbol>>
    var FOLLOW:HashMap<String, HashSet<Symbol>>

    var lcfe:LeftCommonFactorExtractor
    var lre:CFGleftRecursiveElimination
    var faf:FIRSTandFOLLOW

    var prediction_table:HashMap<String, HashMap<String, Production>>

    public init(){
        this.g=Grammar()
        this.g_after_extraction_left_common_factors=Grammar()
        this.g_after_eliminate_left_recursive=Grammar()
        this.cfg=Grammar()
        this.FIRST=HashMap<String, HashSet<Symbol>>()
        this.FOLLOW=HashMap<String, HashSet<Symbol>>()
        this.lcfe=LeftCommonFactorExtractor()
        this.lre=CFGleftRecursiveElimination()
        this.faf=FIRSTandFOLLOW()
        this.prediction_table=HashMap<String, HashMap<String, Production>>()
    }

    public init(s:String){
        this.g=Grammar(s)
        this.g_after_extraction_left_common_factors=Grammar()
        this.g_after_eliminate_left_recursive=Grammar()
        this.cfg=Grammar()
        this.FIRST=HashMap<String, HashSet<Symbol>>()
        this.FOLLOW=HashMap<String, HashSet<Symbol>>()
        this.prediction_table=HashMap<String, HashMap<String, Production>>()

        this.lcfe=LeftCommonFactorExtractor(s)
        this.g_after_extraction_left_common_factors=lcfe.cfg_extract_left_common_factors
        this.lre=CFGleftRecursiveElimination(this.g_after_extraction_left_common_factors)
        this.g_after_eliminate_left_recursive=lre.cfg_elimate_left_recursion
        this.cfg=this.g_after_eliminate_left_recursive
        this.faf=FIRSTandFOLLOW(this.cfg)
        this.FIRST=faf.FIRST
        this.FOLLOW=faf.FOLLOW
        build_prediction_table()
    }

    public init(grammar:Grammar){
        this.g=grammar
        this.g_after_extraction_left_common_factors=Grammar()
        this.g_after_eliminate_left_recursive=Grammar()
        this.cfg=Grammar()
        this.FIRST=HashMap<String, HashSet<Symbol>>()
        this.FOLLOW=HashMap<String, HashSet<Symbol>>()
        this.prediction_table=HashMap<String, HashMap<String, Production>>()

        this.lcfe=LeftCommonFactorExtractor(g)
        this.g_after_extraction_left_common_factors=lcfe.cfg_extract_left_common_factors
        this.lre=CFGleftRecursiveElimination(this.g_after_extraction_left_common_factors)
        this.g_after_eliminate_left_recursive=lre.cfg_elimate_left_recursion
        this.cfg=this.g_after_eliminate_left_recursive
        this.faf=FIRSTandFOLLOW(this.cfg)
        this.FIRST=faf.FIRST
        this.FOLLOW=faf.FOLLOW
        build_prediction_table()
    }

    func isLL1(){
        //对于每个非终结符的所有产生式，检查是否满足LL(1)条件
        for (non_terminal in this.cfg.non_terminals){
            let sentences=this.cfg.find_sentences(non_terminal)
            var result=HashSet<Symbol>()
            var is_first=true
            //如果只有一个产生式，则跳过
            if(sentences.size<=1){
                continue
            }
            //对于每个非终结符A及其产生式A → α | β
            for(sen in sentences){
                if(is_first){
                    let first_sen=faf.get_first_of_sequence(sen.sentence,this.FIRST)
                    if(first_sen.contains(Symbol.TERMINAL("ε"))){
                        result=FOLLOW[non_terminal]
                    }else{
                        result=first_sen
                    }
                    is_first=false
                }else{
                    let first_sen=faf.get_first_of_sequence(sen.sentence,this.FIRST)
                    if(first_sen.contains(Symbol.TERMINAL("ε"))){
                        result=intersection(result,FOLLOW[non_terminal])//如果ε在FIRST(α)中，则FIRST(β) ∩ FOLLOW(A) = ∅
                    }else{
                        result=intersection(result,first_sen)//FIRST(α) ∩ FIRST(β) = ∅
                    }
                }
            }
            if(result.size!=0){
                //print_hashset_symbol(result)
                return false
            }
        }
        return true
    }

    func print(){
        println("\n原始文法为")
        this.g.print_grammar_merge()
        println("\n提取左公共因子后的文法为")
        this.g_after_extraction_left_common_factors.print_grammar_merge()
        println("\n消除左递归后的文法为")
        this.g_after_eliminate_left_recursive.print_grammar_merge()
        println("\n当前的FIRST集为")
        this.faf.print_first()
        println("\n当前的FOLLOW集为")
        this.faf.print_follow()
        println("\n当前预测分析表为")
        this.print_prediction_table()
        
    }

    func intersection(s1:HashSet<Symbol>,s2:HashSet<Symbol>):HashSet<Symbol>{
        var result=HashSet<Symbol>()
        for(s in s1){
            if(s2.contains(s)){
                result.add(s)
            }
        }
        for(s in s2){
            if(s1.contains(s)){
                result.add(s)
            }
        }
        return result
    }

    func print_hashset_symbol(h:HashSet<Symbol>){
        for(s in h){
            print("${s.get_value()} ")
        }
        println()
    }

    // 构建预测分析表
    func build_prediction_table(){

        if(this.isLL1()){
            println("转换后的文法为LL(1)文法，可以构建预测分析表")
        }else{
            println("转换后的文法不为LL(1)文法，无法构建分析表")
            return
        }
        
        // 初始化表结构
        for (non_terminal in this.cfg.non_terminals) {
            this.prediction_table.add(non_terminal, HashMap<String, Production>())
        }

        // 添加终结符和$
        let all_terminals = this.cfg.terminals.clone()
        all_terminals.add("$")
        if(all_terminals.contains("ε")){
            all_terminals.remove("ε")
        }

        // 遍历每个产生式
        for(production in this.cfg.productions){
            let A=production.left
            for(sentence in production.right){
                let new_production=Production(A,ArrayList<Sentence>([sentence]))
                let first_alpha=this.faf.get_first_of_sequence(sentence.sentence,this.FIRST)

                // 对于FIRST(α)中的每个终结符a，将A→α加入M[A,a]
                for(symbol in first_alpha){
                    if(symbol.get_value()!="ε"){
                        this.prediction_table[A].add(symbol.get_value(),new_production)
                    }else{
                        let follow_A=this.FOLLOW[A]
                        for(b in follow_A){
                            this.prediction_table[A].add(b.get_value(),Production(A,ArrayList<Sentence>([Sentence("ε")])))
                        }
                    }
                }
            }
        }
    }

    //对指定句子的预测分析与过程
    func predictive_parser(input_string:String){
        println("\n句子${input_string}的预测分析")
        let grammar=this.cfg
        var stack=ArrayList<Symbol>()//栈顶在at:0
        var current_symbol=""
        var production:Production=Production()
        stack.add(Symbol.NON_TERMINAL(grammar.start_symbol))
        var input_buffer=ArrayList((input_string+"$").split(""))
        println("栈  输入串  动作")
        while(stack.size!=0){
            let top=stack[0]
            stack.remove(at:0)
            current_symbol=input_buffer[0]
            var is_match=false
            var match_symbol=""

            if(top.is_TERMINAL()){
                //若栈顶是终结符号
                if(top.get_value()==current_symbol){
                    //若匹配
                    is_match=true
                    match_symbol=current_symbol
                    input_buffer.remove(at:0)
                }else{
                    return "Syntax Error"
                }
            }else if(top.is_NON_TERMINAL()){
                //若栈顶是非终结符号
                //查预测表
                if(this.prediction_table.contains(top.get_value())){
                    if(this.prediction_table[top.get_value()].contains(current_symbol)){
                        production =this.prediction_table[top.get_value()][current_symbol]
                        if(production.right.size!=0){
                            //倒叙访问
                            for(i in 0..production.right[0].sentence.size){
                                //非空则入栈
                                if(production.right[0].sentence[production.right[0].sentence.size-1-i].get_value()=="ε"){
                                    continue
                                }
                                stack.add(production.right[0].sentence[production.right[0].sentence.size-1-i],at:0)
                            }
                        }else{
                            return "Syntax Error"
                        }
                    }else{
                        return "Syntax Error"
                    }
                }else{
                    return "Syntax Error"
                }               
            }
            if(is_match){
                println("${toString(stack)} ${toString(input_buffer)}  匹配${match_symbol}")
            }else{
                println("${toString(stack)} ${toString(input_buffer)}  输出${toString(production)}")
            }
            
        }
        current_symbol=input_buffer[0]
        if(current_symbol=="$"){
            return "Parsing Successful"
        }else{
            return "Syntax Error"
        }
    }

    // 打印预测分析表
    func print_prediction_table() {
        
        println("=== 预测分析表 ===")
        
        // 收集所有终结符
        let all_terminals = HashSet<String>()
        all_terminals.add(all: this.cfg.terminals.toArray())
        all_terminals.add("$")
        all_terminals.remove("ε")
        
        // 打印表头
        println("非终结符\\终结符")
        print(" ")
        for (terminal in all_terminals) {
            print("| ${terminal} ")
        }
        println("|")
        
        // 打印分隔线
        print("---")
        for (_ in all_terminals) {
            print("|---")
        }
        println("|")
        
        // 打印表内容
        for (non_terminal in this.cfg.non_terminals) {
            print("${non_terminal}")
            
            let table_row = this.prediction_table.get(non_terminal).getOrThrow()
            
            for (terminal in all_terminals) {
                print("|")
                if(!table_row.contains(terminal)){
                    print(" ")
                    continue
                }
                let production = table_row.get(terminal).getOrThrow()
                if (production.right.size!=0) {
                    // 简化显示，只显示第一个匹配的产生式
                    for (sentence in production.right) {
                        print(" ${non_terminal}→${sentence.str} ")  
                    }
                } else {
                    print(" ")
                }
            }
            println("|")
        }
    }

    func toString(s:ArrayList<Symbol>):String{
        var result=""
        for(sym in s){
            result=result+sym.get_value()
        }
        return result
    }
    func toString(s:ArrayList<String>):String{
        var result=""
        for(sym in s){
            result=result+sym
        }
        return result
    }
    func toString(p:Production):String{
        var result=p.left+"->"
        var first=true
        for(sen in p.right){
            if(first){
                first=false
            }else{
                result=result+" | "
            }
            result=result+sen.str
        }
        return result
    }
}