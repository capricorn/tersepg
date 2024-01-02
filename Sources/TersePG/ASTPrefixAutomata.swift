//
//  File.swift
//  
//
//  Created by Collin Palmer on 12/29/23.
//

import Foundation

indirect enum AST: Equatable, CustomStringConvertible {
    case node(tag: String, nodes: [AST])
    
    private func treeDescription(_ depth: Int = 1) -> String  {
        let separator = (0..<depth).map({ _ in "\t" }).joined()
        switch self {
        case .node(let tag, let nodes):
            return "\(tag)\n" + nodes.map({ separator + $0.treeDescription(depth+1) }).joined()
        }
    }
    
    var description: String {
        treeDescription()
    }
}

// TODO: Is default Equatable conformance correct?
struct PrefixResult: Equatable {
    let remainder: String?
    let node: AST?
    
    static let lambda = PrefixResult(remainder: nil, node: nil)
}

typealias ASTPrefixAutomata = (String?) -> PrefixResult

func A(_ auto: @escaping PrefixAutomata, _ node: AST?) -> ASTPrefixAutomata {
    { input in
        if auto(input) != nil {
            return PrefixResult(remainder: auto(input), node: node)
        }
        
        return PrefixResult(remainder: nil, node: nil)
    }
}

func |(_ a1: @escaping ASTPrefixAutomata, _ a2: @escaping ASTPrefixAutomata) -> ASTPrefixAutomata {
    { input in
        guard let input else {
            return .lambda
        }
        
        if a1(input) == PrefixResult.lambda {
            return a2(input)
        } else {
            return a1(input)
        }
    }
}

postfix func *(_ auto: @escaping ASTPrefixAutomata) -> (AST) -> ASTPrefixAutomata {
    { ast in
        return { input in
            guard let input else {
                return PrefixResult.lambda
            }
            
            // TODO: Possible cleanup?
            // TODO: If there is no match, what should the AST be?
            var result: PrefixResult = PrefixResult(remainder: input, node: nil)
            var newAST: AST? = nil
            while (auto(result.remainder) != PrefixResult.lambda) {
                result = auto(result.remainder)
                // If the AST is defined, append each result as its child
                if case .node(let tag, let children) = newAST {
                    if let node = result.node {
                        var newChildren = children
                        newChildren.append(node)
                        //newChildren.append(contentsOf: children)
                        newAST = .node(tag: tag, nodes: newChildren)
                    }
                } else {
                    if case .node(tag: let tag, _) = ast {
                        if let node = result.node {
                            newAST = .node(tag: tag, nodes: [node])
                        }
                    }
                }
            }
            
            return .init(remainder: result.remainder, node: newAST)
        }
    }
}

// TODO: nil test for this
func >(_ a1: @escaping ASTPrefixAutomata, _ a2: @escaping ASTPrefixAutomata) -> ASTPrefixAutomata {
    print("ASTPrefix comp")
    return { input in
        guard a1(input) != PrefixResult.lambda else {
            return PrefixResult.lambda
        }
        
        guard a2(a1(input).remainder) != PrefixResult.lambda else {
            return PrefixResult.lambda
        }
        
        let result = a2(a1(input).remainder)
        guard let a1AST = a1(input).node, let a2AST = result.node else {
            // If both ast nodes do not exist, return the first that does
            return PrefixResult(remainder: result.remainder, node: a1(input).node ?? result.node)
        }
        
        if case .node(let a2Tag, let a2Nodes) = result.node {
            var combinedNodes = a2Nodes
            if let a1Node = a1(input).node {
                combinedNodes.append(a1Node)
            }
            
            let composedNode: AST = .node(tag: a2Tag, nodes: combinedNodes)
            return PrefixResult(remainder: result.remainder, node: composedNode)
        }
        
        return PrefixResult.lambda
    }
}

// Prefix > AST
/*
func >(_ auto: @escaping PrefixAutomata, ast: @escaping ASTPrefixAutomata) -> ASTPrefixAutomata {
    return { input in
        guard let input else {
            return PrefixResult.lambda
        }
        
        guard let autoResult = auto(input) else {
            return PrefixResult.lambda
        }
        
        return ast(autoResult)
    }
}
 */

/*
func >(_ ast: @escaping ASTPrefixAutomata, _ auto: @escaping PrefixAutomata) -> ASTPrefixAutomata {
    return { input in
        /*
        if ast(input) != PrefixResult.lambda {
            let result = ast(input)
            // TODO: Should this guard on failure?
            return PrefixResult(remainder: auto(result.remainder), node: result.node)
        }
        
        return PrefixResult.lambda
         */
        return PrefixResult(remainder: auto(ast(input).remainder), node: ast(input).node)
    }
}
*/

func AR(
    _ ast: AST,
    _ body: @escaping (@escaping ASTPrefixAutomata, String?) -> ASTPrefixAutomata
) -> ASTPrefixAutomata {
    var f: ASTPrefixAutomata!
    f = { (input: String?) in
        let result = body(f, input)(input)
        // Problem: AST is by reference..? need to create a new copy each iteration.
        var newAST = result.node//ast//result.node! //?? ast
        
        if case .node(let tag, let nodes) = ast, let childAST = result.node {
            var newNodes = nodes
            newNodes.append(childAST)
            newAST = .node(tag: tag, nodes: newNodes)
        }
        
        return PrefixResult(remainder: result.remainder, node: newAST)
    }
    
    return f
}
