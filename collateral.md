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

    syntax FlipStep ::= FlipAuthStep
 // --------------------------------

    syntax FlipAuthStep ::= AuthStep
 // --------------------------------

    syntax FlipAuthStep ::= WardStep
 // --------------------------------

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
    rule <k> Flip ILK . tick ID => . ... </k>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-tau> TAU </flip-tau>
         <flip-bids>...
           ID |-> Bid(... tic: TIC, end: END => NOW +Int TAU)
         ...</flip-bids>
      requires END  <Int NOW
       andBool TIC ==Int 0

    syntax FlipStep ::= "tend" Int Int Int
 // --------------------------------------
    rule <k> Flip ILK . tend ID LOT BID
          => Vat . move MSGSENDER GUY BID'
          ~> Vat . move MSGSENDER GAL (BID -Int BID') ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-beg> BEG </flip-beg>
         <flip-ttl> TTL </flip-ttl>
         <flip-bids>...
           ID |-> Bid(... bid: BID' => BID,
                          lot: LOT',
                          guy: GUY => MSGSENDER,
                          tic: TIC => NOW +Int TTL,
                          end: END,
                          gal: GAL,
                          tab: TAB)
         ...</flip-bids>
      requires GUY =/=Int 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool LOT ==Int LOT'
       andBool BID <=Int TAB
       andBool BID >Int BID'
       andBool (BID >=Rat BEG *Rat BID' orBool BID ==Int TAB)

    syntax FlipStep ::= "dent" Int Int Int
 // --------------------------------------
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
           ID |-> Bid(... bid: BID',
                          lot: LOT' => LOT,
                          guy: GUY => MSGSENDER,
                          tic: TIC => NOW +Int TTL,
                          end: END,
                          usr: USR,
                          tab: TAB)
         ...</flip-bids>
      requires GUY =/=Int 0
       andBool (TIC >Int NOW orBool TIC ==Int 0)
       andBool END >Int NOW
       andBool BID ==Int BID'
       andBool BID ==Int TAB
       andBool LOT <Int LOT'
       andBool BEG *Rat LOT <Rat LOT'

    syntax FlipStep ::= "deal" Int
 // ------------------------------
    rule <k> Flip ILK . deal ID => Vat . flux ILK THIS GUY LOT ... </k>
         <this> THIS </this>
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
         ...</flip-bids>
      requires TIC =/=Int 0
       andBool (TIC <Int NOW orBool END <Int NOW)

    syntax FlipStep ::= "yank" Int
 // ------------------------------
    rule <k> Flip ILK . yank ID
          => Vat . flux ILK THIS MSGSENDER LOT
          ~> Vat . move MSGSENDER GUY BID ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... bid: BID, lot: LOT, guy: GUY, tab: TAB) => .Map
         ...</flip-bids>
      requires GUY =/=Int 0 andBool BID <Int TAB

endmodule
```
