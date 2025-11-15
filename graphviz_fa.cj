import std.process.*
import std.core.*
import std.collection.*
import std.fs.*

//把 NFA 或 DFA 画成 PNG 
public class Visualizer {
    var outDir: String= "."
    public init(outDir: String ) {
        this.outDir = outDir
    }

    //公开接口：NFA 转 PNG 
    public func drawNFA(nfa: NFA, name: String): String {
        let dot = buildDot(nfa.start, nfa.accepts, nfa.transitions, true)
        return render(dot, name)
    }

    // 公开接口：DFA 转 PNG 
    public func drawDFA(start:  Int64,
                        accepts: HashSet<Int64>,
                        trans:   HashMap<Int64, HashMap<String, Int64>>,
                        name: String): String {
        // 把 DFA 的“单个下一状态”包装成 HashSet 复用 buildDot 
        let nfaLike = HashMap<Int64, HashMap<String, HashSet<Int64>>>()
        for ((s, m) in trans) {
            let inner = HashMap<String, HashSet<Int64>>()
            for ((sym, t) in m) {
                inner[sym] = HashSet([t])
            }
            nfaLike[s] = inner
        }
        let dot = buildDot(start, accepts, nfaLike, false)
        return render(dot, name)
    }

    //私有
    private func buildDot(start: Int64,
                          accepts: HashSet<Int64>,
                          trans: HashMap<Int64, HashMap<String, HashSet<Int64>>>,
                          nfaMode: Bool): String {
        let sb = StringBuilder()
        if(nfaMode) {
            sb.append("digraph NFA {\n")
        } else {
            sb.append("digraph DFA {\n")
        }
        sb.append("rankdir=LR;\n")
        sb.append("node [shape=circle];\n")

        // 起始状态：加隐形入口 
        sb.append("\"__start__\" [shape=none label=\"\"];\n")
        sb.append("\"__start__\" -> \"${start}\";\n")

        // 接受状态：双圈 
        for (a in accepts) {
            sb.append("\"${a}\" [shape=doublecircle];\n")
        }

        // 转移边 
        var label:String
        for ((s, symMap) in trans) {
            for ((sym, ts) in symMap) {
                for (t in ts) {
                    if(sym=="ε"){
                        label = "ε"
                    }else{
                        label = sym
                    }
                    sb.append("\"${s}\" -> \"${t}\" [label=\"${label}\"];\n")
                }
            }
        }
        sb.append("}\n")
        return sb.toString()
    }

    // 调用系统 dot 生成 PNG，返回文件路径 
    private func render(dot: String, name: String): String {
        let pngPath = "${this.outDir}/${name}.png"
        // let args: Array<String> = ["-Tpng", "-o", pngPath]
        // // 1. 创建Process实例
        // let proc = Process()
        // // 2. 分别设置可执行命令和参数
        // proc.executableURL = URL(fileURLWithPath: "dot") // 或 "dot.exe"
        // proc.arguments = ["-Tpng", "-o", pngPath]
        // proc.redirectStdin(ProcessRedirect.PIPE)
        // try {
        //     proc.start()
        //     proc.stdin.write(dot.bytes)
        //     proc.stdin.flush()
        //     proc.stdin.close()
        //     let exit = proc.wait()
        //     if (exit != 0) {
        //         println("Warning: dot exited with (exit)")
        //     }
        // } catch (e: Exception) {
        //     println("Failed to launch dot, make sure Graphviz installed: (e)")
        // }
        return pngPath
    }

    private func generate_dot_file(dot: String, name: String): String {
        let dotPath = "${this.outDir}/${name}.dot"
        let pngPath = "${this.outDir}/${name}.png"
    
        // 1. 保存DOT文件
        try {
            let file = File.create(dotPath)
            file.write(dot.toArray())
        } catch (error: Exception){
            println("Failed to create DOT file: ${error}")
            return ""
        }
        return dotPath
    }
}
