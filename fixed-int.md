Fixed Point Integers
====================

This module implements fixed point integers in K.
Once it stabalizes, it should be upstreamed into the K Prelude.

```k
module FIXED-INT
    imports INT
    imports BOOL
```

Constructors
------------

Fixed point numbers will be represented as a tuple of their integer value and their one-point.
Projections are provided for the `value`, the `one`, the `base`, and the `decimal`.

```k
    syntax FInt ::= "(" FInt ")"                   [bracket]
                  | FInt ( value: Int , one: Int ) [klabel(FInt), symbol]
 // ---------------------------------------------------------------------

    syntax Int ::=    baseFInt ( FInt ) [function]
                 | decimalFInt ( FInt ) [function]
 // ----------------------------------------------
    rule    baseFInt(FI) => value(FI) /Int one(FI)
    rule decimalFInt(FI) => value(FI) %Int one(FI)
```

These macros allow quickly constructing (and pattern-matching on) fixed-point integers of value `0` and `1`.

```k
    syntax FInt ::= "0FInt" "(" Int ")" | "1FInt" "(" Int ")"
 // ---------------------------------------------------------
    rule 0FInt(ONE) => FInt(0  , ONE) [macro]
    rule 1FInt(ONE) => FInt(ONE, ONE) [macro]
```

Arithmetic
----------

Basic arithmetic operators are provided for the `FInt` sort.
In all cases, the returned integers will be in the width of the first operand.

```k
    syntax FInt ::= FInt "*FInt" FInt [function]
                  | FInt "/FInt" FInt [function]
                  | FInt "^FInt"  Int [function]
                  > FInt "+FInt" FInt [function]
                  | FInt "-FInt" FInt [function]
 // --------------------------------------------
    rule FInt(VALUE1, ONE1) *FInt FInt(VALUE2, ONE2) => FInt((VALUE1 *Int VALUE2) /Int ONE2             , ONE1)
    rule FInt(VALUE1, ONE1) /FInt FInt(VALUE2, ONE2) => FInt((VALUE1 *Int ONE2) /Int VALUE2             , ONE1) requires VALUE2 =/=Int 0
    rule FInt(VALUE1, ONE1) +FInt FInt(VALUE2, ONE2) => FInt(VALUE1 +Int ((VALUE2 *Int ONE1) /Int ONE2) , ONE1)
    rule FInt(VALUE1, ONE1) -FInt FInt(VALUE2, ONE2) => FInt(VALUE1 -Int ((VALUE2 *Int ONE1) /Int ONE2) , ONE1)

    rule FInt( VALUE, ONE) ^FInt E => FInt((VALUE ^Int E) /Int (ONE ^Int (E -Int 1)), ONE)          requires E  >Int 0
    rule FInt(_VALUE, ONE) ^FInt E => 1FInt(ONE)                                                    requires E ==Int 0
    rule FInt( VALUE, ONE) ^FInt E => FInt((ONE ^Int (1 -Int E)) /Int (VALUE ^Int (0 -Int E)), ONE) requires E  <Int 0
```

Comparisons
-----------

Comparisons are also provided for the `FInt` sort.
`FInt`s are compared regardless of their widths, they are scaled to the same width and compared there.
This makes it possible to compare integers of different widths based on the rational they represent, not their fixed-point representation.

```k
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
```

```k
endmodule
```
