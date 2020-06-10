KMCD - K Semantics of Multi Collateral Dai
==========================================

This module combines all sub-modules to model the entire MCD system.

```k
requires "kmcd-driver.md"
requires "cat.md"
requires "dai.md"
requires "end.md"
requires "flap.md"
requires "flip.md"
requires "flop.md"
requires "gem.md"
requires "join.md"
requires "jug.md"
requires "pot.md"
requires "spot.md"
requires "vat.md"
requires "vow.md"

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
          <join-state/>
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
         <pre-state> <kmcd-state> STATE </kmcd-state> => .K </pre-state>
```

```k
endmodule
```
