KMCD Driver
===========

This module defines common state and control flow between all the other KMCD modules.

```k
requires "rat.k"

module KMCD-DRIVER
    imports BOOL
    imports BYTES
    imports INT
    imports MAP
    imports STRING
    imports RAT

    configuration
        <kmcd-driver>
          <k> $PGM:MCDSteps </k>
          <msg-sender> 0:Address </msg-sender>
          <this> 0:Address </this>
          <authorized-accounts> .Set </authorized-accounts>
          <current-time> 0:Int </current-time>
          <call-stack> .List </call-stack>
          <pre-state> .K </pre-state>
          <events> .List </events>
          <frame-events> .List </frame-events>
        </kmcd-driver>
```

MCD Simulations
---------------

```k
    syntax MCDSteps ::= ".MCDSteps" | MCDStep MCDSteps
 // --------------------------------------------------
    rule <k> .MCDSteps => . ... </k>
    rule <k> MCD:MCDStep MCDS:MCDSteps => MCD ~> MCDS ... </k>

    syntax MCDContract ::= contract(MCDStep) [function]
    syntax Address ::= address(MCDContract) [function]
 // ---------------------------------------------------
```

Authentiation
-------------

We have a simplified model of system authentication which bins accounts into:

-   authorized: allowed to initiate transactions to any entry point in KMCD.
-   non-authorized: only allowed to initiate transactions into non-`auth` entry points in KMCD.

Note that any internal `call` does not need authorization, we assume that any internal `call` is responsible for ensuring a safe calling context.

```k
    syntax MCDStep ::= AdminStep
 // ----------------------------

    syntax AdminStep ::= "authorize" Address
 // ----------------------------------------
    rule <k> authorize ADDR => . ... </k>
         <authorized-accounts> ... (.Set => SetItem(ADDR)) </authorized-accounts>

    syntax AuthStep
    syntax MCDStep ::= AuthStep
 // ---------------------------
```

Function Calls
--------------

```k
    syntax CallFrame ::= frame(prevSender: Address, prevEvents: List, continuation: K)
 // ----------------------------------------------------------------------------------

    syntax MCDStep ::= "call" MCDStep
 // ---------------------------------
    rule <k> call MCD:MCDStep ~> CONT => MCD </k>
         <msg-sender> MSGSENDER => THIS </msg-sender>
         <this> THIS => address(contract(MCD)) </this>
         <call-stack> .List => ListItem(frame(MSGSENDER, EVENTS, CONT)) ... </call-stack>
         <frame-events> EVENTS => ListItem(LogNote(MSGSENDER, MCD)) </frame-events>

    syntax ReturnValue ::= Int | Rat
 // --------------------------------
    rule <k> R:ReturnValue => R ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ... </call-stack>
         <events> L => L EVENTS </events>
         <frame-events> EVENTS => PREVEVENTS </frame-events>

    rule <k> . => CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ... </call-stack>
         <events> L => L EVENTS </events>
         <frame-events> EVENTS => PREVEVENTS </frame-events>

    syntax MCDStep ::= "transact" Address MCDStep
 // ---------------------------------------------
    rule <k> transact ADDR:Address MCD:MCDStep => pushState ~> call MCD ~> dropState ... </k>
         <this> _ => ADDR </this>
         <msg-sender> _ => ADDR </msg-sender>
         <authorized-accounts> AUTH_ACCOUNTS </authorized-accounts>
      requires isAuthStep(MCD) impliesBool (ADDR in AUTH_ACCOUNTS)

    syntax MCDStep ::= MCDExceptionStep
    syntax MCDExceptionStep ::= "exception" MCDStep
 // -----------------------------------------------
    rule <k> MCDSTEP:MCDStep => exception MCDSTEP ... </k> requires notBool isMCDExceptionStep(MCDSTEP) [owise]

    rule <k> exception E ~> _ => exception E ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ...</call-stack>
         <frame-events> _ => PREVEVENTS </frame-events>

    rule <k> exception _ ~> dropState => popState ... </k>
         <call-stack> .List </call-stack>

    syntax MCStep ::= "pushState" | "dropState" | "popState"
 // --------------------------------------------------------

    syntax Event ::= LogNote(Address, MCDStep)
 // ------------------------------------------
```

Simulations
-----------

Different contracts use the same names for external functions, so we declare them here.

```k
    syntax InitStep ::= "init" Int
 // ------------------------------
```

Time Increments
---------------

Some methods rely on a timestamp. We simulate that here.

```k
    syntax MCDStep ::= "TimeStep"
 // -----------------------------
    rule <k> TimeStep => . ... </k>
         <current-time> TIME => TIME +Int 1 second </current-time>

    syntax priorities timeUnit > _+Int_ _-Int_ _*Int_ _/Int_
 // --------------------------------------------------------

    syntax Int ::= Int "second"  [timeUnit]
                 | Int "seconds" [timeUnit]
                 | Int "minute"  [timeUnit]
                 | Int "minutes" [timeUnit]
                 | Int "hour"    [timeUnit]
                 | Int "hours"   [timeUnit]
                 | Int "day"     [timeUnit]
                 | Int "days"    [timeUnit]
 // ---------------------------------------
    rule 1 second  => 1                    [macro]
    rule N seconds => N                    [macro]
    rule 1 minute  =>        60    seconds [macro]
    rule N minutes => N *Int 60    seconds [macro]
    rule 1 hour    =>        3600  seconds [macro]
    rule N hours   => N *Int 3600  seconds [macro]
    rule 1 day     =>        86400 seconds [macro]
    rule N days    => N *Int 86400 seconds [macro]
```

Collateral Increments
---------------------

```k
    syntax priorities collateralUnit > _+Int_ _-Int_ _*Int_ _/Int_
 // --------------------------------------------------------------

    syntax Int ::= Int "ether" [collateralUnit]
 // -------------------------------------------
    rule N ether => N *Int 1000000000 [macro]
```

Base Data
---------

-   `Wad`: basic quantities (e.g. balances). Represented in implementation as 1e18 fixed point.
-   `Ray`: precise quantities (e.g. ratios). Represented in implementation as 1e27 fixed point.
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision). Represented in implementation as 1e45 fixed point.
-   `Address`: unique identifier of an account on the network.

```k
    syntax Wad = Rat
 // ----------------

    syntax Ray = Rat
 // ----------------

    syntax Rad = Rat
 // ----------------

    syntax Address ::= Int | String
 // -------------------------------

    syntax MaybeWad ::= Wad | ".Wad"
 // --------------------------------
```

```k
endmodule
```
