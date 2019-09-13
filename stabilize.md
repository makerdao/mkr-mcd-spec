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
        <flap-state>
          <flap-ward> .Map </flap-ward>  // mapping (address => uint) Address |-> Bool
          <flap-bids> .Map </flap-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flap-kicks> 0   </flap-kicks>
          <flap-live>  1   </flap-live>
        </flap-state>
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
    rule <k> step [ Flap . FAS:FlapAuthStep ] => Flap . push ~> Flap . auth ~> Flap . FAS ~> Flap . catch ... </k>
    rule <k> step [ Flap . FS               ] => Flap . push ~>                Flap . FS  ~> Flap . catch ... </k>
      requires notBool isFlapAuthStep(FS)

    syntax FlapStep ::= FlapAuthStep
 // --------------------------------

    syntax FlapAuthStep ::= AuthStep
 // --------------------------------
    rule <k> Flap . auth => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <flap-ward> ... MSGSENDER |-> true ... </flap-ward>

    rule <k> Flap . auth => Flap . exception ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <flap-ward> ... MSGSENDER |-> false ... </flap-ward>

    syntax FlapAuthStep ::= WardStep
 // --------------------------------
    rule <k> Flap . rely ADDR => . ... </k>
         <flap-ward> ... ADDR |-> (_ => true) ... </flap-ward>

    rule <k> Flap . deny ADDR => . ... </k>
         <flap-ward> ... ADDR |-> (_ => false) ... </flap-ward>

    syntax FlapStep ::= StashStep
 // -----------------------------
    rule <k> Flap . push => . ... </k>
         <flapStack> (.List => ListItem(FLAP)) ... </flapStack>
         <flap-state> FLAP </flap-state>

    rule <k> Flap . pop => . ... </k>
         <flapStack> (ListItem(FLAP) => .List) ... </flapStack>
         <flap-state> _ => FLAP </flap-state>

    rule <k> Flap . drop => . ... </k>
         <flapStack> (ListItem(_) => .List) ... </flapStack>

    syntax FlapStep ::= ExceptionStep
 // ---------------------------------
    rule <k>                      Flap . catch => Flap . drop ... </k>
    rule <k> Flap . exception ~>  Flap . catch => Flap . pop  ... </k>
    rule <k> Flap . exception ~> (Flap . FS    => .)          ... </k>
      requires FS =/=K catch

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

    syntax VowStep ::= StashStep
 // ----------------------------

    syntax VowStep ::= ExceptionStep
 // --------------------------------

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
