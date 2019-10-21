```k
requires "kmcd-driver.k"
requires "vat.k"

module SPOT
    imports KMCD-DRIVER
    imports VAT
```

-   `SpotIlk`: `VALUE`, `MAT`

`pip` represents the value of the Ilk as returned by a Pip (oracle)

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

    syntax Event ::= Poke(String, Wad, Ray)
 // ---------------------------------------

    syntax SpotStep ::= "poke" String
 // ---------------------------------
    rule <k> Spot . poke ILK => . ... </k>
         <vat-ilks>...
           ILK |-> Ilk (... spot: _ => (VALUE /Rat PAR) /Rat MAT )
         ...</vat-ilks>
         <spot-ilks>...
           ILK |-> SpotIlk (... pip: VALUE, mat: MAT )
         ...</spot-ilks>
         <spot-par> PAR </spot-par>
         <frame-events> _ => ListItem(Poke(ILK, VALUE, VALUE /Rat PAR /Rat MAT)) </frame-events>
      requires VALUE =/=K .Wad

    rule <k> Spot . poke ILK => . ... </k>
         <spot-ilks> ... ILK |-> SpotIlk (... pip: .Wad) ... </spot-ilks>
         <frame-events> _ => .List </frame-events>
```

```k
endmodule
```
