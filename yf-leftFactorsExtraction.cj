// yf-leftFactorsExtraction.cj
//对每个⾮终结符的候选式，识别最⻓的公共前缀。
//构建字典树（Trie），辅助提取最⻓公共前缀，将公共前缀提取为新⾮终结符的候选式。
//输出去除左公共因⼦的等价⽂法。
import std.collection.{ArrayList, HashMap, HashSet}
import std.core

// Trie树节点
public class TrieNode{
    var symbol:Symbol
    var children:HashMap<Symbol, TrieNode>
    var is_end:Bool // 是否是一个候选式的结束
    var production_count:Int64 // 经过此节点的候选式的数量

    public init(){
        this.symbol=Symbol.TERMINAL("ε")//默认空符号
        this.children=HashMap<Symbol, TrieNode>()
        this.is_end=false
        this.production_count=0
    }
    
    public init(symbol:Symbol){
        this.symbol=symbol
        this.children=HashMap<Symbol, TrieNode>()
        this.is_end=false
        this.production_count=0
    }

    func add_child(sym: Symbol, node: TrieNode) {
        this.children.add(sym, node)
    }
    
    func get_child(sym: Symbol): TrieNode {
        if(has_child(sym)){
            return this.children[sym]
        }else{
            return TrieNode()
        }
    }
    
    func has_child(sym: Symbol): Bool {
        return this.children.contains(sym)
    }

    func isEmpty():Bool{
        if(this.symbol==Symbol.TERMINAL("ε") && this.children.isEmpty() && this.is_end==false && this.production_count==0){
            return true
        }else{
            return false
        }
    }

}

// Trie树
public class Trie{
    var root:TrieNode=TrieNode()

    //插入候选式
    func insert(symbols:ArrayList<Symbol>){
        var current=this.root//用于遍历的当前节点
        current.production_count += 1

        for(symbol in symbols){
            if(!current.children.contains(symbol)){
                //symbol第一次出现
                current.children.add(symbol,TrieNode(symbol))
            }
            current=current.children[symbol]
            current.production_count+=1
        }
        current.is_end=true
    }

    //查找公共前缀集合
    func find_common_prefixs():ArrayList<ArrayList<Symbol>>{
        var common_prefixes = ArrayList<ArrayList<Symbol>>()
        var stack = ArrayList<(TrieNode, ArrayList<Symbol>)>()  
        stack.add((this.root,ArrayList<Symbol>()))
        
        while(stack.size!=0){
            let (current_node,current_path)=stack[stack.size-1]
            stack.remove(at:stack.size-1)

            // 如果当前节点有多个子节点且由多个串共用，且路径不为空，则记录为公共前缀
            if (current_node.children.size > 1 && current_node.production_count>1&& current_path.size> 0 ){
                common_prefixes.add(current_path.clone())
            }

            // 继续遍历子节点
            for ((child_sym, child_node) in current_node.children) {
                var new_path = current_path.clone()
                new_path.add(child_sym.clone())
                stack.add((child_node, new_path))
            }
        }
        return common_prefixes
    }

    // 查找最长公共前缀
    func find_longest_common_prefix(): ArrayList<Symbol> {
        let all_prefixes =find_common_prefixs()
        if (all_prefixes.isEmpty()) {
            return ArrayList<Symbol>()
        }
        
        var longest = all_prefixes.get(0).getOrThrow()
        for(prefix in all_prefixes) {
            if (prefix.size > longest.size){
                longest = prefix
            }
        }
        return longest
    }

    //打印trie树
    func print(){

    }


    
}

public class LeftCommonFactorExtractor{
    var cfg_str:String;
    var cfg:Grammar;
    var cfg_extract_left_common_factors:Grammar;
    public init(){
        this.cfg_str="";
        this.cfg=Grammar();
        this.cfg_extract_left_common_factors=Grammar();
    }
    public init(c:String){
        this.cfg_str=c
        this.cfg=Grammar(c)
        this.cfg_extract_left_common_factors=Grammar()
        this.cfg_extract_left_common_factors=extract_common_factors(Grammar(c))

    }

    //提取文法左公共因子
    public func extract_common_factors(grammar:Grammar):Grammar{
        let new_grammar=grammar.clone()
        for(production in grammar.productions){
            var new_pro_left=production.left.clone()//新的左产生式（用于加单引号）
            var new_pro_right=ArrayList<Sentence>() // 合并后的右边表达式句子集合
            var sentences_array=production.right.clone()
            var sentences_array_change=production.right.clone()//用于增减
            let trie=generate_trie(production)
            let common_prefixes=trie.find_common_prefixs()
            //print_prefixes(common_prefixes)
            for(common_prefix in common_prefixes){
                var branches=ArrayList<ArrayList<Symbol>>()
                for(sen in sentences_array){
                    //如果是这个左公共因子开头
                    if(sen.start_with(common_prefix)){
                        //得到去除前缀后的分支
                        var branch=ArrayList<Symbol>()
                        for(i in common_prefix.size..sen.sentence.size){
                            branch.add(sen.sentence[i])
                        }
                        branches.add(branch)
                        sentences_array_change.remove(at:get_index(sen,sentences_array_change))
                    }
                }
                if(branches.size>0){
                    //新增产生式
                    new_pro_left=new_pro_left+"'"
                    
                    var right=ArrayList<Sentence>()
                    for(b in branches){
                        right.add(Sentence(b))
                    }
                    var new_production=Production(new_pro_left ,right)
                    new_grammar.productions.add(new_production)
                    new_grammar.non_terminals.add(new_pro_left)

                    let new_sen=common_prefix.clone()
                    new_sen.add(Symbol.NON_TERMINAL(new_pro_left))
                    new_pro_right.add(Sentence(new_sen))
                    
                }
                
            }
            // 更改原来的产生式
            for(last_sen in sentences_array_change){
                //剩下的表达式句子（没有包括公共前缀的）
                new_pro_right.add(last_sen)
            }
            
            var new_production=Production(production.left ,new_pro_right)
            let pos=get_index(production,new_grammar.productions)
            new_grammar.productions.remove(at:pos)
            new_grammar.productions.add(new_production,at:pos)
        }

        return new_grammar
    }

    //通过产生式生成trie
    func generate_trie(production:Production):Trie{
        var new_trie=Trie()
        //设置根节点
        new_trie.root.symbol=Symbol.NON_TERMINAL(production.left)
        
        for(sentence in production.right){
            //插入候选式
            new_trie.insert(sentence.sentence)
        }
        return new_trie
    }

    func print_prefixes(prefixes:ArrayList<ArrayList<Symbol>>){
        println("公共前缀：")
        for(prefix in prefixes){
            for(sym in prefix){
                print(sym.get_value())
            }
            println()
        }
        
    }

    func get_index(s:Sentence,arr:ArrayList<Sentence>):Int64{
        var i=0
        for(a in arr){
            if(a.sentence==s.sentence){
                return i
            }
            i=i+1
        }
        //没找到
        return -1
    }

    func get_index(s:Production,arr:ArrayList<Production>):Int64{
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


}