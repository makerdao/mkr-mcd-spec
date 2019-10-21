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
        <jug-addr> 0:Address </jug-addr>
        <jug-ilks> .Map      </jug-ilks> // mapping (bytes32 => JugIlk) String  |-> JugIlk
        <jug-vow>  0:Address </jug-vow>  //                             Address
        <jug-base> 0:Ray     </jug-base> //                             Ray
      </jug>
```

```k
    syntax MCDContract ::= JugContract
    syntax JugContract ::= "Jug"
    syntax MCDStep ::= JugContract "." JugStep [klabel(jugStep)]
 // ------------------------------------------------------------
    rule contract(Jug . _) => Jug
    rule [[ address(Jug) => ADDR ]] <jug-addr> ADDR </jug-addr>

    syntax JugStep ::= JugAuthStep
    syntax AuthStep ::= JugContract "." JugAuthStep [klabel(jugStep)]
 // -----------------------------------------------------------------
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
         <jug-ilks> ... ILK |-> Ilk ( ... duty: (_ => DUTY) ) ... </jug-ilks>

    rule <k> Jug . file base BASE => . ... </k>
         <jug-base> _ => BASE </jug-base>

    rule <k> Jug . file vow-file ADDR => . ... </k>
         <jug-vow> _ => ADDR </jug-vow>
```

**TODO**: Have to call it `vow-file` step to avoid conflict with `<vow>` cell.

Jug Semantics
-------------

```k
    syntax JugAuthStep ::= InitStep
 // -------------------------------
    rule <k> Jug . init ILK => . ... </k>
         <currentTime> TIME </currentTime>
         <jug-ilks> ... ILK |-> Ilk ( ... duty: ILKDUTY => 1, rho: _ => TIME ) ... </jug-ilks>
      requires ILKDUTY ==Int 0
```

```k
    syntax JugStep ::= "drip" String
 // --------------------------------
    rule <k> Jug . drip ILK => call Vat . fold ILK ADDRESS ( ( (BASE +Rat ILKDUTY) ^Rat (TIME -Int ILKRHO) ) *Rat ILKRATE ) -Rat ILKRATE ... </k>
         <currentTime> TIME </currentTime>
         <vat-ilks> ... ILK |-> Ilk ( ... rate: ILKRATE ) ... </vat-ilks>
         <jug-ilks> ... ILK |-> Ilk ( ... duty: ILKDUTY, rho: ILKRHO => TIME ) ... </jug-ilks>
         <jug-vow> ADDRESS </jug-vow>
         <jug-base> BASE </jug-base>
      requires TIME >=Int ILKRHO
```

```k
endmodule
```
