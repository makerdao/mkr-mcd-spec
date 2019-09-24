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
        <gems>
          <gem multiplicity="*" type="Map">
            <gem-id>       "":String </gem-id>
            <gem-addr>     0:Address </gem-addr>
            <gem-balances> .Map      </gem-balances> // mapping (address => uint256) Address |-> Wad
          </gem>
        </gems>
        <flips>
          <flip multiplicity="*" type="Map">
            <flip-ilk>   ""           </flip-ilk>
            <flip-addr>  0:Address    </flip-addr>
            <flip-bids>  .Map         </flip-bids> // mapping (uint => Bid)     Int     |-> Bid
            <flip-beg>   105 /Rat 100 </flip-beg>  // Minimum Bid Increase
            <flip-ttl>   3 hours      </flip-ttl>  // Single Bid Lifetime
            <flip-tau>   2 days       </flip-tau>  // Total Auction Length
            <flip-kicks> 0            </flip-kicks>
          </flip>
        </flips>
        <gemJoins>
          <gemJoin multiplicity="*" type="Map">
            <gemJoin-gem> "" </gemJoin-gem>
            <gemJoin-addr> 0:Address </gemJoin-addr>
          </gemJoin>
        </gemJoins>
        <daiJoin-addr> 0:Address </daiJoin-addr>
      </collateral>

    syntax MCDContract ::= GemContract
    syntax GemContract ::= "Gem" String
    syntax MCDStep ::= GemContract "." GemStep [klabel(gemStep)]
 // ------------------------------------------------------------
    rule contract(Gem GEMID . _) => Gem GEMID
    rule [[ address(Gem GEMID) => ACCTGEM ]] <gem-id> GEMID </gem-id> <gem-addr> ACCTGEM </gem-addr>

    syntax GemAuthStep
    syntax GemStep ::= GemAuthStep
    syntax AuthStep ::= GemContract "." GemAuthStep [klabel(gemStep)]
 // -----------------------------------------------------------------
    rule <k> Gem _ . _ => exception ... </k> [owise]

    syntax GemStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------
    rule <k> Gem GEMID . transferFrom ACCTSRC ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>...
             ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Rat VALUE )
             ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Rat VALUE )
           ...</gem-balances>
         ...
         </gem>
      requires VALUE >=Rat 0
       andBool BALANCE_SRC >=Rat VALUE

    syntax GemStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Gem _ . (move ACCTSRC ACCTDST VALUE => transferFrom ACCTSRC ACCTDST VALUE) ... </k>

    syntax GemStep ::= "push" Address Wad
 // -------------------------------------
    rule <k> Gem _ . (push ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax GemStep ::= "pull" Address Wad
 // -------------------------------------
    rule <k> Gem _ . (push ACCTSRC VALUE => transferFrom ACCTSRC MSGSENDER VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax GemStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Gem _ . (transfer ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax GemStep ::= "mint" Address Wad
 // -------------------------------------
    rule <k> Gem GEMID . mint ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>...
             ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Rat VALUE )
           ...</gem-balances>
         ...
         </gem>
      requires VALUE >=Rat 0

    syntax GemStep ::= "burn" Address Wad
 // -------------------------------------
    rule <k> Gem GEMID . burn ACCTSRC VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>...
             ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Rat VALUE )
           ...</gem-balances>
         ...
         </gem>
      requires VALUE >=Rat 0

    syntax Bid ::= Bid ( bid: Rad, lot: Wad, guy: Address, tic: Int, end: Int, usr: Address, gal: Address, tab: Rad )
 // -----------------------------------------------------------------------------------------------------------------

    syntax MCDContract ::= FlipContract
    syntax FlipContract ::= "Flip" String
    syntax MCDStep ::= FlipContract "." FlipStep [klabel(flipStep)]
 // ---------------------------------------------------------------
    rule contract(Flip ILK . _) => Flip ILK
    rule [[ address(Flip ILK) => ADDR ]] <flip-ilk> ILK </flip-ilk> <flip-addr> ADDR </flip-addr>

    syntax FlipStep ::= FlipAuthStep
    syntax AuthStep ::= FlipContract "." FlipAuthStep [klabel(flipStep)]
 // --------------------------------------------------------------------
    rule <k> Flip _ . _ => exception ... </k> [owise]

    syntax FlipStep ::= "kick" Address Address Rad Wad Rad
 // ------------------------------------------------------
    rule <k> Flip ILK . kick USR GAL TAB LOT BID
          => call Vat . flux ILK MSGSENDER THIS LOT
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

    syntax FlipStep ::= "tend" Int Wad Rad
 // --------------------------------------
    rule <k> Flip ILK . tend ID LOT BID
          => call Vat . move MSGSENDER GUY BID'
          ~> call Vat . move MSGSENDER GAL (BID -Rat BID') ... </k>
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
         <currentTime> NOW </currentTime>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... lot: LOT, guy: GUY, tic: TIC, end: END) => .Map
         ...</flip-bids>
      requires TIC =/=Int 0
       andBool (TIC <Int NOW orBool END <Int NOW)

    syntax FlipAuthStep ::= "yank" Int
 // ----------------------------------
    rule <k> Flip ILK . yank ID
          => call Vat . flux ILK THIS MSGSENDER LOT
          ~> call Vat . move MSGSENDER GUY BID ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>...
           ID |-> Bid(... bid: BID, lot: LOT, guy: GUY, tab: TAB) => .Map
         ...</flip-bids>
      requires GUY =/=K 0 andBool BID <Rat TAB

    syntax MCDContract ::= GemJoinContract
    syntax GemJoinContract ::= "GemJoin" String
    syntax MCDStep ::= GemJoinContract "." GemJoinStep [klabel(gemJoinStep)]
 // ------------------------------------------------------------------------
    rule contract(GemJoin GEMID . _) => GemJoin GEMID
    rule [[ address(GemJoin GEMID) => ACCTJOIN ]] <gemJoin-gem> GEMID </gemJoin-gem> <gemJoin-addr> ACCTJOIN </gemJoin-addr>
    rule <k> GemJoin _ . _ => exception ... </k> [owise]

    syntax GemJoinStep ::= "join" Address Wad
 // -----------------------------------------
    rule <k> GemJoin GEMID . join USR AMOUNT
          => call Vat . slip GEMID USR AMOUNT
          ~> call Gem GEMID . transferFrom MSGSENDER THIS AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>

    syntax GemJoinStep ::= "exit" Address Wad
 // -----------------------------------------
    rule <k> GemJoin GEMID . exit USR AMOUNT
          => call Vat . slip GEMID MSGSENDER (0 -Rat AMOUNT)
          ~> call Gem GEMID . transfer USR AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax MCDContract ::= DaiJoinContract
    syntax GemJoinContract ::= "DaiJoin"
    syntax MCDStep ::= DaiJoinContract "." DaiJoinStep [klabel(daiJoinStep)]
 // ------------------------------------------------------------------------
    rule contract(DaiJoin . _) => DaiJoin
    rule [[ address(DaiJoin) => ACCTJOIN ]] <daiJoin-addr> ACCTJOIN </daiJoin-addr>
    rule <k> DaiJoin . _ => exception ... </k> [owise]

    syntax DaiJoinStep ::= "join" Address Wad
 // -----------------------------------------
    rule <k> DaiJoin . join USR AMOUNT
          => call Vat . move THIS USR AMOUNT
          ~> call Dai . burn MSGSENDER AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>

    syntax DaiJoinStep ::= "exit" Address Wad
 // -----------------------------------------
    rule <k> DaiJoin . exit USR AMOUNT
          => call Vat . move MSGSENDER THIS AMOUNT
          ~> call Dai . mint USR AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>

endmodule
```
