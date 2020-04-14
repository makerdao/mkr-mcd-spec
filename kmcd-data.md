KMCD Data
=========

This module defines base data-types needed for the KMCD system.

```k
requires "rat.k"

module KMCD-DATA
    imports BOOL
    imports INT
    imports RAT
    imports MAP
```

Precision Quantities
--------------------

We model everything with arbitrary precision rationals, but use sort information to indicate the EVM code precision.

-   `Wad`: basic quantities (e.g. balances). Represented in implementation as 1e18 fixed point.
-   `Ray`: precise quantities (e.g. ratios). Represented in implementation as 1e27 fixed point.
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision). Represented in implementation as 1e45 fixed point.

```k
    syntax Wad = Rat
 // ----------------

    syntax Ray = Rat
 // ----------------

    syntax Rad = Rat
 // ----------------

    syntax MaybeWad ::= Wad | ".Wad"
 // --------------------------------
```

```k
    syntax Wad ::= "0Wad" | "1Wad"
 // ------------------------------
    rule 0Wad => 0 [macro]
    rule 1Wad => 1 [macro]

    syntax Ray ::= "0Ray" | "1Ray"
 // ------------------------------
    rule 0Ray => 0 [macro]
    rule 1Ray => 1 [macro]

    syntax Rad ::= "0Rad" | "1Rad"
 // ------------------------------
    rule 0Rad => 0 [macro]
    rule 1Rad => 1 [macro]
```

```k
    syntax Ray ::= Wad2Ray ( Wad ) [function]
 // -----------------------------------------
    rule Wad2Ray(W) => W

    syntax Rad ::= Wad2Rad ( Wad ) [function]
                 | Ray2Rad ( Ray ) [function]
 // -----------------------------------------
    rule Wad2Rad(W) => W
    rule Ray2Rad(R) => R
```

```k
    syntax Wad ::= Wad "*Wad" Wad [function]
                 | Wad "/Wad" Wad [function]
                 | Wad "^Wad" Int [function]
                 > Wad "+Wad" Wad [function]
                 | Wad "-Wad" Wad [function]
 // ----------------------------------------
    rule R1 *Wad R2 => R1 *Rat R2
    rule R1 /Wad R2 => R1 /Rat R2
    rule R1 ^Wad R2 => R1 ^Rat R2
    rule R1 +Wad R2 => R1 +Rat R2
    rule R1 -Wad R2 => R1 -Rat R2

    syntax Ray ::= Ray "*Ray" Ray [function]
                 | Ray "/Ray" Ray [function]
                 | Ray "^Ray" Int [function]
                 > Ray "+Ray" Ray [function]
                 | Ray "-Ray" Ray [function]
 // ----------------------------------------
    rule R1 *Ray R2 => R1 *Rat R2
    rule R1 /Ray R2 => R1 /Rat R2
    rule R1 ^Ray R2 => R1 ^Rat R2
    rule R1 +Ray R2 => R1 +Rat R2
    rule R1 -Ray R2 => R1 -Rat R2

    syntax Rad ::= Rad "*Rad" Rad [function]
                 | Rad "/Rad" Rad [function]
                 | Rad "^Rad" Int [function]
                 > Rad "+Rad" Rad [function]
                 | Rad "-Rad" Rad [function]
 // ----------------------------------------
    rule R1 *Rad R2 => R1 *Rat R2
    rule R1 /Rad R2 => R1 /Rat R2
    rule R1 ^Rad R2 => R1 ^Rat R2
    rule R1 +Rad R2 => R1 +Rat R2
    rule R1 -Rad R2 => R1 -Rat R2
```

```k
    syntax Bool ::= Wad  "<=Wad" Wad [function]
                  | Wad   "<Wad" Wad [function]
                  | Wad  ">=Wad" Wad [function]
                  | Wad   ">Wad" Wad [function]
                  | Wad  "==Wad" Wad [function]
                  | Wad "=/=Wad" Wad [function]
 // -------------------------------------------
    rule W1  <=Wad W2 => W1  <=Rat W2
    rule W1   <Wad W2 => W1   <Rat W2
    rule W1  >=Wad W2 => W1  >=Rat W2
    rule W1   >Wad W2 => W1   >Rat W2
    rule W1  ==Wad W2 => W1  ==Rat W2
    rule W1 =/=Wad W2 => W1 =/=Rat W2

    syntax Bool ::= Ray  "<=Ray" Ray [function]
                  | Ray   "<Ray" Ray [function]
                  | Ray  ">=Ray" Ray [function]
                  | Ray   ">Ray" Ray [function]
                  | Ray  "==Ray" Ray [function]
                  | Ray "=/=Ray" Ray [function]
 // -------------------------------------------
    rule W1  <=Ray W2 => W1  <=Rat W2
    rule W1   <Ray W2 => W1   <Rat W2
    rule W1  >=Ray W2 => W1  >=Rat W2
    rule W1   >Ray W2 => W1   >Rat W2
    rule W1  ==Ray W2 => W1  ==Rat W2
    rule W1 =/=Ray W2 => W1 =/=Rat W2

    syntax Bool ::= Rad  "<=Rad" Rad [function]
                  | Rad   "<Rad" Rad [function]
                  | Rad  ">=Rad" Rad [function]
                  | Rad   ">Rad" Rad [function]
                  | Rad  "==Rad" Rad [function]
                  | Rad "=/=Rad" Rad [function]
 // -------------------------------------------
    rule W1  <=Rad W2 => W1  <=Rat W2
    rule W1   <Rad W2 => W1   <Rat W2
    rule W1  >=Rad W2 => W1  >=Rat W2
    rule W1   >Rad W2 => W1   >Rat W2
    rule W1  ==Rad W2 => W1  ==Rat W2
    rule W1 =/=Rad W2 => W1 =/=Rat W2
```

```k
    syntax Rad ::= Wad "*Rate" Ray [function]
 // -----------------------------------------
    rule R1 *Rate R2 => R1 *Rat R2
```

Time Increments
---------------

Some methods rely on a timestamp.
We simulate that here.

```k
    syntax priorities timeUnit > _+Int_ _-Int_ _*Int_ _/Int_
 // --------------------------------------------------------

    syntax Int ::= Int "second"  [timeUnit]
                 | Int "seconds" [timeUnit]
                 | Int "minute"  [timeUnit]
                 | Int "minutes" [timeUnit]
                 | Int "hour"    [timeUnit]
                 | Int "hours"   [timeUnit]
                 | Int "day"     [timeUnit]
                 | Int "days"    [timeUnit]
 // ---------------------------------------
    rule 1 second  => 1                    [macro]
    rule N seconds => N                    [macro]
    rule 1 minute  =>        60    seconds [macro]
    rule N minutes => N *Int 60    seconds [macro]
    rule 1 hour    =>        3600  seconds [macro]
    rule N hours   => N *Int 3600  seconds [macro]
    rule 1 day     =>        86400 seconds [macro]
    rule N days    => N *Int 86400 seconds [macro]
```

Collateral Increments
---------------------

```k
    syntax priorities collateralUnit > _+Int_ _-Int_ _*Int_ _/Int_
 // --------------------------------------------------------------

    syntax Int ::= Int "ether" [collateralUnit]
 // -------------------------------------------
    rule N ether => N *Int 1000000000 [macro]
```

```k
endmodule
```

