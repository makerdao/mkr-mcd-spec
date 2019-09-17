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

    syntax MCDContract ::= FlapContract
    syntax FlapContract ::= "Flap"
    syntax MCDStep ::= FlapContract "." FlapStep
 // --------------------------------------------
    rule contract(Flap . _) => Flap

    syntax FlapStep ::= FlapAuthStep
    syntax AuthStep ::= FlapAuthStep
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
    syntax MCDContract ::= FlopContract
    syntax FlopContract ::= "Flop"
    syntax MCDStep ::= FlopContract "." FlopStep
 // --------------------------------------------
    rule contract(Flop . _) => Flop

    syntax FlopStep ::= FlopAuthStep
    syntax AuthStep ::= FlopAuthStep
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
    syntax MCDContract ::= VowContract
    syntax VowContract ::= "Vow"
    syntax MCDStep ::= VowContract "." VowStep
 // ------------------------------------------
    rule contract(Vow . _) => Vow

    syntax VowStep ::= VowAuthStep
    syntax AuthStep ::= VowAuthStep
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
