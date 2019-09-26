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
        <flop-state>
          <flop-addr>  0:Address    </flop-addr>
          <flop-bids> .Map          </flop-bids>  // mapping (uint => Bid) Int |-> FlopBid
          <flop-kicks> 0            </flop-kicks>
          <flop-live>  true         </flop-live>
          <flop-beg>   105 /Rat 100 </flop-beg>
          <flop-pad>   150 /Rat 100 </flop-pad>
          <flop-ttl>   3 hours      </flop-ttl>
          <flop-tau>   2 days       </flop-tau>
        </flop-state>
        <vow>
          <vow-addr> 0:Address </vow-addr>
          <vow-sins> .Map      </vow-sins> // mapping (uint256 => uint256) Int |-> Rad
          <vow-sin>  0:Rad     </vow-sin>
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

```k
    syntax Bid ::= FlopBid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int )
 // -------------------------------------------------------------------------------
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
```

- kick(address gal, uint lot, uint bid) returns (uint id)
- Starts an auction

```k
    syntax FlopAuthStep ::= "kick" Address Wad Rad
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
           KICKS +Int 1 |-> FlopBid(... bid: BID,
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
         <flop-bids> ... ID |-> FlopBid(... lot: LOT => LOT *Rat PAD, tic: 0, end: END => NOW +Int TAU ) ... </flop-bids>
         <flop-pad> PAD </flop-pad>
         <flop-tau> TAU </flop-tau>
      requires END <Int NOW
```

- dent(uint id, uint lot, uint bid)
- User action to make a bid for a smaller lot.

```k
    syntax FlopStep ::= "dent" Int Wad Rad
 // --------------------------------------
    rule <k> Flop . dent ID LOT BID
          => call Vat . move MSGSENDER GUY BID
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <currentTime> NOW </currentTime>
         <flop-bids>...
           ID |-> FlopBid(... bid: BID',
                              lot: LOT' => LOT,
                              guy: GUY => MSGSENDER,
                              tic: TIC => TIC +Int TTL,
                              end: END)
         ...</flop-bids>
         <flop-live> true </flop-live>
         <flop-beg> BEG </flop-beg>
         <flop-ttl> TTL </flop-ttl>
      requires (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool BID ==Rat BID'
       andBool LOT <Rat LOT'
       andBool LOT *Rat BEG <=Rat LOT'
```

- deal(uint id)
- Settles the auction.

```k
    syntax FlopStep ::= "deal" Int [klabel(FlopDeal),symbol]
 // --------------------------------------------------------
    rule <k> Flop . deal ID
          => call Gem "MKR" . mint GUY LOT
         ...
         </k>
         <currentTime> NOW </currentTime>
         <flop-bids>...
           ID |-> FlopBid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
         ...</flop-bids>
         <flop-live> true </flop-live>
      requires TIC =/=Int 0
       andBool (TIC <Int NOW orBool END <Int NOW)
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
    rule <k> Flop . yank ID
          => call Vat . move THIS GUY BID
         ...
         </k>
         <this> THIS </this>
         <flop-bids>...
           ID |-> FlopBid(... bid: BID, guy: GUY) => .Map
         ...</flop-bids>
         <flop-live> false </flop-live>
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

    syntax VowAuthStep ::= "fess" Rad
 // ---------------------------------
    rule <k> Vow . fess TAB => . ... </k>
         <currentTime> NOW </currentTime>
         <vow-sins>
           ...
           NOW |-> (SIN' => SIN' +Rat TAB)
           ...
         </vow-sins>
         <vow-sin> SIN => SIN +Rat TAB </vow-sin>

    syntax VowStep ::= "flog" Int
 // -----------------------------
    rule <k> Vow . flog ERA => . ... </k>
         <currentTime> NOW </currentTime>
         <vow-wait> WAIT </vow-wait>
         <vow-sins>... ERA |-> (SIN' => 0) </vow-sins>
         <vow-sin> SIN => SIN -Rat SIN' </vow-sin>
      requires ERA +Int WAIT <=Int NOW

    syntax VowStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vow . heal AMOUNT
          => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
      requires AMOUNT <=Rat DAI
       andBool AMOUNT <=Rat VATSIN -Rat SIN -Rat ASH
       andBool VATSIN >=Rat SIN +Rat ASH

    syntax VowStep ::= "kiss" Rad
 // -----------------------------
    rule <k> Vow . kiss AMOUNT
          => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vow-ash> ASH => ASH -Rat AMOUNT </vow-ash>
       requires AMOUNT <=Rat ASH
        andBool AMOUNT <=Rat DAI

    syntax VowStep ::= "flop"
 // -------------------------
    rule <k> Vow . flop
          => call Flop . kick THIS DUMP SUMP ... </k>
         <this> THIS </this>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH => ASH +Rat SUMP </vow-ash>
         <vow-sump> SUMP </vow-sump>
         <vow-dump> DUMP </vow-dump>
      requires SUMP <=Rat VATSIN -Rat SIN -Rat ASH
       andBool VATSIN >=Rat SIN +Rat ASH
       andBool DAI ==Int 0

    syntax VowStep ::= "flap"
 // -------------------------
    rule <k> Vow . flap
          => call Flap . kick BUMP 0 ... </k>
         <this> THIS </this>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
         <vow-bump> BUMP </vow-bump>
         <vow-hump> HUMP </vow-hump>
      requires DAI >=Rat VATSIN +Rat BUMP +Rat HUMP
       andBool VATSIN -Rat SIN -Rat ASH ==Rat 0

    syntax VowAuthStep ::= "cage"
 // -----------------------------
    rule <k> Vow . cage
          => call Flap . cage FLAPDAI
          ~> call Flop . cage
          ~> call Vat . heal minRat(DAI, VATSIN) ... </k>
         <this> THIS </this>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           address(Flap) |-> FLAPDAI
           ...
         </vat-dai>
         <vow-live> _ => false </vow-live>
         <vow-sin> _ => 0 </vow-sin>
         <vow-ash> _ => 0 </vow-ash>
```

```k
endmodule
```
