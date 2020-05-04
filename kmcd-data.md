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
    syntax Wad ::= wad ( Rat ) [klabel(wad), symbol]
 // ------------------------------------------------

    syntax Ray ::= ray ( Rat ) [klabel(ray), symbol]
 // ------------------------------------------------

    syntax Rad ::= rad ( Rat ) [klabel(rad), symbol]
 // ------------------------------------------------

    syntax MaybeWad ::= Wad | ".Wad"
 // --------------------------------
```

```k
    syntax Wad ::= "0Wad" | "1Wad"
 // ------------------------------
    rule 0Wad => wad(0) [macro]
    rule 1Wad => wad(1) [macro]

    syntax Ray ::= "0Ray" | "1Ray"
 // ------------------------------
    rule 0Ray => ray(0) [macro]
    rule 1Ray => ray(1) [macro]

    syntax Rad ::= "0Rad" | "1Rad"
 // ------------------------------
    rule 0Rad => rad(0) [macro]
    rule 1Rad => rad(1) [macro]
```

```k
    syntax Wad ::= Rad2Wad ( Rad ) [function]
                 | Ray2Wad ( Ray ) [function]
 // -----------------------------------------
    rule Ray2Wad(ray(R)) => wad(R)
    rule Rad2Wad(rad(R)) => wad(R)

    syntax Ray ::= Wad2Ray ( Wad ) [function]
                 | Rad2Ray ( Rad ) [function]
 // -----------------------------------------
    rule Wad2Ray(wad(W)) => ray(W)
    rule Rad2Ray(rad(R)) => ray(R)

    syntax Rad ::= Wad2Rad ( Wad ) [function]
                 | Ray2Rad ( Ray ) [function]
 // -----------------------------------------
    rule Wad2Rad(wad(W)) => rad(W)
    rule Ray2Rad(ray(R)) => rad(R)
```

```k
    syntax Wad ::= Wad "*Wad" Wad [function]
                 | Wad "/Wad" Wad [function]
                 | Wad "^Wad" Int [function]
                 > Wad "+Wad" Wad [function]
                 | Wad "-Wad" Wad [function]
 // ----------------------------------------
    rule wad(R1) *Wad wad(R2) => wad(R1 *Rat R2)
    rule wad(R1) /Wad wad(R2) => wad(R1 /Rat R2)
    rule wad(R1) ^Wad I       => wad(R1 ^Rat I)
    rule wad(R1) +Wad wad(R2) => wad(R1 +Rat R2)
    rule wad(R1) -Wad wad(R2) => wad(R1 -Rat R2)

    syntax Ray ::= Ray "*Ray" Ray [function]
                 | Ray "/Ray" Ray [function]
                 | Ray "^Ray" Int [function]
                 > Ray "+Ray" Ray [function]
                 | Ray "-Ray" Ray [function]
 // ----------------------------------------
    rule ray(R1) *Ray ray(R2) => ray(R1 *Rat R2)
    rule ray(R1) /Ray ray(R2) => ray(R1 /Rat R2)
    rule ray(R1) ^Ray I       => ray(R1 ^Rat I)
    rule ray(R1) +Ray ray(R2) => ray(R1 +Rat R2)
    rule ray(R1) -Ray ray(R2) => ray(R1 -Rat R2)

    syntax Rad ::= Rad "*Rad" Rad [function]
                 | Rad "/Rad" Rad [function]
                 | Rad "^Rad" Int [function]
                 > Rad "+Rad" Rad [function]
                 | Rad "-Rad" Rad [function]
 // ----------------------------------------
    rule rad(R1) *Rad rad(R2) => rad(R1 *Rat R2)
    rule rad(R1) /Rad rad(R2) => rad(R1 /Rat R2)
    rule rad(R1) ^Rad I       => rad(R1 ^Rat I)
    rule rad(R1) +Rad rad(R2) => rad(R1 +Rat R2)
    rule rad(R1) -Rad rad(R2) => rad(R1 -Rat R2)
```

```k
    syntax Wad ::= minWad ( Wad , Wad ) [function]
                 | maxWad ( Wad , Wad ) [function]
 // ----------------------------------------------
    rule minWad(wad(W1), wad(W2)) => wad(minRat(W1, W2))
    rule maxWad(wad(W1), wad(W2)) => wad(maxRat(W1, W2))

    syntax Ray ::= minRay ( Ray , Ray ) [function]
                 | maxRay ( Ray , Ray ) [function]
 // ----------------------------------------------
    rule minRay(ray(W1), ray(W2)) => ray(minRat(W1, W2))
    rule maxRay(ray(W1), ray(W2)) => ray(maxRat(W1, W2))

    syntax Rad ::= minRad ( Rad , Rad ) [function]
                 | maxRad ( Rad , Rad ) [function]
 // ----------------------------------------------
    rule minRad(rad(W1), rad(W2)) => rad(minRat(W1, W2))
    rule maxRad(rad(W1), rad(W2)) => rad(maxRat(W1, W2))
```

```k
    syntax Bool ::= Wad  "<=Wad" Wad [function]
                  | Wad   "<Wad" Wad [function]
                  | Wad  ">=Wad" Wad [function]
                  | Wad   ">Wad" Wad [function]
                  | Wad  "==Wad" Wad [function]
                  | Wad "=/=Wad" Wad [function]
 // -------------------------------------------
    rule wad(W1)  <=Wad wad(W2) => W1  <=Rat W2
    rule wad(W1)   <Wad wad(W2) => W1   <Rat W2
    rule wad(W1)  >=Wad wad(W2) => W1  >=Rat W2
    rule wad(W1)   >Wad wad(W2) => W1   >Rat W2
    rule wad(W1)  ==Wad wad(W2) => W1  ==Rat W2
    rule wad(W1) =/=Wad wad(W2) => W1 =/=Rat W2

    syntax Bool ::= Ray  "<=Ray" Ray [function]
                  | Ray   "<Ray" Ray [function]
                  | Ray  ">=Ray" Ray [function]
                  | Ray   ">Ray" Ray [function]
                  | Ray  "==Ray" Ray [function]
                  | Ray "=/=Ray" Ray [function]
 // -------------------------------------------
    rule ray(W1)  <=Ray ray(W2) => W1  <=Rat W2
    rule ray(W1)   <Ray ray(W2) => W1   <Rat W2
    rule ray(W1)  >=Ray ray(W2) => W1  >=Rat W2
    rule ray(W1)   >Ray ray(W2) => W1   >Rat W2
    rule ray(W1)  ==Ray ray(W2) => W1  ==Rat W2
    rule ray(W1) =/=Ray ray(W2) => W1 =/=Rat W2

    syntax Bool ::= Rad  "<=Rad" Rad [function]
                  | Rad   "<Rad" Rad [function]
                  | Rad  ">=Rad" Rad [function]
                  | Rad   ">Rad" Rad [function]
                  | Rad  "==Rad" Rad [function]
                  | Rad "=/=Rad" Rad [function]
 // -------------------------------------------
    rule rad(W1)  <=Rad rad(W2) => W1  <=Rat W2
    rule rad(W1)   <Rad rad(W2) => W1   <Rat W2
    rule rad(W1)  >=Rad rad(W2) => W1  >=Rat W2
    rule rad(W1)   >Rad rad(W2) => W1   >Rat W2
    rule rad(W1)  ==Rad rad(W2) => W1  ==Rat W2
    rule rad(W1) =/=Rad rad(W2) => W1 =/=Rat W2
```

```k
    syntax Rad ::= Wad "*Rate" Ray [function]
 // -----------------------------------------
    rule wad(R1) *Rate ray(R2) => rad(R1 *Rat R2)

    syntax Wad ::= Rad "/Rate" Ray [function]
 // -----------------------------------------
    rule rad(R1) /Rate ray(R2) => wad(R1 /Rat R2)

    syntax Wad ::= rmul ( Wad , Ray ) [function]
 // --------------------------------------------
    rule rmul(wad(R1), ray(R2)) => wad(R1 *Rat R2)

    syntax Rad ::= rmul ( Rad , Ray ) [function]
 // --------------------------------------------
    rule rmul(rad(R1), ray(R2)) => rad(R1 *Rat R2)

    syntax Ray ::= rdiv ( Ray , Rad ) [function]
 // --------------------------------------------
    rule rdiv(ray(R1), rad(R2)) => ray(R1 /Rat R2)

    syntax Ray ::= wdiv ( Ray , Wad ) [function]
 // --------------------------------------------
    rule wdiv(ray(R1), wad(R2)) => ray(R1 /Rat R2)
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

Random Choices
--------------

```k
module KMCD-RANDOM-CHOICES
    imports KMCD-DATA
```

```k
    syntax Int ::= randIntBounded ( Int , Int ) [function]
 // ------------------------------------------------------
    rule randIntBounded(RAND, BOUND) => 0                          requires         BOUND <Int 0
    rule randIntBounded(RAND, BOUND) => RAND modInt (BOUND +Int 1) requires notBool BOUND <Int 0

    syntax Rat ::= randRat ( Int ) [function]
 // -----------------------------------------
    rule randRat(I) => I /Rat 256

    syntax Rat ::= randRatBounded ( Int , Rat ) [function]
 // ------------------------------------------------------
    rule randRatBounded(I, BOUND) => BOUND *Rat randRat(I)

    syntax Int     ::= chooseInt     ( Int , List ) [function]
    syntax String  ::= chooseString  ( Int , List ) [function]
    syntax Address ::= chooseAddress ( Int , List ) [function]
    syntax CDPID   ::= chooseCDPID   ( Int , List ) [function]
 // ----------------------------------------------------------
    rule chooseInt    (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>Int
    rule chooseString (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>String
    rule chooseAddress(I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>Address
    rule chooseCDPID  (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>CDPID

    syntax Wad ::= randWadBounded ( Int , Wad ) [function]
 // ------------------------------------------------------
    rule randWadBounded(I, wad(W)) => wad(randRatBounded(I, W))

    syntax Ray ::= randRayBounded ( Int , Ray ) [function]
 // ------------------------------------------------------
    rule randRayBounded(I, ray(R)) => ray(randRatBounded(I, R))

    syntax Rad ::= randRadBounded ( Int , Rad ) [function]
 // ------------------------------------------------------
    rule randRadBounded(I, rad(R)) => rad(randRatBounded(I, R))
```

```k
endmodule
```
