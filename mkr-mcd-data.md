MKR MCD Data
============

This file defines the primitive data-types used in the MKR MCD system.

```k
module MKR-MCD-DATA
    imports INT
    imports MAP
```

Base Data
---------

-   `Wad`: fixed point decimal with 18 decimals (for basic quantities, e.g. balances).
-   `Ray`: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios).
-   `Rad`: fixed point decimal with 45 decimals (result of integer multiplication with a `Wad` and a `Ray`).

**TODO**: Should we add operators like `+Wad` which emulate the precision limits described here, or assume the abstract model to be inifinite precision?

```k
    syntax Wad ::= Int
 // ------------------

    syntax Ray ::= Int
 // ------------------

    syntax Rad ::= Int
 // ------------------
```

```k
endmodule
```
