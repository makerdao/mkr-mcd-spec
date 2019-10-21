```k
requires "kmcd-driver.k"
requires "vat.k"

module JUG
    imports KMCD-DRIVER
    imports VAT
```

-   `JugIlk`: `DUTY`, `RHO`.

```k
    syntax JugIlk ::= Ilk ( duty: Ray, rho: Int )                    [klabel(#JugIlk), symbol]
 // ------------------------------------------------------------------------------------------
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

Jug Semantics
-------------

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

    syntax JugAuthStep ::= InitStep
 // -------------------------------
    rule <k> Jug . init ILK => . ... </k>
         <currentTime> TIME </currentTime>
         <jug-ilks> ... ILK |-> Ilk ( ILKDUTY => 1, _ => TIME ) ... </jug-ilks>
      requires ILKDUTY ==Int 0
```

```k
    syntax JugStep ::= "drip" String
 // --------------------------------
    rule <k> Jug . drip ILK => call Vat . fold ILK ADDRESS ( ( (BASE +Rat ILKDUTY) ^Rat (TIME -Int ILKRHO) ) *Rat ILKRATE ) -Rat ILKRATE ... </k>
         <currentTime> TIME </currentTime>
         <vat-ilks> ... ILK |-> Ilk ( _, ILKRATE, _, _, _ ) ... </vat-ilks>
         <jug-ilks> ... ILK |-> Ilk ( ILKDUTY, ILKRHO => TIME ) ... </jug-ilks>
         <jug-vow> ADDRESS </jug-vow>
         <jug-base> BASE </jug-base>
      requires TIME >=Int ILKRHO
```

```k
endmodule
```
