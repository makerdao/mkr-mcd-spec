KMCD Driver
===========

This module defines common state and control flow between all the other KMCD modules.

```k
module KMCD-DRIVER
    imports BOOL
    imports INT
    imports MAP
    imports STRING

    configuration
        <kmcd-driver>
          <k> $PGM:MCDSteps </k>
          <msgSender> 0:Address </msgSender>
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
```

```k
endmodule
```
