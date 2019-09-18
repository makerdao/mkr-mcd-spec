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
        <flop-state>
          <flop-addr>  0:Address    </flop-addr>
          <flop-bids> .Map          </flop-bids>  // mapping (uint => Bid) Int |-> StableBid
          <flop-kicks> 0            </flop-kicks>
          <flop-live>  true         </flop-live>
          <flop-beg>   105 /Rat 100 </flop-beg>
          <flop-ttl>   3 hours      </flop-ttl>
          <flop-tau>   2 days       </flop-tau>
        </flop-state>
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
```

- kick(uint lot, uint bid) returns (uint id)
- Starts a new surplus auction for a lot amount

```k
    syntax FlapAuthStep ::= "kick" Int Int
 // --------------------------------------
    rule <k> Flap . kick LOT BID
          => call Vat . move MSGSENDER THIS LOT
          ~> KICKS +Int 1
          ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flap-bids>... .Map =>
            KICKS +Int 1 |-> StableBid(... bid: BID,
                                           lot: LOT,
                                           guy: MSGSENDER,
                                           tic: 0,
                                           end: NOW +Int TAU)
         ...</flap-bids>
         <flap-kicks> KICKS => KICKS +Int 1 </flap-kicks>
         <flap-live> true </flap-live>
         <flap-tau> TAU </flap-tau>
```

- tend(uint id, uint lot, uint bid)
- Places a bid made by the user. Refunds the previous bidder's bid.

```k
    syntax FlapStep ::= "tend" Int Int Int
 // --------------------------------------
    rule <k> Flap . tend ID LOT BID
          => call Gem "MKR" . move MSGSENDER GUY BID'
          ~> call Gem "MKR" . move MSGSENDER THIS (BID -Int BID')
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flap-bids>...
           ID |-> StableBid(... bid: BID' => BID,
                                lot: LOT',
                                guy: GUY => MSGSENDER,
                                tic: TIC => TIC +Int TTL,
                                end: END)
         ...</flap-bids>
         <flap-live> true </flap-live>
         <flap-ttl> TTL </flap-ttl>
         <flap-beg> BEG </flap-beg>
      requires GUY =/=Int 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END  >Int NOW
       andBool LOT ==Int LOT'
       andBool BID  >Int BID'
       andBool BID >=Rat BID' *Rat BEG
```

- deal(uint id)
- Settles an auction, rewarding the lot to the highest bidder and burning their bid

```k
    syntax FlapStep ::= "deal" Int [klabel(FlapDeal),symbol]
 // --------------------------------------------------------
    rule <k> Flap . deal ID
          => call Vat . move THIS GUY LOT
          ~> call Gem "MKR" . burn THIS BID
         ...
         </k>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flap-bids>...
           ID |-> StableBid(... bid: BID, lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
         ...</flap-bids>
         <flap-live> true </flap-live>
      requires TIC <Int NOW
       andBool (TIC =/=Int 0 orBool END <Int NOW)
```

- cage(uint rad)
- Part of Global Settlement. Freezes the auction house.

```k
    syntax FlapAuthStep ::= "cage" Int
 // ----------------------------------
    rule <k> Flap . cage RAD => call Vat . move THIS MSGSENDER RAD ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flap-live> _ => false </flap-live>
```

- yank(uint id)
- Part of Global Settlement. Refunds the highest bidder's bid.

```k
    syntax FlapStep ::= "yank" Int [klabel(FlapYank),symbol]
 // --------------------------------------------------------
    rule <k> Flap . yank ID
          => call Gem "MKR" . move THIS GUY BID
         ...
         </k>
         <this> THIS </this>
         <flap-bids>...
           ID |-> StableBid(... bid: BID, guy: GUY) => .Map
         ...</flap-bids>
         <flap-live> false </flap-live>
      requires GUY =/=Int 0
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
```

- kick(address gal, uint lot, uint bid) returns (uint id)
- Starts an auction

```k
    syntax FlopAuthStep ::= "kick" Address Int Int
 // ----------------------------------------------
    rule <k> Flop . kick GAL LOT BID
          => KICKS +Int 1
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flop-live> true </flop-live>
         <flop-bids>... .Map =>
           KICKS +Int 1 |-> StableBid(... bid: BID,
                                          lot: LOT,
                                          guy: GAL,
                                          tic: 0,
                                          end: NOW +Int TAU)
         ...</flop-bids>
         <flop-kicks> KICKS => KICKS +Int 1 </flop-kicks>
         <flop-tau> TAU </flop-tau>


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
