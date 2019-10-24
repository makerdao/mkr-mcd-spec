```k
requires "kmcd-driver.k"
requires "vat.k"

module POT
    imports KMCD-DRIVER
    imports VAT
```

Pot Configuration
-----------------

```k
    configuration
      <pot>
        <pot-wards> .Set      </pot-wards>
        <pot-pies>  .Map      </pot-pies> // mapping (address => uint256) Address |-> Wad
        <pot-pie>   0:Wad     </pot-pie>
        <pot-dsr>   1:Ray     </pot-dsr>
        <pot-chi>   1:Rat     </pot-chi> // arbitrary precision
        <pot-vow>   0:Address </pot-vow>
        <pot-rho>   0         </pot-rho>
        <pot-live>  true      </pot-live>
      </pot>
```

```k
    syntax MCDContract ::= PotContract
    syntax PotContract ::= "Pot"
    syntax MCDStep ::= PotContract "." PotStep [klabel(potStep)]
 // ------------------------------------------------------------
    rule contract(Pot . _) => Pot
```

Pot Authorization
-----------------

```k
    syntax PotStep  ::= PotAuthStep
    syntax AuthStep ::= PotContract "." PotAuthStep [klabel(potStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Pot) => WARDS ]] <pot-wards> WARDS </pot-wards>

    syntax PotAuthStep ::= WardStep
 // -------------------------------
    rule <k> Pot . rely ADDR => . ... </k>
         <pot-wards> ... (.Set => SetItem(ADDR)) </pot-wards>

    rule <k> Pot . deny ADDR => . ... </k>
         <pot-wards> WARDS => WARDS -Set SetItem(ADDR) </pot-wards>
```

File-able Fields
----------------

These parameters are controlled by governance:

-   `dsr`: interest rate of the Dai savings accounts.
-   `vow`: where debt is accumulated to offset user savings.

```k
    syntax PotAuthStep ::= "file" PotFile
 // -------------------------------------

    syntax PotFile ::= "dsr" Ray
                     | "vow-file" Address
 // -------------------------------------
    rule <k> Pot . file dsr DSR => . ... </k>
         <pot-dsr> _ => DSR </pot-dsr>

    rule <k> Pot . file vow-file ADDR => . ... </k>
         <pot-vow> _ => ADDR </pot-vow>
```

**TODO**: Need to use `vow-file` as name to avoid conflict with `<vow>` cell.

Pot Semantics
-------------

```k
    syntax PotStep ::= "drip"
 // -------------------------
    rule <k> Pot . drip => call Vat . suck VOW THIS ( PIE *Rat CHI *Rat ( DSR ^Rat (NOW -Int RHO) -Rat 1 ) ) ... </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <pot-chi> CHI => CHI *Rat DSR ^Rat (NOW -Int RHO) </pot-chi>
         <pot-rho> RHO => NOW </pot-rho>
         <pot-dsr> DSR </pot-dsr>
         <pot-vow> VOW </pot-vow>
         <pot-pie> PIE </pot-pie>
      requires NOW >=Int RHO
       andBool DSR >=Rat 1 // to ensure positive interest rate

    syntax PotStep ::= "join" Wad
 // -----------------------------
    rule <k> Pot . join WAD => call Vat . move MSGSENDER THIS ( CHI *Rat WAD ) ... </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-pies> ... MSGSENDER |-> ( MSGSENDER_PIE => MSGSENDER_PIE +Rat WAD ) ... </pot-pies>
         <pot-pie> PIE => PIE +Rat WAD </pot-pie>
         <pot-chi> CHI </pot-chi>
         <pot-rho> RHO </pot-rho>
      requires NOW ==Int RHO

    syntax PotStep ::= "exit" Wad
 // -----------------------------
    rule <k> Pot . exit WAD => call Vat . move THIS MSGSENDER ( CHI *Rat WAD ) ... </k>
         <this> THIS </this>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-pies> ... MSGSENDER |-> ( MSGSENDER_PIE => MSGSENDER_PIE -Rat WAD ) ... </pot-pies>
         <pot-pie> PIE => PIE -Rat WAD </pot-pie>
         <pot-chi> CHI </pot-chi>

    syntax PotAuthStep ::= "cage"
 // -----------------------------
    rule <k> Pot . cage => . ... </k>
         <pot-live> _ => false </pot-live>
         <pot-dsr> _ => 1 </pot-dsr>
```

```k
endmodule
```
