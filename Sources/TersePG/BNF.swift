//
//  File.swift
//  
//
//  Created by Collin Palmer on 1/5/24.
//

import Foundation

infix operator >


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

// TODO: Handling label..?
func >(_ b1: BNFResult, _ b2: BNFResult) -> BNFResult {
    // Perform wrapped composition, return
    let node = BNFNode(label: "N", children: [b1.node, b2.node])
    return BNFResult(auto: b1.auto > b2.auto, node: node)
}


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

func traverse(_ node: BNFNode) -> String {
    let subt = subtrees(node)
    var result = ""

    if subt.isEmpty == false {
        result += "\(node.label) -> \(subt.map({$0.label}).joined(separator: " "))\n"
    }
    
    for tree in subt {
        result += traverse(tree)
    }
    
    return result
}

extension BNFNode: CustomStringConvertible {
    var description: String {
        traverse(self)
    }
}
