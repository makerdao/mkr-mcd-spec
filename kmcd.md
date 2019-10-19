KMCD - K Semantics of Multi Collateral Dai
==========================================

This module combines all sub-modules to model the entire MCD system.

```k
requires "kmcd-driver.k"
requires "cat.k"
requires "dai.k"
requires "end.k"
requires "flap.k"
requires "flip.k"
requires "flop.k"
requires "gem.k"
requires "join.k"
requires "jug.k"
requires "pot.k"
requires "spot.k"
requires "vat.k"
requires "vow.k"

module KMCD
    imports KMCD-DRIVER
    imports CAT
    imports DAI
    imports END
    imports FLAP
    imports FLIP
    imports FLOP
    imports GEM
    imports JOIN
    imports JUG
    imports POT
    imports SPOT
    imports VAT
    imports VOW
```

**TODO**: This is a HACK to get us past unparsing issues with `mcd-pyk.py`.

```k
    imports K-TERM
```

```k
    configuration
      <kmcd>
        <kmcd-driver/>
        <kmcd-state>
          <cat/>
          <dai/>
          <end-state/>
          <flap-state/>
          <flips/>
          <flop-state/>
          <gems/>
          <jug/>
          <pot/>
          <spot/>
          <vat/>
          <vow/>
        </kmcd-state>
      </kmcd>
```

State Storage/Revert Semantics
------------------------------

```k
    rule <k> pushState => . ... </k>
         <kmcd-state> STATE </kmcd-state>
         <pre-state> _ => <kmcd-state> STATE </kmcd-state> </pre-state>

    rule <k> dropState => . ... </k>
         <pre-state> _ => .K </pre-state>

    rule <k> popState => . ... </k>
         (_:KmcdStateCell => <kmcd-state> STATE </kmcd-state>)
         <pre-state> <kmcd-state> STATE </kmcd-state> </pre-state>
```

```k
endmodule
```
