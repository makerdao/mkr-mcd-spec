KMCD Driver
===========

This module defines common state and control flow between all the other KMCD modules.

```k
requires "rat.k"

module KMCD-DRIVER
    imports BOOL
    imports INT
    imports MAP
    imports STRING
    imports RAT

    configuration
        <kmcd-driver>
          <k> $PGM:MCDSteps </k>
          <return-value> .K </return-value>
          <msg-sender> 0:Address </msg-sender>
          <this> 0:Address </this>
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
 // ---------------------------------------------------
```

Authorization Scheme
--------------------

`Address` is a unique identifier of an account on the network.
They can be either an `Int` or a `String` (for readability).
In addition, each `MCDContract` is automatically an `Address`, under the assumption that there is a unique live instance of each one at a time.

```k
    syntax Address ::= Int | String | MCDContract
 // ---------------------------------------------
```

Authorization happens at the `call` boundaries, which includes both transactions and calls between MCD contracts.
Each contract must defined the `authorized` function, which returns the set of accounts which are authorized for that account.
By default it's assumed that the special `ADMIN` account is authorized on all other contracts (for running simulations).
The special account `ANYONE` is not authorized to do anything, so represents any actor in the system.

```k
    syntax MCDStep ::= AdminStep
 // ----------------------------

    syntax Set ::= wards ( MCDContract ) [function]
 // -----------------------------------------------
    rule wards(_) => .Set [owise]

    syntax Address ::= "ADMIN" | "ANYONE"
 // -------------------------------------

    syntax Bool ::= isAuthorized ( Address , MCDContract ) [function]
 // -----------------------------------------------------------------
    rule isAuthorized( ADDR , MCDCONTRACT ) => ADDR ==K ADMIN orBool ADDR in wards(MCDCONTRACT)

    syntax AuthStep
    syntax MCDStep ::= AuthStep
 // ---------------------------

    syntax WardStep ::= "rely" Address
                      | "deny" Address
 // ----------------------------------
```

Transactions
------------

`{push|drop|pop}State` are used for state roll-back (and are given semantics once the entire configuration is present).
Use `transact ...` for initiating top-level calls from a given user.

```k
    syntax AdminStep ::= "transact" Address MCDStep
 // -----------------------------------------------
    rule <k> transact ADDR:Address MCD:MCDStep => measure ~> pushState ~> call MCD ~> dropState ... </k>
         <this> _ => ADDR </this>
         <msg-sender> _ => ADDR </msg-sender>
         <call-stack> _ => .List </call-stack>
         <pre-state> _ => .K </pre-state>
         <frame-events> _ => .List </frame-events>
         <return-value> _ => .K </return-value>

    syntax AdminStep ::= "pushState" | "dropState" | "popState" | "measure"
 // -----------------------------------------------------------------------
```

Function Calls
--------------

Internal function calls utilize the `<call-stack>` to create call-frames and return values to their caller.
On `exception`, the entire current call is discarded to trigger state roll-back (we assume no error handling on internal `exception`).

```k
    syntax CallFrame ::= frame(prevSender: Address, prevEvents: List, continuation: K)
 // ----------------------------------------------------------------------------------

    syntax AdminStep ::= "call" MCDStep
 // -----------------------------------
    rule <k> call MCD:MCDStep ~> CONT => MCD </k>
         <msg-sender> MSGSENDER => THIS </msg-sender>
         <this> THIS => contract(MCD) </this>
         <call-stack> .List => ListItem(frame(MSGSENDER, EVENTS, CONT)) ... </call-stack>
         <frame-events> EVENTS => ListItem(LogNote(MSGSENDER, MCD)) </frame-events>
      requires isAuthStep(MCD) impliesBool isAuthorized(THIS, contract(MCD))

    rule <k> call MCD => exception MCD ... </k> [owise]

    syntax ReturnValue ::= Rat
 // --------------------------
    rule <k> R:ReturnValue => . ... </k>
         <return-value> _ => R </return-value>

    rule <k> . => CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ... </call-stack>
         <events> L => L EVENTS </events>
         <frame-events> EVENTS => PREVEVENTS </frame-events>

    syntax Event ::= Exception ( MCDStep )
 // --------------------------------------

    syntax AdminStep ::= "exception" MCDStep
 // ----------------------------------------
    rule <k> MCDSTEP:MCDStep => exception MCDSTEP ... </k> requires notBool isAdminStep(MCDSTEP) [owise]

    rule <k> exception E ~> _ => exception E ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ...</call-stack>
         <frame-events> _ => PREVEVENTS </frame-events>

    rule <k> exception MCDSTEP ~> dropState => popState ... </k>
         <call-stack> .List </call-stack>
         <events> ... (.List => ListItem(Exception(MCDSTEP))) </events>
```

Log Events
----------

Most operations add to the log, which stores the address which made the call and the step which is being logged.

```k
    syntax Event ::= LogNote(Address, MCDStep)
 // ------------------------------------------
```

Base Data
---------

### Precision Quantities

We model everything with arbitrary precision rationals, but use sort information to indicate the EVM code precision.

-   `Wad`: basic quantities (e.g. balances). Represented in implementation as 1e18 fixed point.
-   `Ray`: precise quantities (e.g. ratios). Represented in implementation as 1e27 fixed point.
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision). Represented in implementation as 1e45 fixed point.

```k
    syntax Wad = Rat
 // ----------------

    syntax Ray = Rat
 // ----------------

    syntax Rad = Rat
 // ----------------

    syntax MaybeWad ::= Wad | ".Wad"
 // --------------------------------
```

### Time Increments

Some methods rely on a timestamp.
We simulate that here.

```k
    syntax Event ::= TimeStep ( Int , Int )
 // ---------------------------------------

    syntax MCDStep ::= "TimeStep"
                     | "TimeStep" Int
 // ---------------------------------
    rule <k> TimeStep => TimeStep 1 ... </k>

    rule <k> TimeStep N => . ... </k>
         <current-time> TIME => TIME +Int N </current-time>
         <events> ... (.List => ListItem(TimeStep(N, TIME +Int N))) </events>
      requires N >Int 0

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

### Collateral Increments

```k
    syntax priorities collateralUnit > _+Int_ _-Int_ _*Int_ _/Int_
 // --------------------------------------------------------------

    syntax Int ::= Int "ether" [collateralUnit]
 // -------------------------------------------
    rule N ether => N *Int 1000000000 [macro]
```

```k
endmodule
```
