System Stabalizer
=================

The system stabalizer takes forceful actions to mitigate risk in the MCD system.

```k
requires "cdp-core.k"

module SYSTEM-STABILIZER
    imports CDP-CORE

    configuration
      <stabilize>
        <flap>
          <flap-ward> .Map </flap-ward>  // mapping (address => uint) Address |-> Bool
          <flap-bids> .Map </flap-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flap-kicks> 0   </flap-kicks>
          <flap-live>  0   </flap-live>
        </flap>
        <flop>
          <flop-ward> .Map </flop-ward>  // mapping (address => uint) Address |-> Bool
          <flop-bids> .Map </flop-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flop-kicks> 0   </flop-kicks>
          <flop-live>  0   </flop-live>
        </flop>
      </stabilize>
```

Flap Semantics
--------------

```k
    syntax Bid ::= Bid ( Int, Int, Address, Int, Int )
 // --------------------------------------------------

    syntax MCDStep ::= "Flap" "." FlapStep
 // --------------------------------------

    syntax FlapStep ::= FlapAuthStep
 // --------------------------------

    syntax FlapAuthStep ::= AuthStep
 // --------------------------------

    syntax FlapAuthStep ::= WardStep
 // --------------------------------

    syntax FlapAuthStep ::= "init" Address Address
 // ----------------------------------------------

    syntax FlapStep ::= StashStep
 // -----------------------------

    syntax FlapStep ::= ExceptionStep
 // ---------------------------------

    syntax FlapStep ::= "kick" Int Int
 // ----------------------------------

    syntax FlapStep ::= "tend" Int Int Int
 // --------------------------------------

    syntax FlapStep ::= "deal" Int
 // ------------------------------

    syntax FlapStep ::= "cage" Int
 // ------------------------------

    syntax FlapStep ::= "yank" Int
 // ------------------------------
```

Flop Semantics
--------------

```k
    syntax MCDStep ::= "Flop" "." FlopStep
 // --------------------------------------

    syntax FlopStep ::= FlopAuthStep
 // --------------------------------

    syntax FlopAuthStep ::= AuthStep
 // --------------------------------

    syntax FlopAuthStep ::= WardStep
 // --------------------------------

    syntax FlopAuthStep ::= "init" Address Address
 // ----------------------------------------------

    syntax FlopStep ::= StashStep
 // -----------------------------

    syntax FlopStep ::= ExceptionStep
 // ---------------------------------

    syntax FlopStep ::= "kick" Int Int Int
 // --------------------------------------

    syntax FlopStep ::= "tick" Int
 // ------------------------------

    syntax FlopStep ::= "dent" Int Int Int
 // --------------------------------------

    syntax FlopStep ::= "deal" Int
 // ------------------------------

    syntax FlopStep ::= "cage"
 // --------------------------

    syntax FlopStep ::= "yank" Int
 // ------------------------------

endmodule
```
