//
//  File.swift
//  
//
//  Created by Collin Palmer on 1/5/24.
//

import Foundation

infix operator >
infix operator |
postfix operator +
postfix operator *


// First: make a wrapper that associates the AST with the PrefixAutomata

final class BNFNode {
    var label: String
    var children: [BNFNode]
    
    init(label: String, children: [BNFNode]) {
        self.label = label
        self.children = children
    }
}

struct BNFResult {
    let auto: PrefixAutomata
    let node: BNFNode
}

func BNF(_ auto: @escaping PrefixAutomata, _ node: BNFNode) -> BNFResult {
    BNFResult(auto: auto, node: node)
}

func bnfRule(_ bnf: BNFResult, _ label: String) -> BNFResult {
    //let node = BNFNode(label: label, children: [bnf.node])
    bnf.node.label = label
    return bnf
    //return BNFResult(auto: bnf.auto, node: bnf)
}

func container(_ bnf: BNFResult, _ label: String) -> BNFResult {
    let node = BNFNode(label: label, children: [bnf.node])
    return BNFResult(auto: bnf.auto, node: node)
}

// TODO: Handling label..?
func >(_ b1: BNFResult, _ b2: BNFResult) -> BNFResult {
    // Perform wrapped composition, return
    let node = BNFNode(label: "N", children: [b1.node, b2.node])
    return BNFResult(auto: b1.auto > b2.auto, node: node)
}

postfix func *(_ b: BNFResult) -> BNFResult {
    let node = BNFNode(label: "*", children: [b.node])
    return BNFResult(auto: (b.auto)*, node: node)
}

postfix func +(_ b: BNFResult) -> BNFResult {
    let node = BNFNode(label: "+", children: [b.node])
    return BNFResult(auto: (b.auto)+, node: node)
}

// TODO
func |(_ b1: BNFResult, _ b2: BNFResult) -> BNFResult {
    let node = BNFNode(label: "|", children: [b1.node,b2.node])
    
    return BNFResult(auto: b1.auto | b2.auto, node: node)
}



// TODO: Implement quantification operators


// TODO: Switch to binary tree type
func subtrees(_ root: BNFNode) -> [BNFNode] {
    var trees: [BNFNode] = []
    for child in root.children {
        if child.label == "N" {
            trees.append(contentsOf: subtrees(child))
        } else {
            trees.append(child)
        }
    }
    
    return trees
}

func traverse(_ root: BNFNode) -> String {
    traverse2(root).joined(separator: "\n")
}

func traverse2(_ root: BNFNode) -> [String] {
    // TODO: Only allow if root is a container (terminal)
    if root.children.isEmpty {
        return []
    }
    
    var output: [String] = []
    
    let result = subtree2(root.children[0])
    output.append("\(root.label) -> \(result.1)")
    
    for subtree in result.0 {
        output.append(contentsOf: traverse2(subtree))
        //output.append(contentsOf: traverse(subtree))
    }
    
    return output
}

/*
func traverse(_ node: BNFNode) -> String {
    let subt = subtrees(node)
    var result = ""
    
    if node.label == "|" {
        var orResults: [String] = []
        for st in subt {
            if st.label == "|" {
                orResults.append(traverse(st))
            } else {
                orResults.append(st.label)
            }
        }
        return orResults.joined(separator: "|")
    }
    
    if node.label == "+" || node.label == "*" {
        // Quantifiers only have a single subtree. So, take its subtrees.
        // Still has subtree of children (Must handle quantifiers)
        // TODO: Cleanup
        for st in subtrees(node.children[0]) {
            var nodes: [String] = []
            switch st.label {
            case "+","*","|":
                nodes.append(traverse(st))
            default:
                nodes.append(st.label)
            }
            return "(\(nodes.joined(separator: " ")))\(node.label)"
        }
        
        /*
        if subt[0].children.isEmpty {
            return "(\(subt[0].label))\(node.label)"
        } else {
            return "(\(traverse(subt[0])))\(node.label)"
        }
         */
    }

    if subt.isEmpty == false {
        var nodes: [String] = []
        for st in subt {
            switch st.label {
            case "+","*","|":
                nodes.append(traverse(st))
            default:
                nodes.append(st.label)
            }
        }
        //result += "\(node.label) -> \(subt.map({$0.label}).joined(separator: " "))\n"
        result += "\(node.label) -> \(nodes.joined(separator: " "))\n"
    }
    
    for tree in subt {
        // TODO: Adjust what is traversed here
        result += traverse(tree)
    }
    
    return result
}
 */

extension BNFNode: CustomStringConvertible {
    var description: String {
        traverse(self)
    }
}


func subtree2(_ root: BNFNode) -> ([BNFNode], String) {
    var nodes: [BNFNode] = []
    var str: String = ""
    
    if root.label == "+" || root.label == "*" {
        let result = subtree2(root.children[0])
        nodes = result.0
        str = "(\(result.1))\(root.label)"
    } else if root.label == "|" {
        let leftResult = subtree2(root.children[0])
        let rightResult = subtree2(root.children[1])
        nodes.append(contentsOf: leftResult.0)
        nodes.append(contentsOf: rightResult.0)
        str = "\(leftResult.1)|\(rightResult.1)"
    } else if root.label == "N" {
        let leftResult = subtree2(root.children[0])
        let rightResult = subtree2(root.children[1])
        nodes.append(contentsOf: leftResult.0)
        nodes.append(contentsOf: rightResult.0)
        str = "\(leftResult.1) \(rightResult.1)"
    } else {
        nodes = [root]
        str = root.label
    }
    
    return (nodes, str)
}
