# coding: utf-8

#词法分析-基本表达转NFA
#输⼊：正规表达式和多个测试字符串。
#输出：⽣成的NFA状态集合及其转换关系，指明每个测试字符串是否被NFA接受。
from collections import defaultdict
import itertools

EPS = 'ε'  # epsilon 表示

#NFA状态转换表
class NFA:
    def __init__(self):
        self.start=None #起始状态id
        self.accepts=set() #接受状态id集合
        # transitions: state -> symbol -> set(next_states)
        self.transitions=defaultdict(lambda:defaultdict(set))#转换关系
        self.__state_gen=itertools.count() #全局唯一的状态 id 生成器
    
    def new_state(self):
        # 返回一个全局唯一的状态 id
        return next(self.__state_gen)
    
    def add_transitions(self,s_from:int,symbol:str,s_to:int):
        # 增加一个转换关系（从s_from,通过输入字母symbol，转换到状态s_to）
        self.transitions[s_from][symbol].add(s_to)

    def merge_nfa(self,start:int,accepts:set,trans):
        # 合并nfa状态转换表的片段
        for s,sy_sets in trans.items():
            for sym, sets in sy_sets.items():
                self.transitions[s][sym].update(sets)
        if self.start is None:
            self.start=start
        self.accepts.update(accepts)

    #def visualization(self):
        #npa的可视化
        
    
#将正则表达式转换为NFA的主要转换器
class RegexToNFAConverter:
    def __init__(self,regex):
        #regex为正规表达式
        #输入的表达式字符串插入显式的连接运算符'.'
        self.regex=self.add_concatenation_operator(regex)
        #将中缀表达式转换为后缀表达式
        self.postfix_expr=self.convert_postfix_expr(self.regex)
        self.nfa=self.postfix_to_nfa(self.postfix_expr)

    def add_concatenation_operator(self,regex:str):
        result=''
        for i in range(len(regex)-1):
            #当前字符是),*,原子，而下一个字符是(或原子时，在当前字符后加入.表示连接运算
            if regex[i] not in ["(","|"] and regex[i+1] not in [")","|","*"]:
                result=result+regex[i]+"."
            else:
                result=result+regex[i]
        
        return result+regex[-1]
    
    def convert_postfix_expr(self,infix_expr:str):
        #优先级：() >> * >> . >> |
        prec={"*":3,".":2,"|":1} #优先级
        assoc={"*":"right",".":"left","|":"left"} #连接方向
        stack=[]
        output=[]
        for token in infix_expr:
            if token=='(':
                stack.append(token)
            elif token==')':
                # 弹出直到 '('
                while stack and stack[-1] !='(':
                    output.append(stack.pop())
                if not stack:
                    raise ValueError("括号不匹配：缺少 '('")
                stack.pop() # 弹出 '('
            elif token in prec:
                # 根据优先级和结合性决定是否弹栈
                while stack and stack[-1] != "(" and ( 
                    (assoc[token]=='left' and prec[token]<=prec.get(stack[-1],0)) or
                    (assoc[token]=='right' and prec[token]<prec.get(stack[-1],0)) 
                ):
                    output.append(stack.pop())
                stack.append(token)
            else:
                #剩下的是操作数
                output.append(token)
        #剩下的操作符
        while stack:
            op=stack.pop()
            if op in ["(",")"]:
                raise ValueError("括号不匹配")
            output.append(op)

        postfix_expr=''.join(output)
        return postfix_expr
    
    def make_basic_nfa_fragment(self,nfa:NFA,char:str):
        # 生成新的基本的nfa片段（子nfa的内容）
        s=nfa.new_state()
        t=nfa.new_state()
        trans=defaultdict(lambda:defaultdict(set))
        trans[s][char].add(t)
        return (s,{t},trans)

    
    def postfix_to_nfa(self,postfix_expr):
        # 依据后缀式用 Thompson 规则构建 NFA
        nfa=NFA()
        stack=[] #放先后生成的nfa表[(s_old,ac_old,trans_old)]
        for token in postfix_expr:
            # 使用Thompson构造法
            if token=='*':
                #闭包运算
                s_old,ac_old,trans_old=stack.pop()
                s_new=nfa.new_state()
                t_new=nfa.new_state()
                trans=defaultdict(lambda: defaultdict(set))

                #先复制旧的
                for s,sy_sets in trans_old.items():
                    for sy,sets in sy_sets.items():
                        trans[s][sy].update(sets)
                # new start -> old start & new accept (空串)
                trans[s_new][EPS].add(s_old)
                trans[s_new][EPS].add(t_new)
                # old accepts -> old start (loop) and -> new accept
                for a in ac_old:
                    trans[a][EPS].add(s_old)
                    trans[a][EPS].add(t_new)
                stack.append((s_new),{t_new},trans)
            elif token=='.':
                # 连接运算
                s1,ac1,trans1=stack.pop()
                s2,ac2,trans2=stack.pop()
                trans=defaultdict(lambda: defaultdict(set))
                for s,sy_sets in trans1.items():
                    for sy,sets in sy_sets.items():
                        trans[s][sy].update(sets)
                for s,sy_sets in trans2.items():
                    for sy,sets in sy_sets.items():
                        trans[s][sy].update(sets)
                # 连接: accepts1 -> ε -> s2
                for a in ac1:
                    trans[a][EPS].add(s2)
                stack.append((s1,ac2,trans))
            elif token=='|':
                #或运算
                s1,ac1,trans1=stack.pop()
                s2,ac2,trans2=stack.pop()
                trans=defaultdict(lambda: defaultdict(set))
                s_new=nfa.new_state()
                t_new=nfa.new_state()
                for s,sy_sets in trans1.items():
                    for sy,sets in sy_sets.items():
                        trans[s][sy].update(sets)
                for s,sy_sets in trans2.items():
                    for sy,sets in sy_sets.items():
                        trans[s][sy].update(sets)
                # new start -> s1, s2
                trans[s_new][EPS].add(s1)
                trans[s_new][EPS].add(s2)
                # accepts -> new accept
                for a in ac1:
                    trans[a][EPS].add(t_new)
                for a in ac2:
                    trans[a][EPS].add(t_new)
                stack.append((s_new,{t_new},trans))
            else:
                #普通字符
                frag=self.make_basic_nfa_fragment(nfa,token)
                stack.append(frag)
        if len(stack)!=1:
            raise ValueError("后缀表达式错误：stack 最后大小 != 1,无法正确合并")
        start,accepts,trans=stack.pop()
        nfa.merge_nfa(start,accepts,trans)
        nfa.start=start
        nfa.accepts=accepts

        return nfa
    
    def test(self,code:int):
        #测试代码
        if code==1:
            #测试添加连接符是否正确
            examples = ["ab", "a(b|c)", "(a|b)*abb", "a*b", "a(b)c"]
            for e in examples:
                print(e, "->", self.add_concatenation_operator(e))
        elif code==2:
            #测试后缀表达式是否正确
            examples = ["ab", "a(b|c)", "(a|b)*abb", "a*b", "a(b)c"]
            for e in examples:
                pos=self.add_concatenation_operator(e)
                print(self.add_concatenation_operator(e),"的后缀表达式是：")
                print(self.convert_postfix_expr(pos))

            



    

if __name__=="__main__":
    regex=RegexToNFAConverter("aa*|bb*")
    regex.test(2)




