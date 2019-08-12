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

Product Data
------------

-   `#VatIlk`: **TODO**

`Ilk` is a collateral with certain risk parameters.
Vat doesn't care about parameters for auctions, so only has stuff like debt ceiling, penalty, etc.
Cat has stuff like penalty.
Ok to say "this is the VatIlk, this is the CatIlk".
"Could have one big `Ilk` type with all the parameters, but there are different types to project out relevant parts to those contracts."
Getters and setters for `Ilk` should be permissioned, and different combinations of Contract + User might have `file` access to different fields (might be non-`file` access methods).

```k
    syntax VatIlk ::= Ilk ( Wad , Ray , Ray , Rad , Rad ) [klabel(#VatIlk), symbol]
 // -------------------------------------------------------------------------------

    syntax Wad ::= VatIlk "." "Art" [function]
 // ------------------------------------------
    rule Ilk(ART, _, _, _, _) . Art => ART

    syntax Ray ::= VatIlk "." "rate" [function]
                 | VatIlk "." "spot" [function]
 // -------------------------------------------
    rule Ilk(_, RATE, _, _, _) . rate => RATE
    rule Ilk(_, _, SPOT, _, _) . spot => SPOT

    syntax Rad ::= VatIlk "." "line" [function]
                 | VatIlk "." "dust" [function]
 // -------------------------------------------
    rule Ilk(_, _, _, LINE, _) . line => LINE
    rule Ilk(_, _, _, _, DUST) . dust => DUST
```

-   `#VatUrn`: **TODO**

`Urn` is individual CDP of a certain `Ilk` for a certain address (actual data that comprises a CDP).
`Urn` has the exact same definition everywhere, so we can get away with a single definition.

```k
    syntax VatUrn ::= Urn ( Wad , Wad ) [klabel(#VatUrn), symbol]
 // -------------------------------------------------------------

    syntax Wad ::= VatUrn "." "ink" [function]
                 | VatUrn "." "art" [function]
 // ------------------------------------------
    rule Urn(INK, _) . ink => INK
    rule Urn(_, ART) . art => ART
```

```k
endmodule
```
