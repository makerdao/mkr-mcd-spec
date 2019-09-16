Collateral Manipulation
=======================

This module provides the link between collateral types and the [cdp-core].

```k
requires "cdp-core.k"
requires "dai.k"

module COLLATERAL
    imports CDP-CORE
    imports DAI

    configuration
      <collateral>
        <flippers>
          <flipper multiplicity="*" type="Map">
            <flip-ilk> 0 </flip-ilk>
            <flipStack> .List </flipStack>
            <flip>
              <flip-ward>  .Map         </flip-ward> // mapping (address => uint) Address |-> Bool
              <flip-bids>  .Map         </flip-bids> // mapping (uint => Bid)     Int     |-> Bid
              <flip-beg>   105 /Rat 100 </flip-beg>  // Minimum Bid Increase
              <flip-ttl>   3 hours      </flip-ttl>  // Single Bid Lifetime
              <flip-tau>   2 days       </flip-tau>  // Total Auction Length
              <flip-kicks> 0            </flip-kicks>
            </flip>
          </flipper>
        </flippers>
      </collateral>

    syntax Bid ::= Bid ( bid: Int, lot: Int, guy: Address, tic: Int, end: Int, usr: Address, gal: Address, tab: Int )
 // -----------------------------------------------------------------------------------------------------------------

    syntax MCDStep ::= "Flip" Int "." FlipStep
 // ------------------------------------------
    rule <k> step [ Flip F . FAS:FlipAuthStep ] => Flip F . push ~> Flip F . auth ~> Flip F . FAS ~> Flip F . catch ... </k>
    rule <k> step [ Flip F . FS               ] => Flip F . push ~>                  Flip F . FS  ~> Flip F . catch ... </k>
      requires notBool isFlipAuthStep(FS)


    syntax FlipStep ::= FlipAuthStep
 // --------------------------------

    syntax FlipAuthStep ::= AuthStep
 // --------------------------------

    syntax FlipAuthStep ::= WardStep
 // --------------------------------

    syntax FlipStep ::= StashStep
 // -----------------------------

    syntax FlipStep ::= ExceptionStep
 // ---------------------------------

    syntax FlipStep ::= "kick" Address Address Int Int Int
 // ------------------------------------------------------
    rule <k> Flip ILK . kick USR GAL TAB LOT BID
          => Vat . flux ILK MSGSENDER THIS LOT
          ~> KICKS +Int 1 ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-tau> TAU </flip-tau>
         <flip-kicks> KICKS => KICKS +Int 1 </flip-kicks>
         <flip-bids>... .Map =>
           KICKS +Int 1 |-> Bid(...
                             bid: BID,
                             lot: LOT,
                             guy: MSGSENDER,
                             tic: 0,
                             end: NOW +Int TAU,
                             usr: USR,
                             gal: GAL,
                             tab: TAB)
         ...</flip-bids>

    syntax FlipStep ::= "tick" Int
 // ------------------------------
    rule <k> Flip ILK . tick ID => Flip ILK . exception ... </k>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... tic: TIC, end: END)
         ...</flip-bids>
      requires notBool canTick(NOW, TIC, END)

    rule <k> Flip ILK . tick ID => . ... </k>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids> BIDS </flip-bids>
      requires notBool ID in_keys(BIDS)

    rule <k> Flip ILK . tick ID => . ... </k>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-tau> TAU </flip-tau>
         <flip-bids>...
           ID |-> Bid(... tic: TIC, end: END => NOW +Int TAU)
         ...</flip-bids>
      requires canTick(NOW, TIC, END)

    syntax Bool ::= canTick(now: Int, tic: Int, end: Int) [function]
 // ----------------------------------------------------------------
    rule canTick(NOW, TIC, END) => END <Int NOW andBool TIC ==Int 0

    syntax FlipStep ::= "tend" Int Int Int
 // --------------------------------------
    rule <k> Flip ILK . tend ID LOT BID => Flip ILK . exception ... </k>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-beg> BEG </flip-beg>
         <flip-bids>...
           ID |-> AUCTION
         ...</flip-bids>
      requires notBool canTend(LOT, BID, NOW, BEG, AUCTION)

    rule <k> Flip ILK . tend ID _ _ => Flip ILK . exception ... </k>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids> BIDS </flip-bids>
      requires notBool ID in_keys(BIDS)

    rule <k> Flip ILK . tend ID LOT BID
          => Vat . move MSGSENDER GUY HIGHBID
          ~> Vat . move MSGSENDER GAL (BID -Int HIGHBID) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-beg> BEG </flip-beg>
         <flip-ttl> TTL </flip-ttl>
         <flip-bids>...
           ID |-> (Bid(... bid: HIGHBID => BID, guy: GUY => MSGSENDER, tic: _ => NOW +Int TTL, gal: GAL) #as AUCTION)
         ...</flip-bids>
      requires canTend(LOT, BID, NOW, BEG, AUCTION)

    syntax Bool ::= canTend(lot: Int, bid: Int, now: Int, beg: Int, auction: Bid) [function]
 // ----------------------------------------------------------------------------------------
    rule canTend(...                     auction: Bid(... guy: 0                )) => false
    rule canTend(... now: NOW,           auction: Bid(... tic: TIC              )) => false requires TIC <=Int NOW andBool TIC =/=Int 0
    rule canTend(... now: NOW,           auction: Bid(... end: END              )) => false requires END <=Int NOW
    rule canTend(... lot: LOT,           auction: Bid(... lot: LOT'             )) => false requires LOT =/=Int LOT'
    rule canTend(... bid: BID,           auction: Bid(... tab: TAB              )) => false requires BID >Int TAB
    rule canTend(... bid: BID,           auction: Bid(... bid: HIGHBID          )) => false requires BID <=Int HIGHBID
    rule canTend(... bid: BID, beg: BEG, auction: Bid(... bid: HIGHBID, tab: TAB)) => false requires BID <Rat BEG *Rat HIGHBID andBool BID =/=Int TAB
    rule canTend(...)                                                              => true  [owise]

    syntax FlipStep ::= "dent" Int Int Int
 // --------------------------------------
    rule <k> Flip ILK . dent ID LOT BID => Flip ILK . exception ... </k>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-beg> BEG </flip-beg>
         <flip-bids>...
           ID |-> AUCTION
         ...</flip-bids>
      requires notBool canDent(LOT, BID, NOW, BEG, AUCTION)

    rule <k> Flip ILK . dent ID _ _ => Flip ILK . exception ... </k>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids> BIDS </flip-bids>
      requires notBool ID in_keys(BIDS)

    rule <k> Flip ILK . dent ID LOT BID
          => Vat.move MSGSENDER GUY BID
          ~> Vat.flux ILK THIS USR (LOT' -Int LOT) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-beg> BEG </flip-beg>
         <flip-ttl> TTL </flip-ttl>
         <flip-bids>...
           ID |-> (Bid(... lot: LOT' => LOT, guy: GUY => MSGSENDER, tic: _ => NOW +Int TTL, usr: USR) #as AUCTION)
         ...</flip-bids>
      requires notBool canDent(LOT, BID, NOW, BEG, AUCTION)

    syntax Bool ::= canDent(lot: Int, bid: Int, now: Int, beg: Int, auction: Bid) [function]
 // ----------------------------------------------------------------------------------------
    rule canDent(...                     auction: Bid(... guy: 0      )) => false
    rule canDent(... now: NOW,           auction: Bid(... tic: TIC    )) => false requires TIC <=Int NOW andBool TIC =/=Int 0
    rule canDent(... now: NOW,           auction: Bid(... end: END    )) => false requires END <=Int NOW
    rule canDent(... bid: BID,           auction: Bid(... bid: HIGHBID)) => false requires BID =/=Int HIGHBID
    rule canDent(... bid: BID,           auction: Bid(... tab: TAB    )) => false requires BID =/=Int TAB
    rule canDent(... lot: LOT,           auction: Bid(... lot: LOT'   )) => false requires LOT >=Int LOT'
    rule canDent(... lot: LOT, beg: BEG, auction: Bid(... lot: LOT'   )) => false requires BEG *Rat LOT >=Rat LOT'
    rule canDent(...)                                                    => true  [owise]

    syntax FlipStep ::= "deal" Int
 // ------------------------------
    rule <k> Flip ILK . deal ID => Flip ILK . exception ... </k>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... tic: TIC, end: END)
         ...</flip-bids>
      requires notBool canDeal(NOW, TIC, END)

    rule <k> Flip ILK . deal ID => Flip ILK . exception ... </k>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids> BIDS </flip-bids>
      requires notBool ID in_keys(BIDS)

    rule <k> Flip ILK . deal ID => Vat . flux ILK THIS GUY LOT ... </k>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
         ...</flip-bids>
      requires canDeal(NOW, TIC, END)

    syntax Bool ::= canDeal(now: Int, tic: Int, end: Int) [function]
 // ----------------------------------------------------------------
    rule canDeal(NOW, TIC, END) => TIC =/=Int 0 andBool (TIC <Int NOW orBool END <Int NOW)

    syntax FlipStep ::= "yank" Int
 // ------------------------------
    rule <k> Flip ILK . yank ID => Flip ILK . exception ... </k>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... bid: BID, guy: GUY, tab: TAB)
         ...</flip-bids>
      requires notBool canYank(BID, GUY, TAB)

    rule <k> Flip ILK . yank ID => Flip ILK . exception ... </k>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids> BIDS </flip-bids>
      requires notBool ID in_keys(BIDS)

    rule <k> Flip ILK . yank ID
          => Vat . flux ILK THIS MSGSENDER LOT
          ~> Vat . move MSGSENDER GUY BID ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... bid: BID, lot: LOT, guy: GUY, tab: TAB) => .Map
         ...</flip-bids>
      requires canYank(BID, GUY, TAB)

    syntax Bool ::= canYank(bid: Int, guy: Int, tab: Int) [function]
 // ----------------------------------------------------------------
    rule canYank(BID, GUY, TAB) => GUY =/=Int 0 andBool BID <Int TAB

endmodule
```
