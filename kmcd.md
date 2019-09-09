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

    configuration
      <kmcd>
        <kmcd-driver/>
        <cdp-core/>
        <dai/>
        <stabilize/>
      </kmcd>
endmodule
```
