```k
requires "kmcd-driver.md"
requires "vat.md"

module JUG
    imports KMCD-DRIVER
    imports VAT
```

Jug Configuration
-----------------

```k
    configuration
      <jug>
        <jug-vat>   0:Address </jug-vat>
        <jug-wards> .Set      </jug-wards>
        <jug-ilks>  .Map      </jug-ilks> // mapping (bytes32 => JugIlk) String  |-> JugIlk
        <jug-vow>   0:Address </jug-vow>  //                             Address
        <jug-base>  ray(0)    </jug-base> //                             Ray
      </jug>
```

```k
    syntax MCDContract ::= JugContract
    syntax JugContract ::= "Jug"
    syntax MCDStep ::= JugContract "." JugStep [klabel(jugStep)]

    syntax CallStep ::= JugStep
    syntax Op       ::= JugOp
    syntax Args     ::= JugArgs
 // ------------------------------------------------------------
    rule contract(Jug . _) => Jug
```

### Constructor

```k
    syntax JugConstructorOp ::= "constructor" [token]
    syntax JugOp            ::= JugConstructorOp
    syntax JugAddressArgs   ::= Address
    syntax JugArgs          ::= JugAddressArgs
    syntax JugStep          ::= JugConstructorOp JugAddressArgs
 // ---------------------------------------------
    rule <k> Jug . constructor JUG_VAT => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <jug> _ </jug>
        => <jug>
             <jug-vat> JUG_VAT </jug-vat>
             <jug-wards> SetItem(MSGSENDER) </jug-wards>
             ...
           </jug>
         )
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
    syntax JugFileOp    ::= "file"
    syntax JugOp        ::= JugFileOp
    syntax JugArgs      ::= JugFileArgs
    syntax JugFileArgs  ::= "duty" String Ray
                          | "base" Ray
                          | "vow-file" Address

    syntax JugAuthStep  ::= JugFileOp JugFileArgs
 // -------------------------------------
    rule <k> Jug . file duty ILK_ID DUTY => . ... </k>
         <jug-ilks> ... ILK_ID |-> Ilk ( ... duty: (_ => DUTY) , rho: RHO ) ... </jug-ilks>
         <current-time> NOW </current-time>
      requires NOW ==Int RHO
       andBool DUTY >=Ray ray(0)

    rule <k> Jug . file base BASE => . ... </k>
         <jug-base> _ => BASE </jug-base>
      requires BASE >=Ray ray(0)

    rule <k> Jug . file vow-file ADDR => . ... </k>
         <jug-vow> _ => ADDR </jug-vow>
```

**TODO**: Have to call it `vow-file` step to avoid conflict with `<vow>` cell.

Jug Semantics
-------------

```k
    syntax JugInitOp     ::= "init"
    syntax JugOp         ::= JugInitOp
    syntax JugStringArgs ::= String
    syntax JugArgs       ::= JugStringArgs
    syntax JugAuthStep   ::= JugInitOp JugStringArgs
 // ------------------------------------
    rule <k> Jug . init ILK_ID => . ... </k>
         <current-time> NOW </current-time>
         <jug-ilks> ... ILK_ID |-> Ilk ( ... duty: ray(0) => ray(1), rho: _ => NOW ) ... </jug-ilks>

    rule <k> Jug . init ILK_ID ... </k>
         <jug-ilks> JUG_ILKS => JUG_ILKS [ ILK_ID <- Ilk ( ... duty: ray(0) , rho: 0 ) ] </jug-ilks>
      requires notBool ILK_ID in_keys(JUG_ILKS)
```

```k
    syntax JugDripOp ::= "drip"
    syntax JugOp     ::= JugDripOp
    syntax JugStep   ::= JugDripOp JugStringArgs
 // --------------------------------
    rule <k> Jug . drip ILK_ID => call JUG_VAT . fold ILK_ID JUG_VOW ( ( (BASE +Ray ILKDUTY) ^Ray (TIME -Int ILKRHO) ) *Ray ILKRATE ) -Ray ILKRATE ... </k>
         <current-time> TIME </current-time>
         <jug-vat> JUG_VAT </jug-vat>
         <vat-ilks> ... ILK_ID |-> Ilk ( ... rate: ILKRATE ) ... </vat-ilks>
         <jug-ilks> ... ILK_ID |-> Ilk ( ... duty: ILKDUTY, rho: ILKRHO => TIME ) ... </jug-ilks>
         <jug-vow> JUG_VOW </jug-vow>
         <jug-base> BASE </jug-base>
      requires TIME >=Int ILKRHO
```

```k
endmodule
```
