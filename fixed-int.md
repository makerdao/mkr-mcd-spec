```k
module FIXED-INT
    imports INT
    imports BOOL

    syntax FInt ::= "(" FInt ")"                   [bracket]
                  | FInt ( value: Int , one: Int ) [klabel(FInt), symbol]
 // ---------------------------------------------------------------------

    // Operations always produce the width of the left integer.
    syntax FInt ::= FInt "*FInt" FInt [function]
                  | FInt "/FInt" FInt [function]
                  | FInt "^FInt"  Int [function]
                  > FInt "+FInt" FInt [function]
                  | FInt "-FInt" FInt [function]
 // --------------------------------------------
    rule FInt(VALUE1, ONE1) *FInt FInt(VALUE2, ONE2) => FInt((VALUE1 *Int VALUE2) /Int ONE2, ONE1)
    rule FInt(VALUE1, ONE1) /FInt FInt(VALUE2, ONE2) => FInt((VALUE1 *Int ONE2) /Int VALUE2, ONE1) requires VALUE2 =/=Int 0
    rule FInt(VALUE1, ONE1) ^FInt E            => FInt(VALUE1 ^Int E, ONE1)
    rule FInt(VALUE1, ONE1) +FInt FInt(VALUE2, ONE2) => FInt(VALUE1 +Int ((VALUE2 *Int ONE1) /Int ONE2), ONE1)
    rule FInt(VALUE1, ONE1) -FInt FInt(VALUE2, ONE2) => FInt(VALUE1 -Int ((VALUE2 *Int ONE1) /Int ONE2), ONE1)

    syntax Bool ::= FInt   "<FInt" FInt [function]
                  | FInt  "<=FInt" FInt [function]
                  | FInt   ">FInt" FInt [function]
                  | FInt  ">=FInt" FInt [function]
                  | FInt  "==FInt" FInt [function]
                  | FInt "=/=FInt" FInt [function]
 // ----------------------------------------------
    rule FInt(VALUE1, ONE1)   <FInt FInt(VALUE2, ONE2) => VALUE1 *Int ONE2   <Int VALUE2 *Int ONE1
    rule FInt(VALUE1, ONE1)  <=FInt FInt(VALUE2, ONE2) => VALUE1 *Int ONE2  <=Int VALUE2 *Int ONE1
    rule FInt(VALUE1, ONE1)   >FInt FInt(VALUE2, ONE2) => VALUE1 *Int ONE2   >Int VALUE2 *Int ONE1
    rule FInt(VALUE1, ONE1)  >=FInt FInt(VALUE2, ONE2) => VALUE1 *Int ONE2  >=Int VALUE2 *Int ONE1
    rule FInt(VALUE1, ONE1)  ==FInt FInt(VALUE2, ONE2) => VALUE1 *Int ONE2  ==Int VALUE2 *Int ONE1
    rule FInt(VALUE1, ONE1) =/=FInt FInt(VALUE2, ONE2) => VALUE1 *Int ONE2 =/=Int VALUE2 *Int ONE1

    syntax Int ::=    baseFInt ( FInt ) [function]
                 | decimalFInt ( FInt ) [function]
 // ----------------------------------------------
    rule    baseFInt(FI) => value(FI) /Int one(FI)
    rule decimalFInt(FI) => value(FI) %Int one(FI)
endmodule
```
