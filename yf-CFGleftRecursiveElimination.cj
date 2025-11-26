// yf-CFGleftRecursiveElimination.cj
//输入：⼀个上下文无关文法，包括非终结符、终结符和产生式。
//输出: 消去左递归后的文法
import std.collection.{ArrayList, HashMap, HashSet}
import std.core

// 文法符号类型
public enum Symbol<: Hashable & Equatable<Symbol>{
    |TERMINAL(String)|NON_TERMINAL(String)|OPERATOR(String)
    //文法符号有三种类型：终结符号，非终结符号，运算符
    func get_value():String{
        match(this){
            case TERMINAL(s:String)    => s
            case NON_TERMINAL(s:String) => s
            case OPERATOR(s:String)   =>s
        }
    }
    
    public func hashCode(): Int64 {
        match (this) {
        case TERMINAL(s:String)    => 1 ^ s.hashCode()
        case NON_TERMINAL(s:String) => 2 ^ s.hashCode()
        case OPERATOR(s:String)   => 3 ^ s.hashCode()
        }
    }

    public operator func ==(rhs: Symbol):Bool {
        match ((this,rhs)) {
        case (TERMINAL(a), TERMINAL(b))         => a == b
        case (NON_TERMINAL(a), NON_TERMINAL(b)) => a == b
        case (OPERATOR(a),OPERATOR(b))          => a == b
        case _                                  => false        // 交叉情况：TERMINAL vs NON_TERMINAL
        }
    }
    func print_symbol(){
        match(this){
            case TERMINAL(s:String)    => print("TERMINAL:${s}")
            case NON_TERMINAL(s:String) => print("NON_TERMINAL:${s}")
            case OPERATOR(s:String)   =>print("OPERATOR:${s}")
        }
        println()
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
        this.str=String()
        for (sym in sen){
            this.str=this.str+sym.get_value()+" "
        }
        this.sentence=sen
    }

    //将纯字符串的句子分割为ArrayList<Symbol>，默认符号+' 是连续在一起的符号，即A'为一个整体，其他以单个符号为一个整体，即AB视为A和B.
    //特殊多字符文法符号由spe_sy指出（暂时不考虑）
    //默认大写为非终结符号，小写、数字为终结符号
    func str_to_split(string:String){
        var new_sentence=ArrayList<Symbol>()
        for (s in string.split("")){
            if(s>="A" && s<="Z"){
                //大写字符，默认为非终结符号
                let i=string.indexOf(s).getOrThrow()
                let quoteByte: UInt8 = 0x27   // ASCII 单引号 '
                let curlyQuoteByte: UInt8 = 0x92  // Windows 经常出现的右单引号（’）
                if(i+1<=string.size-1){
                    let b = string[i + 1]
                    if((b == quoteByte || b == curlyQuoteByte)){
                        if(b==quoteByte){
                            new_sentence.add(Symbol.NON_TERMINAL(s+"'"))
                        }else{
                            new_sentence.add(Symbol.NON_TERMINAL(s+"’"))
                        }
                    }else{
                    new_sentence.add(Symbol.NON_TERMINAL(s))
                    }
                }else{
                    new_sentence.add(Symbol.NON_TERMINAL(s))
                }

            }else if([",","|","+","*",".","(",")","+","-","/"].contains(s)){
                //运算操作符
                new_sentence.add(Symbol.OPERATOR(s))
                
            }else if(s==" "){
                //空格，跳过
                continue

            }else if(s=="'"||s=="’"){
                //',跳过
                continue

            }else{
                //小写字符和数字，默认为终结符号
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
                        case _  => continue
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
}

// 测试函数
func test_grammar(){
    let s=
    '''
E→ET+ | ET- | T
T→TF* | TF/ | F
F→(E) | i
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
        this.cfg_elimate_left_recursion=elimate_left_recursion(this.cfg);
    }
    public func elimate_left_recursion(cfg:Grammar):Grammar{
        var new_cfg=Grammar()

        return new_cfg
    }
    
}