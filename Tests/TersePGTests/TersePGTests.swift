import XCTest
@testable import TersePG

postfix operator *
infix operator |: AdditionPrecedence
infix operator >: MultiplicationPrecedence

final class TersePGTests: XCTestCase {
    func testPartialJSONParse() throws {
        // TODO: On `nil`, return character of failure?
        // TODO: ? quantifier
        // TODO: Option to pass recursive matcher to subrules to shorten rule length
        // Json matcher
        let V = P("\"") > P("1")* > P("\"")
        //let K = R { r, input in (V > P(":") > V | V > P(":") > r)(input) }
        //let K = V > P(":") > V
        let K = R { r, input in (V > P(":") > V | V > P(":") > P("{") > r > P("}"))(input) }
        let JR = R { r, input in ((K > P(","))* > K)(input) }
        //let JR = R { r, input in (K | ((r > P(","))* > r))(input) }
        //let JR = R { r, input in (V > P(":") > V | V > P(":") > r | (r > P(","))* > r)(input) }
        let J = P("{") > JR > P("}")

        //V("\"1111\"")

        // Intentionally wrong
        XCTAssert(J(#"{"111":"a"}"#) == nil)
        // Correct json
        XCTAssert(J(#"{"111":"1"}"#)?.isEmpty ?? false)
        XCTAssert(J(#"{"111":"1","1":"1"}"#)?.isEmpty ?? false)
        XCTAssert(J(#"{"111":"1","1":{"11":"1"}}"#)?.isEmpty ?? false)
    }
    
    func testNestedListParse() throws {
        let digit = P("1")
        let L = R { r, input in (digit|(((P("[") > ((r>P(","))*)) > r) > P("]")))(input) }

        XCTAssert(L("[1,[1,[1],[1]]]")?.isEmpty ?? false)
    }
    
    func testRecursiveASTParse() throws {
        let ListNode: AST = .node(tag: "List", nodes: [])
        // TODO: Make available elsewhere
        // Note: this is a possible approach to 'result builders'..?
        typealias RecursiveProduction = (@escaping ASTPrefixAutomata) -> ASTPrefixAutomata
        
        // Should remove operator ambiguity..
        let nestedParenRule: RecursiveProduction = { r in
            // What to do about ambiguous operators?
            // Presumably dispatches to the wrong method since r is quite happy
            // to execute on String?.. (happened before..)
            A(P("["), nil) > r > A(P("]"), nil)
        }
        // Problem: wrong function being resolved..?
        let l2 = AR(ListNode) { (r: @escaping ASTPrefixAutomata, input: String?) -> ASTPrefixAutomata in
            nestedParenRule(r) | A(P("[") > P("]"), ListNode)
        }
        
        //let l2 = AR(ListNode) { r, input in (P("[") > r) > P("]") }
        print("Remainder: \(l2("[[[]]]").remainder)")
        print("Nested list: \(l2("[[[]]]").node)")
    }
    
    func testASTCompositionOperatorLeftEmpty() throws {
        let ListNode: AST = .node(tag: "List", nodes: [])
        let ast = A(P("["), nil) > A(P("]"), ListNode)
        
        XCTAssert(ast("[]").node != nil)
        
        if case .node(let tag, _) = ast("[]]").node {
            XCTAssert(tag == "List")
            return
        }
        
        XCTFail()
    }
    
    func testASTCompositionOperatorRightEmpty() throws {
        let ListNode: AST = .node(tag: "List", nodes: [])
        let ast = A(P("["), ListNode) > A(P("]"), nil)
        
        XCTAssert(ast("[]").node != nil)
        
        if case .node(let tag, _) = ast("[]]").node {
            XCTAssert(tag == "List")
            return
        }
        
        XCTFail()
    }
    
    // Verify the correct tree is built
    func testASTCompositionChildNode() throws {
        // Next, test on recursive tree
        let ListNode: AST = .node(tag: "List", nodes: [])
        let submatcher = A(P("["), nil) > A(P("]"), ListNode)
        let matcher = A(P("["), nil) > submatcher > A(P("]"), ListNode)
        
        // TODO: Verify equality
        XCTAssert(matcher("[[]]").node == .node(tag: "List", nodes: [.node(tag: "List", nodes: [])]))
    }
    
    func testASTCompositionDeep() throws {
        let ListNode: AST = .node(tag: "List", nodes: [])
        let submatch = A(P("a"), ListNode)
        let m = submatch > submatch > submatch
        print(m("aaa").node!)
        
        /*
        XCTAssert(m("aaa").node == .node(tag: "List", nodes: [.node(tag: "List", nodes: [.node(tag: "List", nodes: [])])]))
        */
        
        // TODO: Did I implement printing wrong..?
        let t1: AST = .node(tag: "List", nodes: [.node(tag: "List", nodes: [.node(tag: "Terminal", nodes: [])])])
        print(t1)
        
        let r = m("aaa")
        if case .node(let tag, let nodes) = r.node {
            if case .node(let tag, let nodes2) = nodes.first {
                if case .node(let tag, let _) = nodes2.first {
                    return
                }
            }
        }
        
        
        XCTFail()
    }
    
    func testRecursiveASTComposition() throws {
        let ListNode: AST = .node(tag: "List", nodes: [])
        let RootNode: AST = .node(tag: "Root", nodes: [])
        // TODO: Can r be wrapped with the required node..?
        // TODO: See how AR modifies the AST
        // Try a different node for terminals
        // So: why is the leaf not a child?
        let LeafNode: AST = .node(tag: "Leaf", nodes: [])
        let matcher = AR(ListNode) { r, input in
            (A(P("["), nil) > A(P("]"), LeafNode))
            | (A(P("["), nil) > r > A(P("]"), ListNode))
        }
        
        // Problem: top-level list is missing..? (Still, closer)
        // TODO: Try ast quantifier
        print(matcher("[[[[]]]]").node!)
        
        // IMO: For recursive, why does a node need provided?
        // TODO: Use RootNode to help figure things out
        // WIP: Trees of any form
        let m1 = AR(ListNode) { r, input in ((A(P("["), nil) > r > A(P("]"), ListNode))*)(RootNode) }
        print(m1("[][[[][]]]").node ?? "n/a")
    }
    
    func testNumberTreeMatcher() throws {
        // TODO: Verify precedence
        /*
        let digit = P("0")|P("1")|P("2")|P("3")|P("4")|P("5")|P("6")|P("7")|P("8")|P("9")
        //let list = R { r, input in ((digit*) | (P("[") > r > P("]")) | (r > P(",") > r))(input) }
        let list = R { r, input in ((P("[") > r > P("]")) | ((r > P(","))* > r) | digit*)(input) }
        let root = (P("[") > list) > P("]")
        
        print(root("[11,1]"))
         */
        
        //let root = R { r, input in (P("[") > r > P("]") | P("1"))(input) }
        let digit = P("0")|P("1")|P("2")|P("3")|P("4")|P("5")|P("6")|P("7")|P("8")|P("9")
        // TODO: Try to replace iteration with `r > P > r`, see if it works / terminates
        // TODO: Cleanup (w/out parens) and add to readme
        // Problem: making digit -> digit* short-circuits parser..
        let L = R { r, input in ((digit)|(((P("[") > ((r>P(","))*)) > r) > P("]")))(input) }
        print(L("[[2],[2,[3,4]]]"))
        
        // Drop parens, see if it still matches:
        // (If it doesn't, then clearly operator precedence is wrong)
        //let L2 = R { r, input in (digit* | (((P("[") > ((r>P(","))*)) > r) > P("]")))(input) }
        let L2 = R { r, input in (digit+ | P("[") > (r>P(","))* > r > P("]"))(input) }
        print(L2("[[122],[2,[3,4]]]"))
        //print(root("[[1]]"))
    }
    
    /// Parse a very simple lexed form of BNF, encoded into characters
    func testBNFMatcher() throws {
        /**
         Think in terms of the following encoding performed by a lexer:
         
         ProductionRule = "P"
         AssignmentSymbol = "A"
         QuantifiedRule = "Q"
         Rule = "R"
         Stop = "S"
         
         If a list of production rules is allowed it can be encoded as:
         (P A (Q|R)+ S)*
         */
        let matcher = (P("P") > P("A") > (P("Q")|P("R"))+ > P("S"))*
        XCTAssert(matcher("PARQSPARS")?.isEmpty ?? false)
    }
}
