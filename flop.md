```k
requires "kmcd-driver.md"
requires "gem.md"
requires "vat.md"
requires "vow.md"
```

- dent(uint id, uint lot, uint bid)
- User action to make a bid for a smaller lot.

```k
module FLOP
    imports VOW
    imports PRE-FLOP

    syntax FlopStep ::= "dent" Int Wad Rad
 // --------------------------------------
    rule <k> Flop . dent ID LOT BID
          => #if MSGSENDER =/=K GUY #then call FLOP_VAT . move MSGSENDER GUY BID #else . #fi
          ~> #if TIC ==Int 0 #then call GUY . kiss ( minRad(BID, ASH) ) #else . #fi
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <current-time> NOW </current-time>
         <flop-vat> FLOP_VAT:VatContract </flop-vat>
         <vow-ash> ASH </vow-ash>
         <flop-bids> ... ID |-> FlopBid(... bid: BID', lot: LOT' => LOT, guy: GUY => MSGSENDER, tic: TIC => TIC +Int TTL, end: END) ... </flop-bids>
         <flop-live> true </flop-live>
         <flop-beg> BEG </flop-beg>
         <flop-ttl> TTL </flop-ttl>
      requires LOT >=Wad wad(0)
       andBool BID >=Rad rad(0)
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool BID ==Rad BID'
       andBool LOT <Wad LOT'
       andBool LOT *Wad BEG <=Wad LOT'
```

```k
endmodule
```

```k
module PRE-FLOP
    imports KMCD-DRIVER
    imports GEM
    imports VAT
```

Flop Configuration
------------------

```k
    configuration
      <flop-state>
        <flop-vat>   0:Address               </flop-vat>
        <flop-mkr>   0:Address               </flop-mkr>
        <flop-wards> .Set                    </flop-wards>
        <flop-bids>  .Map                    </flop-bids>  // mapping (uint => Bid) Int |-> FlopBid
        <flop-kicks>  0                      </flop-kicks>
        <flop-live>   true                   </flop-live>
        <flop-beg>    wad(105) /Wad wad(100) </flop-beg>
        <flop-pad>    wad(150) /Wad wad(100) </flop-pad>
        <flop-ttl>    3 hours                </flop-ttl>
        <flop-tau>    2 days                 </flop-tau>
        <flop-vow>    0:Address              </flop-vow>
      </flop-state>
```

```k
    syntax MCDContract ::= FlopContract
    syntax FlopContract ::= "Flop"
    syntax MCDStep ::= FlopContract "." FlopStep [klabel(flopStep)]
 // ---------------------------------------------------------------
    rule contract(Flop . _) => Flop
```

### Constructor

```k
    syntax FlopStep ::= "constructor" Address Address
 // -------------------------------------------------
    rule <k> Flop . constructor FLOP_VAT FLOP_MKR => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <flop-state> _ </flop-state>
        => <flop-state>
             <flop-vat> FLOP_VAT </flop-vat>
             <flop-mkr> FLOP_MKR </flop-mkr>
             <flop-wards> SetItem(MSGSENDER) </flop-wards>
             <flop-live> true </flop-live>
             ...
           </flop-state>
         )
```

Flop Authorization
------------------

```k
    syntax FlopStep ::= FlopAuthStep
    syntax AuthStep ::= FlopContract "." FlopAuthStep [klabel(flopStep)]
 // --------------------------------------------------------------------
    rule [[ wards(Flop) => WARDS ]] <flop-wards> WARDS </flop-wards>

    syntax FlopAuthStep ::= WardStep
 // -------------------------------
    rule <k> Flop . rely ADDR => . ... </k>
         <flop-wards> ... (.Set => SetItem(ADDR)) </flop-wards>

    rule <k> Flop . deny ADDR => . ... </k>
         <flop-wards> WARDS => WARDS -Set SetItem(ADDR) </flop-wards>
```

Flop Data
---------

-   `FlopBid` tracks the parameters of an auction:

    -   `bid`: current bid on auction.
    -   `lot`: quantity being auctioned off.
    -   `guy`: current high bidder.
    -   `tic`: expiration date of an auction, extended on new bids.
    -   `end`: global expiration date of an auction.

```k
    syntax FlopBid ::= FlopBid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int )
 // -----------------------------------------------------------------------------------
```

File-able Fields
----------------

The parameters controlled by governance are:

-   `beg`: minimum increase in bid size.
-   `ttl`: time increase for auction duration when receiving new bids.
-   `tau`: total auction duration length.
-   `pad`: lot increase factor for each `tick`.

```k
    syntax FlopAuthStep ::= "file" FlopFile
 // ---------------------------------------

    syntax FlopFile ::= "beg" Wad
                      | "ttl" Int
                      | "tau" Int
                      | "pad" Wad
                      | "vow-file" Address
 // --------------------------------------
    rule <k> Flop . file beg BEG => . ... </k>
         <flop-beg> _ => BEG </flop-beg>
      requires BEG >=Wad wad(0)

    rule <k> Flop . file ttl TTL => . ... </k>
         <flop-ttl> _ => TTL </flop-ttl>
      requires TTL >=Int 0

    rule <k> Flop . file tau TAU => . ... </k>
         <flop-tau> _ => TAU </flop-tau>
      requires TAU >=Int 0

    rule <k> Flop . file pad PAD => . ... </k>
         <flop-pad> _ => PAD </flop-pad>
      requires PAD >=Wad wad(0)

    rule <k> Flop . file vow-file ADDR => . ... </k>
         <flop-vow> _ => ADDR </flop-vow>
```

Flop Events
-----------

```k
    syntax CustomEvent ::= FlopKick(Int, Wad, Rad, Address) [klabel(FlopKick), symbol]
 // ----------------------------------------------------------------------------------
```

Flop Semantics
--------------

- kick(address gal, uint lot, uint bid) returns (uint id)
- Starts an auction

```k
    syntax FlopAuthStep ::= "kick" Address Wad Rad
 // ----------------------------------------------
    rule <k> Flop . kick GAL LOT BID
          => KICKS +Int 1
         ...
         </k>
         <current-time> NOW </current-time>
         <flop-live> true </flop-live>
         <flop-bids> ... .Map => KICKS +Int 1 |-> FlopBid(... bid: BID, lot: LOT, guy: GAL, tic: 0, end: NOW +Int TAU) ... </flop-bids>
         <flop-kicks> KICKS => KICKS +Int 1 </flop-kicks>
         <flop-tau> TAU </flop-tau>
         <frame-events> ... (.List => ListItem(FlopKick(KICKS +Int 1, LOT, BID, GAL))) </frame-events>
      requires LOT >=Wad wad(0)
       andBool BID >=Rad rad(0)
```

- tick(uint id)
- Extends the end time of the auction when no one has made a bid

```k
    syntax FlopStep ::= "tick" Int
 // ------------------------------
    rule <k> Flop . tick ID => . ... </k>
         <current-time> NOW </current-time>
         <flop-bids> ... ID |-> FlopBid(... lot: LOT => LOT *Wad PAD, tic: 0, end: END => NOW +Int TAU ) ... </flop-bids>
         <flop-pad> PAD </flop-pad>
         <flop-tau> TAU </flop-tau>
      requires END <Int NOW
```

- deal(uint id)
- Settles the auction.

```k
    syntax FlopStep ::= "deal" Int [klabel(FlopDeal),symbol]
 // --------------------------------------------------------
    rule <k> Flop . deal ID
          => call FLOP_MKR . mint GUY LOT
         ...
         </k>
         <current-time> NOW </current-time>
         <flop-mkr> FLOP_MKR:GemContract </flop-mkr>
         <flop-bids> ... ID |-> FlopBid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map ... </flop-bids>
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
          => call FLOP_VAT . suck VOWADDR GUY BID
         ...
         </k>
         <flop-vat> FLOP_VAT:VatContract </flop-vat>
         <flop-bids> ... ID |-> FlopBid(... bid: BID, guy: GUY) => .Map ... </flop-bids>
         <flop-live> false </flop-live>
         <flop-vow> VOWADDR </flop-vow>
```

```k
endmodule
```
