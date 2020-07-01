```k
requires "kmcd-driver.md"
requires "vat.md"

module SPOT
    imports KMCD-DRIVER
    imports VAT
```

Spot Configuration
------------------

```k
    configuration
      <spot>
        <spot-wards> .Set   </spot-wards>
        <spot-ilks>  .Map   </spot-ilks> // mapping (bytes32 => ilk)  String  |-> SpotIlk
        <spot-par>   ray(1) </spot-par>
        <spot-live>  true   </spot-live>
      </spot>
```

```k
    syntax MCDContract ::= SpotContract
    syntax SpotContract ::= "Spot"
    syntax MCDStep ::= SpotContract "." SpotStep [klabel(spotStep)]
 // ---------------------------------------------------------------
    rule contract(Spot . _) => Spot
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
    rule <k> Spot . file pip ILK_ID .Wad => . ... </k>
         <spot-live> true </spot-live>
         <spot-ilks> ... ILK_ID |-> SpotIlk ( ... pip: (_ => .Wad) ) ... </spot-ilks>

    rule <k> Spot . file pip ILK_ID PRICE:Wad => . ... </k>
         <spot-live> true </spot-live>
         <spot-ilks> ... ILK_ID |-> SpotIlk ( ... pip: (_ => PRICE) ) ... </spot-ilks>
      requires PRICE >=Wad wad(0)

    rule <k> Spot . file mat ILK_ID MAT => . ... </k>
         <spot-live> true </spot-live>
         <spot-ilks> ... ILK_ID |-> SpotIlk ( ... mat: (_ => MAT) ) ... </spot-ilks>
      requires MAT >=Ray ray(0)

    rule <k> Spot . file par PAR => . ... </k>
         <spot-live> true </spot-live>
         <spot-par> _ => PAR </spot-par>
      requires PAR >=Ray ray(0)
```

**TODO**: We currently store a `MaybeWad` for `pip` instead of a contract address to call to get that data.

Spot Events
-----------

```k
    syntax CustomEvent ::= Poke(String, Wad, Ray) [klabel(Poke)   , symbol]
                         | NoPoke(String)         [klabel(NoPoke) , symbol]
 // -----------------------------------------------------------------------
```

Spot Initialization
-------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `init`: Initialize the spotter for a given ilk.
-   `setPrice`: Manually inject a value for the price feed of a given ilk.

```k
    syntax SpotAuthStep ::= "init"     String
                          | "setPrice" String Wad
 // ---------------------------------------------
    rule <k> Spot . init ILK_ID => . ... </k>
         <spot-ilks> ILKS => ILKS [ ILK_ID <- SpotIlk( ... pip: .Wad, mat: ray(0) ) ] </spot-ilks>
      requires notBool ILK_ID in_keys(ILKS)

    rule <k> Spot . setPrice ILK_ID PRICE => . ... </k>
         <spot-ilks> ... ILK_ID |-> SpotIlk( ... pip: (_ => PRICE) ) ... </spot-ilks>
```

Spot Semantics
--------------

```k
    syntax SpotStep ::= "poke" String
 // ---------------------------------
    rule <k> Spot . poke ILK_ID => call Vat . file spot ILK_ID ((Wad2Ray(VALUE) /Ray PAR) /Ray MAT) ... </k>
         <spot-ilks> ... ILK_ID |-> SpotIlk (... pip: VALUE, mat: MAT ) ... </spot-ilks>
         <spot-par> PAR </spot-par>
         <frame-events> ... (.List => ListItem(Poke(ILK_ID, VALUE, (Wad2Ray(VALUE) /Ray PAR) /Ray MAT))) </frame-events>
      requires VALUE =/=K .Wad

    rule <k> Spot . poke ILK_ID => . ... </k>
         <spot-ilks> ... ILK_ID |-> SpotIlk (... pip: .Wad) ... </spot-ilks>
         <frame-events> ... (.List => ListItem(NoPoke(ILK_ID))) </frame-events>
```
Spot Deactivation
-----------------

-   `Spot.cage` disables access to this instance of Spot.

```k
    syntax SpotAuthStep ::= "cage" [klabel(#SpotCage), symbol]
 // --------------------------------------------------------
    rule <k> Spot . cage => . ... </k>
         <spot-live> _ => false </spot-live>
```

```k
endmodule
```
