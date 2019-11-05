```k
requires "kmcd-driver.k"
requires "vat.k"

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
          <flip-ilk>   ""           </flip-ilk>
          <flip-wards> .Set         </flip-wards>
          <flip-bids>  .Map         </flip-bids> // mapping (uint => Bid)     Int     |-> FlipBid
          <flip-beg>   105 /Rat 100 </flip-beg>  // Minimum Bid Increase
          <flip-ttl>   3 hours      </flip-ttl>  // Single Bid Lifetime
          <flip-tau>   2 days       </flip-tau>  // Total Auction Length
          <flip-kicks> 0            </flip-kicks>
        </flip>
      </flips>
```

```k
    syntax MCDContract ::= FlipContract
    syntax FlipContract ::= "Flip" String
    syntax MCDStep ::= FlipContract "." FlipStep [klabel(flipStep)]
 // ---------------------------------------------------------------
    rule contract(Flip ILKID . _) => Flip ILKID
```

Flip Authorization
------------------

```k
    syntax FlipStep ::= FlipAuthStep
    syntax AuthStep ::= FlipContract "." FlipAuthStep [klabel(flipStep)]
 // --------------------------------------------------------------------
    rule [[ wards(Flip ILKID) => WARDS ]] <flip> <flip-ilk> ILKID </flip-ilk> <flip-wards> WARDS </flip-wards> ... </flip>

    syntax FlipAuthStep ::= WardStep
 // --------------------------------
    rule <k> Flip ILKID . rely ADDR => . ... </k>
         <flip>
           <flip-ilk> ILKID </flip-ilk>
           <flip-wards> ... (.Set => SetItem(ADDR)) </flip-wards>
           ...
         </flip>

    rule <k> Flip ILKID . deny ADDR => . ... </k>
         <flip>
           <flip-ilk> ILKID </flip-ilk>
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
    syntax Bid ::= FlipBid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int, usr: Address, gal: Address, tab: Rad )
 // ---------------------------------------------------------------------------------------------------------------------
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

    syntax FlipFile ::= "beg" Ray
                      | "ttl" Int
                      | "tau" Int
 // -----------------------------
    rule <k> Flip ILKID . file beg BEG => . ... </k>
         <flip>
           <flip-ilk> ILKID </flip-ilk>
           <flip-beg> _ => BEG </flip-beg>
           ...
         </flip>

    rule <k> Flip ILKID . file ttl TTL => . ... </k>
         <flip>
           <flip-ilk> ILKID </flip-ilk>
           <flip-ttl> _ => TTL </flip-ttl>
           ...
         </flip>

    rule <k> Flip ILKID . file tau TAU => . ... </k>
         <flip>
           <flip-ilk> ILKID </flip-ilk>
           <flip-tau> _ => TAU </flip-tau>
           ...
         </flip>
```

Flip Events
-----------

```k
    syntax Event ::= FlipKick(Int, Wad, Rad, Rad, Address, Address)
 // ---------------------------------------------------------------
```

Flip Initialization
-------------------

-   `init` initializes a `<flip>` sub-configuration contract for a given ilk.

```k
    syntax FlipAuthStep ::= "init"
 // ------------------------------
    rule <k> Flip ILK . init => . ... </k>
         <flips> ... (.Bag => <flip> <flip-ilk> ILK </flip-ilk> ... </flip>) ... </flips>
```

Flip Semantics
--------------

```k
    syntax FlipAuthStep ::= "kick" Address Address Rad Wad Rad
 // ----------------------------------------------------------
    rule <k> Flip ILK . kick USR GAL TAB LOT BID
          => call Vat . flux ILK MSGSENDER THIS LOT
          ~> KICKS +Int 1 ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-tau> TAU </flip-tau>
           <flip-kicks> KICKS => KICKS +Int 1 </flip-kicks>
           <flip-bids>
             ...
             .Map => KICKS +Int 1 |-> FlipBid( ... bid: BID, lot: LOT, guy: MSGSENDER, tic: 0, end: NOW +Int TAU, usr: USR, gal: GAL, tab: TAB )
             ...
           </flip-bids>
           ...
         </flip>
         <frame-events> _ => ListItem(FlipKick(KICKS +Int 1, LOT, BID, TAB, USR, GAL)) </frame-events>

    syntax FlipStep ::= "tick" Int
 // ------------------------------
    rule <k> Flip ILK . tick ID => . ... </k>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-tau> TAU </flip-tau>
           <flip-bids>
             ...
             ID |-> FlipBid(... tic: TIC, end: END => NOW +Int TAU)
             ...
           </flip-bids>
           ...
         </flip>
      requires END  <Int NOW
       andBool TIC ==Int 0

    syntax FlipStep ::= "tend" Int Wad Rad
 // --------------------------------------
    rule <k> Flip ILK . tend ID LOT BID
          => call Vat . move MSGSENDER GUY BID'
          ~> call Vat . move MSGSENDER GAL (BID -Rat BID') ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-beg> BEG </flip-beg>
           <flip-ttl> TTL </flip-ttl>
           <flip-bids>
             ...
             ID |-> FlipBid(... bid: BID' => BID, lot: LOT', guy: GUY => MSGSENDER, tic: TIC => NOW +Int TTL, end: END, gal: GAL, tab: TAB)
           ...
           </flip-bids>
           ...
         </flip>
      requires GUY =/=K 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool LOT ==Rat LOT'
       andBool BID <=Rat TAB
       andBool BID >Rat BID'
       andBool (BID >=Rat BEG *Rat BID' orBool BID ==Rat TAB)

    syntax FlipStep ::= "dent" Int Wad Rad
 // --------------------------------------
    rule <k> Flip ILK . dent ID LOT BID
          => call Vat.move MSGSENDER GUY BID
          ~> call Vat.flux ILK THIS USR (LOT' -Rat LOT) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-beg> BEG </flip-beg>
           <flip-ttl> TTL </flip-ttl>
           <flip-bids>
             ...
             ID |-> FlipBid(... bid: BID', lot: LOT' => LOT, guy: GUY => MSGSENDER, tic: TIC => NOW +Int TTL, end: END, usr: USR, tab: TAB)
             ...
           </flip-bids>
           ...
         </flip>
      requires GUY =/=K 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool BID ==Rat BID'
       andBool BID ==Rat TAB
       andBool LOT <Rat LOT'
       andBool BEG *Rat LOT <Rat LOT'

    syntax FlipStep ::= "deal" Int
 // ------------------------------
    rule <k> Flip ILK . deal ID => call Vat . flux ILK THIS GUY LOT ... </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-bids>
             ...
             ID |-> FlipBid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
             ...
           </flip-bids>
           ...
         </flip>
      requires TIC =/=Int 0
       andBool (TIC <Int NOW orBool END <Int NOW)

    syntax FlipAuthStep ::= "yank" Int
 // ----------------------------------
    rule <k> Flip ILK . yank ID
          => call Vat . flux ILK THIS MSGSENDER LOT
          ~> call Vat . move MSGSENDER GUY BID ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-bids>
             ...
             ID |-> FlipBid(... bid: BID, lot: LOT, guy: GUY, tab: TAB) => .Map
             ...
           </flip-bids>
           ...
         </flip>
      requires GUY =/=K 0 andBool BID <Rat TAB
```

```k
endmodule
```
