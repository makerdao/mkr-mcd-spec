```k
requires "kmcd-driver.k"

module CAT
    imports KMCD-DRIVER
```

-   `CatIlk`: `FLIP`, `CHOP`, `LUMP`

`Ilk` is a collateral with certain risk parameters.
Cat has stuff like penalty.

```k
    syntax CatIlk ::= Ilk ( Art: Wad, rate: Ray, spot: Ray, line: Rad )           [klabel(#CatIlk), symbol]
 // -------------------------------------------------------------------------------------------------------
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

    syntax CatAuthStep ::= "cage" [klabel(#CatCage), symbol]
 // --------------------------------------------------------
```

```k
endmodule
```
