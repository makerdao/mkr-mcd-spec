```k
requires "kmcd-driver.k"
requires "gem.k"
requires "vat.k"

module FLOP
    imports KMCD-DRIVER
    imports GEM
    imports VAT
```

```k
    syntax Bid ::= FlopBid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int )
 // -------------------------------------------------------------------------------
```

Flop Configuration
------------------

```k
    configuration
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

    syntax Event ::= FlopKick(Int, Wad, Rad, Address)
 // -------------------------------------------------
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
         <frame-events> _ => ListItem(FlopKick(KICKS +Int 1, LOT, BID, GAL)) </frame-events>
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

```k
endmodule
```
