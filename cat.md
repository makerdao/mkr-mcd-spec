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
    syntax CatIlk ::= Ilk ( chop: Ray, lump: Wad ) [klabel(#CatIlk), symbol]
 // ------------------------------------------------------------------------
```

Cat Configuration
-----------------

```k
    configuration
      <cat>
        <cat-addr> 0:Address </cat-addr>
        <cat-ilks> .Map      </cat-ilks>
        <cat-live> true      </cat-live>
        <cat-vow>  0:Address </cat-vow>
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
         <cat-ilks>...
           ILK |-> Ilk(... chop: CHOP, lump: LUMP)
         ...</cat-ilks>
         <vat-ilks>...
           ILK |-> Ilk(... rate: RATE, spot: SPOT)
         ...</vat-ilks>
         <vat-urns>...
           { ILK, URN } |-> Urn( INK, URNART )
         ...</vat-urns>
         <cat-vow> VOWADDR </cat-vow>
      requires (INK *Rat SPOT) <Rat (URNART *Rat RATE)

    syntax CatStep ::= "emitBite" String Address Wad Wad Wad
    syntax Event ::= Bite(ilk: String, urn: Address, ink: Wad, art: Wad, tab: Wad, flip: Address, id: Int)
 // ------------------------------------------------------------------------------------------------------
    rule <k> ID:Int ~> emitBite ILK URN INK ART TAB => ID ... </k>
         <frame-events> _ => ListItem(Bite(ILK, URN, INK, ART, TAB, address(Flip ILK), ID)) </frame-events>

    syntax CatAuthStep ::= "cage" [klabel(#CatCage), symbol]
 // --------------------------------------------------------
    rule <k> Cat . cage => . ... </k>
         <cat-live> _ => false </cat-live>
```

```k
endmodule
```
