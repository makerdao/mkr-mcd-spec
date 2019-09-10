KMCD Driver
===========

This module defines common state and control flow between all the other KMCD modules.

```k
module KMCD-DRIVER
    imports BOOL
    imports BYTES
    imports INT
    imports MAP
    imports STRING

    configuration
        <kmcd-driver>
          <k> $PGM:MCDSteps </k>
          <msg-sender> 0:Address </msg-sender>
          <this> 0:Address </this>
          <currentTime> 0:Int </currentTime>
        </kmcd-driver>
```

MCD Simulations
---------------

```k
    syntax MCDStep
    syntax MCDSteps ::= ".MCDSteps" | MCDStep MCDSteps
 // --------------------------------------------------
    rule <k> .MCDSteps => . ... </k>
```

The `step [_]` operator allows enforcing certain invariants during execution.

```k
    syntax MCDStep ::= "step" "[" MCDStep "]"
 // -----------------------------------------
    rule <k> MCD:MCDStep MCDS:MCDSteps => step [ MCD ] ~> MCDS ... </k>
```

Simulations
-----------

Different contracts use the same names for external functions, so we declare them here.

```k
    syntax InitStep ::= "init" Int
 // ------------------------------

    syntax WardStep ::= "rely" Address | "deny" Address
 // ---------------------------------------------------

    syntax AuthStep ::= "auth"
 // --------------------------

    syntax StashStep ::= "push" | "pop" | "drop"
 // --------------------------------------------

    syntax ExceptionStep ::= "catch" | "exception"
 // ----------------------------------------------
```

Time Increments
---------------

Some methods rely on a timestamp. We simulate that here.

```k
    syntax MCDStep ::= "TimeStep"
 // -----------------------------
    rule <k> step [ TimeStep ] => . ... </k>
         <currentTime> TIME => TIME +Int 1 </currentTime>
```

Base Data
---------

-   `Wad`: basic quantities (e.g. balances).
-   `Ray`: precise quantities (e.g. ratios).
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision).
-   `Address`: unique identifier of an account on the network.

**TODO**: Should we add operators like `+Wad` which emulate the precision limits described in `makerdao/dss/DEVELOPING.md`, or assume the abstract model to be inifinite precision?

```k
    syntax Wad ::= Int
 // ------------------

    syntax Ray ::= Int
 // ------------------

    syntax Rad ::= Int
 // ------------------

    syntax Address ::= Int | String
 // -------------------------------

    syntax Value ::= Int | ".Value"
 // -------------------------------
```

Constants
---------

```k
    syntax Int ::= "ilk_init"
 // -------------------------
    rule ilk_init => 1000000000000000000000000000 [macro]
```

Math Functions
--------------

```k
    syntax Int ::= #pow ( Int, Int ) [function]
 // -------------------------------------------
    rule #pow( X, 0 ) => ilk_init
    rule #pow( X, 1 ) => X
    rule #pow( X, N ) => X *Int #pow( X, N -Int 1 ) /Int ilk_init
```

```k
endmodule
```
