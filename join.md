```k
requires "kmcd-driver.k"
requires "dai.k"
requires "gem.k"
requires "vat.k"

module JOIN
    imports KMCD-DRIVER
    imports DAI
    imports GEM
    imports VAT
```

Join Configuration
------------------

```k
    configuration
      <join-state>
        <gemJoins>
          <gemJoin multiplicity="*" type="Map">
            <gemJoin-gem> "" </gemJoin-gem>
            <gemJoin-addr> 0:Address </gemJoin-addr>
          </gemJoin>
        </gemJoins>
        <daiJoin-addr> 0:Address </daiJoin-addr>
      </join-state>
```

Join Semantics
--------------

```k
    syntax MCDContract ::= GemJoinContract
    syntax GemJoinContract ::= "GemJoin" String
    syntax MCDStep ::= GemJoinContract "." GemJoinStep [klabel(gemJoinStep)]
 // ------------------------------------------------------------------------
    rule contract(GemJoin GEMID . _) => GemJoin GEMID
    rule [[ address(GemJoin GEMID) => ACCTJOIN ]] <gemJoin-gem> GEMID </gemJoin-gem> <gemJoin-addr> ACCTJOIN </gemJoin-addr>

    syntax GemJoinStep ::= "join" Address Wad
 // -----------------------------------------
    rule <k> GemJoin GEMID . join USR AMOUNT
          => call Vat . slip GEMID USR AMOUNT
          ~> call Gem GEMID . transferFrom MSGSENDER THIS AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
      requires AMOUNT >=Rat 0

    syntax GemJoinStep ::= "exit" Address Wad
 // -----------------------------------------
    rule <k> GemJoin GEMID . exit USR AMOUNT
          => call Vat . slip GEMID MSGSENDER (0 -Rat AMOUNT)
          ~> call Gem GEMID . transfer USR AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires AMOUNT >=Rat 0

    syntax MCDContract ::= DaiJoinContract
    syntax DaiJoinContract ::= "DaiJoin"
    syntax MCDStep ::= DaiJoinContract "." DaiJoinStep [klabel(daiJoinStep)]
 // ------------------------------------------------------------------------
    rule contract(DaiJoin . _) => DaiJoin
    rule [[ address(DaiJoin) => ACCTJOIN ]] <daiJoin-addr> ACCTJOIN </daiJoin-addr>

    syntax DaiJoinStep ::= "join" Address Wad
 // -----------------------------------------
    rule <k> DaiJoin . join USR AMOUNT
          => call Vat . move THIS USR AMOUNT
          ~> call Dai . burn MSGSENDER AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
      requires AMOUNT >=Rat 0

    syntax DaiJoinStep ::= "exit" Address Wad
 // -----------------------------------------
    rule <k> DaiJoin . exit USR AMOUNT
          => call Vat . move MSGSENDER THIS AMOUNT
          ~> call Dai . mint USR AMOUNT ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
      requires AMOUNT >=Rat 0
```

```k
endmodule
```
