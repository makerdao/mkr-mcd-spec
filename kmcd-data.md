KMCD Data
=========

This module defines base data-types needed for the KMCD system.

```k
requires "fixed-int.k"

module KMCD-DATA
    imports BOOL
    imports FIXED-INT
    imports MAP
```

Precision Quantities
--------------------

We model everything with arbitrary precision rationals, but use sort information to indicate the EVM code precision.

-   `Way`: conversions between `Wad` and `Ray` (1e9).
-   `Wad`: basic quantities (e.g. balances) (1e18).
-   `Ray`: precise quantities (e.g. ratios) (1e27).
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision) (1e45).

```k
    syntax Value ::= Wad | Ray | Rad | Int
 // --------------------------------------

    syntax Int ::= "WAY" | "WAD" | "RAY" | "RAD"
 // --------------------------------------------
    rule WAY => 1000000000                                     [macro]
    rule WAD => 1000000000000000000                            [macro]
    rule RAY => 1000000000000000000000000000                   [macro]
    rule RAD => 1000000000000000000000000000000000000000000000 [macro]

    syntax Way = FInt
    syntax Way ::= way ( Int )
 // --------------------------
    rule way(I) => FInt(I *Int WAY, WAY) [macro]

    syntax Wad = FInt
    syntax Wad ::= wad ( Int )
 // --------------------------
    rule wad(0) => 0FInt(WAD)            [macro]
    rule wad(1) => 1FInt(WAD)            [macro]
    rule wad(I) => FInt(I *Int WAD, WAD) [macro, owise]

    syntax Ray = FInt
    syntax Ray ::= ray ( Int )
 // --------------------------
    rule ray(0) => 0FInt(RAY)            [macro]
    rule ray(1) => 1FInt(RAY)            [macro]
    rule ray(I) => FInt(I *Int RAY, RAY) [macro, owise]

    syntax Rad = FInt
    syntax Rad ::= rad ( Int )
 // --------------------------
    rule rad(0) => 0FInt(RAD)            [macro]
    rule rad(1) => 1FInt(RAD)            [macro]
    rule rad(I) => FInt(I *Int RAD, RAD) [macro, owise]

    syntax MaybeWad ::= Wad | ".Wad"
 // --------------------------------
```

```k
    syntax Wad ::= Rad2Wad ( Rad ) [function]
 // -----------------------------------------
    rule Rad2Wad(FInt(R, RAD)) => FInt(R /Int RAY, WAD)

    syntax Ray ::= Wad2Ray ( Wad ) [function]
 // -----------------------------------------
    rule Wad2Ray(FInt(W, WAD)) => FInt(W *Int WAY, RAY)

    syntax Rad ::= Wad2Rad ( Wad ) [function]
                 | Ray2Rad ( Ray ) [function]
 // -----------------------------------------
    rule Wad2Rad(FInt(W, WAD)) => FInt(W *Int RAY, RAD)
    rule Ray2Rad(FInt(R, RAY)) => FInt(R *Int WAD, RAD)
```

```k
    syntax Wad ::= Wad "*Wad" Wad [function]
                 | Wad "/Wad" Wad [function]
                 | Wad "^Wad" Int [function]
                 > Wad "+Wad" Wad [function]
                 | Wad "-Wad" Wad [function]
 // ----------------------------------------
    rule FI1 *Wad FI2    => FI1 *FInt FI2
    rule FI1 /Wad wad(0) => wad(0)
    rule FI1 /Wad FI2    => FI1 /FInt FI2 [owise]
    rule FI1 ^Wad I      => FI1 ^FInt I
    rule FI1 +Wad FI2    => FI1 +FInt FI2
    rule FI1 -Wad FI2    => FI1 -FInt FI2

    syntax Ray ::= Ray "*Ray" Ray [function]
                 | Ray "/Ray" Ray [function]
                 | Ray "^Ray" Int [function]
                 > Ray "+Ray" Ray [function]
                 | Ray "-Ray" Ray [function]
 // ----------------------------------------
    rule FI1 *Ray FI2    => FI1 *FInt FI2
    rule FI1 /Ray ray(0) => ray(0)
    rule FI1 /Ray FI2    => FI1 /FInt FI2 [owise]
    rule FI1 ^Ray I      => FI1 ^FInt I
    rule FI1 +Ray FI2    => FI1 +FInt FI2
    rule FI1 -Ray FI2    => FI1 -FInt FI2

    syntax Rad ::= Rad "*Rad" Rad [function]
                 | Rad "/Rad" Rad [function]
                 | Rad "^Rad" Int [function]
                 > Rad "+Rad" Rad [function]
                 | Rad "-Rad" Rad [function]
 // ----------------------------------------
    rule FI1 *Rad FI2    => FI1 *FInt FI2
    rule FI1 /Rad rad(0) => rad(0)
    rule FI1 /Rad FI2    => FI1 /FInt FI2 [owise]
    rule FI1 ^Rad I      => FI1 ^FInt I
    rule FI1 +Rad FI2    => FI1 +FInt FI2
    rule FI1 -Rad FI2    => FI1 -FInt FI2
```

```k
    syntax Wad ::= minWad ( Wad , Wad ) [function]
 // ----------------------------------------------
    rule minWad(FInt(W1, WAD), FInt(W2, WAD)) => FInt(minInt(W1, W2), WAD)

    syntax Rad ::= minRad ( Rad , Rad ) [function]
 // ----------------------------------------------
    rule minRad(FInt(W1, RAD), FInt(W2, RAD)) => FInt(minInt(W1, W2), RAD)
```

```k
    syntax Bool ::= Wad  "<=Wad" Wad [function]
                  | Wad   "<Wad" Wad [function]
                  | Wad  ">=Wad" Wad [function]
                  | Wad   ">Wad" Wad [function]
                  | Wad  "==Wad" Wad [function]
                  | Wad "=/=Wad" Wad [function]
 // -------------------------------------------
    rule W1  <=Wad W2 => W1  <=FInt W2
    rule W1   <Wad W2 => W1   <FInt W2
    rule W1  >=Wad W2 => W1  >=FInt W2
    rule W1   >Wad W2 => W1   >FInt W2
    rule W1  ==Wad W2 => W1  ==FInt W2
    rule W1 =/=Wad W2 => W1 =/=FInt W2

    syntax Bool ::= Ray  "<=Ray" Ray [function]
                  | Ray   "<Ray" Ray [function]
                  | Ray  ">=Ray" Ray [function]
                  | Ray   ">Ray" Ray [function]
                  | Ray  "==Ray" Ray [function]
                  | Ray "=/=Ray" Ray [function]
 // -------------------------------------------
    rule W1  <=Ray W2 => W1  <=FInt W2
    rule W1   <Ray W2 => W1   <FInt W2
    rule W1  >=Ray W2 => W1  >=FInt W2
    rule W1   >Ray W2 => W1   >FInt W2
    rule W1  ==Ray W2 => W1  ==FInt W2
    rule W1 =/=Ray W2 => W1 =/=FInt W2

    syntax Bool ::= Rad  "<=Rad" Rad [function]
                  | Rad   "<Rad" Rad [function]
                  | Rad  ">=Rad" Rad [function]
                  | Rad   ">Rad" Rad [function]
                  | Rad  "==Rad" Rad [function]
                  | Rad "=/=Rad" Rad [function]
 // -------------------------------------------
    rule W1  <=Rad W2 => W1  <=FInt W2
    rule W1   <Rad W2 => W1   <FInt W2
    rule W1  >=Rad W2 => W1  >=FInt W2
    rule W1   >Rad W2 => W1   >FInt W2
    rule W1  ==Rad W2 => W1  ==FInt W2
    rule W1 =/=Rad W2 => W1 =/=FInt W2
```

```k
    syntax Rad ::= Wad "*Rate" Ray [function]
 // -----------------------------------------
    rule FInt(W, WAD) *Rate FInt(R, RAY) => FInt(W *Int R, RAD)

    syntax Wad ::= Rad "/Rate" Ray [function]
 // -----------------------------------------
    rule FInt(_ , _  ) /Rate ray(0)        => wad(0)
    rule FInt(R1, RAD) /Rate FInt(R2, RAY) => FInt(R1 /Int R2, WAD) [owise]

    // syntax Wad ::= rmul ( Wad , Ray ) [function]
    // syntax Rad ::= rmul ( Rad , Ray ) [function]
    syntax FInt ::= rmul ( FInt , FInt ) [function]
 // -----------------------------------------------
    rule rmul(FInt(W, WAD), FInt(R, RAY)) => FInt((W *Int R) /Int RAY, WAD)
    rule rmul(FInt(W, RAD), FInt(R, RAY)) => FInt((W *Int R) /Int RAY, RAD)

    syntax Ray ::= rdiv ( Ray , Rad ) [function]
 // --------------------------------------------
    rule rdiv(FInt(_ , RAY), rad(0))        => ray(0)
    rule rdiv(FInt(R1, RAY), FInt(R2, RAD)) => FInt((R1 *Int RAY) /Int R2, RAY) [owise]

    syntax Ray ::= wdiv ( Ray , Wad ) [function]
 // --------------------------------------------
    rule wdiv(FInt(_ , RAY), wad(0))        => ray(0)
    rule wdiv(FInt(R1, RAY), FInt(R2, WAD)) => FInt((R1 *Int WAD) /Int R2, RAY) [owise]
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
    rule randIntBounded(RAND, BOUND) => ((RAND %Int 256) *Int BOUND) /Int 256

    syntax Int     ::= chooseInt     ( Int , List ) [function]
    syntax String  ::= chooseString  ( Int , List ) [function]
    syntax Address ::= chooseAddress ( Int , List ) [function]
    syntax CDPID   ::= chooseCDPID   ( Int , List ) [function]
 // ----------------------------------------------------------
    rule chooseInt    (RAND, ITEMS) => { ITEMS [ RAND %Int size(ITEMS) ] }:>Int
    rule chooseString (RAND, ITEMS) => { ITEMS [ RAND %Int size(ITEMS) ] }:>String
    rule chooseAddress(RAND, ITEMS) => { ITEMS [ RAND %Int size(ITEMS) ] }:>Address
    rule chooseCDPID  (RAND, ITEMS) => { ITEMS [ RAND %Int size(ITEMS) ] }:>CDPID

    syntax Wad ::= randWadBounded ( Int , Wad ) [function]
 // ------------------------------------------------------
    rule randWadBounded(RAND, FInt(_, WAD) #as FI) => wad(randIntBounded(RAND, baseFInt(FI)))

    syntax Ray ::= randRayBounded ( Int , Ray ) [function]
 // ------------------------------------------------------
    rule randRayBounded(RAND, FInt(_, RAY) #as FI) => ray(randIntBounded(RAND, baseFInt(FI)))

    syntax Rad ::= randRadBounded ( Int , Rad ) [function]
 // ------------------------------------------------------
    rule randRadBounded(RAND, FInt(_, RAD) #as FI) => rad(randIntBounded(RAND, baseFInt(FI)))
```

```k
endmodule
```
