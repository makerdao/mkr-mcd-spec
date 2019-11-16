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
        <vow-wards> .Set  </vow-wards>
        <vow-sins>  .Map  </vow-sins> // mapping (uint256 => uint256) Int |-> Rad
        <vow-sin>   0:Rad </vow-sin>
        <vow-ash>   0:Rad </vow-ash>
        <vow-wait>  0     </vow-wait>
        <vow-dump>  0:Wad </vow-dump>
        <vow-sump>  0:Rad </vow-sump>
        <vow-bump>  0:Rad </vow-bump>
        <vow-hump>  0:Rad </vow-hump>
        <vow-live>  true  </vow-live>
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

    rule <k> Vow . file bump BUMP => . ... </k>
         <vow-bump> _ => BUMP </vow-bump>

    rule <k> Vow . file hump HUMP => . ... </k>
         <vow-hump> _ => HUMP </vow-hump>

    rule <k> Vow . file sump SUMP => . ... </k>
         <vow-sump> _ => SUMP </vow-sump>

    rule <k> Vow . file dump DUMP => . ... </k>
         <vow-dump> _ => DUMP </vow-dump>
```

Vow Semantics
-------------

```k
    syntax VowAuthStep ::= "fess" Rad
 // ---------------------------------
    rule <k> Vow . fess TAB => . ... </k>
         <current-time> NOW </current-time>
         <vow-sins> ... NOW |-> (SIN' => SIN' +Rat TAB) ... </vow-sins>
         <vow-sin> SIN => SIN +Rat TAB </vow-sin>

    syntax VowStep ::= "flog" Int
 // -----------------------------
    rule <k> Vow . flog ERA => . ... </k>
         <current-time> NOW </current-time>
         <vow-wait> WAIT </vow-wait>
         <vow-sins> ... ERA |-> (SIN' => 0) ... </vow-sins>
         <vow-sin> SIN => SIN -Rat SIN' </vow-sin>
      requires ERA +Int WAIT <=Int NOW

    syntax VowStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vow . heal AMOUNT => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai> ... THIS |-> DAI ... </vat-dai>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
      requires AMOUNT <=Rat DAI
       andBool AMOUNT <=Rat VATSIN -Rat SIN -Rat ASH
       andBool VATSIN >=Rat SIN +Rat ASH

    syntax VowStep ::= "kiss" Rad
 // -----------------------------
    rule <k> Vow . kiss AMOUNT => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai> ... THIS |-> DAI ... </vat-dai>
         <vow-ash> ASH => ASH -Rat AMOUNT </vow-ash>
       requires AMOUNT <=Rat ASH
        andBool AMOUNT <=Rat DAI

    syntax VowStep ::= "flop"
 // -------------------------
    rule <k> Vow . flop => call Flop . kick THIS DUMP SUMP ... </k>
         <this> THIS </this>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai> ... THIS |-> DAI ... </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH => ASH +Rat SUMP </vow-ash>
         <vow-sump> SUMP </vow-sump>
         <vow-dump> DUMP </vow-dump>
      requires SUMP <=Rat VATSIN -Rat SIN -Rat ASH
       andBool VATSIN >=Rat SIN +Rat ASH
       andBool DAI ==Int 0

    syntax VowStep ::= "flap"
 // -------------------------
    rule <k> Vow . flap => call Flap . kick BUMP 0 ... </k>
         <this> THIS </this>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai> ... THIS |-> DAI ... </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
         <vow-bump> BUMP </vow-bump>
         <vow-hump> HUMP </vow-hump>
      requires DAI >=Rat VATSIN +Rat BUMP +Rat HUMP
       andBool VATSIN -Rat SIN -Rat ASH ==Rat 0

    syntax VowAuthStep ::= "cage"
 // -----------------------------
    rule <k> Vow . cage
          => call Flap . cage FLAPDAI
          ~> call Flop . cage
          ~> call Vat . heal minRat(DAI, VATSIN)
         ...
         </k>
         <this> THIS </this>
         <vat-sin> ... THIS |-> VATSIN ... </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           Flap |-> FLAPDAI
           ...
         </vat-dai>
         <vow-live> _ => false </vow-live>
         <vow-sin> _ => 0 </vow-sin>
         <vow-ash> _ => 0 </vow-ash>
      requires THIS =/=K Flap
```

```k
endmodule
```
