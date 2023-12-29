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
}
