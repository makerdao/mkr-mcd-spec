```k
requires "kmcd-driver.md"
requires "vat.md"

module FLIP
    imports KMCD-DRIVER
    imports VAT
```

Flip Configuration
------------------

```k
    configuration
      <flips>
        <flip multiplicity="*" type="Map">
          <flip-ilk>   ""                     </flip-ilk>
          <flip-wards> .Set                   </flip-wards>
          <flip-bids>  .Map                   </flip-bids> // mapping (uint => Bid) Int |-> FlipBid
          <flip-beg>   wad(105) /Wad wad(100) </flip-beg>  // Minimum Bid Increase
          <flip-ttl>   3 hours                </flip-ttl>  // Single Bid Lifetime
          <flip-tau>   2 days                 </flip-tau>  // Total Auction Length
          <flip-kicks> 0                      </flip-kicks>
        </flip>
      </flips>
```

```k
    syntax MCDContract ::= FlipContract
    syntax FlipContract ::= "Flip" String
    syntax MCDStep ::= FlipContract "." FlipStep [klabel(flipStep)]
 // ---------------------------------------------------------------
    rule contract(Flip ILK_ID . _) => Flip ILK_ID
```

Flip Authorization
------------------

```k
    syntax FlipStep ::= FlipAuthStep
    syntax AuthStep ::= FlipContract "." FlipAuthStep [klabel(flipStep)]
 // --------------------------------------------------------------------
    rule [[ wards(Flip ILK_ID) => WARDS ]] <flip> <flip-ilk> ILK_ID </flip-ilk> <flip-wards> WARDS </flip-wards> ... </flip>

    syntax FlipAuthStep ::= WardStep
 // --------------------------------
    rule <k> Flip ILK_ID . rely ADDR => . ... </k>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-wards> ... (.Set => SetItem(ADDR)) </flip-wards>
           ...
         </flip>

    rule <k> Flip ILK_ID . deny ADDR => . ... </k>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-wards> WARDS => WARDS -Set SetItem(ADDR) </flip-wards>
           ...
         </flip>
```

Flip Data
---------

-   `FlipBid` tracks parameters of a given Flipper auction:

    -   `bid`: the current bid.
    -   `lot`: the quantity being auctioned off.
    -   `guy`: current high bidder.
    -   `tic`: expiration time of auction (updated on bids).
    -   `end`: global expiration time of auction (set at start).
    -   `usr`: receives collateral gems from the auction.
    -   `gal`: receives Dai from the auction.
    -   `tab`: total Dai wanted for auction.

```k
    syntax FlipBid ::= FlipBid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int, usr: Address, gal: Address, tab: Rad )
 // -------------------------------------------------------------------------------------------------------------------------
```

File-able Fields
----------------

The parameters controlled by governance are:

-   `beg`: minimum increase in bid size.
-   `ttl`: time increase for auction duration when receiving new bids.
-   `tau`: total auction duration length.

```k
    syntax FlipAuthStep ::= "file" FlipFile
 // ---------------------------------------

    syntax FlipFile ::= "beg" Wad
                      | "ttl" Int
                      | "tau" Int
 // -----------------------------
    rule <k> Flip ILK_ID . file beg BEG => . ... </k>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-beg> _ => BEG </flip-beg>
           ...
         </flip>
      requires BEG >=Wad wad(0)

    rule <k> Flip ILK_ID . file ttl TTL => . ... </k>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-ttl> _ => TTL </flip-ttl>
           ...
         </flip>
      requires TTL >=Int 0

    rule <k> Flip ILK_ID . file tau TAU => . ... </k>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-tau> _ => TAU </flip-tau>
           ...
         </flip>
      requires TAU >=Int 0
```

Flip Events
-----------

```k
    syntax Event ::= FlipKick(Address, String, Int, Wad, Rad, Rad, Address, Address) [klabel(FlipKick), symbol]
 // -----------------------------------------------------------------------------------------------------------
```

Flip Initialization
-------------------

-   `init` initializes a `<flip>` sub-configuration contract for a given ilk.

```k
    syntax FlipAuthStep ::= "init"
 // ------------------------------
    rule <k> Flip ILK_ID . init => . ... </k>
         <flips> ... (.Bag => <flip> <flip-ilk> ILK_ID </flip-ilk> ... </flip>) ... </flips>
```

Flip Semantics
--------------

```k
    syntax FlipAuthStep ::= "kick" Address Address Rad Wad Rad
 // ----------------------------------------------------------
    rule <k> Flip ILK_ID . kick USR GAL TAB LOT BID
          => call Vat . flux ILK_ID MSGSENDER THIS LOT
          ~> KICKS +Int 1
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-tau> TAU </flip-tau>
           <flip-kicks> KICKS => KICKS +Int 1 </flip-kicks>
           <flip-bids> ... .Map => KICKS +Int 1 |-> FlipBid( ... bid: BID, lot: LOT, guy: MSGSENDER, tic: 0, end: NOW +Int TAU, usr: USR, gal: GAL, tab: TAB ) ... </flip-bids>
           ...
         </flip>
         <frame-events> ... (.List => ListItem(FlipKick(MSGSENDER, ILK_ID, KICKS +Int 1, LOT, BID, TAB, USR, GAL))) </frame-events>
      requires TAB >=Rad rad(0)
       andBool LOT >=Wad wad(0)
       andBool BID >=Rad rad(0)

    syntax FlipStep ::= "tick" Int
 // ------------------------------
    rule <k> Flip ILK_ID . tick ID => . ... </k>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-tau> TAU </flip-tau>
           <flip-bids> ... ID |-> FlipBid(... tic: TIC, end: END => NOW +Int TAU) ... </flip-bids>
           ...
         </flip>
      requires END  <Int NOW
       andBool TIC ==Int 0

    syntax FlipStep ::= "tend" Int Wad Rad
 // --------------------------------------
    rule <k> Flip ILK_ID . tend ID LOT BID
          => #if MSGSENDER =/=K GUY #then call Vat . move MSGSENDER GUY BID' #else . #fi
          ~> call Vat . move MSGSENDER GAL (BID -Rad BID')
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-beg> BEG </flip-beg>
           <flip-ttl> TTL </flip-ttl>
           <flip-bids> ... ID |-> FlipBid(... bid: BID' => BID, lot: LOT', guy: GUY => MSGSENDER, tic: TIC => NOW +Int TTL, end: END, gal: GAL, tab: TAB) ... </flip-bids>
           ...
         </flip>
      requires LOT >=Wad wad(0)
       andBool BID >=Rad rad(0)
       andBool GUY =/=K 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool LOT ==Wad LOT'
       andBool BID <=Rad TAB
       andBool BID >Rad BID'
       andBool (BID >=Rad Wad2Rad(BEG) *Rad BID' orBool BID ==Rad TAB)

    syntax FlipStep ::= "dent" Int Wad Rad
 // --------------------------------------
    rule <k> Flip ILK_ID . dent ID LOT BID
          => #if MSGSENDER =/=K GUY #then call Vat . move MSGSENDER GUY BID #else . #fi
          ~> call Vat.flux ILK_ID THIS USR (LOT' -Wad LOT)
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-beg> BEG </flip-beg>
           <flip-ttl> TTL </flip-ttl>
           <flip-bids> ... ID |-> FlipBid(... bid: BID', lot: LOT' => LOT, guy: GUY => MSGSENDER, tic: TIC => NOW +Int TTL, end: END, usr: USR, tab: TAB) ... </flip-bids>
           ...
         </flip>
      requires LOT >=Wad wad(0)
       andBool BID >=Rad rad(0)
       andBool GUY =/=K 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool BID ==Rad BID'
       andBool BID ==Rad TAB
       andBool LOT <Wad LOT'
       andBool BEG *Wad LOT <Wad LOT'

    syntax FlipStep ::= "deal" Int
 // ------------------------------
    rule <k> Flip ILK_ID . deal ID => call Vat . flux ILK_ID THIS GUY LOT ... </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-bids> ... ID |-> FlipBid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map ... </flip-bids>
           ...
         </flip>
      requires TIC =/=Int 0
       andBool (TIC <Int NOW orBool END <Int NOW)

    syntax FlipAuthStep ::= "yank" Int
 // ----------------------------------
    rule <k> Flip ILK_ID . yank ID
          => call Vat . flux ILK_ID THIS MSGSENDER LOT
          ~> call Vat . move MSGSENDER GUY BID
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-bids> ... ID |-> FlipBid(... bid: BID, lot: LOT, guy: GUY, tab: TAB) => .Map ... </flip-bids>
           ...
         </flip>
      requires GUY =/=K 0 andBool BID <Rad TAB
```

```k
endmodule
```
