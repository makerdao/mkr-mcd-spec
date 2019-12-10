KMCD - Properties
=================

```k
requires "kmcd.k"

module KMCD-PROPS
    imports KMCD

    configuration
        <kmcd-properties>
          <kmcd/>
          <violation> false </violation>
        </kmcd-properties>
```

Measurables
-----------

### Measure Event

```k
    syntax Event ::= Measure ( debt: Rat , controlDai: Map , potChi: Rat , potPie: Rat )
 // ------------------------------------------------------------------------------------
    rule <k> measure => . ... </k>
         <events> ... (.List => ListItem(Measure(... debt: DEBT, controlDai: controlDais(keys_list(VAT_DAIS)), potChi: POT_CHI, potPie: POT_PIE))) </events>
         <vat-debt> DEBT </vat-debt>
         <vat-dai> VAT_DAIS </vat-dai>
         <pot-chi> POT_CHI </pot-chi>
         <pot-pie> POT_PIE </pot-pie>
```

### Dai in Circulation

State predicates that capture undesirable states in the system (representing violations of certain invariants).

```k
    syntax Map ::= controlDais    ( List       ) [function]
                 | controlDaisAux ( List , Map ) [function]
 // -------------------------------------------------------
    rule controlDais(USERS) => controlDaisAux(USERS, .Map)

    rule controlDaisAux(.List               , USER_DAIS) => USER_DAIS
    rule controlDaisAux(ListItem(ADDR) REST , USER_DAIS) => controlDaisAux(REST, USER_DAIS [ ADDR <- controlDaiForUser(ADDR) ])

    syntax Rat ::= controlDaiForUser ( Address ) [function]
                 | vatDaiForUser     ( Address ) [function]
                 | erc20DaiForUser   ( Address ) [function]
                 | potDaiForUser     ( Address ) [function]
 // -------------------------------------------------------
    rule controlDaiForUser(ADDR) => vatDaiForUser(ADDR) +Rat potDaiForUser(ADDR) +Rat erc20DaiForUser(ADDR)

    rule    vatDaiForUser(_) => 0 [owise]
    rule [[ vatDaiForUser(ADDR) => VAT_DAI ]]
         <vat-dai> ... ADDR |-> VAT_DAI:Rat ... </vat-dai>

    rule potDaiForUser(ADDR) => vatDaiForUser(Pot) *Rat portionOfPie(ADDR)

    rule    erc20DaiForUser(_) => 0 [owise]
    rule [[ erc20DaiForUser(ADDR) => USER_ADAPT_DAI ]]
         <dai-balance> ... ADDR |-> USER_ADAPT_DAI ... </dai-balance>

    syntax Rat ::= portionOfPie ( Address ) [function]
 // --------------------------------------------------
    rule    portionOfPie(_) => 0 [owise]
    rule [[ portionOfPie(ADDR) => USER_PIE /Rat PIE ]]
         <pot-pies> ... ADDR |-> USER_PIE ... </pot-pies>
         <pot-pie> PIE </pot-pie>
      requires PIE =/=Rat 0
       andBool ADDR =/=K Pot
```

### Vat Measures

Art of an ilk = Sum of all urn art across all users for that ilk.

```k
    syntax Int ::= sumOfUrnArt(Map, String, Int) [function, functional]
 // -------------------------------------------------------------------
    rule sumOfUrnArt( {ILKID , ADDR} |-> Urn ( _ , ART) URNS, ILKID', SUM)
      => #if ILKID ==K ILKID'
            #then sumOfUrnArt( URNS, ILKID', SUM +Int ART)
            #else sumOfUrnArt( URNS, ILKID', SUM)
         #fi

    rule sumOfUrnArt( _ |-> _ URNS, ILKID', SUM ) => sumOfUrnArt( URNS, ILKID', SUM ) [owise]

    rule sumOfUrnArt(.Map, _, SUM) => SUM
```

Ink of an ilk = Sum of all urn ink across all users for that ilk.

Total debt = Sum of all debt across all users.

```k
    syntax Int ::= sumOfAllDebt(Map, Int) [function, functional]
 // ------------------------------------------------------------
    rule sumOfAllDebt( ADDR |-> DAI USERDAI, SUM)
      => sumOfAllDebt( USERDAI, SUM +Int DAI)

    rule sumOfAllDebt( _ |-> _ USERDAI, SUM ) => sumOfAllDebt( USERDAI, SUM ) [owise]

    rule sumOfAllDebt(.Map, SUM) => SUM
```

Total vice = Sum of all sin across all users.

```k
    syntax Int ::= sumOfAllSin(Map, Int) [function, functional]
 // ------------------------------------------------------------
    rule sumOfAllSin( ADDR |-> SIN USERSIN, SUM)
      => sumOfAllSin( USERSIN, SUM +Int SIN)

    rule sumOfAllSin( _ |-> _ USERSIN, SUM ) => sumOfAllSin( USERSIN, SUM ) [owise]

    rule sumOfAllSin(.Map, SUM) => SUM
```

Total dai of all users = CDP debt for all users and gem + system debt (vice)

```k
    syntax Rat ::= sumOfAllUserDebt( ilks: Map, urns: Map, sum: Rat) [function, functional]
 // ---------------------------------------------------------------------------------------
    rule sumOfAllUserDebt(
             ILKID |-> ILK ILKS => ILKS,
             URNS,
             SUM => SUM +Rat (rate(ILK) *Rat sumOfUrnArt(URNS, ILKID, 0)) )

    rule sumOfAllUserDebt(_ |-> _ ILKS => ILKS, URNS, SUM) [owise]

    rule sumOfAllUserDebt(.Map, _, SUM) => SUM
```

Violations
----------

A violation occurs if any of the properties above holds.

```k
    syntax Bool ::= violated(List) [function, functional]
 // -----------------------------------------------------
    rule violated(EVENTS) => zeroTimePotInterest(EVENTS)
                      orBool unAuthFlipKick(EVENTS)
                      orBool unAuthFlapKick(EVENTS)
                      orBool potEndInterest(EVENTS)
```

A violation can be checked using the Admin step `assert`. If a violation is detected,
it is recorded in the state and execution is immediately terminated.

```k
    syntax AdminStep ::= "assert"
 // -----------------------------
    rule <k> (assert => .) ... </k>
         <events> EVENTS </events>
      requires notBool violated(EVENTS)

    rule <k> assert ~> _ => . </k>
         <events> EVENTS </events>
         <violation> false => true </violation>
      requires violated(EVENTS)
```

### Bounded Debt Growth

The Debt growth should be bounded in principle by the interest rates available in the system.

```k
    syntax Bool ::= totalDebtBounded    ( List             ) [function]
                  | totalDebtBoundedAux ( List , Rat , Rat ) [function]
 // -------------------------------------------------------------------
    rule totalDebtBounded(.List)                           => true
    rule totalDebtBounded(ListItem(Measure(DEBT, _)) REST) => totalDebtBoundedAux(REST, DEBT, 1) // initial DSR 1
    rule totalDebtBounded(ListItem(_) REST)                => totalDebtBounded(REST)             [owise]

    rule totalDebtBoundedAux( .List                                           , _    , _   ) => true
    rule totalDebtBoundedAux( ListItem(Measure(DEBT', _))                _    , DEBT , _   ) => false requires DEBT' >Rat DEBT
    rule totalDebtBoundedAux( ListItem(TimeStep(TIME, _))                REST , DEBT , DSR ) => totalDebtBoundedAux( REST , DEBT +Rat (vatDaiForUser(Pot) *Rat ((DSR ^Rat TIME) -Rat 1)) , DSR  )
    rule totalDebtBoundedAux( ListItem(LogNote(_ , Pot . file dsr DSR')) REST , DEBT , DSR ) => totalDebtBoundedAux( REST , DEBT                      , DSR' )
    rule totalDebtBoundedAux( ListItem(_)                                REST , DEBT , DSR ) => totalDebtBoundedAux( REST , DEBT                      , DSR  ) [owise]
```

### Pot Chi * Pot Pie == Vat Dai(Pot)

The Pot Chi multiplied by Pot Pie should equal the Vat Dai for the Pot

```k
    syntax Bool ::= potChiPieDai    ( List ) [function]
 // ---------------------------------------------------
    rule potChiPieDai( .List                                                                                 ) => true
    rule potChiPieDai( ListItem(Measure(... controlDai: CONTROL_DAI, potChi: POT_CHI, potPie: POT_PIE)) _    ) => false requires POT_CHI *Rat POT_PIE =/=Rat CONTROL_DAI[Pot]
    rule potChiPieDai( ListItem(_)                                                                      REST ) => potChiPieDai( REST ) [owise]
```

### Vat Invariants

-   Conservation of collatoral (Art -- in gem):

```k
    syntax Bool ::= conservedArt() [function, functional]
    syntax Bool ::= conservedArt(List) [function, functional]
 // ---------------------------------------------------------
    rule [[ conservedArt() => conservedArt(keys_list(ILKS)) ]]
      <vat-ilks> ILKS </vat-ilks>

    //rule conservedArt() => false [owise]

    rule conservedArt( ILKIDS )
      => conservedArtOfIlk( { ILKIDS[0] }:>String )
         andBool conservedArt( range(ILKIDS, 1, 0) )
      requires size( ILKIDS ) >Int 0

    rule conservedArt(.List) => true

    syntax Bool ::= conservedArtOfIlk(String) [function, functional]
 // ----------------------------------------------------------------
    rule [[ conservedArtOfIlk(ILKID) => ART ==Int sumOfUrnArt(URNS, ILKID, 0) ]]
      <vat-ilks> ... ILKID |-> Ilk( ... Art: ART ) ... </vat-ilks>
      <vat-urns> URNS </vat-urns>

    rule conservedArtOfIlk(ILKID) => false [owise]
```

-   Conservation of Ink of an Ilk

**Note:** Cannot be stated directly since the total `Ink` is not maintained in the state.

-   Conservation of debt (debt -- in dai):

```k
    syntax Bool ::= conservedDebt() [function, functional]
 // ------------------------------------------------------
    rule [[ conservedDebt() => DEBT ==Int sumOfAllDebt(USERDAI, 0) ]]
      <vat-debt> DEBT </vat-debt>
      <vat-dai> USERDAI </vat-dai>

    rule conservedDebt() => false [owise]
```

-   Conservation of vice (sin):

```k
    syntax Bool ::= conservedVice() [function, functional]
 // ------------------------------------------------------
    rule [[ conservedVice() => VICE ==Int sumOfAllSin(USERSIN, 0) ]]
      <vat-vice> VICE </vat-vice>
      <vat-sin> USERSIN </vat-sin>

    rule conservedVice() => false [owise]
```

- Conservation of dai (total dai supply):

```k
    syntax Bool ::= conservedTotalDai() [function, functional]
 // ----------------------------------------------------------
    rule [[ conservedTotalDai() =>
              sumOfAllDebt(USERDAI, 0) ==K (sumOfAllUserDebt(ILKS, URNS, 0) +Rat sumOfAllSin(USERSIN, 0))
         ]]
      <vat-dai> USERDAI </vat-dai>
      <vat-sin> USERSIN </vat-sin>
      <vat-ilks> ILKS </vat-ilks>
      <vat-urns> URNS </vat-urns>

    //rule conservedTotalDai() => false [owise]
```

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
           ListItem( TimeStep(N,_) )
           EVENTS:List
         )
         => zeroTimePotInterestEnd(EVENTS)
      requires N >Int 0

    rule zeroTimePotInterest( ListItem(_) EVENTS:List )
         => zeroTimePotInterest(EVENTS) [owise]

    rule zeroTimePotInterest(.List) => false

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
         => zeroTimePotInterest(EVENTS)

    rule zeroTimePotInterestEnd( ListItem(_) EVENTS:List )
         => zeroTimePotInterestEnd(EVENTS) [owise]

    rule zeroTimePotInterestEnd(.List) => false
```

```k
endmodule
```
