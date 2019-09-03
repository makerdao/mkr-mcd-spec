KMCD - K Semantics of Multi Collateral Dai
==========================================

This module combines all sub-modules to model the entire MCD system.

```k
requires "kmcd-driver.k"
requires "cdp-core.k"
requires "collateral.k"
requires "dai.k"
requires "kmcd.k"
requires "rates.k"
requires "stabalize.k"

module KMCD
    imports COLLATERAL
    imports RATES
    imports SYSTEM-STABILIZER

    configuration
      <kmcd>
        <kmcd-driver/>
      </kmcd>
endmodule
```
