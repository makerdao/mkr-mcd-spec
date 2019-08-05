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
        <vat>
          <ward> .Map  </ward> // mapping (address => uint)                (actually a Bool) Int          |-> Bool
          <can>  .Map  </can>  // mapping (address (address => uint))      (actually a Bool) Int, Int     |-> Bool
          <ilks> .Map  </ilks> // mapping (bytes32 => VatIlk)                                Int          |-> VatIlk
          <urns> .Map  </urns> // mapping (bytes32 => (address => VatUrn))                   Int, Address |-> VatUrn
          <gem>  .Map  </gem>  // mapping (bytes32 => (address => uint256))                  Int, Address |-> Wad
          <dai>  .Map  </dai>  // mapping (address => uint256)                               Address      |-> Rad
          <sin>  .Map  </sin>  // mapping (address => uint256)                               Address      |-> Rad
          <debt> 0:Rad </debt> // Total Dai Issued
          <vice> 0:Rad </vice> // Total Unbacked Dai
          <Line> 0:Rad </Line> // Total Debt Ceiling
          <live> true  </live> // Access Flag
        </vat>
        <log-events> .List </log-events>
      </mkr-mcd>

    syntax Pgm ::= ".Pgm"
 // ---------------------
```

```k
endmodule
```
