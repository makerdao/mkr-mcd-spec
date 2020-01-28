KMCD - Properties
=================

```k
requires "kmcd.k"

module KMCD-PROPS
    imports KMCD

    configuration
        <kmcd-properties>
          <kmcd/>
          <processed-events> .List </processed-events>
          <properties> #violationFSMs </properties>
        </kmcd-properties>
```

Measurables
-----------

### Measure Event

```k
    syntax Event ::= Measure
    syntax Measure ::= Measure () [function]
                     | Measure ( debt: Rat , controlDai: Map , potChi: Rat , potPie: Rat , sumOfScaledArts: Rat, vice: Rat, endDebt: Rat )
 // --------------------------------------------------------------------------------------------------------------------------------------
    rule [[ Measure() => Measure(... debt: DEBT, controlDai: controlDais(keys_list(VAT_DAIS)), potChi: POT_CHI, potPie: POT_PIE, sumOfScaledArts: calcSumOfScaledArts(VAT_ILKS, VAT_URNS), vice: VAT_VICE, endDebt: END_DEBT) ]]
         <vat-debt> DEBT     </vat-debt>
         <vat-dai>  VAT_DAIS </vat-dai>
         <vat-ilks> VAT_ILKS </vat-ilks>
         <vat-urns> VAT_URNS </vat-urns>
         <vat-vice> VAT_VICE </vat-vice>
         <pot-chi>  POT_CHI  </pot-chi>
         <pot-pie>  POT_PIE  </pot-pie>
         <end-debt> END_DEBT </end-debt>
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

Total backed debt (sum over each CDP's art times corresponding ilk's rate)

```k
    syntax Rat ::= calcSumOfScaledArts(Map, Map) [function]
                 | calcSumOfScaledArtsAux(List, Map, Map, Rat) [function]
 // ---------------------------------------------------------------------
    rule calcSumOfScaledArts(VAT_ILKS, VAT_URNS) => calcSumOfScaledArtsAux(keys_list(VAT_ILKS), VAT_ILKS, VAT_URNS, 0)

    rule calcSumOfScaledArtsAux(                        .List ,        _ ,        _ , TOTAL ) => TOTAL
    rule calcSumOfScaledArtsAux( ListItem(ILK_ID) VAT_ILK_IDS , VAT_ILKS , VAT_URNS , TOTAL ) => calcSumOfScaledArtsAux(VAT_ILK_IDS, VAT_ILKS, VAT_URNS, TOTAL +Rat (sumOfUrnArt(VAT_URNS, ILK_ID, 0) *Rat rate({VAT_ILKS[ILK_ID]}:>VatIlk)))
```

### Flap Measures

Sum of all lot values (i.e. total surplus dai up for auction).

```k
    syntax Rat ::= sumOfAllFlapLots(Map) [function]
                 | sumOfAllFlapLotsAux(List, Map, Rat) [function]
 // -------------------------------------------------------------
    rule sumOfAllFlapLots(FLAP_BIDS) => sumOfAllFlapLotsAux(keys_list(FLAP_BIDS), FLAP_BIDS, 0)

    rule sumOfAllFlapLotsAux(                          .List ,         _ , SUM ) => SUM
    rule sumOfAllFlapLotsAux( ListItem(BID_ID) FLAP_BIDS_IDS , FLAP_BIDS , SUM ) => sumOfAllFlapLotsAux(FLAP_BIDS_IDS, FLAP_BIDS, SUM +Rat lot({FLAP_BIDS[BID_ID]}:>FlapBid))
```

Sum of all bid values (i.e. total amount of MKR that's been bid on dai currently up for auction).

```k
    syntax Rat ::= sumOfAllFlapBids(Map) [function]
                 | sumOfAllFlapBidsAux(List, Map, Rat) [function]
 // -------------------------------------------------------------
    rule sumOfAllFlapBids(FLAP_BIDS) => sumOfAllFlapBidsAux(keys_list(FLAP_BIDS), FLAP_BIDS, 0)

    rule sumOfAllFlapBidsAux(                          .List ,         _ , SUM ) => SUM
    rule sumOfAllFlapBidsAux( ListItem(BID_ID) FLAP_BIDS_IDS , FLAP_BIDS , SUM ) => sumOfAllFlapBidsAux(FLAP_BIDS_IDS, FLAP_BIDS, SUM +Rat bid({FLAP_BIDS[BID_ID]}:>FlapBid))
```

Violations
----------

A violation occurs if any of the properties above holds.

```k
    syntax Map ::= "#violationFSMs" [function]
 // ------------------------------------------
    rule #violationFSMs => ( "Zero-Time Pot Interest Accumulation" |-> zeroTimePotInterest                     )
                           ( "Pot Interest Accumulation After End" |-> potEndInterest                          )
                           ( "Unauthorized Flip Kick"              |-> unAuthFlipKick                          )
                           ( "Unauthorized Flap Kick"              |-> unAuthFlapKick                          )
                           ( "Total Bound on Debt"                 |-> totalDebtBounded(... dsr: 1)            )
                           ( "PotChi PotPie VatPot"                |-> potChiPieDai(... offset: 0, joining: 0) )
                           ( "Total Backed Debt Consistency"       |-> totalBackedDebtConsistency              )
                           ( "Debt Constant After Thaw"            |-> debtConstantAfterThaw                   )
                           ( "Flap Dai Consistency"                |-> flapDaiConsistency         )
                           ( "Flap MKR Consistency"                |-> flapMkrConsistency         )
```

A violation can be checked using the Admin step `assert`. If a violation is detected,
it is recorded in the state and execution is immediately terminated.

```k
    syntax AdminStep ::= "#assert"
 // ------------------------------
    rule <k> assert => deriveAll(keys_list(VFSMS), EVENTS ListItem(Measure())) ~> #assert ... </k>
         <events> EVENTS => .List </events>
         <properties> VFSMS </properties>

    rule <k> #assert => . ... </k>
         <properties> VFSMS </properties>
      requires notBool anyViolation(values(VFSMS))
```

### Violation Finite State Machines (FSMs)

These Finite State Machines help track whether certain properties of the system are violated or not.
Every FSM is equipped one special state, `Violated`, which holds the prior state to being violated.

```k
    syntax ViolationFSM ::= Violated ( ViolationFSM )
 // -------------------------------------------------
```

You can inject `checkViolated(_)` steps to each FSM to see whether we should halt because that FSM has a violation.

```k
    syntax Bool ::= anyViolation ( List ) [function]
 // ------------------------------------------------
    rule anyViolation(.List)                   => false
    rule anyViolation(ListItem(Violated(_)) _) => true
    rule anyViolation(ListItem(VFSM)     REST) => anyViolation(REST) [owise]
```

For each FSM, the user must define the `derive` function, which dictates how that FSM behaves.
A default `owise` rule is added which leaves the FSM state unchanged.

```k
    syntax ViolationFSM ::= derive ( ViolationFSM , Event ) [function]
 // ------------------------------------------------------------------
    rule derive(VFSM, _) => VFSM [owise]

    syntax AdminStep ::= deriveAll  ( List , List  )
                       | deriveVFSM ( List , Event )
 // ------------------------------------------------
    rule <k> deriveAll(_, .List) => . ... </k>
    rule <k> deriveAll(VFSMIDS, ListItem(E) REST)
          => deriveVFSM(VFSMIDS, E)
          ~> deriveAll(VFSMIDS, REST)
         ...
         </k>
         <processed-events> ... (.List => ListItem(E)) </processed-events>

    rule <k> deriveVFSM(.List                 , E) => .                   ... </k>
    rule <k> deriveVFSM(ListItem(VFSMID) REST , E) => deriveVFSM(REST, E) ... </k>
         <properties> ... VFSMID |-> (VFSM => derive(VFSM, E)) ... </properties>
```

### Total Backed Debt Consistency

Vat.debt minus Vat.vice should equal the sum over all ilks and CDP accounts of the CDP's art times the ilk's rate.

```k
    syntax ViolationFSM ::= "totalBackedDebtConsistency"
 // ----------------------------------------------------
    rule derive(totalBackedDebtConsistency, Measure(... debt: DEBT, sumOfScaledArts: SUM, vice: VICE)) => Violated(totalBackedDebtConsistency) requires SUM =/=Rat (DEBT -Rat VICE)
```

### Debt Constant After Thaw

Vat.debt should not change after End.thaw is called, as this implies the creation or destruction of dai which would mess up the End's accounting.

```k
    syntax ViolationFSM ::= "debtConstantAfterThaw"
 // -----------------------------------------------
    rule derive(debtConstantAfterThaw, Measure(... debt: DEBT, endDebt: END_DEBT)) => Violated(debtConstantAfterThaw) requires (END_DEBT =/=Rat 0) andBool (DEBT =/=Rat END_DEBT)
```

### Bounded Debt Growth

The Debt growth should be bounded in principle by the interest rates available in the system.

```k
    syntax ViolationFSM ::= totalDebtBounded    (             dsr: Rat )
                          | totalDebtBoundedRun ( debt: Rat , dsr: Rat )
                          | totalDebtBoundedEnd ( debt: Rat            )
 // --------------------------------------------------------------------
    rule derive(totalDebtBounded(... dsr: DSR), Measure(... debt: DEBT)) => totalDebtBoundedRun(... debt: DEBT, dsr: DSR)

    rule derive( totalDebtBoundedRun(... debt: DEBT, dsr: _  ) #as PREV , Measure(... debt: DEBT')            ) => Violated(PREV) requires DEBT' >Rat DEBT
    rule derive( totalDebtBoundedRun(... debt: DEBT, dsr: DSR)          , TimeStep(TIME, _)                   ) => totalDebtBoundedRun(... debt: DEBT +Rat (vatDaiForUser(Pot) *Rat ((DSR ^Rat TIME) -Rat 1)), dsr: DSR)
    rule derive( totalDebtBoundedRun(... debt: DEBT, dsr: DSR)          , LogNote(_ , Vat . frob _ _ _ _ _ _) ) => totalDebtBounded(... dsr: DSR)
    rule derive( totalDebtBoundedRun(... debt: DEBT, dsr: DSR)          , LogNote(_ , Pot . file dsr DSR')    ) => totalDebtBoundedRun(... debt: DEBT, dsr: DSR')
    rule derive( totalDebtBoundedRun(... debt: DEBT, dsr: _  )          , LogNote(_ , End . cage         )    ) => totalDebtBoundedEnd(... debt: DEBT)

    rule derive(totalDebtBoundedEnd(... debt: DEBT) #as PREV, Measure(... debt: DEBT')) => Violated(PREV) requires DEBT' =/=Rat DEBT
```

### Pot Chi * Pot Pie == Vat Dai(Pot)

The Pot Chi multiplied by Pot Pie should equal the Vat Dai for the Pot

```k
    syntax ViolationFSM ::= potChiPieDai ( offset: Rat , joining: Rat )
 // -------------------------------------------------------------------
    rule derive( potChiPieDai(... offset: OFFSET, joining: JOINING ) , LogNote(_, Pot . join WAD)       ) => potChiPieDai(... offset: OFFSET          , joining: JOINING +Rat WAD )
    rule derive( potChiPieDai(... offset: OFFSET, joining: JOINING ) , LogNote(_, Vat . move _ Pot WAD) ) => potChiPieDai(... offset: OFFSET +Rat WAD , joining: JOINING          )

    rule derive(potChiPieDai(... offset: OFFSET => OFFSET -Rat (JOINING *Rat POT_CHI), joining: JOINING => 0), Measure(... potChi: POT_CHI)) requires JOINING =/=Rat 0

    rule derive(potChiPieDai(... offset: OFFSET, joining: 0) #as PREV, Measure(... controlDai: CONTROL_DAI, potChi: POT_CHI, potPie: POT_PIE)) => Violated(PREV) requires POT_CHI *Rat POT_PIE =/=Rat #lookup(CONTROL_DAI, Pot) -Rat OFFSET
```

### Kicking off a fake `flip` auction (inspired by lucash-flip)

The property checks if `flip . kick` is ever called by an unauthorized user (alternatively, the property can check whether a `flip` auction is kicked off with a zero bid?).

```k
    syntax ViolationFSM ::= "unAuthFlipKick"
 // ----------------------------------------
    rule derive(unAuthFlipKick, FlipKick(ADDR, ILK, _, _, _, _, _, _)) => Violated(unAuthFlipKick) requires notBool isAuthorized(ADDR, Flip ILK)
```

### Kicking off a fake `flap` auction (inspired by lucash-flap)

The property checks if `flap . kick` is ever called by an unauthorized user (alternatively, the property can check whether a `flap` auction is kicked off with a zero bid?).

```k
    syntax ViolationFSM ::= "unAuthFlapKick"
 // ----------------------------------------
    rule derive(unAuthFlapKick, FlapKick(ADDR, _, _, _)) => Violated(unAuthFlapKick) requires notBool isAuthorized(ADDR, Flap)
```

### Earning interest from a pot after End is deactivated (inspired by the lucash-pot-end attack)

The property checks if an `End . cage` is eventually followed by a successful `Pot . file dsr`.

```k
    syntax ViolationFSM ::= "potEndInterest" | "potEndInterestEnd"
 // --------------------------------------------------------------
    rule derive(potEndInterest   , LogNote( _ , End . cage       )) => potEndInterestEnd
    rule derive(potEndInterestEnd, LogNote( _ , Pot . file dsr _ )) => Violated(potEndInterestEnd)
```

### Earning interest from a pot in zero time (inspired by the lucash-pot attack)

The property checks if a successful `Pot . join` is preceded by a `TimeStep` more recently than a `Pot . drip'.

```k
    syntax ViolationFSM ::= "zeroTimePotInterest" | "zeroTimePotInterestEnd"
 // ------------------------------------------------------------------------
    rule derive(zeroTimePotInterest, TimeStep(N,_)) => zeroTimePotInterestEnd
      requires N >Int 0

    rule derive(zeroTimePotInterestEnd, LogNote( _ , Pot . join _ )) => Violated(zeroTimePotInterestEnd)
    rule derive(zeroTimePotInterestEnd, LogNote( _ , Pot . drip   )) => zeroTimePotInterest
```

### Flap dai consistency

TODO: add events for tend, deal, yank and enforce consistency for those as well.

```k
    syntax ViolationFSM ::= "flapDaiConsistency"
 // --------------------------------------------
    rule derive(flapDaiConsistency, FlapKick(_, _, _, _)) => Violated requires notBool(flapDaiGtOrEtSumOfFlapLots())
    rule derive(flapDaiConsistency, FlapYank(_))          => Violated requires notBool(flapDaiGtOrEtSumOfFlapLots())
```

### Flap MKR consistency

TODO: add events for tend, deal, yank and enforce consistency for those as well.

```k
    syntax ViolationFSM ::= "flapMkrConsistency"
 // --------------------------------------------
    rule derive(flapMkrConsistency, FlapKick(_, _, _, _)) => Violated requires notBool(flapMkrGtOrEtSumOfFlapBids())
    rule derive(flapMkrConsistency, FlapYank(_))          => Violated requires notBool(flapMkrGtOrEtSumOfFlapBids())
```

### Flap Invariants

```k
    syntax Bool ::= flapDaiGtOrEtSumOfFlapLots() [function, functional]
 // -------------------------------------------------------------------
    rule [[ flapDaiGtOrEtSumOfFlapLots() =>
              #lookup(USERDAI, Flap) >=Rat sumOfAllFlapLots(FLAP_BIDS)
         ]]
      <flap-bids> FLAP_BIDS </flap-bids>
      <vat-dai> USERDAI </vat-dai>
```

```k
    syntax Bool ::= flapMkrGtOrEtSumOfFlapBids() [function, functional]
 // -------------------------------------------------------------------
    rule [[ flapMkrGtOrEtSumOfFlapBids() =>
              #lookup(BALS, Flap) >=Rat sumOfAllFlapBids(FLAP_BIDS)
         ]]
      <flap-bids> FLAP_BIDS </flap-bids>
      <gem-balances> BALS </gem-balances>
```

```k
endmodule
```
