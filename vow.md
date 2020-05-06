```k
requires "kmcd-driver.k"
requires "flap.k"
requires "flop.k"
requires "vat.k"

module VOW
    imports KMCD-DRIVER
    imports FLAP
    imports FLOP
    imports VAT
```

Vow Configuration
-----------------

```k
    configuration
      <vow>
        <vow-wards> .Set   </vow-wards>
        <vow-sins>  .Map   </vow-sins> // mapping (uint256 => uint256) Int |-> Rad
        <vow-sin>   rad(0) </vow-sin>
        <vow-ash>   rad(0) </vow-ash>
        <vow-wait>  0      </vow-wait>
        <vow-dump>  wad(0) </vow-dump>
        <vow-sump>  rad(0) </vow-sump>
        <vow-bump>  rad(0) </vow-bump>
        <vow-hump>  rad(0) </vow-hump>
        <vow-live>  true   </vow-live>
      </vow>
```

```k
    syntax MCDContract ::= VowContract
    syntax VowContract ::= "Vow"
    syntax MCDStep ::= VowContract "." VowStep [klabel(vowStep)]
 // ------------------------------------------------------------
    rule contract(Vow . _) => Vow
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
    rule <k> Vow . heal AMOUNT => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai> ... THIS |-> VATDAI ... </vat-dai>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
      requires AMOUNT >=Rad rad(0)
       andBool AMOUNT <=Rad VATDAI
       andBool AMOUNT <=Rad (VATSIN -Rad SIN) -Rad ASH

    syntax VowStep ::= "kiss" Rad
 // -----------------------------
    rule <k> Vow . kiss AMOUNT => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai> ... THIS |-> VATDAI ... </vat-dai>
         <vow-ash> ASH => ASH -Rad AMOUNT </vow-ash>
       requires AMOUNT >=Rad rad(0)
        andBool AMOUNT <=Rad ASH
        andBool AMOUNT <=Rad VATDAI

    syntax VowStep ::= "flop"
 // -------------------------
    rule <k> Vow . flop => call Flop . kick THIS DUMP SUMP ... </k>
         <this> THIS </this>
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
    rule <k> Vow . flap => call Flap . kick BUMP wad(0) ... </k>
         <this> THIS </this>
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
          => call Flap . cage FLAPDAI
          ~> call Flop . cage
          ~> call Vat . heal minRad(VATDAI, VATSIN)
         ...
         </k>
         <this> THIS </this>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai>
           ...
           THIS |-> VATDAI
           Flap |-> FLAPDAI
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
