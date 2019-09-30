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

```k
    syntax CatIlk ::= Ilk ( flip: Address, chop: Ray, lump: Wad ) [klabel(#CatIlk), symbol]
 // ---------------------------------------------------------------------------------------
```

Cat Configuration
-----------------

```k
    configuration
      <cat>
        <cat-addr> 0:Address </cat-addr>
        <cat-ilks> .Map      </cat-ilks>
        <cat-live> true      </cat-live>
      </cat>
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
    rule <k> Cat . bite ILK URN
          => call Vat . grab ILK URN THIS VOWADDR (-1 *Rat minRat(INK,LUMP)) (-1 *Rat minRat(ART, minRat(INK,LUMP) *Rat ART /Rat INK))
          ~> call Vow . fess (ART *Rat RATE)
          ~> call Flip FLIP . kick URN VOWADDR (ART *Rat RATE *Rat CHOP) minRat(INK,LUMP) 0
         ...
         </k>
         <this> THIS </this>
         <cat-live> true </cat-live>
         <cat-ilks>...
           ID |-> Ilk(... flip: FLIP, chop: CHOP, lump: LUMP)
         ...</cat-ilks>
         <vat-ilks>...
           ID |-> Ilk(... rate: RATE, spot: SPOT)
         ...</vat-ilks>
         <vat-urns>...
           ID |-> Urn( INK, ART )
         ...</vat-urns>
         <vow-addr> VOWADDR </vow-addr>
      requires (INK *Rat SPOT) <Rat (ART *Rat RATE)

    syntax CatAuthStep ::= "cage" [klabel(#CatCage), symbol]
 // --------------------------------------------------------
    rule <k> Cat . cage => . ... </k>
         <cat-live> _ => false </cat-live>
```

```k
endmodule
```
