```k
requires "kmcd-driver.k"
requires "vat.k"

module JUG
    imports KMCD-DRIVER
    imports VAT
```

Jug Configuration
-----------------

```k
    configuration
      <jug>
        <jug-wards> .Set      </jug-wards>
        <jug-ilks>  .Map      </jug-ilks> // mapping (bytes32 => JugIlk) String  |-> JugIlk
        <jug-vow>   0:Address </jug-vow>  //                             Address
        <jug-base>  0:Ray     </jug-base> //                             Ray
      </jug>
```

```k
    syntax MCDContract ::= JugContract
    syntax JugContract ::= "Jug"
    syntax MCDStep ::= JugContract "." JugStep [klabel(jugStep)]
 // ------------------------------------------------------------
    rule contract(Jug . _) => Jug
```

Jug Authorization
-----------------

```k
    syntax JugStep  ::= JugAuthStep
    syntax AuthStep ::= JugContract "." JugAuthStep [klabel(jugStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Jug) => WARDS ]] <jug-wards> WARDS </jug-wards>

    syntax JugAuthStep ::= WardStep
 // -------------------------------
    rule <k> Jug . rely ADDR => . ... </k>
         <jug-wards> ... (.Set => SetItem(ADDR)) </jug-wards>

    rule <k> Jug . deny ADDR => . ... </k>
         <jug-wards> WARDS => WARDS -Set SetItem(ADDR) </jug-wards>
```

Jug Data
--------

-   `JugIlk` tracks the ilk parameters for stability fee collection:

    -   `duty`: risk premium used for calculating stability fee for this ilk.
    -   `rho`: last time stability fee was collected for this ilk.

```k
    syntax JugIlk ::= Ilk ( duty: Ray, rho: Int ) [klabel(#JugIlk), symbol]
 // -----------------------------------------------------------------------
```

File-able Fields
----------------

These parameters are controlled by governance:

-   `duty`: risk premium for a given ilk.
-   `base`: stability fee rate.
-   `vow`: address which accumulates stability fees.

```k
    syntax JugAuthStep ::= "file" JugFile
 // -------------------------------------

    syntax JugFile ::= "duty" String Ray
                     | "base" Ray
                     | "vow-file" Address
 // -------------------------------------
    rule <k> Jug . file duty ILKID DUTY => . ... </k>
         <jug-ilks> ... ILK |-> Ilk ( ... duty: (_ => DUTY) , rho: RHO ) ... </jug-ilks>
         <current-time> NOW </current-time>
      requires NOW ==Int RHO

    rule <k> Jug . file base BASE => . ... </k>
         <jug-base> _ => BASE </jug-base>

    rule <k> Jug . file vow-file ADDR => . ... </k>
         <jug-vow> _ => ADDR </jug-vow>
```

**TODO**: Have to call it `vow-file` step to avoid conflict with `<vow>` cell.

Jug Semantics
-------------

```k
    syntax JugAuthStep ::= "init" String
 // ------------------------------------
    rule <k> Jug . init ILK => . ... </k>
         <current-time> NOW </current-time>
         <jug-ilks> ... ILK |-> Ilk ( ... duty: 0 => 1, rho: _ => NOW ) ... </jug-ilks>
```

```k
    syntax JugStep ::= "drip" String
 // --------------------------------
    rule <k> Jug . drip ILK => call Vat . fold ILK ADDRESS ( ( (BASE +Rat ILKDUTY) ^Rat (TIME -Int ILKRHO) ) *Rat ILKRATE ) -Rat ILKRATE ... </k>
         <current-time> TIME </current-time>
         <vat-ilks> ... ILK |-> Ilk ( ... rate: ILKRATE ) ... </vat-ilks>
         <jug-ilks> ... ILK |-> Ilk ( ... duty: ILKDUTY, rho: ILKRHO => TIME ) ... </jug-ilks>
         <jug-vow> ADDRESS </jug-vow>
         <jug-base> BASE </jug-base>
      requires TIME >=Int ILKRHO
```

```k
endmodule
```
