// cj-DFAmizimizer.cj
//功能：将⼀个给定的DFA转换为等价的最⼩化DFA，并测试多个字符串是否被该最⼩化DFA接受。
//输⼊：⼀个DFA（包括状态集合、状态转换表、初始状态和接受状态集合）。
//输出：最⼩化后的DFA状态集合及其转换关系，指明最⼩化前后的状态数和状态转换关系。

import std.collection.*
import std.core.*

// DFA 最小化器
public class DFAminimizer{
    var dfa:DFA
    var minimized_dfa:DFA

    public init(){
        this.dfa=DFA()
        this.minimized_dfa=DFA()
    }
    public init(dfa:DFA){
        this.dfa=dfa
        this.minimized_dfa=DFA()
        this.minimized_dfa=mizimize()
    }

    func find_predecessors(c:HashSet<Int64>, symbol:String):HashSet<Int64>{
        //找到所有通过symbol转换到集合c中状态的前驱状态
        var predecessors=HashSet<Int64>()
        for (s in this.dfa.states){
            if(this.dfa.transitions.contains(s)){
                let sy_map=this.dfa.transitions[s]
                if(sy_map.contains(symbol)){
                    let to_state=sy_map[symbol]
                    if(c.contains(to_state)){
                        predecessors.add(s)
                    }
                }
            }
        }
        return predecessors
    }

    func intersection(s1:HashSet<Int64>, s2:HashSet<Int64>):HashSet<Int64>{
        //计算两个集合的交集
        var inter_set=HashSet<Int64>()
        for (e in s1){
            if(s2.contains(e)){
                inter_set.add(e)
            }
        }
        return inter_set
    }
    
    func difference(s1:HashSet<Int64>, s2:HashSet<Int64>):HashSet<Int64>{
        //计算两个集合的差集 s1 - s2
        var diff_set=HashSet<Int64>()
        for (e in s1){
            if(!s2.contains(e)){
                diff_set.add(e)
            }
        }
        return diff_set
    }

    func build_minimized_dfa(partitions:ArrayList<HashSet<Int64>>):DFA{
        //根据划分结果构建最小化DFA
        var min_dfa=DFA()
        var state_map=HashMap<Int64, Int64>()//原DFA状态到最小化DFA状态的映射
        for (i in 0..partitions.size){
            let part=partitions[i]
            for (s in part){
                state_map.add(s, Int64(i))
            }
        }
        //设置最小化DFA的状态集合
        for (i in 0..partitions.size){
            min_dfa.states.add(Int64(i))
        }
        //设置最小化DFA的起始状态
        let start_state=this.dfa.start
        let min_start_state=state_map[start_state]
        min_dfa.start=min_start_state
        //设置最小化DFA的接受状态集合
        for (part in partitions){
            for (s in part){
                if(this.dfa.accepts.contains(s)){
                    let min_state=state_map[s]
                    min_dfa.accepts.add(min_state)
                    break
                }
            }
        }
        //设置最小化DFA的转换关系
        for (s in this.dfa.states){
            if(this.dfa.transitions.contains(s)){
                let sy_map=this.dfa.transitions[s]
                for ((symbol, to_state) in sy_map){
                    let from_min_state=state_map[s]
                    let to_min_state=state_map[to_state]
                    min_dfa.add_transitions(min_dfa.transitions, from_min_state, symbol, to_min_state)
                }
            }
        }
        //设置最小化DFA的字母表
        min_dfa.alphabet=this.dfa.alphabet

        return min_dfa
    }

    func index_of_partition(partitions:ArrayList<HashSet<Int64>>, state:HashSet<Int64>):Int64{
        //找到状态state所属的划分的索引
        for (i in 0..partitions.size){
            let part=partitions[i]
            if(part==state){
                return Int64(i)
            }
        }
        return -1
    }

    public func mizimize(){
        // 使用Hopcroft算法将DFA最小化
        // 初始化划分
        var ac_set=HashSet<Int64>()
        var non_ac_set=HashSet<Int64>()
        let accepts= this.dfa.accepts
        let states=this.dfa.states
        for (s in states){
            if(accepts.contains(s)){
                //接受状态划分
                ac_set.add(s)
            }else{
                //非接受状态划分
                non_ac_set.add(s)
            }
        }
        var p=ArrayList<HashSet<Int64>>()//划分集合
        var w=ArrayList<HashSet<Int64>>()//待处理划分集合
        if(ac_set.size>0){
            p.add(ac_set)
            w.add(ac_set)
        }
        if(non_ac_set.size>0){
            p.add(non_ac_set)
            w.add(non_ac_set)
        }

        while (w.size!=0){
            let c=w[w.size-1]//取出待处理划分集合中的最后一个划分
            w.remove(at: w.size-1)
            for (symbol in this.dfa.alphabet){
                let pre=find_predecessors(c, symbol)//找到所有通过symbol转换到集合c中状态的前驱状态
                let p_=ArrayList<HashSet<Int64>>(p)//当前的划分集合的副本
                for (b in p_){
                    //b是当前划分集合中的一个划分
                    let b1:HashSet<Int64>//存放b与pre的交集
                    let b2:HashSet<Int64>//存放b与pre的差集
                    b1=intersection(b,pre)
                    b2=difference(b,pre)

                    if(b1.size>0 && b2.size>0){
                        //需要划分b
                        p.remove(at: index_of_partition(p,b))
                        p.add(b1)
                        p.add(b2)
                        //更新待处理划分集合w
                        if(w.contains(b)){
                            w.remove(at: index_of_partition(w,b))
                            w.add(b1)
                            w.add(b2)
                        }else{
                            //选择较小的划分加入w
                            if(b1.size<=b2.size){
                                w.add(b1)
                            }else{
                                w.add(b2)
                            }
                        }
                    }
                }
            }

        }
        // println("最小化后DFA的状态划分结果:")
        // for (i in 0..p.size){
        //     println("划分 ${i}: ${p[i]}")
        // }
        
        return build_minimized_dfa(p)

    }



}
