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
        <flop-state>
          <flop-ward> .Map          </flop-ward>  // mapping (address => uint) Address |-> Bool
          <flop-bids> .Map          </flop-bids>  // mapping (uint => Bid)     Int     |-> Bid
          <flop-kicks> 0            </flop-kicks>
          <flop-live>  true         </flop-live>
          <flop-beg>   105 /Rat 100 </flop-beg>
          <flop-ttl>   3 hours      </flop-ttl>
          <flop-tau>   2 days       </flop-tau>
        </flop-state>
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

    syntax FlopStep ::= StashStep
 // -----------------------------

    syntax FlopStep ::= ExceptionStep
 // ---------------------------------
```

- kick(address gal, uint lot, uint bid) returns (uint id)
- Starts an auction

```k
    syntax FlopAuthStep ::= "kick" Address Int Int
 // ----------------------------------------------
    rule <k> Flop . kick GAL LOT BID
          => Vat . move MSGSENDER THIS LOT
          ~> KICKS +Int 1
          ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flop-live> true </flop-live>
         <flop-bids>... .Map =>
           KICKS +Int 1 |-> Bid(...
                             bid: BID,
                             lot: LOT,
                             guy: GAL,
                             tic: 0,
                             end: NOW +Int TAU)
         ...</flop-bids>
         <flop-kicks> KICKS => KICKS +Int 1 </flop-kicks>
         <flop-tau> TAU </flop-tau>
```

- tick(uint id)
- Extends the end time of the auction when no one has made a bid

```k
    syntax FlopStep ::= "tick" Int
 // ------------------------------
    rule <k> Flop . tick ID => . ... </k>
         <currentTime> NOW </currentTime>
         <flop-bids> ... ID |-> Bid(... tic: 0, end: END => NOW +Int TAU ) ... </flop-bids>
         <flop-tau> TAU </flop-tau>
      requires END <Int NOW
```

- dent(uint id, uint lot, uint bid)
- User action to make a bid for a smaller lot.

```k
    syntax FlopStep ::= "dent" Int Int Int
 // --------------------------------------
    rule <k> Flop . dent ID LOT BID => Vat . move MSGSENDER GUY BID ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <currentTime> NOW </currentTime>
         <flop-bids>...
           ID |-> Bid(... bid: BID',
                          lot: LOT' => LOT,
                          guy: GUY => MSGSENDER,
                          tic: TIC => TIC +Int TTL,
                          end: END)
         ...</flop-bids>
         <flop-live> true </flop-live>
         <flop-beg> BEG </flop-beg>
         <flop-ttl> TTL </flop-ttl>
      requires GUY =/=Int 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool BID ==Int BID'
       andBool LOT <Int LOT'
       andBool LOT *Rat BEG <=Rat LOT'
```

- deal(uint id)
- Settles the auction.

**TODO** Flop.deal calls Gem.mint. We don't have Gem yet.
- `<k> Flop . deal ID => Gem . mint GUY LOT ... </k>`

```k
    syntax FlopStep ::= "deal" Int [klabel(FlopDeal),symbol]
 // --------------------------------------------------------
    rule <k> Flop . deal ID => . ... </k>
         <currentTime> NOW </currentTime>
         <flop-bids>...
           ID |-> Bid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
         ...</flop-bids>
         <flop-live> true </flop-live>
      requires TIC <Int NOW
       andBool (TIC =/=Int 0 orBool END <Int NOW)
```

- cage()
- Part of global settlement. Freezes the auctions.

```k
    syntax FlopAuthStep ::= "cage" [klabel(FlopCage),symbol]
 // --------------------------------------------------------
    rule <k> Flop . cage => . ... </k>
         <flop-live> _ => false </flop-live>
```

- yank(uint id)
- Global settlement. Refunds the current bid.

```k
    syntax FlopStep ::= "yank" Int [klabel(FlopYank),symbol]
 // --------------------------------------------------------
    rule <k> Flop . yank ID => Vat . move THIS GUY BID ... </k>
         <this> THIS </this>
         <flop-bids>...
           ID |-> Bid(... bid: BID, guy: GUY) => .Map
         ...</flop-bids>
         <flop-live> false </flop-live>
      requires GUY =/=Int 0
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
