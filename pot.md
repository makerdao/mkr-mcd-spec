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
        <pot-pie>   wad(0)    </pot-pie>
        <pot-dsr>   ray(1)    </pot-dsr>
        <pot-chi>   ray(1)    </pot-chi>
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
         <pot-rho> RHO </pot-rho>
         <current-time> NOW </current-time>
         <pot-live> true </pot-live>
      requires NOW ==Int RHO
       andBool DSR >=Ray ray(0)

    rule <k> Pot . file vow-file ADDR => . ... </k>
         <pot-vow> _ => ADDR </pot-vow>
```

**TODO**: Need to use `vow-file` as name to avoid conflict with `<vow>` cell.

Pot Initialization
------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `initUser`: Add the given user's account to the pies.

```k
    syntax PotAuthStep ::= "initUser" Address
 // -----------------------------------------
    rule <k> Pot . initUser ADDR => . ... </k>
         <pot-pies> PIES => PIES [ ADDR <- wad(0) ] </pot-pies>
      requires notBool ADDR in_keys(PIES)
```

Pot Semantics
-------------

```k
    syntax PotStep ::= "drip"
 // -------------------------
    rule <k> Pot . drip => call Vat . suck VOW THIS ( PIE *Rate ( CHI *Ray ( DSR ^Ray (NOW -Int RHO) -Ray ray(1) ) ) ) ... </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <pot-chi> CHI => CHI *Ray (DSR ^Ray (NOW -Int RHO)) </pot-chi>
         <pot-rho> RHO => NOW </pot-rho>
         <pot-dsr> DSR </pot-dsr>
         <pot-vow> VOW </pot-vow>
         <pot-pie> PIE </pot-pie>
      requires NOW >=Int RHO
       andBool DSR >=Ray ray(1) // to ensure positive interest rate

    syntax PotStep ::= "join" Wad
 // -----------------------------
    rule <k> Pot . join AMOUNT => call Vat . move MSGSENDER THIS ( AMOUNT *Rate CHI ) ... </k>
         <this> THIS </this>
         <current-time> NOW </current-time>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-pies> ... MSGSENDER |-> ( MSGSENDER_PIE => MSGSENDER_PIE +Wad AMOUNT ) ... </pot-pies>
         <pot-pie> PIE => PIE +Wad AMOUNT </pot-pie>
         <pot-chi> CHI </pot-chi>
         <pot-rho> RHO </pot-rho>
      requires AMOUNT >=Wad wad(0)
       andBool NOW ==Int RHO

    syntax PotStep ::= "exit" Wad
 // -----------------------------
    rule <k> Pot . exit AMOUNT => call Vat . move THIS MSGSENDER ( AMOUNT *Rate CHI ) ... </k>
         <this> THIS </this>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-pies> ... MSGSENDER |-> ( MSGSENDER_PIE => MSGSENDER_PIE -Wad AMOUNT ) ... </pot-pies>
         <pot-pie> PIE => PIE -Wad AMOUNT </pot-pie>
         <pot-chi> CHI </pot-chi>
      requires AMOUNT >=Wad wad(0)
       andBool MSGSENDER_PIE >=Wad AMOUNT

    syntax PotAuthStep ::= "cage"
 // -----------------------------
    rule <k> Pot . cage => . ... </k>
         <pot-live> _ => false </pot-live>
         <pot-dsr> _ => ray(1) </pot-dsr>
```

```k
endmodule
```
