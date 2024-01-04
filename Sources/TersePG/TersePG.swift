typealias PrefixAutomata = (String?) -> String?

postfix operator *
postfix operator +
infix operator |: AdditionPrecedence
infix operator >: MultiplicationPrecedence

func P(_ char: Character) -> PrefixAutomata {
    { input in
        guard let input else {
            return nil
        }
        
        if input.isEmpty {
            return nil
        }
        
        if input.first == char {
            return String(input.suffix(input.count-1))
        }
        
        return nil
    }
}

func R(_ body: @escaping (@escaping PrefixAutomata, String?) -> String?) -> PrefixAutomata {
    var f: PrefixAutomata!
    f = { (input: String?) in
        body(f, input)
    }
    
    return f
}

postfix func *(_ auto: @escaping PrefixAutomata) -> PrefixAutomata {
    { input in
        guard let input else {
            return nil
        }
        
        var result: String? = input
        while (auto(result) != nil) {
            result = auto(result)
        }
        
        return result
    }
}

postfix func +(_ auto: @escaping PrefixAutomata) -> PrefixAutomata {
    { input in
        guard let input else {
            return nil
        }
        
        var result: String? = auto(input)
        while (auto(result) != nil) {
            result = auto(result)
        }
        
        return result
    }
}

func |(_ a1: @escaping PrefixAutomata, _ a2: @escaping PrefixAutomata) -> PrefixAutomata {
    { input in
        guard let input else {
            return nil
        }
        
        return a1(input) ?? a2(input)
    }
}

// Compose a2(a1(s))
func >(_ a1: @escaping PrefixAutomata, _ a2: @escaping PrefixAutomata) -> PrefixAutomata {
    { input in
        guard let input else {
            return nil
        }
        
        guard let a1Result = a1(input) else {
            return nil
        }
        
        return a2(a1Result)
    }
}
