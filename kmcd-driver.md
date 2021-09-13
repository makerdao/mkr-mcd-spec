KMCD Driver
===========

This module defines common state and control flow between all the other KMCD modules.

```k
requires "evm.md"
requires "kmcd-data.md"

module KMCD-DRIVER
    imports KMCD-DATA
    imports MAP
    imports STRING
    imports BYTES
    imports LIST
    imports EVM

    configuration
        <kmcd-driver>
          <return-value> .K </return-value>
          <msg-sender> 0:Address </msg-sender>
          <this> 0:Address </this>
          <current-time> 0:Int </current-time>
          <mcd-call-stack> .List </mcd-call-stack>
          <pre-state> .K </pre-state>
          <events> .List </events>
          <tx-log> .Transaction </tx-log>
          <frame-events> .List </frame-events>
          <kevm/>
        </kmcd-driver>
```

MCD Simulations
---------------

```k
    syntax EthereumSimulation ::= MCDSteps
 // --------------------------------------

    syntax MCDSteps ::= ".MCDSteps" | MCDStep MCDSteps
 // --------------------------------------------------
    rule <k> .MCDSteps => . ... </k> <exit-code> _ => 0 </exit-code>
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

    syntax Set ::= wards ( MCDContract ) [function, functional]
 // -----------------------------------------------------------
    rule wards(_) => .Set [owise]

    syntax Address ::= "ADMIN" | "ANYONE"
 // -------------------------------------

    syntax Bool ::= isAuthorized ( Address , MCDContract ) [function]
 // -----------------------------------------------------------------
    rule isAuthorized( ADDR , MCDCONTRACT ) => ADDR ==K ADMIN orBool ADDR in wards(MCDCONTRACT)
```

Transactions
------------

`{push|drop|pop}State` are used for state roll-back (and are given semantics once the entire configuration is present).
Use `transact ...` for initiating top-level calls from a given user.

```k
    syntax AdminStep ::= "transact" Address MCDStep | "#end-transact"
 // -----------------------------------------------------------------
    rule <k> transact ADDR:Address MCD:MCDStep => pushState ~> call MCD ~> #end-transact ~> assert ~> dropState ... </k>
         <this> _ => ADDR </this>
         <msg-sender> _ => ADDR </msg-sender>
         <mcd-call-stack> _ => .List </mcd-call-stack>
         <pre-state> _ => .K </pre-state>
         <tx-log> _ => Transaction(... acct: ADDR, call: MCD, events: .List, txException: false) </tx-log>
         <frame-events> _ => .List </frame-events>
         <return-value> _ => .K </return-value>

    rule <k> #end-transact => . ... </k>
         <events> ... (.List => ListItem(TXLOG)) </events>
         <tx-log> TXLOG => .Transaction </tx-log>

    rule <k> exception MCDSTEP ~> #end-transact => #end-transact ~> exception MCDSTEP ... </k>
         <tx-log> Transaction(... txException: _ => true) </tx-log>

    syntax Event ::= Transaction
    syntax Transaction ::= ".Transaction"                                                                   [klabel(.Transaction) , symbol]
                         | Transaction ( acct: Address , call: MCDStep , events: List , txException: Bool ) [klabel(Transaction)  , symbol]
 // ---------------------------------------------------------------------------------------------------------------------------------------

    syntax AdminStep ::= "pushState" | "dropState" | "popState" | "assert"
 // ----------------------------------------------------------------------
```

Function Calls
--------------

Internal function calls utilize the `<mcd-call-stack>` to create call-frames and return values to their caller.
On `exception`, the entire current call is discarded to trigger state roll-back (we assume no error handling on internal `exception`).

```k
    syntax CallFrame ::= frame(prevSender: Address, prevEvents: List, continuation: K)
 // ----------------------------------------------------------------------------------

    syntax AdminStep ::= "call"     MCDStep
                       | "makecall" MCDStep
                       | ModifierStep
 // ---------------------------------
    rule <k> call MCD:MCDStep => checkauth MCD ~> checklock MCD ~> makecall MCD ~> checkunlock MCD ...  </k>

    rule <k> makecall MCD:MCDStep ~> CONT => MCD </k>
         <msg-sender> MSGSENDER => THIS </msg-sender>
         <this> THIS => contract(MCD) </this>
         <mcd-call-stack> .List => ListItem(frame(MSGSENDER, EVENTS, CONT)) ... </mcd-call-stack>
         <frame-events> EVENTS => ListItem(LogNote(MSGSENDER, MCD)) </frame-events>

    rule <k> . => CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> _THIS => MSGSENDER </this>
         <mcd-call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ... </mcd-call-stack>
         <tx-log> Transaction(... events: L => L EVENTS) </tx-log>
         <frame-events> EVENTS => PREVEVENTS </frame-events>
```

### Modifier Calls

Modifiers in Solidity are used to modify the behaviour of a function.
At the moment these are typically used in the codebase to check prerequisite conditions when acessing functions in order to prevent unauthorized access and re-entrant calls.
`AuthStep` is used as the modifier to check if a caller belongs to the contract's `wards`.
`LockStep` is used as a non re-entrant check.

```k
    syntax AuthStep
    syntax MCDStep ::= LockStep | AuthStep
 // --------------------------------------

    syntax WardOp ::= "rely" | "deny"
    syntax WardArgs ::= Address
    syntax WardStep ::= WardOp WardArgs

    syntax Op ::= WardOp
    syntax Args ::= WardArgs
    syntax CallStep ::= WardStep
 // ----------------------------------

    syntax ModifierStep ::= "checkauth"   MCDStep
                          | "checklock"   MCDStep
                          | "checkunlock" MCDStep
                          | "lock"        MCDStep
                          | "unlock"      MCDStep
 // ---------------------------------------------

    syntax LockAuthStep
    syntax LockStep ::= LockAuthStep
    syntax AuthStep ::= LockAuthStep
 // --------------------------------
    rule <k> V:Value => . ... </k> <return-value> _ => V </return-value>

    rule <k> checkauth MCD:AuthStep => .             ... </k> <this> THIS </this> requires isAuthorized(THIS, contract(MCD))
    rule <k> checkauth MCD          => .             ... </k>                     requires notBool isAuthStep(MCD)
    rule <k> checkauth MCD          => exception MCD ... </k>                     [owise]

    rule <k> checklock MCD:LockStep => lock MCD ... </k>
    rule <k> checklock MCD          => .        ... </k> requires notBool isLockStep(MCD)

    rule <k> checkunlock MCD:LockStep => unlock MCD ... </k>
    rule <k> checkunlock MCD          => .          ... </k> requires notBool isLockStep(MCD)

    rule <k> lock   MCD => exception MCD ... </k> [owise]
    rule <k> unlock MCD => exception MCD ... </k> [owise]
```

### Exception Handling

Whenever an exception occurs the state must be rolled back.
During the regular execution of a step this implies popping the `mcd-call-stack` and rolling back `frame-events`.

```k
    syntax Event ::= Exception ( Address , MCDStep ) [klabel(LogException), symbol]
 // -------------------------------------------------------------------------------

    syntax AdminStep ::= "exception" MCDStep
 // ----------------------------------------
    rule <k> MCDSTEP:MCDStep => exception MCDSTEP ... </k> requires notBool isAdminStep(MCDSTEP) [owise]

    rule <k> exception E ~> _ => exception E ~> CONT </k>
         <msg-sender> MSGSENDER => PREVSENDER </msg-sender>
         <this> _THIS => MSGSENDER </this>
         <mcd-call-stack> ListItem(frame(PREVSENDER, PREVEVENTS, CONT)) => .List ... </mcd-call-stack>
         <tx-log> Transaction(... events: L => L EVENTS) </tx-log>
         <frame-events> EVENTS => PREVEVENTS </frame-events>

    rule <k> exception _MCDSTEP ~> dropState => popState ... </k>
         <mcd-call-stack> .List </mcd-call-stack>

    rule <k> exception _ ~> (assert         => .) ... </k>
    rule <k> exception _ ~> (_:ModifierStep => .) ... </k>
    rule <k> exception _ ~> (makecall _     => .) ... </k>
```

### Function Signature and Arguments

Each individual contract function call, `CallStep`, is characterized by its function name, `Op`, and its arguments, `Args`.

```k
    syntax Op
    syntax Args
    syntax CallStep
```

Log Events
----------

Most operations add to the log, which stores the address which made the call and the step which is being logged.

```k
    syntax Event ::= LogNote(Address, MCDStep) [klabel(LogNote), symbol]
 // --------------------------------------------------------------------
```

Some contracts emit custom events, which are held in a subsort.

```k
    syntax CustomEvent
    syntax Event ::= CustomEvent
 // ----------------------------
```

Time Steps
----------

Some methods rely on a timestamp.
We simulate that here.

```k
    syntax Event ::= TimeStep ( Int , Int ) [klabel(LogTimeStep), symbol]
 // ---------------------------------------------------------------------

    syntax MCDStep ::= "TimeStep"
                     | "TimeStep" Int
 // ---------------------------------
    rule <k> TimeStep => TimeStep 1 ... </k>

    rule <k> TimeStep N => assert ... </k>
         <current-time> TIME => TIME +Int N </current-time>
         <events> ... (.List => ListItem(TimeStep(N, TIME +Int N))) </events>
      requires N >Int 0
```

```k
endmodule
```
