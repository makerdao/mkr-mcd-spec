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
          <authorized-accounts> .Map </authorized-accounts>
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

Authorization Scheme
--------------------

Authorization happens at the `call` boundaries, which includes both transactions and calls between MCD contracts.
Each contract must defined the `authorized` function, which returns the set of accounts which are authorized for that account.
By default it's assumed that the special `ADMIN` account is authorized on all other contracts (for running simulations).

```k
    syntax MCDStep ::= AdminStep
 // ----------------------------

    syntax Set ::= wards ( MCDContract ) [function]
 // -----------------------------------------------
    rule wards(_) => .Set [owise]

    syntax Address ::= "ADMIN"
 // --------------------------

    syntax Bool ::= isAuthorized ( Address , MCDContract ) [function]
 // -----------------------------------------------------------------
    rule isAuthorized( _     , _           ) => false                      [owise]
    rule isAuthorized( ADMIN , _           ) => true
    rule isAuthorized( ADDR  , MCDCONTRACT ) => ADDR in wards(MCDCONTRACT) requires ADDR =/=K ADMIN

    syntax AuthStep
    syntax MCDStep ::= AuthStep
 // ---------------------------
```

Transactions
------------

`{push|drop|pop}State` are used for state roll-back (and are given semantics once the entire configuration is present).
Use `transact ...` for initiating top-level calls from a given user.

```k
    syntax AdminStep ::= "transact" Address MCDStep
 // -----------------------------------------------
    rule <k> transact ADDR:Address MCD:MCDStep => pushState ~> call MCD ~> dropState ... </k>
         <this> _ => ADDR </this>
         <msg-sender> _ => ADDR </msg-sender>

    syntax MCStep ::= "pushState" | "dropState" | "popState"
 // --------------------------------------------------------
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
         <this> THIS => address(contract(MCD)) </this>
         <authorized-accounts> AUTHS </authorized-accounts>
         <call-stack> .List => ListItem(frame(MSGSENDER, EVENTS, CONT)) ... </call-stack>
         <frame-events> EVENTS => ListItem(LogNote(MSGSENDER, MCD)) </frame-events>
      requires isAuthStep(MCD) impliesBool isAuthorized(THIS, contract(MCD))

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

    syntax AdminStep ::= "exception" MCDStep
 // ----------------------------------------
    rule <k> MCDSTEP:MCDStep => exception MCDSTEP ... </k> requires notBool isAdminStep(MCDSTEP) [owise]

    rule <k> exception E ~> _ => exception E ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ...</call-stack>
         <frame-events> _ => PREVEVENTS </frame-events>

    rule <k> exception _ ~> dropState => popState ... </k>
         <call-stack> .List </call-stack>
```

Log Events
----------

Most operations add to the log, which stores the address which made the call and the step which is being logged.

```k
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

### Account addresses

-   `Address`: unique identifier of an account on the network, an `Int` in real life, but `String` here for readability.

```k
    syntax Address ::= Int | String
 // -------------------------------

    syntax String ::= Address2String ( Address ) [function]
 // -------------------------------------------------------
    rule Address2String ( I:Int    ) => Int2String(I)
    rule Address2String ( S:String ) => S
```

### Time Increments

Some methods rely on a timestamp.
We simulate that here.

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
