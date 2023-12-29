//
//  File.swift
//  
//
//  Created by Collin Palmer on 12/29/23.
//

import Foundation

indirect enum AST: Equatable, CustomStringConvertible {
    case node(tag: String, nodes: [AST])
    
    var description: String {
        switch self {
        case .node(let tag, let nodes):
            return "\(tag)\n" + nodes.map({ "\t" + $0.description }).joined()
        }
    }
}

// TODO: Is default Equatable conformance correct?
struct PrefixResult: Equatable {
    let remainder: String?
    let node: AST?
    
    static let lambda = PrefixResult(remainder: nil, node: nil)
}

typealias ASTPrefixAutomata = (String?) -> PrefixResult

func A(_ auto: @escaping PrefixAutomata, _ node: AST) -> ASTPrefixAutomata {
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

// Prefix > AST
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

func >(_ ast: @escaping ASTPrefixAutomata, _ auto: @escaping PrefixAutomata) -> ASTPrefixAutomata {
    return { input in
        if ast(input) != PrefixResult.lambda {
            let result = ast(input)
            return PrefixResult(remainder: auto(result.remainder), node: result.node)
        }
        
        return PrefixResult.lambda
    }
}

func >(_ a1: @escaping ASTPrefixAutomata, _ a2: @escaping ASTPrefixAutomata) -> ASTPrefixAutomata {
    return { input in
        print("ASTPrefix composition")
        if a1(input) != PrefixResult.lambda {
            let a1Result = a1(input)
            // Make a1's result a child of a2
            let a2Result = a2(a1Result.remainder)
            
            print("Composing ast")
            if case .node(let a2Tag, let a2Nodes) = a2Result.node {
                var combinedNodes = a2Nodes
                if let a1Node = a1Result.node {
                    combinedNodes.append(a1Node)
                }
                
                print("Combined nodes: \(combinedNodes)")
                
                let composedNode: AST = .node(tag: a2Tag, nodes: combinedNodes)
                return PrefixResult(remainder: a2Result.remainder, node: composedNode)
            }
        }
        
        return PrefixResult.lambda
    }
}