CDP Core
========

This module represents the CDP core accounting engine, mostly encompassed by state in and operations over `<vat>`.

```k
requires "kmcd-driver.k"

module CDP-CORE
    imports KMCD-DRIVER
```


-   `JugIlk`: `DUTY`, `RHO`.
-   `CatIlk`: `FLIP`, `CHOP`, `LUMP`
-   `SpotIlk`: `VALUE`, `MAT`

`Ilk` is a collateral with certain risk parameters.
Cat has stuff like penalty.

```k
    syntax JugIlk ::= Ilk ( duty: Ray, rho: Int )                    [klabel(#JugIlk), symbol]
 // ------------------------------------------------------------------------------------------

    syntax CatIlk ::= Ilk ( Art: Wad, rate: Ray, spot: Ray, line: Rad )           [klabel(#CatIlk), symbol]
 // -------------------------------------------------------------------------------------------------------

    syntax SpotIlk ::= SpotIlk ( pip: MaybeWad, mat: Ray )            [klabel(#SpotIlk), symbol]
 // --------------------------------------------------------------------------------------------
```

Vat CDP State
-------------

```k
    configuration
      <cdp-core>
        <jug>
          <jug-addr> 0:Address </jug-addr>
          <jug-ilks> .Map      </jug-ilks> // mapping (bytes32 => JugIlk) String  |-> JugIlk
          <jug-vow>  0:Address </jug-vow>  //                             Address
          <jug-base> 0:Ray     </jug-base> //                             Ray
        </jug>
        <cat>
          <cat-addr> 0:Address </cat-addr>
          <cat-ilks> .Map      </cat-ilks>
          <cat-live> true      </cat-live>
        </cat>
        <spot>
          <spot-addr> 0:Address </spot-addr>
          <spot-ilks> .Map      </spot-ilks> // mapping (bytes32 => ilk)  String  |-> SpotIlk
          <spot-par>  0:Ray     </spot-par>
        </spot>
      </cdp-core>
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
    rule <k> Jug . _ => exception ... </k> [owise]

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

Cat Semantics
-------------

```k
    syntax MCDContract ::= CatContract
    syntax CatContract ::= "Cat"
    syntax MCDStep ::= CatContract "." CatStep [klabel(catStep)]
 // ------------------------------------------------------------
    rule contract(Cat . _) => Cat
    rule [[ address(Cat) => ADDR ]] <cat-addr> ADDR </cat-addr>

    syntax CatStep ::= CatAuthStep
    syntax AuthStep ::= CatContract "." CatAuthStep [klabel(catStep)]
 // -----------------------------------------------------------------
    rule <k> Cat . _ => exception ... </k> [owise]

    syntax CatStep ::= "bite" String Address
 // ----------------------------------------

    syntax CatAuthStep ::= "cage" [klabel(#CatCage), symbol]
 // --------------------------------------------------------
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
