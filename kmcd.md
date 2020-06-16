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

Deployment
----------

Here we model the deployment contract of the MCD system.
At it's core, it calls the constructors of all the sub-contracts with appropriate arguments.

```k
    syntax MCDContract ::= DeployContract
    syntax DeployContract ::= "Deploy"
    syntax MCDStep ::= DeployContract "." DeployStep [klabel(deployStep)]
 // ---------------------------------------------------------------------

    syntax DeployStep ::= "deploy" Address
 // --------------------------------------
    rule <k> Deploy . deploy GOV
          => call Deploy . deployVat
          ~> call Deploy . deployDai
          ~> call Deploy . deployTaxation
          ~> call Deploy . deployAuctions GOV
          ~> call Deploy . deployLiquidator
          ~> call Deploy . deployShutdown GOV
         ...
         </k>

    syntax DeployStep ::= "deployVat"
 // ---------------------------------
    rule <k> Deploy . deployVat
          => call Vat  . constructor
          ~> call Spot . constructor Vat
          ~> call Vat  . rely Spot
         ...
         </k>

    syntax DeployStep ::= "deployDai"
 // ---------------------------------
    rule <k> Deploy . deployDai
          => call Dai     . constructor
          ~> call DaiJoin . constructor Vat Dai
          ~> call Dai     . rely DaiJoin
         ...
         </k>

    syntax DeployStep ::= "deployTaxation"
 // --------------------------------------
    rule <k> Deploy . deployTaxation
          => call Jug . constructor Vat
          ~> call Pot . constructor Vat
          ~> call Vat . rely Jug
          ~> call Vat . rely Pot
         ...
         </k>

    syntax DeployStep ::= "deployAuctions" Address
 // ----------------------------------------------
    rule <k> Deploy . deployAuctions GOV
          => call Flap . constructor Vat GOV
          ~> call Flop . constructor Vat GOV
          ~> call Vow  . constructor Vat Flap Flop
          ~> call Jug  . file vow-file Vow
          ~> call Pot  . file vow-file Vow
          ~> call Vat  . rely Flop
          ~> call Flap . rely Vow
          ~> call Flop . rely Vow
         ...
         </k>

    syntax DeployStep ::= "deployLiquidator"
 // ----------------------------------------
    rule <k> Deploy . deployLiquidator
          => call Cat . constructor Vat
          ~> call Cat . file vow-file Vow
          ~> call Vat . rely Cat
          ~> call Vow . rely Cat
         ...
         </k>

    syntax DeployStep ::= "deployShutdown" Address
 // ----------------------------------------------
    rule <k> Deploy . deployShutdown GOV
          => End  . constructor
          ~> End  . file vat-file  Vat
          ~> End  . file cat-file  Cat
          ~> End  . file vow-file  Vow
          ~> End  . file pot-file  Pot
          ~> End  . file spot-file Spot
          ~> Vat  . rely End
          ~> Cat  . rely End
          ~> Vow  . rely End
          ~> Pot  . rely End
          ~> Spot . rely End
         ...
         </k>
```

```k
endmodule
```
