```k
module FIXED-INT
    imports INT
    imports BOOL

    syntax FInt ::= "(" FInt ")"                   [bracket]
                  | FInt ( value: Int , one: Int ) [klabel(FInt), symbol]
 // ---------------------------------------------------------------------
    rule #Ceil(FInt(... value: V, one: O)) => { V >=Int 0 andBool O >Int 0 #Equals true } [anywhere]

    // Operations always produce the width of the left integer.
    syntax FInt ::= FInt "*FInt" FInt [function]
                  | FInt "/FInt" FInt [function]
                  | FInt "^FInt"  Int [function]
                  > FInt "+FInt" FInt [function]
                  | FInt "-FInt" FInt [function]
 // --------------------------------------------
    rule FInt(V1, O1) *FInt FInt(V2, O2) => FInt((V1 *Int V2) /Int O2, O1)
    rule FInt(V1, O1) /FInt FInt(V2, O2) => FInt((V1 *Int O2) /Int V2, O1) requires V2 =/=Int 0
    rule FInt(V1, O1) ^FInt E            => FInt(V1 ^Int E, O1)
    rule FInt(V1, O1) +FInt FInt(V2, O2) => FInt(V1 +Int ((V2 *Int O1) /Int O2), O1)
    rule FInt(V1, O1) -FInt FInt(V2, O2) => FInt(V1 -Int ((V2 *Int O1) /Int O2), O1)

    syntax Bool ::= FInt   "<FInt" FInt [function]
                  | FInt  "<=FInt" FInt [function]
                  | FInt   ">FInt" FInt [function]
                  | FInt  ">=FInt" FInt [function]
                  | FInt  "==FInt" FInt [function]
                  | FInt "=/=FInt" FInt [function]
 // ----------------------------------------------
    rule FInt(V1, O1)   <FInt FInt(V2, O2) => V1 *Int O2   <Int V2 *Int O1
    rule FInt(V1, O1)  <=FInt FInt(V2, O2) => V1 *Int O2  <=Int V2 *Int O1
    rule FInt(V1, O1)   >FInt FInt(V2, O2) => V1 *Int O2   >Int V2 *Int O1
    rule FInt(V1, O1)  >=FInt FInt(V2, O2) => V1 *Int O2  >=Int V2 *Int O1
    rule FInt(V1, O1)  ==FInt FInt(V2, O2) => V1 *Int O2  ==Int V2 *Int O1
    rule FInt(V1, O1) =/=FInt FInt(V2, O2) => V1 *Int O2 =/=Int V2 *Int O1

    syntax Int ::=    baseFInt ( FInt ) [function]
                 | decimalFInt ( FInt ) [function]
 // ----------------------------------------------
    rule    baseFInt(FI) => value(FI) /Int one(FI)
    rule decimalFInt(FI) => value(FI) %Int one(FI)
endmodule
```
