```k
requires "kmcd-driver.k"
requires "vat.k"

module SPOT
    imports KMCD-DRIVER
    imports VAT
```

-   `SpotIlk`: `VALUE`, `MAT`

```k
    syntax SpotIlk ::= SpotIlk ( pip: MaybeWad, mat: Ray )            [klabel(#SpotIlk), symbol]
 // --------------------------------------------------------------------------------------------
```

Spot Configuration
------------------

```k
    configuration
      <spot>
        <spot-addr> 0:Address </spot-addr>
        <spot-ilks> .Map      </spot-ilks> // mapping (bytes32 => ilk)  String  |-> SpotIlk
        <spot-par>  0:Ray     </spot-par>
      </spot>
```

Spot Semantics
--------------

```k
    syntax MCDContract ::= SpotContract
    syntax SpotContract ::= "Spot"
    syntax MCDStep ::= SpotContract "." SpotStep [klabel(spotStep)]
 // ---------------------------------------------------------------
    rule contract(Spot . _) => Spot
    rule [[ address(Spot) => ADDR ]] <spot-addr> ADDR </spot-addr>

    syntax SpotAuthStep
    syntax SpotStep ::= SpotAuthStep
    syntax AuthStep ::= SpotContract "." SpotAuthStep [klabel(spotStep)]
 // --------------------------------------------------------------------
    rule <k> Spot . _ => exception ... </k> [owise]

    syntax SpotStep ::= "poke" String
 // ---------------------------------
    rule <k> Spot . poke ILK => . ... </k>
         <vat-ilks> ... ILK |-> Ilk ( _, _, ( _ => (VALUE /Rat PAR) /Rat MAT ), _, _ ) ... </vat-ilks>
         <spot-ilks> ... ILK |-> SpotIlk ( VALUE, MAT ) ... </spot-ilks>
         <spot-par> PAR </spot-par>
      requires VALUE =/=K .Wad

    rule <k> Spot . poke ILK => . ... </k>
         <spot-ilks> ... ILK |-> SpotIlk ( .Wad, _ ) ... </spot-ilks>
```

```k
endmodule
```
