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
}
