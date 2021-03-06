```k
requires "kmcd-driver.md"
requires "flap.md"
requires "flop.md"
requires "vat.md"

module VOW
    imports KMCD-DRIVER
    imports FLAP
    imports PRE-FLOP
    imports VAT
```

Vow Configuration
-----------------

```k
    configuration
      <vow>
        <vow-vat>     0:Address </vow-vat>
        <vow-flapper> 0:Address </vow-flapper>
        <vow-flopper> 0:Address </vow-flopper>
        <vow-wards>   .Set      </vow-wards>
        <vow-sins>    .Map      </vow-sins> // mapping (uint256 => uint256) Int |-> Rad
        <vow-sin>     rad(0)    </vow-sin>
        <vow-ash>     rad(0)    </vow-ash>
        <vow-wait>    0         </vow-wait>
        <vow-dump>    wad(0)    </vow-dump>
        <vow-sump>    rad(0)    </vow-sump>
        <vow-bump>    rad(0)    </vow-bump>
        <vow-hump>    rad(0)    </vow-hump>
        <vow-live>    true      </vow-live>
      </vow>
```

```k
    syntax MCDContract ::= VowContract
    syntax VowContract ::= "Vow"
    syntax MCDStep ::= VowContract "." VowStep [klabel(vowStep)]
 // ------------------------------------------------------------
    rule contract(Vow . _) => Vow
```

### Constructor

```k
    syntax VowStep ::= "constructor" Address Address Address
 // --------------------------------------------------------
    rule <k> Vow . constructor VOW_VAT VOW_FLAPPER VOW_FLOPPER
          => call VOW_VAT . hope VOW_FLAPPER
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <vow> _ </vow>
        => <vow>
             <vow-vat> VOW_VAT </vow-vat>
             <vow-flapper> VOW_FLAPPER </vow-flapper>
             <vow-flopper> VOW_FLOPPER </vow-flopper>
             <vow-wards> SetItem(MSGSENDER) </vow-wards>
             <vow-live> true </vow-live>
             ...
           </vow>
         )
```

Vow Authorization
-----------------

```k
    syntax VowStep  ::= VowAuthStep
    syntax AuthStep ::= VowContract "." VowAuthStep [klabel(vowStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Vow) => WARDS ]] <vow-wards> WARDS </vow-wards>

    syntax VowAuthStep ::= WardStep
 // -------------------------------
    rule <k> Vow . rely ADDR => . ... </k>
         <vow-live> true </vow-live>
         <vow-wards> ... (.Set => SetItem(ADDR)) </vow-wards>

    rule <k> Vow . deny ADDR => . ... </k>
         <vow-wards> WARDS => WARDS -Set SetItem(ADDR) </vow-wards>
```

File-able Data
--------------

These praameters are set by governance:

-   `wait`: delay before `flog`ing is allowed.
-   `bump`: Flap auction lot size.
-   `hump`: Buffer on Flap auction lot size.
-   `sump`: Flop auction initial bid.
-   `dump`: Flop auction lot size.

```k
    syntax VowAuthStep ::= "file" VowFile
 // -------------------------------------

    syntax VowFile ::= "wait" Int
                     | "bump" Rad
                     | "hump" Rad
                     | "sump" Rad
                     | "dump" Wad
 // -----------------------------
    rule <k> Vow . file wait WAIT => . ... </k>
         <vow-wait> _ => WAIT </vow-wait>
      requires WAIT >=Int 0

    rule <k> Vow . file bump BUMP => . ... </k>
         <vow-bump> _ => BUMP </vow-bump>
      requires BUMP >=Rad rad(0)

    rule <k> Vow . file hump HUMP => . ... </k>
         <vow-hump> _ => HUMP </vow-hump>
      requires HUMP >=Rad rad(0)

    rule <k> Vow . file sump SUMP => . ... </k>
         <vow-sump> _ => SUMP </vow-sump>
      requires SUMP >=Rad rad(0)

    rule <k> Vow . file dump DUMP => . ... </k>
         <vow-dump> _ => DUMP </vow-dump>
      requires DUMP >=Wad wad(0)
```

Vow Semantics
-------------

```k
    syntax VowAuthStep ::= "fess" Rad
 // ---------------------------------
    rule <k> Vow . fess TAB => . ... </k>
         <current-time> NOW </current-time>
         <vow-sins> ... NOW |-> (SIN' => SIN' +Rad TAB) ... </vow-sins>
         <vow-sin> SIN => SIN +Rad TAB </vow-sin>
      requires TAB >=Rad rad(0)

    syntax VowStep ::= "flog" Int
 // -----------------------------
    rule <k> Vow . flog ERA => . ... </k>
         <current-time> NOW </current-time>
         <vow-wait> WAIT </vow-wait>
         <vow-sins> ... ERA |-> (SIN' => rad(0)) ... </vow-sins>
         <vow-sin> SIN => SIN -Rad SIN' </vow-sin>
      requires ERA >=Int 0
       andBool ERA +Int WAIT <=Int NOW

    syntax VowStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vow . heal AMOUNT => call VOW_VAT . heal AMOUNT ... </k>
         <this> THIS </this>
         <vow-vat> VOW_VAT:VatContract </vow-vat>
         <vat-dai> ... THIS |-> VATDAI ... </vat-dai>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
      requires AMOUNT >=Rad rad(0)
       andBool AMOUNT <=Rad VATDAI
       andBool AMOUNT <=Rad (VATSIN -Rad SIN) -Rad ASH

    syntax VowStep ::= "kiss" Rad
 // -----------------------------
    rule <k> Vow . kiss AMOUNT => call VOW_VAT . heal AMOUNT ... </k>
         <this> THIS </this>
         <vow-vat> VOW_VAT:VatContract </vow-vat>
         <vat-dai> ... THIS |-> VATDAI ... </vat-dai>
         <vow-ash> ASH => ASH -Rad AMOUNT </vow-ash>
       requires AMOUNT >=Rad rad(0)
        andBool AMOUNT <=Rad ASH
        andBool AMOUNT <=Rad VATDAI

    syntax VowStep ::= "flop"
 // -------------------------
    rule <k> Vow . flop => call VOW_FLOPPER . kick THIS DUMP SUMP ... </k>
         <this> THIS </this>
         <vow-flopper> VOW_FLOPPER:FlopContract </vow-flopper>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai> ... THIS |-> VATDAI ... </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH => ASH +Rad SUMP </vow-ash>
         <vow-sump> SUMP </vow-sump>
         <vow-dump> DUMP </vow-dump>
      requires SUMP <=Rad (VATSIN -Rad SIN) -Rad ASH
       andBool VATDAI ==Rad rad(0)

    syntax VowStep ::= "flap"
 // -------------------------
    rule <k> Vow . flap => call VOW_FLAPPER . kick BUMP wad(0) ... </k>
         <this> THIS </this>
         <vow-flapper> VOW_FLAPPER:FlapContract </vow-flapper>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai> ... THIS |-> VATDAI ... </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
         <vow-bump> BUMP </vow-bump>
         <vow-hump> HUMP </vow-hump>
      requires VATDAI >=Rad (VATSIN +Rad BUMP) +Rad HUMP
       andBool (VATSIN -Rad SIN) -Rad ASH ==Rad rad(0)

    syntax VowAuthStep ::= "cage"
 // -----------------------------
    rule <k> Vow . cage
          => call VOW_FLAPPER . cage FLAPDAI
          ~> call VOW_FLOPPER . cage
          ~> call VOW_VAT . heal minRad(VATDAI, VATSIN)
         ...
         </k>
         <this> THIS </this>
         <vow-vat> VOW_VAT:VatContract </vow-vat>
         <vow-flopper> VOW_FLOPPER:FlopContract </vow-flopper>
         <vow-flapper> VOW_FLAPPER:FlapContract </vow-flapper>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai>
           ...
           THIS |-> VATDAI
           VOW_FLAPPER |-> FLAPDAI
           ...
         </vat-dai>
         <vow-live> _ => false </vow-live>
         <vow-sin> _ => rad(0) </vow-sin>
         <vow-ash> _ => rad(0) </vow-ash>
      requires THIS =/=K Flap
```

```k
endmodule
```
