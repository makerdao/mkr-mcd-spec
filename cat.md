```k
requires "kmcd-driver.k"
requires "flip.k"
requires "vat.k"
requires "vow.k"

module CAT
    imports KMCD-DRIVER
    imports FLIP
    imports VAT
    imports VOW
```

Cat Configuration
-----------------

```k
    configuration
      <cat>
        <cat-wards> .Set      </cat-wards>
        <cat-ilks>  .Map      </cat-ilks>
        <cat-live>  true      </cat-live>
        <cat-vow>   0:Address </cat-vow>
      </cat>
```

```k
    syntax MCDContract ::= CatContract
    syntax CatContract ::= "Cat"
    syntax MCDStep ::= CatContract "." CatStep [klabel(catStep)]
 // ------------------------------------------------------------
    rule contract(Cat . _) => Cat
```

Cat Authorization
-----------------

```k
    syntax CatStep  ::= CatAuthStep
    syntax AuthStep ::= CatContract "." CatAuthStep [klabel(catStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Cat) => WARDS ]] <cat-wards> WARDS </cat-wards>

    syntax CatAuthStep ::= WardStep
 // -------------------------------
    rule <k> Cat . rely ADDR => . ... </k>
         <cat-wards> ... (.Set => SetItem(ADDR)) </cat-wards>

    rule <k> Cat . deny ADDR => . ... </k>
         <cat-wards> WARDS => WARDS -Set SetItem(ADDR) </cat-wards>
```

Cat Data
--------

-   `CatIlk` tracks parameters needed for `bite`ing CDPs.

    -   `chop`: liquidation penalty (scaling parameter to reduce amount of `ink` retrievable from auction upon liquidation).
    -   `lump`: maximum liquidation lot quantity.

```k
    syntax CatIlk ::= Ilk ( chop: Ray, lump: Wad ) [klabel(#CatIlk), symbol]
 // ------------------------------------------------------------------------
```

**NOTE**: The `flip` liquidator address is not included in `CatIlk` because we assume a unique `Flipper` for each `Ilk`.

Cat Events
----------

```k
    syntax Event ::= Bite(ilk: String, urn: Address, ink: Wad, art: Wad, tab: Wad, flip: Address, id: Int) [klabel(Bite), symbol]
 // -----------------------------------------------------------------------------------------------------------------------------

    syntax CatStep ::= "emitBite" String Address Wad Wad Wad
 // --------------------------------------------------------
    rule <k> emitBite ILK URN INK ART TAB => ID ... </k>
         <return-value> ID:Int </return-value>
         <frame-events> _ => ListItem(Bite(ILK, URN, INK, ART, TAB, Flip ILK, ID)) </frame-events>
```

File-able Fields
----------------

The parameters controlled by governance are:

-   `vow`: debt accumulator for bitten CDPs.
-   `chop`: liquidation penalty.
-   `lump`: liquidation lot quantity.

```k
    syntax CatFile ::= "vow-file" Address
                     | "chop" String Ray
                     | "lump" String Wad
 // ------------------------------------

    syntax CatAuthStep ::= "file" CatFile
 // -------------------------------------
    rule <k> Cat . file vow-file ADDR => . ... </k>
         <cat-vow> _ => ADDR </cat-vow>

    rule <k> Cat . file chop ILKID CHOP => . ... </k>
         <cat-ilks> ... ILKID |-> Ilk ( ... chop: (_ => CHOP) ) ... </cat-ilks>

    rule <k> Cat . file lump ILKID LUMP => . ... </k>
         <cat-ilks> ... ILKID |-> Ilk ( ... lump: (_ => LUMP) ) ... </cat-ilks>
```

**NOTE**: `flip` is not fileable since we are assuming a unique liquidator for each ilk.

**TODO**: Have to name it `vow-file` fileable step to avoid conflict with `<vow>` cell.

Cat Semantics
-------------

```k
    syntax CatStep ::= "bite" String Address
 // ----------------------------------------
    rule <k> Cat . bite ILK URN
          => #fun(LOT
          => #fun(ART
          => #fun(TAB
          => call Vat . grab ILK URN THIS VOWADDR (-1 *Rat LOT) (-1 *Rat ART)
          ~> call Vow . fess TAB
          ~> call Flip ILK . kick URN VOWADDR (TAB *Rat CHOP) LOT 0
          ~> emitBite ILK URN LOT ART TAB)
          (ART *Rat RATE))
          (minRat(URNART, LOT *Rat URNART /Rat INK)))
          (minRat(INK, LUMP))
         ...
         </k>
         <this> THIS </this>
         <cat-live> true </cat-live>
         <cat-ilks> ... ILK |-> Ilk(... chop: CHOP, lump: LUMP) ... </cat-ilks>
         <vat-ilks> ... ILK |-> Ilk(... rate: RATE, spot: SPOT) ... </vat-ilks>
         <vat-urns> ... { ILK, URN } |-> Urn( INK, URNART ) ... </vat-urns>
         <cat-vow> VOWADDR </cat-vow>
      requires (INK *Rat SPOT) <Rat (URNART *Rat RATE)

    syntax CatAuthStep ::= "cage" [klabel(#CatCage), symbol]
 // --------------------------------------------------------
    rule <k> Cat . cage => . ... </k>
         <cat-live> _ => false </cat-live>
```

```k
endmodule
```
