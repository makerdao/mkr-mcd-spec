```k
requires "cdp-core.k"
requires "collateral.k"
requires "dai.k"
requires "kmcd-driver.k"
requires "mkr-mcd-data.k"
requires "rates.k"
requires "system-stabilizer.k"

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
      </kmcd>

    syntax MCDSteps ::= MCDStep | MCDStep MCDSteps

    syntax MCDStep ::= ".MCDStep"

endmodule
```
