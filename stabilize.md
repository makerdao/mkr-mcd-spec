System Stabalizer
=================

The system stabalizer takes forceful actions to mitigate risk in the MCD system.

```k
requires "cdp-core.k"

module SYSTEM-STABILIZER
    imports CDP-CORE

    configuration
      <stabilize>
        <flapState>
          <flap-addr>  0:Address </flap-addr>
          <flap-bids>  .Map      </flap-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flap-kicks> 0         </flap-kicks>
          <flap-live>  true      </flap-live>
        </flapState>
        <flopState>
          <flop-addr>  0:Address </flop-addr>
          <flop-bids>  .Map      </flop-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flop-kicks> 0         </flop-kicks>
          <flop-live>  true      </flop-live>
        </flopState>
        <vow>
          <vow-addr> 0:Address </vow-addr>
          <vow-sins> .Map      </vow-sins> // mapping (uint256 => uint256) Int     |-> Rad
          <vow-sin>  0:Rad      </vow-sin>
          <vow-ash>  0:Rad     </vow-ash>
          <vow-wait> 0         </vow-wait>
          <vow-dump> 0:Wad     </vow-dump>
          <vow-sump> 0:Rad     </vow-sump>
          <vow-bump> 0:Rad     </vow-bump>
          <vow-hump> 0:Rad     </vow-hump>
          <vow-live> true      </vow-live>
        </vow>
      </stabilize>
```

Flap Semantics
--------------

```k
    syntax Bid ::= FlapBid ( bid: Wad, lot: Rad, guy: Address, tic: Int, end: Int )
 // -------------------------------------------------------------------------------

    syntax MCDContract ::= FlapContract
    syntax FlapContract ::= "Flap"
    syntax MCDStep ::= FlapContract "." FlapStep [klabel(flapStep)]
 // ---------------------------------------------------------------
    rule contract(Flap . _) => Flap
    rule [[ address(Flap) => ADDR ]] <flap-addr> ADDR </flap-addr>

    syntax FlapStep ::= FlapAuthStep
    syntax AuthStep ::= FlapContract "." FlapAuthStep [klabel(flapStep)]
 // --------------------------------------------------------------------
    rule <k> Flap . _ => exception ... </k> [owise]

    syntax FlapStep ::= "kick" Rad Int
 // ----------------------------------

    syntax FlapStep ::= "tend" Int Int Int
 // --------------------------------------

    syntax FlapStep ::= "deal" Int
 // ------------------------------

    syntax FlapAuthStep ::= "cage" Int
 // ----------------------------------

    syntax FlapStep ::= "yank" Int
 // ------------------------------
```

Flop Semantics
--------------

```k
    syntax Bid ::= FlopBid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int )
 // -------------------------------------------------------------------------------

    syntax MCDContract ::= FlopContract
    syntax FlopContract ::= "Flop"
    syntax MCDStep ::= FlopContract "." FlopStep [klabel(flopStep)]
 // ---------------------------------------------------------------
    rule contract(Flop . _) => Flop
    rule [[ address(Flop) => ADDR ]] <flop-addr> ADDR </flop-addr>

    syntax FlopStep ::= FlopAuthStep
    syntax AuthStep ::= FlopContract "." FlopAuthStep [klabel(flopStep)]
 // --------------------------------------------------------------------
    rule <k> Flop . _ => exception ... </k> [owise]

    syntax FlopAuthStep ::= "kick" Int Int Int
 // ------------------------------------------

    syntax FlopStep ::= "tick" Int
 // ------------------------------

    syntax FlopStep ::= "dent" Int Int Int
 // --------------------------------------

    syntax FlopStep ::= "deal" Int
 // ------------------------------

    syntax FlopAuthStep ::= "cage"
 // ------------------------------

    syntax FlopStep ::= "yank" Int
 // ------------------------------
```

Vow Semantics
-------------

```k
    syntax MCDContract ::= VowContract
    syntax VowContract ::= "Vow"
    syntax MCDStep ::= VowContract "." VowStep [klabel(vowStep)]
 // ------------------------------------------------------------
    rule contract(Vow . _) => Vow
    rule [[ address(Vow) => ADDR ]] <vow-addr> ADDR </vow-addr>

    syntax VowStep ::= VowAuthStep
    syntax AuthStep ::= VowContract "." VowAuthStep [klabel(vowStep)]
 // -----------------------------------------------------------------
    rule <k> Vow . _ => exception ... </k> [owise]

    syntax VowAuthStep ::= "fess" Int
 // ---------------------------------

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

    syntax VowAuthStep ::= "cage"
 // -----------------------------

```

```k
endmodule
```
