This package is an experimental parser generator, implemented using
'extended' regex derivatives.

A regex derivative in this package:

```swift
P("abc")("abc") = "a"
```

## Derivative operators

### Composition

Composition of the form `P1 > P2` takes the result of `P1` and feeds it into `P2`.

```swift
(P("a") > P("b"))("ab") == ""
```

### Quantifiers

Typical regex quantifiers:

```swift
(P("a")+)("aaab") == "b"
(P("a")*)("aa") == ""
(P("a")~)("xyz") == "xyz"
```

### Alternation

Same operation as regex:

```swift
(P("a")|P("b"))("b") == ""
```

### Recursion

This operator provides the extra power necessary for parsing CFGs. 

```swift
R { r, input in P("[") > r > P("]") }
```

The above will parse any nested list such as `"[[[]]]"`.

### Constructing and composing parsers: an example

TODO
