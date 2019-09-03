KMCD Driver
===========

This module defines common state and control flow between all the other KMCD modules.

```k
module KMCD-DRIVER

    configuration
        <kmcd-driver>
          <k> $PGM:MCDSteps </k>
        </kmcd-driver>

    syntax MCDStep
    syntax MCDSteps ::= ".MCDSteps" | MCDStep MCDSteps
 // --------------------------------------------------
    rule <k> .MCDSteps                 => .           ... </k>
    rule <k> MCD:MCDStep MCDS:MCDSteps => MCD ~> MCDS ... </k>
endmodule
```
