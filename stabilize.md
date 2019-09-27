System Stabalizer
=================

The system stabalizer takes forceful actions to mitigate risk in the MCD system.

```k
requires "cdp-core.k"
requires "collateral.k"

module SYSTEM-STABILIZER
    imports CDP-CORE
    imports COLLATERAL

    configuration
      <stabilize>
        <vow>
          <vow-addr> 0:Address </vow-addr>
          <vow-sins> .Map      </vow-sins> // mapping (uint256 => uint256) Int |-> Rad
          <vow-sin>  0:Rad     </vow-sin>
          <vow-ash>  0:Rad     </vow-ash>
          <vow-wait> 0         </vow-wait>
          <vow-dump> 0:Wad     </vow-dump>
          <vow-sump> 0:Rad     </vow-sump>
          <vow-bump> 0:Rad     </vow-bump>
          <vow-hump> 0:Rad     </vow-hump>
          <vow-live> true      </vow-live>
        </vow>
      </stabilize>
```

Vow Semantics
-------------

```k
    syntax MCDContract ::= VowContract
    syntax VowContract ::= "Vow"
    syntax MCDStep ::= VowContract "." VowStep [klabel(vowStep)]
 // ------------------------------------------------------------
    rule contract(Vow . _) => Vow
    rule [[ address(Vow) => ADDR ]] <vow-addr> ADDR </vow-addr>

    syntax VowStep ::= VowAuthStep
    syntax AuthStep ::= VowContract "." VowAuthStep [klabel(vowStep)]
 // -----------------------------------------------------------------
    rule <k> Vow . _ => exception ... </k> [owise]

    syntax VowAuthStep ::= "fess" Rad
 // ---------------------------------
    rule <k> Vow . fess TAB => . ... </k>
         <currentTime> NOW </currentTime>
         <vow-sins>
           ...
           NOW |-> (SIN' => SIN' +Rat TAB)
           ...
         </vow-sins>
         <vow-sin> SIN => SIN +Rat TAB </vow-sin>

    syntax VowStep ::= "flog" Int
 // -----------------------------
    rule <k> Vow . flog ERA => . ... </k>
         <currentTime> NOW </currentTime>
         <vow-wait> WAIT </vow-wait>
         <vow-sins>... ERA |-> (SIN' => 0) </vow-sins>
         <vow-sin> SIN => SIN -Rat SIN' </vow-sin>
      requires ERA +Int WAIT <=Int NOW

    syntax VowStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vow . heal AMOUNT
          => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH </vow-ash>
      requires AMOUNT <=Rat DAI
       andBool AMOUNT <=Rat VATSIN -Rat SIN -Rat ASH
       andBool VATSIN >=Rat SIN +Rat ASH

    syntax VowStep ::= "kiss" Rad
 // -----------------------------
    rule <k> Vow . kiss AMOUNT
          => call Vat . heal AMOUNT ... </k>
         <this> THIS </this>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vow-ash> ASH => ASH -Rat AMOUNT </vow-ash>
       requires AMOUNT <=Rat ASH
        andBool AMOUNT <=Rat DAI

    syntax VowStep ::= "flop"
 // -------------------------
    rule <k> Vow . flop
          => call Flop . kick THIS DUMP SUMP ... </k>
         <this> THIS </this>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
         <vow-sin> SIN </vow-sin>
         <vow-ash> ASH => ASH +Rat SUMP </vow-ash>
         <vow-sump> SUMP </vow-sump>
         <vow-dump> DUMP </vow-dump>
      requires SUMP <=Rat VATSIN -Rat SIN -Rat ASH
       andBool VATSIN >=Rat SIN +Rat ASH
       andBool DAI ==Int 0

    syntax VowStep ::= "flap"
 // -------------------------
    rule <k> Vow . flap
          => call Flap . kick BUMP 0 ... </k>
         <this> THIS </this>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           ...
         </vat-dai>
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
          ~> call Vat . heal minRat(DAI, VATSIN) ... </k>
         <this> THIS </this>
         <vat-sin>
           ...
           THIS |-> VATSIN
           ...
         </vat-sin>
         <vat-dai>
           ...
           THIS |-> DAI
           address(Flap) |-> FLAPDAI
           ...
         </vat-dai>
         <vow-live> _ => false </vow-live>
         <vow-sin> _ => 0 </vow-sin>
         <vow-ash> _ => 0 </vow-ash>
```

```k
endmodule
```
