KMCD - K Semantics of Multi Collateral Dai
==========================================

This module combines all sub-modules to model the entire MCD system.

```k
requires "kmcd-driver.k"
requires "cdp-core.k"
requires "collateral.k"
requires "dai.k"
requires "rates.k"
requires "stabilize.k"

module KMCD
    imports CDP-CORE
    imports COLLATERAL
    imports DAI
    imports KMCD-DRIVER
    imports RATES
    imports SYSTEM-STABILIZER
```

**TODO**: This is a HACK to get us past unparsing issues with `mcd-pyk.py`.

```k
    imports K-TERM
```

```k
    configuration
      <kmcd>
        <kmcd-driver/>
        <cdp-core/>
        <dai/>
        <stabilize/>
        <collateral/>
        <rates/>
        <endPhase> false </endPhase>
        <endStack> .List </endStack>
        <end>
          <end-ward> .Map </end-ward> // mapping (address => uint)                         Address |-> Bool
          <end-live> 0    </end-live>
          <end-when> 0    </end-when>
          <end-wait> 0    </end-wait>
          <end-debt> 0    </end-debt>
          <end-tag>  .Map </end-tag>  // mapping (bytes32 => uint256)                      Int     |-> Ray
          <end-gap>  .Map </end-gap>  // mapping (bytes32 => uint256)                      Int     |-> Wad
          <end-art>  .Map </end-art>  // mapping (bytes32 => uint256)                      Int     |-> Wad
          <end-fix>  .Map </end-fix>  // mapping (bytes32 => uint256)                      Int     |-> Ray
          <end-bag>  .Map </end-bag>  // mapping (address => uint256)                      Int     |-> Wad
          <end-out>  .Map </end-out>  // mapping (bytes32 => mapping (address => uint256)) Int     |-> Wad
        </end>
      </kmcd>
```

End Semantics
-------------

```k
    syntax MCDContract ::= EndContract
    syntax EndContract ::= "End"
    syntax MCDStep ::= EndContract "." EndStep
 // ------------------------------------------

    syntax EndStep ::= EndAuthStep
 // ------------------------------

    syntax EndAuthStep ::= "init"
 // -----------------------------

    syntax EndStep ::= "cage"
                     | "cage" Int
 // -----------------------------

    syntax EndStep ::= "skip" Int Int
 // ---------------------------------

    syntax EndStep ::= "skim" Int Address
 // -------------------------------------

    syntax EndStep ::= "free" Int
 // -----------------------------

    syntax EndStep ::= "thaw"
 // -------------------------

    syntax EndStep ::= "flow" Int
 // -----------------------------

    syntax EndStep ::= "pack" Wad
 // -----------------------------

    syntax EndStep ::= "cash" Int Wad
 // ---------------------------------

```

```k
endmodule
```
