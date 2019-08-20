MKR MCD Data
============

This file defines the primitive data-types used in the MKR MCD system.

```k
module MKR-MCD-DATA
    imports BOOL
    imports INT
    imports MAP
```

Base Data
---------

-   `Wad`: basic quantities (e.g. balances).
-   `Ray`: precise quantities (e.g. ratios).
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision).
-   `Address`: unique identifier of an account on the network.

**TODO**: Should we add operators like `+Wad` which emulate the precision limits described in `makerdao/dss/DEVELOPING.md`, or assume the abstract model to be inifinite precision?

```k
    syntax Wad ::= Int
 // ------------------

    syntax Ray ::= Int
 // ------------------

    syntax Rad ::= Int
 // ------------------

    syntax Address ::= Int
 // ----------------------
```

-   `CDPID`: Identifies a given users `ilk` or `urn`.

```k
    syntax CDPID ::= "{" Int "," Address "}"
 // ----------------------------------------
```

Some useful constants come up:

```k
    syntax Int ::= "ilk_init"
 // -------------------------
    rule ilk_init => 1000000000000000000000000000 [macro]
```

Product Data
------------

-   `VatIlk`: `ART`, `RATE`, `SPOT`, `LINE`, `DUST`.

`Ilk` is a collateral with certain risk parameters.
Vat doesn't care about parameters for auctions, so only has stuff like debt ceiling, penalty, etc.
Cat has stuff like penalty.
Ok to say "this is the VatIlk, this is the CatIlk".
"Could have one big `Ilk` type with all the parameters, but there are different types to project out relevant parts to those contracts."
Getters and setters for `Ilk` should be permissioned, and different combinations of Contract + User might have `file` access to different fields (might be non-`file` access methods).

```k
    syntax VatIlk ::= Ilk ( Wad , Ray , Ray , Rad , Rad ) [klabel(#VatIlk), symbol]
 // -------------------------------------------------------------------------------
```

-   `ilkLine` returns the `LINE` associated with an `Ilk`.
-   `ilkDust` returns the `DUST` associated with an `Ilk`.

```k
    syntax Int ::= ilkLine ( VatIlk ) [function, functional]
                 | ilkDust ( VatIlk ) [function, functional]
 // --------------------------------------------------------
    rule ilkLine(Ilk(_, _, _, LINE, _   )) => LINE
    rule ilkDust(Ilk(_, _, _, _,    DUST)) => DUST
```

-   `VatUrn`: `INK`, `ART`

`Urn` is individual CDP of a certain `Ilk` for a certain address (actual data that comprises a CDP).
`Urn` has the exact same definition everywhere, so we can get away with a single definition.

```k
    syntax VatUrn ::= Urn ( Wad , Wad ) [klabel(#VatUrn), symbol]
 // -------------------------------------------------------------
```

-   `urnBalance` takes an `Urn` and it's corresponding `Ilk` and returns the "balance" of the `Urn` (`collateral - debt`).
-   `urnDebt` calculates the `RATE`-scaled `ART` of an `Urn`.
-   `urnCollateral` calculates the `SPOT`-scaled `INK` of an `Urn`.

```k
    syntax Int ::= urnBalance    ( VatIlk , VatUrn ) [function, functional]
                 | urnDebt       ( VatIlk , VatUrn ) [function, functional]
                 | urnCollateral ( VatIlk , VatUrn ) [function, functional]
 // -----------------------------------------------------------------------
    rule urnBalance(ILK, URN) => urnCollateral(ILK, URN) -Int urnDebt(ILK, URN)

    rule urnDebt      (Ilk(_ , RATE , _    , _ , _), Urn( _   , ART )) => ART *Int RATE
    rule urnCollateral(Ilk(_ , _    , SPOT , _ , _), Urn( INK , _   )) => INK *Int SPOT
```

```k
endmodule
```
