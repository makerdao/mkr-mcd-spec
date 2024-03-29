```k
requires "kmcd-driver.md"
requires "gem.md"
requires "vat.md"

module FLAP
    imports KMCD-DRIVER
    imports GEM
    imports VAT
```

Flap Configuration
------------------

```k
    configuration
      <flap-state>
        <flap-vat>   0:Address              </flap-vat>
        <flap-mkr>   0:Address              </flap-mkr>
        <flap-wards> .Set                   </flap-wards>
        <flap-bids>  .Map                   </flap-bids>  // mapping (uint => Bid) Int |-> FlapBid
        <flap-kicks> 0                      </flap-kicks>
        <flap-live>  true                   </flap-live>
        <flap-beg>   wad(105) /Wad wad(100) </flap-beg>
        <flap-ttl>   3 hours                </flap-ttl>
        <flap-tau>   2 days                 </flap-tau>
      </flap-state>
```

Flap Semantics
--------------

```k
    syntax MCDContract ::= FlapContract
    syntax FlapContract ::= "Flap"
    syntax MCDStep ::= FlapContract "." FlapStep [klabel(flapStep)]
 // ---------------------------------------------------------------
    rule contract(Flap . _) => Flap
```

### Constructor

```k
    syntax FlapStep ::= "constructor" Address Address
 // -------------------------------------------------
    rule <k> Flap . constructor FLAP_VAT FLAP_MKR => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <flap-state> _ </flap-state>
        => <flap-state>
             <flap-vat> FLAP_VAT:VatContract </flap-vat>
             <flap-mkr> FLAP_MKR:GemContract </flap-mkr>
             <flap-wards> SetItem(MSGSENDER) </flap-wards>
             <flap-live> true </flap-live>
             ...
           </flap-state>
         )
```

Flap Authorization
------------------

```k
    syntax FlapStep ::= FlapAuthStep
    syntax AuthStep ::= FlapContract "." FlapAuthStep [klabel(flapStep)]
 // --------------------------------------------------------------------
    rule [[ wards(Flap) => WARDS ]] <flap-wards> WARDS </flap-wards>

    syntax FlapAuthStep ::= WardStep
 // --------------------------------
    rule <k> Flap . rely ADDR => . ... </k>
         <flap-wards> ... (.Set => SetItem(ADDR)) </flap-wards>

    rule <k> Flap . deny ADDR => . ... </k>
         <flap-wards> WARDS => WARDS -Set SetItem(ADDR) </flap-wards>
```

Flap Data
---------

-   `FlapBid` tracks parameters of each auction:

    -   `bid`: current high bid.
    -   `lot`: quantity being bid on.
    -   `guy`: current high bidder.
    -   `tic`: expiration time of auction (updated on bids).
    -   `end`: global expiration time of auction (set at start).

```k
    syntax FlapBid ::= FlapBid ( bid: Wad, lot: Rad, guy: Address, tic: Int, end: Int )
 // -----------------------------------------------------------------------------------
```

File-able Fields
----------------

The parameters controlled by governance are:

-   `beg`: minimum increase in bid size.
-   `ttl`: time increase for auction duration when receiving new bids.
-   `tau`: total auction duration length.

```k
    syntax FlapAuthStep ::= "file" FlapFile
 // ---------------------------------------

    syntax FlapFile ::= "beg" Wad
                      | "ttl" Int
                      | "tau" Int
 // -----------------------------
    rule <k> Flap . file beg BEG => . ... </k>
         <flap-beg> _ => BEG </flap-beg>
      requires BEG >=Wad wad(0)

    rule <k> Flap . file ttl TTL => . ... </k>
         <flap-ttl> _ => TTL </flap-ttl>
      requires TTL >=Int 0

    rule <k> Flap . file tau TAU => . ... </k>
         <flap-tau> _ => TAU </flap-tau>
      requires TAU >=Int 0
```

Flap Events
-----------

```k
    syntax CustomEvent ::= FlapKick(Address, Int, Rad, Wad) [klabel(FlapKick), symbol]
 // ----------------------------------------------------------------------------------
```

Flap Semantics
--------------

- kick(uint lot, uint bid) returns (uint id)
- Starts a new surplus auction for a lot amount

```k
    syntax FlapAuthStep ::= "kick" Rad Wad
 // --------------------------------------
    rule <k> Flap . kick LOT BID
          => call FLAP_VAT . move MSGSENDER THIS LOT
          ~> KICKS +Int 1
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flap-vat> FLAP_VAT:VatContract </flap-vat>
         <flap-bids> ... .Map => KICKS +Int 1 |-> FlapBid(... bid: BID, lot: LOT, guy: MSGSENDER, tic: 0, end: NOW +Int TAU) ... </flap-bids>
         <flap-kicks> KICKS => KICKS +Int 1 </flap-kicks>
         <flap-live> true </flap-live>
         <flap-tau> TAU </flap-tau>
         <frame-events> ... (.List => ListItem(FlapKick(MSGSENDER, KICKS +Int 1, LOT, BID))) </frame-events>
      requires LOT >=Rad rad(0)
       andBool BID >=Wad wad(0)
```

- tick(uint id)
- Extends the end time of the auction if no one has bid yet

```k
    syntax FlapStep ::= "tick" Int [klabel(FlapTick),symbol]
 // --------------------------------------------------------
    rule <k> Flap . tick BID_ID => . ... </k>
         <current-time> NOW </current-time>
         <flap-bids> ... BID_ID |-> FlapBid(... tic: 0, end: END => NOW +Int TAU) ... </flap-bids>
         <flap-tau> TAU </flap-tau>
      requires END <Int NOW
```

- tend(uint id, uint lot, uint bid)
- Places a bid made by the user. Refunds the previous bidder's bid.

```k
    syntax FlapStep ::= "tend" Int Rad Wad
 // --------------------------------------
    rule <k> Flap . tend BID_ID LOT BID
          => #if MSGSENDER =/=K GUY #then call FLAP_MKR . move MSGSENDER GUY BID' #else . #fi
          ~> call FLAP_MKR . move MSGSENDER THIS (BID -Wad BID')
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flap-mkr> FLAP_MKR:GemContract </flap-mkr>
         <flap-bids> ... BID_ID |-> FlapBid(... bid: BID' => BID, lot: LOT', guy: GUY => MSGSENDER, tic: TIC => TIC +Int TTL, end: END) ... </flap-bids>
         <flap-live> true </flap-live>
         <flap-ttl> TTL </flap-ttl>
         <flap-beg> BEG </flap-beg>
      requires LOT >=Rad rad(0)
       andBool BID >=Wad wad(0)
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END  >Int NOW
       andBool LOT ==Rad LOT'
       andBool BID  >Wad BID'
       andBool BID >=Wad BID' *Wad BEG
```

- deal(uint id)
- Settles an auction, rewarding the lot to the highest bidder and burning their bid

```k
    syntax FlapStep ::= "deal" Int [klabel(FlapDeal),symbol]
 // --------------------------------------------------------
    rule <k> Flap . deal BID_ID
          => call FLAP_VAT . move THIS GUY LOT
          ~> call FLAP_MKR . burn THIS BID
         ...
         </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flap-vat> FLAP_VAT:VatContract </flap-vat>
         <flap-mkr> FLAP_MKR:GemContract </flap-mkr>
         <flap-bids> ... BID_ID |-> FlapBid(... bid: BID, lot: LOT, guy: GUY, tic: TIC, end: END) => .Map ... </flap-bids>
         <flap-live> true </flap-live>
      requires TIC =/=Int 0
       andBool (TIC <Int NOW orBool END <Int NOW)
```

- cage(uint rad)
- Part of Global Settlement. Freezes the auction house.

```k
    syntax FlapAuthStep ::= "cage" Rad
 // ----------------------------------
    rule <k> Flap . cage AMOUNT => call FLAP_VAT . move THIS MSGSENDER AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flap-vat> FLAP_VAT:VatContract </flap-vat>
         <flap-live> _ => false </flap-live>
      requires AMOUNT >=Rad rad(0)
```

- yank(uint id)
- Part of Global Settlement. Refunds the highest bidder's bid.

```k
    syntax FlapStep ::= "yank" Int [klabel(FlapYank), symbol]
 // ---------------------------------------------------------
    rule <k> Flap . yank BID_ID => call FLAP_MKR . move THIS GUY BID ... </k>
         <this> THIS </this>
         <flap-mkr> FLAP_MKR:GemContract </flap-mkr>
         <flap-bids> ... BID_ID |-> FlapBid(... bid: BID, guy: GUY) => .Map ... </flap-bids>
         <flap-live> false </flap-live>
```

```k
endmodule
```
