```k
requires "kmcd-driver.k"
requires "vat.k"

module SPOT
    imports KMCD-DRIVER
    imports VAT
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
```

Spot Data
---------

-   `SpotIlk` tracks the price parameters of a given ilk:

    -   `pip`: potential new price from feed.
    -   `mat`: the liquidation ratio for a given ilk.

```k
    syntax SpotIlk ::= SpotIlk ( pip: MaybeWad, mat: Ray ) [klabel(#SpotIlk), symbol]
 // ---------------------------------------------------------------------------------
```

**TODO**: Instead of holding the contract to call to get the new price in `pip`, we are holding the "potential new price" directly.

File-able Fields
----------------

These parameters are controlled by governance/oracles:

-   `pip`: next price to give from price feed.
-   `mat`: liquidation ratio for a given ilk.
-   `par`: **TODO** it's unclear.
    Wiki page says "relationship between Dai and 1 unit of value in the price. (Similar to TRFM.)", but that would seem to require storing one `par` per ilk.
    Perhaps this means "actual price of Dai?", as in "how off-stable is Dai"?

```k
    syntax SpotAuthStep ::= "file" SpotFile
 // ---------------------------------------

    syntax SpotFile ::= "pip" String MaybeWad
                      | "mat" String Ray
                      | "par" Ray
 // -----------------------------
    rule <k> Spot . file pip ILKID PIP => . ... </k>
         <spot-ilks> ... ILKID |-> SpotIlk ( ... pip: (_ => PIP) ) ... </spot-ilks>

    rule <k> Spot . file mat ILKID MAT => . ... </k>
         <spot-ilks> ... ILKID |-> SpotIlk ( ... mat: (_ => MAT) ) ... </spot-ilks>

    rule <k> Spot . file par PAR => . ... </k>
         <spot-par> _ => PAR </spot-par>
```

**TODO**: We currently store a `MaybeWad` for `pip` instead of a contract address to call to get that data.

Spot Events
-----------

```k
    syntax Event ::= Poke(String, Wad, Ray)
 // ---------------------------------------
```

Spot Semantics
--------------

```k
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
