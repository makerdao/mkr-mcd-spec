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

