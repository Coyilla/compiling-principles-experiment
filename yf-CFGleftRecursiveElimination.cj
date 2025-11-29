// yf-CFGleftRecursiveElimination.cj
//输入：⼀个上下文无关文法，包括非终结符、终结符和产生式。
//输出: 消去左递归后的文法
import std.collection.{ArrayList, HashSet}
import std.core

// 文法符号类型
public enum Symbol<: Hashable & Equatable<Symbol>{
    |TERMINAL(String)|NON_TERMINAL(String)
    //文法符号有两种类型：终结符号，非终结符号
    func get_value():String{
        match(this){
            case TERMINAL(s:String)    => s
            case NON_TERMINAL(s:String) => s
        }
    }
    
    public func hashCode(): Int64 {
        match (this) {
        case TERMINAL(s:String)    => 1 ^ s.hashCode()
        case NON_TERMINAL(s:String) => 2 ^ s.hashCode()
        }
    }

    public operator func ==(rhs: Symbol):Bool {
        match ((this,rhs)) {
        case (TERMINAL(a), TERMINAL(b))         => a == b
        case (NON_TERMINAL(a), NON_TERMINAL(b)) => a == b
        case _                                  => false        // 交叉情况：TERMINAL vs NON_TERMINAL
        }
    }
    func print_symbol(){
        match(this){
            case TERMINAL(s:String)    => print("TERMINAL:${s}")
            case NON_TERMINAL(s:String) => print("NON_TERMINAL:${s}")
        }
        println()
    }
    func is_NON_TERMINAL():Bool{
        match(this){
            case NON_TERMINAL(s:String) => true
            case _   =>false
        }
    }

    func is_TERMINAL():Bool{
        match(this){
            case TERMINAL(s:String) => true
            case _   =>false
        }
    }
    func clone():Symbol{
        match(this){
            case TERMINAL(s:String)    =>Symbol.TERMINAL(s)
            case NON_TERMINAL(s:String) => Symbol.NON_TERMINAL(s)
        }
    }
    
}

// 文法符号组成的句子
public struct  Sentence {
    var sentence:ArrayList<Symbol>
    var str:String //比如a+B
    
    public init(){
        this.str=String()
        this.sentence=ArrayList<Symbol>()
    }
    public init(s:String){
        //通过字符串识别
        this.str=s
        this.sentence=ArrayList<Symbol>()
        this.sentence=str_to_split(s)
    }
    public init(sen:ArrayList<Symbol>){
        //直接给定
        this.sentence=sen.clone()
        this.str=String()
        this.str=sen_join_str(sen)
    }

    //将纯字符串的句子分割为ArrayList<Symbol>，默认符号+' 是连续在一起的符号，即A'为一个整体，其他以单个符号为一个整体，即AB视为A和B.
    //特殊多字符文法符号由spe_sy指出（暂时不考虑）
    //默认大写为非终结符号，小写、数字为终结符号
    func str_to_split(string:String){
        var new_sentence=ArrayList<Symbol>()
        for (s in string.split("")){
            if(s>="A" && s<="Z"){
                //大写字符，默认为非终结符号
                new_sentence.add(Symbol.NON_TERMINAL(s))
            }else if(s==" "){
                //空格，跳过
                continue
            }else if(s=="'"||s=="’"){
                //',找到前面的一个非终结符号，更新加入'
                var last_non_terminal=new_sentence.get(new_sentence.size-1).getOrThrow().get_value()
                new_sentence.remove(at:new_sentence.size-1)
                new_sentence.add(Symbol.NON_TERMINAL(last_non_terminal+s))
            }else{
                //其余默认为终结符号
                new_sentence.add(Symbol.TERMINAL(s))
            }
            
        }

        return new_sentence
    }
    func print_sentence(){
        for (s in this.sentence){
            print(s.get_value())
        }
        println()
    }
    func sen_join_str(sen:ArrayList<Symbol>){
        var s=String()
        for(symbol in sen){
            s=s+symbol.get_value()+" "
        }
        return s
    }
    func clone(){
        var news=Sentence()
        news.sentence=ArrayList<Symbol>()
        for(s in this.sentence){
            news.sentence.add(s.clone())
        }
        news.str=this.str.clone()
        return news
    }

    func start_with(prefix:ArrayList<Symbol>):Bool{
        if(prefix.size>this.sentence.size){
            return false //前缀比原串还长
        }
        for (i in 0..prefix.size){
            if(this.sentence[i]!=prefix[i]){
                return false
            }
        }
        return true
    }

    public operator func ==(rhs: Sentence):Bool{
        if(this.sentence==rhs.sentence){
            return true
        }else{
            return false
        }
    }

}

// 产生式
public struct Production{
    var left: String  // 左部非终结符
    var right: ArrayList<Sentence> // 右部候选式（每个候选式是符号列表）
    //A->A+b | c
    //left:A
    //right:{A+b ,  c}

    public init(){
        this.left=String()
        this.right=ArrayList<Sentence>()
    }
    public init(production:String){
        //比如A->AB
        var psplit =production.split("->")
        if(psplit.size==1){
            psplit=production.split("→")
        }
        if(psplit.size!=2){
            //出错，默认赋值
            this.left=String()
            this.right=ArrayList<Sentence>()
        }else{
            this.left=psplit[0].trimAscii() // 左部非终结符
            this.right=ArrayList<Sentence>()// 右部候选式
            var sen=String()//暂时存放单独的句子，用于处理|分割的问题
            var stack=ArrayList<String>()//栈，看（）是否成对
            for(s in psplit[1].split("")){
                if(s=="("){
                    stack.add("(")
                    sen=sen+s.toString()
                }else if (s==")"){
                    if(stack.size>0){
                        stack.remove(at:stack.size-1)
                    }
                    sen=sen+s
                }else if (s=="|"){
                    if(stack.size>0 && stack[stack.size-1]=="("){
                        sen=sen+s
                    }else{
                        this.right.add(Sentence(sen))
                        sen=String()
                    }
                }else if(s==" "){
                    continue
                }
                else{
                    sen=sen+s
                }
            }
            if(!sen.isEmpty()){
                this.right.add(Sentence(sen))
            }
        }
    }
    public init(l:String,r:ArrayList<Sentence>){
        this.left=l
        this.right=r
    }
    func print_production(){
        for(r in this.right){
            println(this.left.toString()+" -> "+r.str)
        }
    }
    func print_production_merge(){
        var rarray=ArrayList<String>()
        for(r in this.right){
            rarray.add(r.str)
        }
        println(this.left.toString()+" -> "+String.join(rarray.toArray(),delimiter: " | "))
    }
    func clone(){
        var new_production=Production()
        new_production.right=this.right.clone()
        new_production.left=this.left.clone()
        return new_production 
    }
    func right_contains(s:Sentence){
        for (pro_s in this.right){
            if(s.sentence==pro_s.sentence){
                return true
            }
        }
        return false
    }
    public operator func ==(rhs:Production):Bool{
        if(this.left==rhs.left){
            if(this.right.size==rhs.right.size){
                return true
            }
        }
        return false
    }
}

// 文法
public struct Grammar  {
    var non_terminals: HashSet<String>
    var terminals: HashSet<String>
    var productions: ArrayList<Production>
    var start_symbol: String
    public init(){
        this.non_terminals=HashSet<String>()
        this.terminals=HashSet<String>()
        this.productions=ArrayList<Production>()
        this.start_symbol=String()
    }
    public init( non_terminals: HashSet<String>,terminals: HashSet<String>,productions: ArrayList<Production>,start_symbol: String){
        this.terminals=terminals
        this.productions=productions
        this.start_symbol=start_symbol
        this.non_terminals=non_terminals
    }
    public init(string:String){
        this.non_terminals=HashSet<String>()
        this.terminals=HashSet<String>()
        this.productions=ArrayList<Production>()
        this.start_symbol=String()
        var flag=true
        for(s in string.split("\n")){
            //println(s)
            if(s==""){
                continue
            }
            let pro=Production(s)
            this.productions.add(pro)
            if(flag){
                flag=false
                this.start_symbol=pro.left
            }
            this.non_terminals.add(pro.left)
            for(sentence in pro.right){
                for(symbol in sentence.sentence){
                    match(symbol){
                        case TERMINAL(s:String)    => this.terminals.add(s)
                        case NON_TERMINAL(s:String) => this.non_terminals.add(s)
                    }
                }

            }
        }
    }
    public func print_grammar(){
        println("非终结符: " + this.non_terminals.toString())
        println("终结符: " + this.terminals.toString())
        println("产生式: ")
        for(production in this.productions){
            production.print_production() 
        }
        println("开始符号: " + this.start_symbol)
    }
    public func print_grammar_merge(){
        println("非终结符: " + this.non_terminals.toString())
        println("终结符: " + this.terminals.toString())
        println("产生式: ")
        for(production in this.productions){
            production.print_production_merge() 
        }
        println("开始符号: " + this.start_symbol)
    }

    func get_production(l:String):Production{
        for(p in this.productions){
            if(p.left==l){
                return p
            }
        }
        return Production()
    }
    func clone(){
        var new_grammar=Grammar()
        new_grammar.productions=this.productions.clone()
        new_grammar.non_terminals=this.non_terminals.clone()
        new_grammar.terminals=this.terminals.clone()
        new_grammar.start_symbol=this.start_symbol.clone()
        return new_grammar
    }

    func find_sentences(l:String):ArrayList<Sentence>{
        for(production in this.productions){
            if(production.left==l){
                return production.right
            }
        }
        return ArrayList<Sentence>()
    }

    func toString(){
        var s=String()
        var is_first=true
        for(production in this.productions){
            if(is_first){
                is_first=false
            }else{
                s=s+"\n"
            }
            var rarray=ArrayList<String>()
            for(r in production.right){
                rarray.add(r.str.trimAscii())
            }
            s=s+production.left.toString()+" -> "+String.join(rarray.toArray(),delimiter: " | ")
        }
        
        return s
    }
}

// 测试函数
func test_grammar(){
    let s=
    '''
 S → abcS’ | bcS’ | cS’
 S’ → abcS’ | ε
'''
   let g:Grammar=Grammar(s)
   g.print_grammar()
   g.print_grammar_merge()
}






public class CFGleftRecursiveElimination{
    var cfg_str:String;
    var cfg:Grammar;
    var cfg_elimate_left_recursion:Grammar;
    public init(){
        this.cfg_str="";
        this.cfg=Grammar();
        this.cfg_elimate_left_recursion=Grammar();
    }
    public init(c:String){
        this.cfg_str=c
        this.cfg=Grammar(c)
        this.cfg_elimate_left_recursion=Grammar()
        this.cfg_elimate_left_recursion=elimate_left_recursion(Grammar(c))

    }

    public init(g:Grammar){
        this.cfg_str=g.toString()
        this.cfg=g
        this.cfg_elimate_left_recursion=Grammar()
        this.cfg_elimate_left_recursion=elimate_left_recursion(g)

    }
    func get_index(s:String,arr:Array<String>):Int64{
        var i=0
        for(a in arr){
            if(a==s){
                return i
            }
            i=i+1
        }
        //没找到
        return -1
    }
    func compare_index(s1:String,s2:String,arr:Array<String>):Int64{
        let i1=get_index(s1,arr)
        let i2=get_index(s2,arr)
        if(i1>=0 && i2>=0){
            if(i1<i2){
                return -1
            }else if(i1>i2){
                return 1
            }else{
                return 0
            }
        }else{
            return 2 //不存在
        }
    }
    
    public func elimate_left_recursion(cfg:Grammar):Grammar{
        // step1 消除间接左递归
        var new_cfg=cfg.clone()
        //非终结符号排序（以出现顺序）
        let order=new_cfg.non_terminals.toArray()
        var changed = true
        // 需要多次迭代直到没有变化
        while (changed) {
            changed = false
            for (i in 0..(new_cfg.productions.size)){
                let production_i=new_cfg.productions[i].clone() //当前判断的产生式（原始版）
                let current_nt = production_i.left //当前非终结符

                for(p_i in 0..production_i.right.size){
                    let candidate = production_i.right[p_i] // 正在处理的式子
                    if(candidate.sentence.size > 0 && candidate.sentence[0].is_NON_TERMINAL()){
                        let first_nt = candidate.sentence[0].get_value() // 正在处理的式子的首个字符
                        // 检查是否是需要替换的非终结符（排在当前非终结符前面）
                        let current_index = order.indexOf(current_nt).getOrThrow()//当前非终结符的索引
                        let first_index = order.indexOf(first_nt).getOrThrow()//正在处理的式子的首个字符的索引
                        if (first_index>= 0 && first_index < current_index) {
                            // 存在需要替换的间接左递归
                            let production_j = new_cfg.get_production(first_nt) //用于替换的产生式
                            for (sen_j in production_j.right) {
                                let new_sen = candidate.sentence.clone()
                                new_sen.remove(at: 0)  // 移除开头的first_nt
                                new_sen.add(at: 0, all: sen_j.sentence)  // 插入替换的产生式右部
                            
                                // 检查是否产生新的产生式
                                let new_sentence = Sentence(new_sen)
                                if (!new_cfg.productions[i].right_contains(new_sentence)) {
                                    new_cfg.productions[i].right.add(new_sentence)
                                    changed = true
                                }
                            }
                            // 移除原始产生式
                            new_cfg.productions[i].right.remove(at:p_i)
                        }
                    
                    }
                }

            }
        }
        //step2 消除直接左递归
        new_cfg=remove_direct_left_recursion(new_cfg)
        
        return new_cfg
    }
    func remove_direct_left_recursion(cfg:Grammar):Grammar{
        var new_cfg=cfg.clone()
        for (i in 0..(new_cfg.productions.size)){
            let production_i=new_cfg.productions[i].clone() //当前判断的产生式（原始版）
            let current_nt = production_i.left //当前非终结符

            var dlr_set=ArrayList<Sentence>()//直接左递归的式子的集合
            var non_dlr_set=ArrayList<Sentence>()//非直接左递归式子集合

            for(p_i in 0..production_i.right.size){
                var candidate = production_i.right[p_i] // 正在处理的式子
                if(candidate.sentence.size > 0){
                    let first_nt = candidate.sentence[0].get_value() // 正在处理的式子的首个字符
                    if(current_nt==first_nt){
                        // 为直接左递归
                        dlr_set.add(candidate)
                    }else{
                        // 不为直接左递归
                        non_dlr_set.add(candidate)
                    }   
                }
            }
            //处理直接左递归
            if(dlr_set.size>0){
                let new_current_nt=current_nt+"'"
                for (j in 0..non_dlr_set.size) {
                    let old = non_dlr_set[j]
                    non_dlr_set[j] = Sentence(old.str + new_current_nt)
                }
                var new_production1=Production(current_nt,non_dlr_set)
                new_cfg.productions[i]=new_production1
                new_cfg.non_terminals.add(new_current_nt)

                var new_production2=Production()//新的产生式
                new_production2.left=new_current_nt
                for (j in 0..dlr_set.size) {
                    let old = dlr_set[j]
                    old.sentence.remove(at:0)
                    old.sentence.add(Symbol.NON_TERMINAL(new_current_nt))
                    dlr_set[j] = Sentence(old.sentence)
                }
                dlr_set.add(Sentence("ε"))
                new_production2.right=dlr_set
                new_cfg.productions.add(new_production2)//更新new_cfg
                new_cfg.terminals.add("ε")
            }    

        }
        return new_cfg
    }
    
}