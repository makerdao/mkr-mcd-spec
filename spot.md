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
        <spot-wards> .Set  </spot-wards>
        <spot-ilks>  .Map  </spot-ilks> // mapping (bytes32 => ilk)  String  |-> SpotIlk
        <spot-par>   0:Ray </spot-par>
      </spot>
```

```k
    syntax MCDContract ::= SpotContract
    syntax SpotContract ::= "Spot"
    syntax MCDStep ::= SpotContract "." SpotStep [klabel(spotStep)]
 // ---------------------------------------------------------------
    rule contract(Spot . _) => Spot
    rule address(Spot) => "SPOT"
```

Spot Authorization
------------------

```k
    syntax SpotStep ::= SpotAuthStep
    syntax AuthStep ::= SpotContract "." SpotAuthStep [klabel(spotStep)]
 // --------------------------------------------------------------------
    rule [[ wards(Spot) => WARDS ]] <spot-wards> WARDS </spot-wards>

    syntax SpotAuthStep ::= WardStep
 // -------------------------------
    rule <k> Spot . rely ADDR => . ... </k>
         <spot-wards> ... (.Set => SetItem(ADDR)) </spot-wards>

    rule <k> Spot . deny ADDR => . ... </k>
         <spot-wards> WARDS => WARDS -Set SetItem(ADDR) </spot-wards>
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
-   `par`: reference number for 1 Dai, used to scale target value of a single Dai (newer version of Target Rate Feedback Mechanism).

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
