# coding: utf-8

#词法分析-基本表达转NFA
#输⼊：正规表达式和多个测试字符串。
#输出：⽣成的NFA状态集合及其转换关系，指明每个测试字符串是否被NFA接受。

#将正则表达式转换为NFA的主要转换器
class RegexToNFAConverter:
    def __init__(self,regex):
        #regex为正规表达式
        #输入的表达式字符串插入显式的连接运算符'.'
        self.regex=self.add_concatenation_operator(regex)
        #将中缀表达式转换为后缀表达式
        self.postfix_expr=self.convert_postfix_expr(self.regex)

    def add_concatenation_operator(self,regex):
        result=''
        for i in range(len(regex)-1):
            #当前字符是),*,原子，而下一个字符是(或原子时，在当前字符后加入.表示连接运算
            if regex[i] not in ["(","|"] and regex[i+1] not in [")","|","*"]:
                result=result+regex[i]+"."
            else:
                result=result+regex[i]
        
        return result+regex[-1]
    
    def convert_postfix_expr(self,infix_expr):
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
    
    #测试代码
    def test(self,code):
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




