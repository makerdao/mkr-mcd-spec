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
        <k> $PGM:MCDSteps </k>
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
```

Simulations
-----------

Simulations will be sequences of `MCDStep`.

```k
    syntax MCDStep
    syntax MCDSteps ::= MCDStep | MCDStep MCDSteps
 // ----------------------------------------------
    rule <k> MCD:MCDStep MCDS:MCDSteps => MCD ~> MCDS ... </k>
```

Vat Semantics
-------------

**TODO**: Should the `vat` map state from `address => ...` be stored as a configuration cell `<vats> <vat multiplicity="*" type="Map"> </vat> </vats>`?

```k
    syntax MCDStep ::= "Vat" "." VatStep
 // ------------------------------------
```

`Vat.rely ACCOUNT` and `Vat.deny ACCOUNT` toggle `ward [ ACCOUNT ]`.

```k
    syntax VatStep ::= "rely" Address | "deny" Address
 // --------------------------------------------------
    rule <k> Vat . rely ADDR => . ... </k>
         <ward> ... ADDR |-> (_ => true) ... </ward>

    rule <k> Vat . deny ADDR => . ... </k>
         <ward> ... ADDR |-> (_ => false) ... </ward>
```

```k
endmodule
```
