System Stabalizer
=================

The system stabalizer takes forceful actions to mitigate risk in the MCD system.

```k
requires "cdp-core.k"

module SYSTEM-STABILIZER
    imports CDP-CORE

    configuration
      <stabilize>
        <flapStack> .List </flapStack>
        <flapState>
          <flap-ward> .Map </flap-ward>  // mapping (address => uint) Address |-> Bool
          <flap-bids> .Map </flap-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flap-kicks> 0   </flap-kicks>
          <flap-live>  0   </flap-live>
        </flapState>
        <flopStack> .List </flopStack>
        <flopState>
          <flop-ward> .Map </flop-ward>  // mapping (address => uint) Address |-> Bool
          <flop-bids> .Map </flop-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flop-kicks> 0   </flop-kicks>
          <flop-live>  0   </flop-live>
        </flopState>
        <vowStack> .List </vowStack>
        <vow>
          <vow-ward>  .Map </vow-ward> // mapping (address => uint)    Address |-> Bool
          <vow-sins>  .Map </vow-sins> // mapping (uint256 => uint256) Int     |-> Int
          <vow-sin>   0    </vow-sin>
          <vow-ash>   0    </vow-ash>
          <vow-wait>  0    </vow-wait>
          <vow-sump>  0    </vow-sump>
          <vow-bump>  0    </vow-bump>
          <vow-hump>  0    </vow-hump>
          <vow-live>  0    </vow-live>
        </vow>
      </stabilize>
```

Flap Semantics
--------------

```k
    syntax Bid ::= Bid ( Int, Int, Address, Int, Int ) [klabel(BidBid)]
 // -------------------------------------------------------------------

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
```

Vow Semantics
-------------

```k
    syntax MCDStep ::= "Vow" "." VowStep
 // ------------------------------------

    syntax VowStep ::= VowAuthStep
 // ------------------------------

    syntax VowAuthStep ::= AuthStep
 // -------------------------------

    syntax VowAuthStep ::= WardStep
 // -------------------------------

    syntax VowAuthStep ::= "init" Address Address Address
 // -----------------------------------------------------

    syntax VowStep ::= "fess" Int
 // -----------------------------

    syntax VowStep ::= "flog" Int
 // -----------------------------

    syntax VowStep ::= "heal" Rad
 // -----------------------------

    syntax VowStep ::= "kiss" Rad
 // -----------------------------

    syntax VowStep ::= "flop"
 // -------------------------

    syntax VowStep ::= "flap"
 // -------------------------

    syntax VowStep ::= "cage"
 // -------------------------

```

```k
endmodule
```
