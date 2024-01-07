//
//  BNFTests.swift
//  
//
//  Created by Collin Palmer on 1/5/24.
//

import XCTest
@testable import TersePG

infix operator >: MultiplicationPrecedence

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
}
