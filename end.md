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
          <end-wards> .Set </end-wards>
          <end-live>  true </end-live>
          <end-when>  0    </end-when>
          <end-wait>  0    </end-wait>
          <end-debt>  0Rad </end-debt>
          <end-tag>   .Map </end-tag>  // mapping (bytes32 => uint256)                      String  |-> Ray
          <end-gap>   .Map </end-gap>  // mapping (bytes32 => uint256)                      String  |-> Wad
          <end-art>   .Map </end-art>  // mapping (bytes32 => uint256)                      String  |-> Wad
          <end-fix>   .Map </end-fix>  // mapping (bytes32 => uint256)                      String  |-> Ray
          <end-bag>   .Map </end-bag>  // mapping (address => uint256)                      Address |-> Wad
          <end-out>   .Map </end-out>  // mapping (bytes32 => mapping (address => uint256)) CDPID   |-> Wad
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
      requires WAIT >=Int 0
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
         <end-gap> GAPS => GAPS [ ILKID <- 0Wad ] </end-gap>
      requires notBool ILKID in_keys(GAPS)

    rule <k> End . initBag ADDR => . ... </k>
         <end-bag> BAGS => BAGS [ ADDR <- 0Wad ] </end-bag>
      requires notBool ADDR in_keys(BAGS)

    rule <k> End . initOut ILKID ADDR => . ... </k>
         <end-out> OUTS => OUTS [ { ILKID , ADDR } <- 0Wad ] </end-out>
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
         <end-tag> TAGS => TAGS [ ILK <- wdiv(PAR, PIP) ] </end-tag>
         <end-art> ARTS => ARTS [ ILK <- ART ] </end-art>
         <spot-par> PAR </spot-par>
         <spot-ilks> ... ILK |-> SpotIlk(... pip: PIP) ... </spot-ilks>
         <vat-ilks> ... ILK |-> Ilk(... Art: ART)::VatIlk ... </vat-ilks>
       requires notBool ILK in_keys(TAGS)

    syntax EndStep ::= "skip" String Int
 // ------------------------------------
    rule <k> End . skip ILK ID
          => call Vat . suck Vow Vow  TAB
          ~> call Vat . suck Vow THIS BID
          ~> call Vat . hope Flip ILK
          ~> call Flip ILK . yank ID
          ~> call Vat . grab ILK USR THIS Vow LOT (TAB /Rate RATE)
         ...
         </k>
         <this> THIS </this>
         <end-tag> ... ILK |-> TAG ... </end-tag>
         <end-art> ... ILK |-> (ART => ART +Wad (TAB /Rate RATE)) ... </end-art>
         <vat-ilks> ... ILK |-> Ilk(... rate: RATE)::VatIlk ... </vat-ilks>
         <flip>
           <flip-ilk> ILK </flip-ilk>
           <flip-bids> ... ID |-> FlipBid(... bid: BID, lot: LOT, usr: USR, tab: TAB) ... </flip-bids>
           ...
         </flip>
      requires TAG =/=Ray 0Ray
       andBool LOT >=Wad 0Wad
       andBool TAB /Rate RATE >=Wad 0Wad

    syntax EndStep ::= "skim" String Address
 // ----------------------------------------
    rule <k> End . skim ILK ADDR
          => call Vat . grab ILK ADDR THIS Vow (0Wad -Wad minWad(INK, rmul(rmul(ART, RATE), TAG))) (0Wad -Wad ART)
         ...
         </k>
         <this> THIS </this>
         <end-tag> ... ILK |-> TAG ... </end-tag>
         <end-gap> ... ILK |-> (GAP => GAP +Wad (rmul(rmul(ART, RATE), TAG) -Wad minWad(INK, rmul(rmul(ART, RATE), TAG)))) ... </end-gap>
         <vat-ilks> ... ILK |-> Ilk(... rate: RATE)::VatIlk ... </vat-ilks>
         <vat-urns> ... {ILK, ADDR} |-> Urn(... ink: INK, art: ART) ... </vat-urns>
      requires TAG =/=Ray 0Ray

    syntax EndStep ::= "free" String
 // --------------------------------
    rule <k> End . free ILK
          => call Vat . grab ILK MSGSENDER MSGSENDER Vow (0Wad -Wad INK) 0Wad
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <end-live> false </end-live>
         <vat-urns> ... {ILK, MSGSENDER} |-> Urn(... ink: INK, art: ART) ... </vat-urns>
      requires ART ==Wad 0Wad

    syntax EndStep ::= "thaw"
 // -------------------------
    rule <k> End . thaw => . ... </k>
         <current-time> NOW </current-time>
         <end-live> false </end-live>
         <end-debt> 0Rad => DEBT </end-debt>
         <end-when> WHEN </end-when>
         <end-wait> WAIT </end-wait>
         <vat-dai> ... Vow |-> 0Rad ... </vat-dai>
         <vat-debt> DEBT </vat-debt>
      requires NOW >=Int WHEN +Int WAIT

    syntax EndStep ::= "flow" String
 // --------------------------------
    rule <k> End . flow ILK => . ... </k>
         <end-debt> DEBT </end-debt>
         <end-fix> FIX => FIX [ ILK <- rdiv(Wad2Ray(rmul(rmul(ART, RATE), TAG) -Wad GAP), DEBT) ] </end-fix>
         <end-tag> ... ILK |-> TAG ... </end-tag>
         <end-gap> ... ILK |-> GAP ... </end-gap>
         <end-art> ... ILK |-> ART ... </end-art>
         <vat-ilks> ... ILK |-> Ilk(... rate: RATE)::VatIlk ... </vat-ilks>
      requires DEBT =/=Rad 0Rad
       andBool rmul(rmul(ART, RATE), TAG) >=Wad GAP
       andBool notBool ILK in_keys(FIX)

    syntax EndStep ::= "pack" Wad
 // -----------------------------
    rule <k> End . pack AMOUNT
          => call Vat . move MSGSENDER Vow Wad2Rad(AMOUNT)
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <end-debt> DEBT </end-debt>
         <end-bag> ... MSGSENDER |-> (BAG => BAG +Wad AMOUNT) ... </end-bag>
      requires AMOUNT >=Wad 0Wad
       andBool DEBT =/=Rad 0Rad

    syntax EndStep ::= "cash" String Wad
 // ------------------------------------
    rule <k> End . cash ILK AMOUNT
          => call Vat . flux ILK THIS MSGSENDER rmul(AMOUNT, FIX)
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <end-fix> ... ILK |-> FIX ... </end-fix>
         <end-out> ... {ILK, MSGSENDER} |-> (OUT => OUT +Wad AMOUNT) ... </end-out>
         <end-bag> ... MSGSENDER |-> BAG ... </end-bag>
      requires AMOUNT >=Wad 0Wad
       andBool FIX =/=Ray 0Ray
       andBool OUT +Wad AMOUNT <=Wad BAG
```

```k
endmodule
```
