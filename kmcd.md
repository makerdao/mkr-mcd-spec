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

```k
    syntax Bool ::= unAuthFlipKick(List) [function, functional]
 // -----------------------------------------------------------
    rule unAuthFlipKick(
           ListItem(FlipKick(ADDR, ILK, _, _, _, _, _, _))
           EVENTS:List
         )
         => #if isAuthorized(ADDR, Flip ILK) #then unAuthFlipKick(EVENTS) #else true #fi

    rule unAuthFlipKick( ListItem(_) EVENTS:List )
         => unAuthFlipKick(EVENTS) [owise]

    rule unAuthFlipKick(.List) => false
```

### Kicking off a fake `flap` auction (inspired by lucash-flap)

The property checks if `flap . kick` is ever called by an unauthorized user (alternatively, the property can check whether a `flap` auction is kicked off with a zero bid?).

```k
    syntax Bool ::= unAuthFlapKick(List) [function, functional]
 // -----------------------------------------------------------
    rule unAuthFlapKick(
          ListItem(FlapKick(ADDR, _, _, _))
           EVENTS:List
         )
         => #if isAuthorized(ADDR, Flap) #then unAuthFlapKick(EVENTS) #else true #fi

    rule unAuthFlapKick( ListItem(_) EVENTS:List )
         => unAuthFlapKick(EVENTS) [owise]

    rule unAuthFlapKick(.List) => false
```

### Earning interest from a pot after End is deactivated (inspired by the lucash-pot-end attack)

The property checks if an `End . cage` is eventually followed by a successful `Pot . file dsr`.

```k
    syntax Bool ::= potEndInterest(List) [function, functional]
 // -----------------------------------------------------------
    rule potEndInterest(
           ListItem(LogNote( ADDR, End . cage))
           EVENTS:List
         )
         => potEndInterestEnd(EVENTS)

    rule potEndInterest(ListItem(_) EVENTS:List )
         => potEndInterest(EVENTS) [owise]

    rule potEndInterest(.List) => false

    syntax Bool ::= potEndInterestEnd(List) [function, functional]
 // ----------------------------------------------------------------
    rule potEndInterestEnd(
           ListItem(LogNote( _ , Pot . file dsr _ ))
           EVENTS:List
         )
         => true 

    rule potEndInterestEnd( ListItem(_) EVENTS:List )
         => potEndInterestEnd(EVENTS) [owise]

    rule potEndInterestEnd(.List) => false
```

### Earning interest from a pot in zero time (inspired by the lucash-pot attack)

The property checks if a successful `Pot . join` is preceded by a `TimeStep` more recently than a `Pot . drip'. 

```k
    syntax Bool ::= zeroTimePotInterest(List) [function, functional]
 // ----------------------------------------------------------------
    rule zeroTimePotInterest(
           ListItem(LogNote( ADDR, Pot . drip ))
           EVENTS:List
         )
         => zeroTimePotInterestBegin(EVENTS)

    rule zeroTimePotInterest( ListItem(_) EVENTS:List )
         => zeroTimePotInterest(EVENTS) [owise]

    rule zeroTimePotInterest(.List) => false

    syntax Bool ::= zeroTimePotInterestBegin(List) [function, functional]
 // ---------------------------------------------------------------------
    rule zeroTimePotInterestBegin(
           ListItem( TimeStep(N,_) )
           EVENTS:List
         )
         => zeroTimePotInterestEnd(EVENTS)
      requires N >Int 0

    rule zeroTimePotInterestBegin( ListItem(_) EVENTS:List )
         => zeroTimePotInterestBegin(EVENTS) [owise]

    rule zeroTimePotInterestBegin(.List) => false

    syntax Bool ::= zeroTimePotInterestEnd(List) [function, functional]
 // -------------------------------------------------------------------
    rule zeroTimePotInterestEnd(
           ListItem(LogNote( _ , Pot . join _ ))
           EVENTS:List
         )
         => true

    rule zeroTimePotInterestEnd(
           ListItem(LogNote( _ , Pot . drip ))
           EVENTS:List
         )
         => zeroTimePotInterestBegin(EVENTS)

    rule zeroTimePotInterestEnd( ListItem(_) EVENTS:List )
         => zeroTimePotInterestEnd(EVENTS) [owise]

    rule zeroTimePotInterestEnd(.List) => false
```

Violations
----------

A violation occurs if any of the properties above holds.

```k
    rule violated(EVENTS) => zeroTimePotInterest(EVENTS)
                      orBool unAuthFlipKick(EVENTS)
                      orBool unAuthFlapKick(EVENTS)
                      orBool potEndInterest(EVENTS)
```

```k
endmodule
```
