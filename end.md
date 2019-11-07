```k
requires "kmcd-driver.k"
requires "cat.k"
requires "flip.k"
requires "pot.k"
requires "spot.k"
requires "vow.k"
requires "vat.k"

module END
    imports KMCD-DRIVER
    imports CAT
    imports FLIP
    imports POT
    imports SPOT
    imports VOW
    imports VAT
```

End Configuration
-----------------

```k
    configuration
      <end-state>
        <endPhase> false </endPhase>
        <end>
          <end-wards> .Set  </end-wards>
          <end-live>  true  </end-live>
          <end-when>  0     </end-when>
          <end-wait>  0     </end-wait>
          <end-debt>  0:Rad </end-debt>
          <end-tag>   .Map  </end-tag>  // mapping (bytes32 => uint256)                      String  |-> Ray
          <end-gap>   .Map  </end-gap>  // mapping (bytes32 => uint256)                      String  |-> Wad
          <end-art>   .Map  </end-art>  // mapping (bytes32 => uint256)                      String  |-> Wad
          <end-fix>   .Map  </end-fix>  // mapping (bytes32 => uint256)                      String  |-> Ray
          <end-bag>   .Map  </end-bag>  // mapping (address => uint256)                      Address |-> Wad
          <end-out>   .Map  </end-out>  // mapping (bytes32 => mapping (address => uint256)) CDPID   |-> Wad
        </end>
      </end-state>
```

```k
    syntax MCDContract ::= EndContract
    syntax EndContract ::= "End"
    syntax MCDStep ::= EndContract "." EndStep [klabel(endStep)]
 // ------------------------------------------------------------
    rule contract(End . _) => End
```

End Authorization
-----------------

```k
    syntax EndStep  ::= EndAuthStep
    syntax AuthStep ::= EndContract "." EndAuthStep [klabel(endStep)]
 // -----------------------------------------------------------------
    rule [[ wards(End) => WARDS ]] <end-wards> WARDS </end-wards>

    syntax EndAuthStep ::= WardStep
 // -------------------------------
    rule <k> End . rely ADDR => . ... </k>
         <end-wards> ... (.Set => SetItem(ADDR)) </end-wards>

    rule <k> End . deny ADDR => . ... </k>
         <end-wards> WARDS => WARDS -Set SetItem(ADDR) </end-wards>
```

File-able Fields
----------------

These parameters are controlled by governance:

-   `wait`: time buffer on `thaw` step.

```k
    syntax EndAuthStep ::= "file" EndFile
 // -------------------------------------

    syntax EndFile ::= "wait" Int
 // -----------------------------
    rule <k> End . file wait WAIT => . ... </k>
         <end-live> true </end-live>
         <end-wait> _ => WAIT </end-wait>
```

**NOTE**: We have not added `file` steps for `vat`, `cat`, `vow`, `pot`, or `spot` because this model does not deal with swapping out implementations.

End Initialization
------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `initGap`: Initialize the gap for a given ilk to 0.
    **TODO**: Should `End . initGap ILKID` happen directly when `End . cage ILKID` happens?

```k
    syntax EndAuthStep ::= "initGap" String
                         | "initBag" Address
                         | "initOut" String Address
 // -----------------------------------------------
    rule <k> End . initGap ILKID => . ... </k>
         <end-gap> GAPS => GAPS [ ILKID <- 0 ] </end-gap>
      requires notBool ILKID in_keys(GAPS)

    rule <k> End . initBag ADDR => . ... </k>
         <end-bag> BAGS => BAGS [ ADDR <- 0 ] </end-bag>
      requires notBool ADDR in_keys(BAGS)

    rule <k> End . initOut ILKID ADDR => . ... </k>
         <end-out> OUTS => OUTS [ { ILKID , ADDR } <- 0 ] </end-out>
      requires notBool { ILKID , ADDR } in_keys(OUTS)
```

End Semantics
-------------

```k
    syntax EndAuthStep ::= "cage"
 // -----------------------------
    rule <k> End . cage
          => call Vat . cage
          ~> call Cat . cage
          ~> call Vow . cage
          ~> call Pot . cage
         ...
         </k>
         <current-time> NOW </current-time>
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
          => call Vat . suck Vow Vow  TAB
          ~> call Vat . suck Vow THIS BID
          ~> call Vat . hope Flip ILK
          ~> call Flip ILK . yank ID
          ~> call Vat . grab ILK USR THIS Vow LOT (TAB /Rat RATE)
         ...
         </k>
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
           ID |-> FlipBid(... bid: BID, lot: LOT, usr: USR, tab: TAB)
           ...
         </flip-bids>
      requires TAG =/=Rat 0
       andBool LOT >=Rat 0
       andBool TAB /Rat RATE >=Rat 0

    syntax EndStep ::= "skim" String Address
 // ----------------------------------------
    rule <k> End . skim ILK URN
          => call Vat . grab ILK URN THIS Vow (0 -Rat minRat(INK, ART *Rat RATE *Rat TAG)) (0 -Rat ART)
         ...
         </k>
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
          => call Vat . grab ILK MSGSENDER MSGSENDER Vow (0 -Rat INK) 0
         ...
         </k>
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
    rule <k> End . thaw => . ... </k>
         <current-time> NOW </current-time>
         <end-live> false </end-live>
         <end-debt> 0 => DEBT </end-debt>
         <end-when> WHEN </end-when>
         <end-wait> WAIT </end-wait>
         <vat-dai>
           ...
           Vow |-> 0
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
          => call Vat . move MSGSENDER Vow AMOUNT
         ...
         </k>
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
          => call Vat . flux ILK THIS MSGSENDER (AMOUNT *Rat FIX)
         ...
         </k>
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
