```k
requires "kmcd-driver.md"
requires "flip.md"
requires "vat.md"
requires "vow.md"

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
        <cat-vat>   0:Address </cat-vat>
        <cat-vow>   0:Address </cat-vow>
        <cat-wards> .Set      </cat-wards>
        <cat-ilks>  .Map      </cat-ilks>
        <cat-live>  true      </cat-live>
      </cat>
```

```k
    syntax MCDContract ::= CatContract
    syntax CatContract ::= "Cat"
    syntax MCDStep ::= CatContract "." CatStep [klabel(catStep)]

    syntax CallStep ::= CatStep
    syntax Op       ::= CatOp
    syntax Args     ::= CatArgs
 // ------------------------------------------------------------
    rule contract(Cat . _) => Cat
```

### Constructor

```k
    syntax CatConstructorOp ::= "constructor"
    syntax CatOp            ::= CatConstructorOp
    syntax CatAddressArgs   ::= Address
    syntax CatArgs          ::= CatAddressArgs
    syntax CatStep          ::= CatConstructorOp CatAddressArgs
 // ----------------------------------------
    rule <k> Cat . constructor CAT_VAT => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <cat> _ </cat>
        => <cat>
             <cat-vat> CAT_VAT </cat-vat>
             <cat-wards> SetItem(MSGSENDER) </cat-wards>
             <cat-live> true </cat-live>
             ...
           </cat>
         )
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
    syntax CatIlk ::= Ilk ( flip: Address, chop: Ray, lump: Wad ) [klabel(#CatIlk), symbol]
 // ---------------------------------------------------------------------------------------
```

**NOTE**: The `flip` liquidator address is not included in `CatIlk` because we assume a unique `Flipper` for each `Ilk`.

Cat Events
----------

```k
    syntax CustomEvent ::= Bite(ilk: String, urn: Address, ink: Wad, art: Wad, tab: Rad, flip: Address, id: Int) [klabel(Bite), symbol]
 // -----------------------------------------------------------------------------------------------------------------------------------

    syntax CatStep ::= "emitBite" String Address Wad Wad Rad
 // --------------------------------------------------------
    rule <k> emitBite ILK_ID URN INK ART TAB => ID ... </k>
         <return-value> ID:Int </return-value>
         <frame-events> ... (.List => ListItem(Bite(ILK_ID, URN, INK, ART, TAB, Flip ILK_ID, ID))) </frame-events>
```

File-able Fields
----------------

The parameters controlled by governance are:

-   `vow`: debt accumulator for bitten CDPs.
-   `chop`: liquidation penalty.
-   `lump`: liquidation lot quantity.

```k

    syntax CatFileOp    ::= "file"
    syntax CatOp        ::= CatFileOp
    syntax CatArgs      ::= CatFileArgs
    syntax CatFileArgs  ::= "vow-file" Address
                          | "chop" String Ray
                          | "lump" String Wad
                          | "flip" String Address

    syntax CatAuthStep ::= CatFileOp CatFileArgs
 // ----------------------------------------
    rule <k> Cat . file vow-file ADDR => . ... </k>
         <cat-vow> _ => ADDR </cat-vow>

    rule <k> Cat . file chop ILK_ID CHOP => . ... </k>
         <cat-ilks> ... ILK_ID |-> Ilk ( ... chop: (_ => CHOP) ) ... </cat-ilks>
      requires CHOP >=Ray ray(0)

    rule <k> Cat . file lump ILK_ID LUMP => . ... </k>
         <cat-ilks> ... ILK_ID |-> Ilk ( ... lump: (_ => LUMP) ) ... </cat-ilks>
      requires LUMP >=Wad wad(0)

    rule <k> Cat . file flip ILK_ID CAT_FLIP => . ... </k>
         <cat-ilks> ... ILK_ID |-> Ilk ( ... flip: (_ => CAT_FLIP) ) ... </cat-ilks>

    rule <k> Cat . file flip ILK_ID _ ... </k>
         <cat-ilks> CAT_ILKS => CAT_ILKS [ ILK_ID <- Ilk(... flip: 0, chop: ray(0), lump: wad(0)) ] </cat-ilks>
      requires notBool ILK_ID in_keys(CAT_ILKS)
```

**NOTE**: `flip` is not fileable since we are assuming a unique liquidator for each ilk.

**TODO**: Have to name it `vow-file` fileable step to avoid conflict with `<vow>` cell.

Cat Semantics
-------------

```k
    syntax CatBiteOp ::= "bite"
    syntax CatOp ::= CatBiteOp
    syntax CatIlkUrnArgs ::= String Address
    syntax CatArgs ::= CatIlkUrnArgs
    syntax CatStep ::= CatBiteOp CatIlkUrnArgs
 // ----------------------------------------
    rule <k> Cat . bite ILK_ID URN
          => #fun(LOT
          => #fun(ART
          => #fun(TAB
          => call CAT_VAT  . grab ILK_ID URN THIS CAT_VOW (wad(0) -Wad LOT) (wad(0) -Wad ART)
          ~> call CAT_VOW  . fess TAB
          ~> call CAT_FLIP . kick URN CAT_VOW rmul(TAB, CHOP) LOT rad(0)
          ~> emitBite ILK_ID URN LOT ART TAB)
          (ART *Rate RATE))
          (minWad(URNART, (LOT *Wad URNART) /Wad INK)))
          (minWad(INK, LUMP))
         ...
         </k>
         <this> THIS </this>
         <cat-vat> CAT_VAT </cat-vat>
         <cat-vow> CAT_VOW </cat-vow>
         <cat-live> true </cat-live>
         <cat-ilks> ... ILK_ID |-> Ilk(... flip: CAT_FLIP, chop: CHOP, lump: LUMP) ... </cat-ilks>
         <vat-ilks> ... ILK_ID |-> Ilk(... rate: RATE, spot: SPOT) ... </vat-ilks>
         <vat-urns> ... { ILK_ID, URN } |-> Urn(... ink: INK, art: URNART ) ... </vat-urns>
      requires (INK *Rate SPOT) <Rad (URNART *Rate RATE)

    syntax CatAuthStep ::= "cage" [klabel(#CatCage), symbol]
 // --------------------------------------------------------
    rule <k> Cat . cage => . ... </k>
         <cat-live> _ => false </cat-live>
```

```k
endmodule
```
