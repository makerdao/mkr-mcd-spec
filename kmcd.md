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

Properties
----------

State predicates that capture undesirable states in the system (representing violations of certain invariants).

### Kicking off a fake `flip` auction (inspired by lucash-flip)

The property checks if `flip . kick` is ever called by an unauthorized user (alternatively, the property can check whether a `flip` auction is kicked off with a zero bid?).

### Kicking off a fake `flap` auction (inspired by lucash-flap)

The property checks if `flap . kick` is ever called by an unauthorized user (alternatively, the property can check whether a `flap` auction is kicked off with a zero bid?).

### Earning interest from a pot after End is deactivated (inspired by the lucash-pot-end attack)

The property checks if an `End . cage` is eventually followed by a successful `Pot . join`and `Pot . exit` before `End` is reactivated.

### Earning interest from a pot in zero time (inspired by the lucash-pot attack)

The property checks if a sequence of `Pot . join`, `Pot . drip` and `Pot . exit` is executed in zero time.
```k

    syntax Bool ::= zeroTimePotInterest(List) [function, functional]
 // ----------------------------------------------------
    rule zeroTimePotInterest(
           ListItem(LogNote( ADDR, Pot . join WAD1 ))
           EVENTS:List
         )
         => zeroTimePotInterestBegin(EVENTS, ADDR)

    rule zeroTimePotInterest( ListItem(_) EVENTS:List )
         => zeroTimePotInterest(EVENTS) [owise]

    rule zeroTimePotInterest(.List) => false

    syntax Bool ::= zeroTimePotInterestBegin(List, String) [function, functional]
 // -----------------------------------------------------------------
    rule zeroTimePotInterestBegin(
           ListItem(LogNote( ADDR, Pot . drip ))
           EVENTS:List, ADDR
         )
         => zeroTimePotInterestEnd(EVENTS, ADDR)

    rule zeroTimePotInterestBegin(
           ListItem( TimeStep(N,_) )
           EVENTS:List, ADDR
         )
         => zeroTimePotInterest(EVENTS)
      requires N >Int 0

    rule zeroTimePotInterestBegin( ListItem(_) EVENTS:List, ADDR )
         => zeroTimePotInterestBegin(EVENTS, ADDR) [owise]

    rule zeroTimePotInterestBegin(.List, _) => false

    syntax Bool ::= zeroTimePotInterestEnd(List, String) [function, functional]
 // -----------------------------------------------------------------
    rule zeroTimePotInterestEnd(
           ListItem(LogNote( ADDR, Pot . exit WAD ))
           EVENTS:List, ADDR
         )
         => true

    rule zeroTimePotInterestEnd(
           ListItem( TimeStep(N,_) )
           EVENTS:List, ADDR
         )
         => zeroTimePotInterest(EVENTS)
      requires N >Int 0

    rule zeroTimePotInterestEnd( ListItem(_) EVENTS:List, ADDR )
         => zeroTimePotInterestEnd(EVENTS, ADDR) [owise]

    rule zeroTimePotInterestEnd(.List, _) => false
```

Violations
----------

A violation occurs if any of the properties above holds.

```k
    rule violated(EVENTS) => true
      requires zeroTimePotInterest(EVENTS)
```

```k
endmodule
```
