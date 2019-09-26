KMCD - K Semantics of Multi Collateral Dai
==========================================

This module combines all sub-modules to model the entire MCD system.

```k
requires "kmcd-driver.k"
requires "cat.k"
requires "dai.k"
requires "end.k"
requires "flap.k"
requires "flip.k"
requires "flop.k"
requires "gem.k"
requires "join.k"
requires "jug.k"
requires "pot.k"
requires "spot.k"
requires "vat.k"
requires "vow.k"

module KMCD
    imports KMCD-DRIVER
    imports CAT
    imports DAI
    imports END
    imports FLAP
    imports FLIP
    imports FLOP
    imports GEM
    imports JOIN
    imports JUG
    imports POT
    imports SPOT
    imports VAT
    imports VOW
```

**TODO**: This is a HACK to get us past unparsing issues with `mcd-pyk.py`.

```k
    imports K-TERM
```

```k
    configuration
      <kmcd>
        <kmcd-driver/>
        <kmcd-state>
          <dai/>
          <gems/>
          <vat/>
          <endPhase> false </endPhase>
          <end>
            <end-addr> 0:Address </end-addr>
            <end-live> true      </end-live>
            <end-when> 0         </end-when>
            <end-wait> 0         </end-wait>
            <end-debt> 0:Rad      </end-debt>
            <end-tag>  .Map      </end-tag>  // mapping (bytes32 => uint256)                      String  |-> Ray
            <end-gap>  .Map      </end-gap>  // mapping (bytes32 => uint256)                      String  |-> Wad
            <end-art>  .Map      </end-art>  // mapping (bytes32 => uint256)                      String  |-> Wad
            <end-fix>  .Map      </end-fix>  // mapping (bytes32 => uint256)                      String  |-> Ray
            <end-bag>  .Map      </end-bag>  // mapping (address => uint256)                      Address |-> Wad
            <end-out>  .Map      </end-out>  // mapping (bytes32 => mapping (address => uint256)) CDPID   |-> Wad
          </end>
        </kmcd-state>
      </kmcd>
```

State Storage/Revert Semantics
------------------------------

```k
    rule <k> pushState => . ... </k>
         <kmcd-state> STATE </kmcd-state>
         <preState> _ => <kmcd-state> STATE </kmcd-state> </preState>

    rule <k> dropState => . ... </k>
         <preState> _ => .K </preState>

    rule <k> popState => . ... </k>
         (_:KmcdStateCell => <kmcd-state> STATE </kmcd-state>)
         <preState> <kmcd-state> STATE </kmcd-state> </preState>
```

End Semantics
-------------

```k
    syntax MCDContract ::= EndContract
    syntax EndContract ::= "End"
    syntax MCDStep ::= EndContract "." EndStep [klabel(endStep)]
 // ------------------------------------------------------------
    rule contract(End . _) => End
    rule [[ address(End) => ADDR ]] <end-addr> ADDR </end-addr>

    syntax EndStep ::= EndAuthStep
    syntax AuthStep ::= EndContract "." EndAuthStep [klabel(endStep)]
 // -----------------------------------------------------------------
    rule <k> End . _ => exception ... </k> [owise]

    syntax EndAuthStep ::= "cage"
 // -----------------------------
    rule <k> End . cage
          => call Vat . cage
          ~> call Cat . cage
          ~> call Vow . cage
          ~> call Pot . cage ... </k>
         <currentTime> NOW </currentTime>
         <end-live> true => false </end-live>
         <end-when> _ => NOW </end-when>

    syntax EndStep ::= "cage" String
 // --------------------------------
    rule <k> End . cage ILK:String => . ... </k>
         <end-live> false </end-live>
         <end-tag> TAGS => TAGS [ ILK <- PAR /Rat PIP ] </end-tag>
         <end-art> ARTS => ARTS [ ILK <- ART ] </end-art>
         <spot-par> PAR </spot-par>
         <spot-ilks>
           ...
           ILK |-> SpotIlk(... pip: PIP)
           ...
         </spot-ilks>
         <vat-ilks>
           ...
           ILK |-> Ilk(... Art: ART)::VatIlk
           ...
         </vat-ilks>
       requires notBool ILK in_keys(TAGS)

    syntax EndStep ::= "skip" String Int
 // ------------------------------------
    rule <k> End . skip ILK ID
          => call Vat . suck address(Vow) address(Vow) TAB
          ~> call Vat . suck address(Vow) THIS BID
          ~> call Vat . hope address(Flip ILK)
          ~> call Flip ILK . yank ID
          ~> call Vat . grab ILK USR THIS address(Vow) LOT (TAB /Rat RATE) ... </k>
         <this> THIS </this>
         <end-tag>
          ...
          ILK |-> TAG
          ...
         </end-tag>
         <end-art>
           ...
           ILK |-> (ART => ART +Rat (TAB /Rat RATE))
           ...
         </end-art>
         <vat-ilks>
           ...
           ILK |-> Ilk(... rate: RATE)::VatIlk
           ...
         </vat-ilks>
         <flip-ilk> ILK </flip-ilk>
         <flip-bids>
           ...
           ID |-> Bid(... bid: BID, lot: LOT, usr: USR, tab: TAB)
           ...
         </flip-bids>
      requires TAG =/=Rat 0
       andBool LOT >=Rat 0
       andBool TAB /Rat RATE >=Rat 0

    syntax EndStep ::= "skim" String Address
 // ----------------------------------------
    rule <k> End . skim ILK URN
          => call Vat . grab ILK URN THIS address(Vow) (0 -Rat minRat(INK, ART *Rat RATE *Rat TAG)) (0 -Rat ART) ... </k>
         <this> THIS </this>
         <end-tag>
          ...
          ILK |-> TAG
          ...
         </end-tag>
         <end-gap>
          ...
          ILK |-> (GAP => GAP +Rat ((ART *Rat RATE *Rat TAG) -Rat minRat(INK, (ART *Rat RATE *Rat TAG))))
          ...
         </end-gap>
         <vat-ilks>
           ...
           ILK |-> Ilk(... rate: RATE)::VatIlk
           ...
         </vat-ilks>
         <vat-urns>
           ...
           {ILK, URN} |-> Urn(... ink: INK, art: ART)
           ...
         </vat-urns>
      requires TAG =/=Rat 0

    syntax EndStep ::= "free" String
 // --------------------------------
    rule <k> End . free ILK
          => call Vat . grab ILK MSGSENDER MSGSENDER address(Vow) (0 -Rat INK) 0 ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <end-live> false </end-live>
         <vat-urns>
           ...
           {ILK, MSGSENDER} |-> Urn(... ink: INK, art: ART)
           ...
         </vat-urns>
      requires ART ==Int 0

    syntax EndStep ::= "thaw"
 // -------------------------
    rule <k> End . thaw ... </k>
         <currentTime> NOW </currentTime>
         <end-live> false </end-live>
         <end-debt> 0 => DEBT </end-debt>
         <end-when> WHEN </end-when>
         <end-wait> WAIT </end-wait>
         <vat-dai>
           ...
           address(Vow) |-> 0
           ...
         </vat-dai>
         <vat-debt> DEBT </vat-debt>
      requires NOW >=Int WHEN +Int WAIT

    syntax EndStep ::= "flow" String
 // --------------------------------
    rule <k> End . flow ILK => . ... </k>
         <end-debt> DEBT </end-debt>
         <end-fix> FIX => FIX [ ILK <- (ART *Rat RATE *Rat TAG -Rat GAP) /Rat DEBT ] </end-fix>
         <end-tag>
          ...
          ILK |-> TAG
          ...
         </end-tag>
         <end-gap>
           ...
           ILK |-> GAP
           ...
         </end-gap>
         <end-art>
           ...
           ILK |-> ART
           ...
         </end-art>
         <vat-ilks>
           ...
           ILK |-> Ilk(... rate: RATE)::VatIlk
           ...
         </vat-ilks>
      requires DEBT =/=Rat 0
       andBool ART *Rat RATE *Rat TAG >=Rat GAP
       andBool notBool ILK in_keys(FIX)

    syntax EndStep ::= "pack" Wad
 // -----------------------------
    rule <k> End . pack AMOUNT
          => call Vat . move MSGSENDER address(Vow) AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <end-debt> DEBT </end-debt>
         <end-bag>
           ...
           MSGSENDER |-> (BAG => BAG +Rat AMOUNT)
           ...
         </end-bag>
      requires DEBT =/=Rat 0

    syntax EndStep ::= "cash" String Wad
 // ------------------------------------
    rule <k> End . cash ILK AMOUNT
          => call Vat . flux ILK THIS MSGSENDER (AMOUNT *Rat FIX) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <end-fix>
           ...
           ILK |-> FIX
           ...
         </end-fix>
         <end-out>
          ...
          {ILK, MSGSENDER} |-> (OUT => OUT +Rat AMOUNT)
          ...
         </end-out>
         <end-bag>
           ...
           MSGSENDER |-> BAG
           ...
         </end-bag>
      requires FIX =/=Rat 0
       andBool OUT +Rat AMOUNT <=Rat BAG
```

```k
endmodule
```
