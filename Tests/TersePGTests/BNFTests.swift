//
//  BNFTests.swift
//  
//
//  Created by Collin Palmer on 1/5/24.
//

import XCTest
@testable import TersePG

infix operator >: MultiplicationPrecedence
infix operator |

final class BNFTests: XCTestCase {
    func testBNFConstruction() throws {
        // TODO: Distinguish betw. terminal and root nodes?
        // TODO: Implement string convertible
        let aNode = BNFNode(label: "A", children: [])
        let bNode = BNFNode(label: "B", children: [])
        
        let xNode = BNFNode(label: "X", children: [])
        let yNode = BNFNode(label: "Y", children: [])
        
        // Instead of this, assign a new label to the composition
        let nestedRule = bnfRule(BNF(P("X"), xNode) > BNF(P("Y"), yNode), "Subrule")
        // Problem: associating w/ top level production rule?
        let bnf = bnfRule((BNF(P("A"), aNode) > nestedRule > BNF(P("B"), bNode)), "TestRule")
        
        print(traverse(bnf.node))
    }
    
    func testBNFBNF() throws {
        let ProductionRule = BNFNode(label: "\"P\"", children: [])
        let AssignmentRule = BNFNode(label: "\"A\"", children: [])
        let QuantifiedRule = BNFNode(label: "\"Q\"", children: [])
        let Rule = BNFNode(label: "\"R\"", children: [])
        let Stop = BNFNode(label: "\"S\"", children: [])
        
        let BNFProduction = container(BNF(P("P"), ProductionRule), "ProductionRule")
        let BNFAssignment = container(BNF(P("A"), AssignmentRule), "AssignmentRule")
        let BNFQuantRule = container(BNF(P("Q"), QuantifiedRule), "QuantifiedRule")
        let BNFRule = container(BNF(P("R"), Rule), "Rule")
        let BNFStop = container(BNF(P("S"), Stop), "Stop")
        
        let rule = container(BNFQuantRule|BNFRule, "BNFRule")
        let bnf = container(
            (BNFProduction > BNFAssignment > rule+ > BNFStop)*,
            "BNF"
        )
        
        let expectedMessage = """
        BNF -> (ProductionRule AssignmentRule (BNFRule)+ Stop)*
        ProductionRule -> "P"
        AssignmentRule -> "A"
        BNFRule -> QuantifiedRule|Rule
        QuantifiedRule -> "Q"
        Rule -> "R"
        Stop -> "S"
        """
        
        XCTAssert(bnf.node.description == expectedMessage, bnf.node.description)
    }
    
    func testBNFGeneration() throws {
        let a = BNF(P("A"), BNFNode(label: "A", children: []))
        let b = BNF(P("B"), BNFNode(label: "B", children: []))
        let c = BNF(P("C"), BNFNode(label: "C", children: []))
        
        let subtree = container((a|(b|c)), "Subtree")
        
        let root = container((subtree* > b > c), "RootProduction")
        
        let expectedMessage = """
        RootProduction -> (Subtree)* B C
        Subtree -> A|B|C
        """
        
        XCTAssert(root.node.description == expectedMessage)
    }
}
