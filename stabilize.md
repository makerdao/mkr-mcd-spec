System Stabalizer
=================

The system stabalizer takes forceful actions to mitigate risk in the MCD system.

```k
requires "cdp-core.k"
requires "collateral.k"

module SYSTEM-STABILIZER
    imports CDP-CORE
    imports COLLATERAL

    configuration
      <stabilize>
        <flap-state>
          <flap-addr>  0:Address    </flap-addr>
          <flap-bids> .Map          </flap-bids>  // mapping (uint => Bid) Int |-> StableBid
          <flap-kicks> 0            </flap-kicks>
          <flap-live>  true         </flap-live>
          <flap-beg>   105 /Rat 100 </flap-beg>
          <flap-ttl>   3 hours      </flap-ttl>
          <flap-tau>   2 days       </flap-tau>
        </flap-state>
        <flopStack> .List </flopStack>
        <flopState>
          <flop-addr>  0:Address </flop-addr>
          <flop-bids>  .Map      </flop-bids>  // mapping (uint => Bid) Int |-> StableBid
          <flop-kicks> 0         </flop-kicks>
          <flop-live>  0         </flop-live>
        </flopState>
        <vow>
          <vow-addr> 0:Address </vow-addr>
          <vow-sins> .Map      </vow-sins> // mapping (uint256 => uint256) Int |-> Int
          <vow-sin>  0         </vow-sin>
          <vow-ash>  0         </vow-ash>
          <vow-wait> 0         </vow-wait>
          <vow-sump> 0         </vow-sump>
          <vow-bump> 0         </vow-bump>
          <vow-hump> 0         </vow-hump>
          <vow-live> 0         </vow-live>
        </vow>
      </stabilize>
```

Flap Semantics
--------------

```k
    syntax Bid ::= StableBid ( bid: Int, lot: Int, guy: Address, tic: Int, end: Int )
 // ---------------------------------------------------------------------------------

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

    syntax FlapStep ::= "kick" Int Int
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
