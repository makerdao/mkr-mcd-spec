KMCD - K Specification of MKR Multi-collateral Dai
==================================================

```k
requires "mkr-mcd-data.k"

module MKR-MCD
    imports MKR-MCD-DATA
```

MCD State
---------

```k
    configuration
      <mkr-mcd>
        <k> $PGM:Pgm </k>
      </mkr-mcd>

    syntax Pgm ::= ".Pgm"
 // ---------------------
```

```k
endmodule
```
