```k
requires "kmcd-driver.md"
requires "cat.md"
requires "flip.md"
requires "pot.md"
requires "spot.md"
requires "vow.md"
requires "vat.md"

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
          <end-vat>   0:Address </end-vat>
          <end-cat>   0:Address </end-cat>
          <end-vow>   0:Address </end-vow>
          <end-pot>   0:Address </end-pot>
          <end-spot>  0:Address </end-spot>
          <end-wards> .Set      </end-wards>
          <end-live>  true      </end-live>
          <end-when>  0         </end-when>
          <end-wait>  0         </end-wait>
          <end-debt>  rad(0)    </end-debt>
          <end-tag>   .Map      </end-tag>  // mapping (bytes32 => uint256)                      String  |-> Ray
          <end-gap>   .Map      </end-gap>  // mapping (bytes32 => uint256)                      String  |-> Wad
          <end-art>   .Map      </end-art>  // mapping (bytes32 => uint256)                      String  |-> Wad
          <end-fix>   .Map      </end-fix>  // mapping (bytes32 => uint256)                      String  |-> Ray
          <end-bag>   .Map      </end-bag>  // mapping (address => uint256)                      Address |-> Wad
          <end-out>   .Map      </end-out>  // mapping (bytes32 => mapping (address => uint256)) CDPID   |-> Wad
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

### Constructor

```k
    syntax EndStep ::= "constructor"
 // --------------------------------
    rule <k> End . constructor => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <end> _ </end>
        => <end>
             <end-wards> SetItem(MSGSENDER) </end-wards>
             <end-live> true </end-live>
             ...
           </end>
         )
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
                     | "vat-file"  Address
                     | "cat-file"  Address
                     | "vow-file"  Address
                     | "pot-file"  Address
                     | "spot-file" Address
 // --------------------------------------
    rule <k> End . file wait WAIT => . ... </k>
         <end-live> true </end-live>
         <end-wait> _ => WAIT </end-wait>
      requires WAIT >=Int 0

    rule <k> End . file vat-file END_VAT => . ... </k>
         <end-live> true </end-live>
         <end-vat> _ => END_VAT </end-vat>

    rule <k> End . file cat-file END_CAT => . ... </k>
         <end-live> true </end-live>
         <end-cat> _ => END_CAT </end-cat>

    rule <k> End . file vow-file END_VOW => . ... </k>
         <end-live> true </end-live>
         <end-vow> _ => END_VOW </end-vow>

    rule <k> End . file pot-file END_POT => . ... </k>
         <end-live> true </end-live>
         <end-pot> _ => END_POT </end-pot>

    rule <k> End . file spot-file END_SPOT => . ... </k>
         <end-live> true </end-live>
         <end-spot> _ => END_SPOT </end-spot>
```

End Initialization
------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `initGap`: Initialize the gap for a given ilk to 0.
    **TODO**: Should `End . initGap ILK_ID` happen directly when `End . cage ILK_ID` happens?

```k
    syntax EndAuthStep ::= "initGap" String
                         | "initBag" Address
                         | "initOut" String Address
 // -----------------------------------------------
    rule <k> End . initGap ILK_ID => . ... </k>
         <end-gap> GAPS => GAPS [ ILK_ID <- wad(0) ] </end-gap>
      requires notBool ILK_ID in_keys(GAPS)

    rule <k> End . initBag ADDR => . ... </k>
         <end-bag> BAGS => BAGS [ ADDR <- wad(0) ] </end-bag>
      requires notBool ADDR in_keys(BAGS)

    rule <k> End . initOut ILK_ID ADDR => . ... </k>
         <end-out> OUTS => OUTS [ { ILK_ID , ADDR } <- wad(0) ] </end-out>
      requires notBool { ILK_ID , ADDR } in_keys(OUTS)
```

End Semantics
-------------

```k
    syntax EndAuthStep ::= "cage"
 // -----------------------------
    rule <k> End . cage
          => call END_VAT . cage
          ~> call END_CAT . cage
          ~> call END_VOW . cage
          ~> call END_POT . cage
         ...
         </k>
         <current-time> NOW </current-time>
         <end-live> true => false </end-live>
         <end-when> _ => NOW </end-when>
         <end-vat> END_VAT:VatContract </end-vat>
         <end-cat> END_CAT:CatContract </end-cat>
         <end-vow> END_VOW:VowContract </end-vow>
         <end-pot> END_POT:PotContract </end-pot>

    syntax EndStep ::= "cage" String
 // --------------------------------
    rule <k> End . cage ILK_ID:String => . ... </k>
         <end-live> false </end-live>
         <end-tag> TAGS => TAGS [ ILK_ID <- wdiv(PAR, PIP) ] </end-tag>
         <end-art> ARTS => ARTS [ ILK_ID <- ART ] </end-art>
         <spot-par> PAR </spot-par>
         <spot-ilks> ... ILK_ID |-> SpotIlk(... pip: PIP) ... </spot-ilks>
         <vat-ilks> ... ILK_ID |-> Ilk(... Art: ART)::VatIlk ... </vat-ilks>
       requires notBool ILK_ID in_keys(TAGS)

    syntax EndStep ::= "skip" String Int
 // ------------------------------------
    rule <k> End . skip ILK_ID BID_ID
          => call END_VAT . suck Vow Vow  TAB
          ~> call END_VAT . suck Vow THIS BID
          ~> call END_VAT . hope Flip ILK_ID
          ~> call Flip ILK_ID . yank BID_ID
          ~> call END_VAT . grab ILK_ID USR THIS Vow LOT (TAB /Rate RATE)
         ...
         </k>
         <this> THIS </this>
         <end-vat> END_VAT:VatContract </end-vat>
         <end-tag> ... ILK_ID |-> TAG ... </end-tag>
         <end-art> ... ILK_ID |-> (ART => ART +Wad (TAB /Rate RATE)) ... </end-art>
         <vat-ilks> ... ILK_ID |-> Ilk(... rate: RATE)::VatIlk ... </vat-ilks>
         <flip>
           <flip-ilk> ILK_ID </flip-ilk>
           <flip-bids> ... BID_ID |-> FlipBid(... bid: BID, lot: LOT, usr: USR, tab: TAB) ... </flip-bids>
           ...
         </flip>
      requires TAG =/=Ray ray(0)
       andBool LOT >=Wad wad(0)
       andBool TAB /Rate RATE >=Wad wad(0)

    syntax EndStep ::= "skim" String Address
 // ----------------------------------------
    rule <k> End . skim ILK_ID ADDR
          => call END_VAT . grab ILK_ID ADDR THIS Vow (wad(0) -Wad minWad(INK, rmul(rmul(ART, RATE), TAG))) (wad(0) -Wad ART)
         ...
         </k>
         <this> THIS </this>
         <end-vat> END_VAT:VatContract </end-vat>
         <end-tag> ... ILK_ID |-> TAG ... </end-tag>
         <end-gap> ... ILK_ID |-> (GAP => GAP +Wad (rmul(rmul(ART, RATE), TAG) -Wad minWad(INK, rmul(rmul(ART, RATE), TAG)))) ... </end-gap>
         <vat-ilks> ... ILK_ID |-> Ilk(... rate: RATE)::VatIlk ... </vat-ilks>
         <vat-urns> ... {ILK_ID, ADDR} |-> Urn(... ink: INK, art: ART) ... </vat-urns>
      requires TAG =/=Ray ray(0)

    syntax EndStep ::= "free" String
 // --------------------------------
    rule <k> End . free ILK_ID
          => call END_VAT . grab ILK_ID MSGSENDER MSGSENDER Vow (wad(0) -Wad INK) wad(0)
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <end-live> false </end-live>
         <end-vat> END_VAT:VatContract </end-vat>
         <vat-urns> ... {ILK_ID, MSGSENDER} |-> Urn(... ink: INK, art: ART) ... </vat-urns>
      requires ART ==Wad wad(0)

    syntax EndStep ::= "thaw"
 // -------------------------
    rule <k> End . thaw => . ... </k>
         <current-time> NOW </current-time>
         <end-live> false </end-live>
         <end-debt> rad(0) => DEBT </end-debt>
         <end-when> WHEN </end-when>
         <end-wait> WAIT </end-wait>
         <vat-dai> ... Vow |-> rad(0) ... </vat-dai>
         <vat-debt> DEBT </vat-debt>
      requires NOW >=Int WHEN +Int WAIT

    syntax EndStep ::= "flow" String
 // --------------------------------
    rule <k> End . flow ILK_ID => . ... </k>
         <end-debt> DEBT </end-debt>
         <end-fix> FIX => FIX [ ILK_ID <- rdiv(Wad2Ray(rmul(rmul(ART, RATE), TAG) -Wad GAP), DEBT) ] </end-fix>
         <end-tag> ... ILK_ID |-> TAG ... </end-tag>
         <end-gap> ... ILK_ID |-> GAP ... </end-gap>
         <end-art> ... ILK_ID |-> ART ... </end-art>
         <vat-ilks> ... ILK_ID |-> Ilk(... rate: RATE)::VatIlk ... </vat-ilks>
      requires DEBT =/=Rad rad(0)
       andBool rmul(rmul(ART, RATE), TAG) >=Wad GAP
       andBool notBool ILK_ID in_keys(FIX)

    syntax EndStep ::= "pack" Wad
 // -----------------------------
    rule <k> End . pack AMOUNT
          => call END_VAT . move MSGSENDER Vow Wad2Rad(AMOUNT)
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <end-vat> END_VAT:VatContract </end-vat>
         <end-debt> DEBT </end-debt>
         <end-bag> ... MSGSENDER |-> (BAG => BAG +Wad AMOUNT) ... </end-bag>
      requires AMOUNT >=Wad wad(0)
       andBool DEBT =/=Rad rad(0)

    syntax EndStep ::= "cash" String Wad
 // ------------------------------------
    rule <k> End . cash ILK_ID AMOUNT
          => call END_VAT . flux ILK_ID THIS MSGSENDER rmul(AMOUNT, FIX)
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <end-vat> END_VAT:VatContract </end-vat>
         <end-fix> ... ILK_ID |-> FIX ... </end-fix>
         <end-out> ... {ILK_ID, MSGSENDER} |-> (OUT => OUT +Wad AMOUNT) ... </end-out>
         <end-bag> ... MSGSENDER |-> BAG ... </end-bag>
      requires AMOUNT >=Wad wad(0)
       andBool FIX =/=Ray ray(0)
       andBool OUT +Wad AMOUNT <=Wad BAG
```

```k
endmodule
```
