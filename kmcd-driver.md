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
          <currentTime> 0:Int </currentTime>
          <callStack> .List </callStack>
          <preState> .K </preState>
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

Function Calls
--------------

```k
    syntax CallFrame ::= frame(prevSender: Address, continuation: K)

    syntax AuthStep
    syntax MCDStep ::= AuthStep
    syntax MCDStep ::= "call" MCDStep
 // ---------------------------------
    rule <k> call AS:AuthStep ~> CONT => contract(AS) . auth ~> AS </k>
         <msg-sender> MSGSENDER => THIS </msg-sender>
         <this> THIS => address(contract(AS)) </this>
         <callStack> .List => ListItem(frame(MSGSENDER, CONT)) ... </callStack>
    rule <k> call MCD:MCDStep ~> CONT => MCD </k>
         <msg-sender> MSGSENDER => THIS </msg-sender>
         <this> THIS => address(contract(MCD)) </this>
         <callStack> .List => ListItem(frame(MSGSENDER, CONT)) ... </callStack>
      requires notBool isAuthStep(MCD)

    syntax ReturnValue ::= Int | Rat
 // --------------------------------
    rule <k> R:ReturnValue => R ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <callStack> ListItem(frame(PREVSENDER, CONT)) => .List ... </callStack>

    rule <k> . => CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <callStack> ListItem(frame(PREVSENDER, CONT)) => .List ... </callStack>

    syntax MCDStep ::= "transact" MCDStep
 // -------------------------------------
    rule <k> transact MCD:MCDStep => pushState ~> call MCD ~> dropState ... </k>

    syntax MCDStep ::= "exception"
 // ------------------------------
    rule <k> exception ~> _ => exception ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> THIS => MSGSENDER </this>
         <callStack> ListItem(frame(PREVSENDER, CONT)) => .List ...</callStack>

    rule <k> exception ~> dropState => popState ... </k>
         <callStack> .List </callStack>

    syntax MCStep ::= "pushState" | "dropState" | "popState"
 // --------------------------------------------------------
```

Authentiation
-------------

**TODO**: authentication and wards

```k
    syntax MCDStep ::= MCDContract "." "auth"
 // -----------------------------------------
    rule <k> MCD:MCDContract . auth => . ... </k>
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
         <currentTime> TIME => TIME +Int 1 second </currentTime>

    syntax Int ::= Int "second"  [timeUnit]
                 | Int "seconds" [timeUnit]
                 | Int "minute"  [timeUnit]
                 | Int "minutes" [timeUnit]
                 | Int "hour"    [timeUnit]
                 | Int "hours"   [timeUnit]
                 | Int "day"     [timeUnit]
                 | Int "days"    [timeUnit]
 // -------------------------

    syntax priorities timeUnit > _+Int_ _-Int_ _*Int_ _/Int_

    rule 1 second  => 1                    [macro]
    rule N seconds => N                    [macro]
    rule 1 minute  =>        60    seconds [macro]
    rule N minutes => N *Int 60    seconds [macro]
    rule 1 hour    =>        3600  seconds [macro]
    rule N hours   => N *Int 3600  seconds [macro]
    rule 1 day     =>        86400 seconds [macro]
    rule N days    => N *Int 86400 seconds [macro]
```

Base Data
---------

-   `Wad`: basic quantities (e.g. balances).
-   `Ray`: precise quantities (e.g. ratios).
-   `Rad`: result of multiplying `Wad` and `Ray` (highest precision).
-   `Address`: unique identifier of an account on the network.

**TODO**: Should we add operators like `+Wad` which emulate the precision limits described in `makerdao/dss/DEVELOPING.md`, or assume the abstract model to be inifinite precision?

```k
    syntax Wad ::= Int
 // ------------------

    syntax Ray ::= Int
 // ------------------

    syntax Rad ::= Int
 // ------------------

    syntax Address ::= Int | String
 // -------------------------------

    syntax Value ::= Int | ".Value"
 // -------------------------------
```

Constants
---------

```k
    syntax Int ::= "ilk_init"
 // -------------------------
    rule ilk_init => 1000000000000000000000000000 [macro]
```

Math Functions
--------------

```k
    syntax Int ::= #pow ( Int, Int ) [function]
 // -------------------------------------------
    rule #pow( X, 0 ) => ilk_init
    rule #pow( X, 1 ) => X
    rule #pow( X, N ) => X *Int #pow( X, N -Int 1 ) /Int ilk_init
```

```k
endmodule
```
