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
        let ProductionRule = BNFNode(label: "ProductionRule", children: [])
        let AssignmentRule = BNFNode(label: "AssignmentRule", children: [])
        let QuantifiedRule = BNFNode(label: "QuantifiedRule", children: [])
        let Rule = BNFNode(label: "Rule", children: [])
        let Stop = BNFNode(label: "Stop", children: [])
        
        let BNFProduction = BNF(P("P"), ProductionRule)
        let BNFAssignment = BNF(P("A"), AssignmentRule)
        let BNFQuantRule = BNF(P("Q"), QuantifiedRule)
        let BNFRule = BNF(P("R"), Rule)
        let BNFStop = BNF(P("S"), Stop)
        
        // WIP: Handle quantifiers correctly
        let rule = bnfRule((BNFQuantRule|BNFRule), "BNFRule")+
        let bnf = bnfRule(
            (BNFProduction > BNFAssignment > rule > BNFStop)*,
            "BNF"
        )
        print(bnf.node)
    }
    
    func testBNFOr() throws {
        let a = BNF(P("A"), BNFNode(label: "A", children: []))
        let b = BNF(P("B"), BNFNode(label: "B", children: []))
        let c = BNF(P("C"), BNFNode(label: "C", children: []))
        
        XCTAssert(((a|b)|c).node.description == "A|B|C")
    }
    
    func testBNFQuantifier() throws {
        let a = BNF(P("A"), BNFNode(label: "A", children: []))
        let b = BNF(P("B"), BNFNode(label: "B", children: []))
        
        XCTAssert((a+).node.description == "A+")
        XCTAssert((((a|b)+).node).description == "(A|B)+")
    }
}
