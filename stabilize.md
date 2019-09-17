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
          <flap-ward> .Map          </flap-ward>  // mapping (address => uint) Address |-> Bool
          <flap-bids> .Map          </flap-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flap-kicks> 0            </flap-kicks>
          <flap-live>  true         </flap-live>
          <flap-beg>   105 /Rat 100 </flap-beg>
          <flap-ttl>   3 hours      </flap-ttl>
          <flap-tau>   2 days       </flap-tau>
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
    syntax Bid ::= Bid ( bid: Int, lot: Int, guy: Address, tic: Int, end: Int ) [klabel(BidBid)]
 // --------------------------------------------------------------------------------------------

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
```

- kick(uint lot, uint bid) returns (uint id)
- Starts a new surplus auction for a lot amount

```k
    syntax FlapAuthStep ::= "kick" Int Int
 // --------------------------------------
    rule <k> Flap . kick LOT BID
          => Vat . move MSGSENDER THIS LOT
          ~> KICKS +Int 1
          ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flap-bids>... .Map =>
            KICKS +Int 1 |-> Bid(... bid: BID,
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

**TODO** Flap.tend needs to call Gem.move. We don't have Gem yet.
`<k> Flap . tend ID LOT BID => Gem . move MSGSENDER GUY BID' ~> Gem . move MSGSENDER THIS (BID -Int BID') ... </k>`

```k
    syntax FlapStep ::= "tend" Int Int Int
 // --------------------------------------
    rule <k> Flap . tend ID LOT BID => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flap-bids>...
           ID |-> Bid(... bid: BID' => BID,
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

**TODO** Flap.deal calls Gem.burn
`<k> Flap . deal ID => Vat . move THIS GUY LOT ~> Gem . burn THIS BID ... </k>`

```k
    syntax FlapStep ::= "deal" Int [klabel(FlapDeal),symbol]
 // --------------------------------------------------------
    rule <k> Flap . deal ID => Vat . move THIS GUY LOT ... </k>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flap-bids>...
           ID |-> Bid(... bid: BID, lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
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
    rule <k> Flap . cage RAD => Vat . move THIS MSGSENDER RAD ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flap-live> _ => false </flap-live>
```

- yank(uint id)
- Part of Global Settlement. Refunds the highest bidder's bid.

**TODO** Flap.yank calls Gem.move
`<k> Flap . yank ID => Gem . move THIS GUY BID ... </k>`

```k
    syntax FlapStep ::= "yank" Int [klabel(FlapYank),symbol]
 // --------------------------------------------------------
    rule <k> Flap . yank ID => . ... </k>
         <this> THIS </this>
         <flap-bids>...
           ID |-> Bid(... bid: BID, guy: GUY) => .Map
         ...</flap-bids>
         <flap-live> false </flap-live>
      requires GUY =/=Int 0
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
