KMCD - K Specification of MKR Multi-collateral Dai
==================================================

```k
requires "mkr-mcd-data.k"

module MKR-MCD
    imports MKR-MCD-DATA
```

MCD State
---------

```k
    configuration
      <mkr-mcd>
        <k> $PGM:MCDSteps </k>
        <msgSender> 0:Address </msgSender>
        <vatStack> .List </vatStack>
        <vat>
          <ward> .Map  </ward> // mapping (address => uint)                 Address |-> Bool
          <can>  .Map  </can>  // mapping (address (address => uint))       Address |-> Set
          <ilks> .Map  </ilks> // mapping (bytes32 => Ilk)                  Int     |-> VatIlk
          <urns> .Map  </urns> // mapping (bytes32 => (address => Urn))     CDPID   |-> VatUrn
          <gem>  .Map  </gem>  // mapping (bytes32 => (address => uint256)) CDPID   |-> Wad
          <dai>  .Map  </dai>  // mapping (address => uint256)              Address |-> Rad
          <sin>  .Map  </sin>  // mapping (address => uint256)              Address |-> Rad
          <debt> 0:Rad </debt> // Total Dai Issued
          <vice> 0:Rad </vice> // Total Unbacked Dai
          <Line> 0:Rad </Line> // Total Debt Ceiling
          <live> true  </live> // Access Flag
        </vat>
      </mkr-mcd>
```

Simulations
-----------

Simulations will be sequences of `MCDStep`.

```k
    syntax MCDSteps ::= MCDStep | MCDStep MCDSteps
 // ----------------------------------------------
    rule <k> MCD:MCDStep MCDS:MCDSteps => step [ MCD ] ~> MCDS ... </k>

    syntax MCDStep ::= ".MCDStep"
 // -----------------------------
    rule <k> .MCDStep => . ... </k>
```

The `step [_]` operator allows enforcing certain invariants during execution.

```k
    syntax MCDStep ::= "step" "[" MCDStep "]"
 // -----------------------------------------
```

Vat Semantics
-------------

The `Vat` implements the core accounting for MCD, allowing manipulation of `<gem>`, `<urns>`, `<dai>`, and `<sin>` in pre-specified ways.

-   `<gem>`: Locked collateral which can be used for collateralizing debt.
-   `<urns>`: Collateralized debt positions (CDPs), marking how much collateral is backing a given piece of debt.
-   `<dai>`: Stable-coin balances.
-   `<sin>`: Debt balances (anticoin).

Each type of `<gem>` is a `VatIlk`, which is tracked in `<ilks>`.
A given `ilk` tracks market factors for that collateral, including total debt/collateral, current spot price, maximum debt allowed, and what is considered a dust amount.

When taking a `VatStep` (a step which directly manipulates the `<vat>`), we make sure at the end of execution that any invariants that should hold for the `<vat>` do.
If any violations are found (eg. someone's balance goes down without a `wish`), then the state is rolled back.

```k
    syntax MCDStep ::= "Vat" "." VatStep
 // ------------------------------------
    rule <k> step [ Vat . VAS:VatAuthStep ] => Vat . push ~> Vat . auth ~> Vat . VAS ~> Vat . invariant ~> Vat . catch ... </k>
    rule <k> step [ Vat . VS              ] => Vat . push ~>               Vat . VS  ~> Vat . invariant ~> Vat . catch ... </k>
      requires notBool isVatAuthStep(VS)

    syntax VatStep ::= VatAuthStep
 // ------------------------------
```

We can save and restore the current `<vat>` state using `push`, `pop`, and `drop`.
This allows us to enforce properties after each step, and restore the old state when violated.

```k
    syntax VatStep ::= "push" | "pop" | "drop"
 // ------------------------------------------
    rule <k> Vat . push => . ... </k>
         <vatStack> (.List => ListItem(VAT)) ... </vatStack>
         <vat> VAT </vat>

    rule <k> Vat . pop => . ... </k>
         <vatStack> (ListItem(VAT) => .List) ... </vatStack>
         <vat> _ => VAT </vat>

    rule <k> Vat . drop => . ... </k>
         <vatStack> (ListItem(_) => .List) ... </vatStack>

    syntax VatStep ::= "catch" | "exception"
 // ----------------------------------------
    rule <k>                     Vat . catch => Vat . drop ... </k>
    rule <k> Vat . exception ~>  Vat . catch => Vat . pop  ... </k>
    rule <k> Vat . exception ~> (Vat . VS    => .)         ... </k>
      requires VS =/=K catch
```

### Warding Control

`Vat.auth` checks that the given account has been `ward`ed.
`Vat.rely ACCOUNT` and `Vat.deny ACCOUNT` toggle `ward [ ACCOUNT ]`.
**TODO**: `rely` and `deny` should be `note`.
**TODO**: Should we actually model `ward`ing? Sounds like an implementation detail of Ethereum.

Warding allows controlling which versions of a smart contract are allowed to call into this one.
By adjusting the `<ward>`, you can upgrade contracts in place by deploying a new contract for some part of the MCD system.

```k
    syntax VatStep ::= "auth"
 // -------------------------
    rule <k> Vat . auth => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <ward> ... MSGSENDER |-> true ... </ward>

    rule <k> Vat . auth => Vat . exception ... </k>
         <msgSender> MSGSENDER </msgSender>
         <ward> ... MSGSENDER |-> false ... </ward>

    syntax VatAuthStep ::= "rely" Address | "deny" Address
 // ------------------------------------------------------
    rule <k> Vat . rely ADDR => . ... </k>
         <ward> ... ADDR |-> (_ => true) ... </ward>

    rule <k> Vat . deny ADDR => . ... </k>
         <ward> ... ADDR |-> (_ => false) ... </ward>
```

### Vat Invariant

**TODO**: Extract invariants from implementation.

```k
    syntax VatStep ::= "invariant"
 // ------------------------------
    rule <k> Vat . invariant => Vat . exception ... </k> [owise]

    rule <k> Vat . invariant => . ... </k>
         <debt> DEBT:Int </debt>
         <vice> VICE:Int </vice>
         <dai>  DAI      </dai>
         <sin>  SIN      </sin>
      requires DEBT >=Int 0
       andBool VICE >=Int 0
       andBool allPositive(values(DAI))
       andBool allPositive(values(SIN))

    syntax Bool ::= allPositive ( List ) [function]
 // -----------------------------------------------
    rule allPositive(.List         ) => true
    rule allPositive(ListItem(V) VS) => false           requires notBool V >=Int 0
    rule allPositive(ListItem(V) VS) => allPositive(VS) requires         V >=Int 0
```

By setting `<can>` for an account, you are authorizing it to manipulate your `<gem>`, `<dai>`, and `<urns>` directly.
This is quite permissive, and would allow the account to drain all your locked collateral and assets, for example.

-   `Vat.wish` checks that the current account has been authorized by the given account to manipulate their positions.
-   `Vat.nope` and `Vat.hope` toggle the permissions of the current account, adding/removing another account to the authorized account set.

**NOTE**: It is assumed that `<can>` has already been initialized with the relevant accounts.

```k
    syntax VatStep ::= "wish" Address
 // ---------------------------------
    rule <k> Vat . wish ADDRFROM => . ... </k>
         <msgSender> MSGSENDER </msgSender>
      requires ADDRFROM ==K MSGSENDER

    rule <k> Vat . wish ADDRFROM => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <can> ... ADDRFROM |-> CANADDRS:Set ... </can>
      requires MSGSENDER in CANADDRS

    rule <k> Vat . wish ADDRFROM => Vat . exception ... </k>
         <msgSender> MSGSENDER </msgSender>
         <can> ... ADDRFROM |-> CANADDRS:Set ... </can>
      requires ADDRFROM =/=K MSGSENDER
       andBool notBool MSGSENDER in CANADDRS

    syntax VatStep ::= "hope" Address | "nope" Address
 // --------------------------------------------------
    rule <k> Vat . hope ADDRTO => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <can> ... MSGSENDER |-> (CANADDRS => CANADDRS SetItem(ADDRTO)) ... </can>

    rule <k> Vat . nope ADDRTO => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <can> ... MSGSENDER |-> (CANADDRS => CANADDRS -Set SetItem(ADDRTO)) ... </can>
```

### Ilk Initialization

-   `Vat.init` creates a new `ilk` collateral type, failing if the given `ilk` already exists.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "init" Int
 // ---------------------------------
    rule <k> Vat . init ILKID => . ... </k>
         <ilks> ILKS => ILKS [ ILKID <- ilk_init ] </ilks>
      requires notBool ILKID in_keys(ILKS)

    rule <k> Vat . init ILKID => Vat . exception ... </k>
         <ilks> ... ILKID |-> _ ... </ilks>
```

### `<gem>` manipulation and transfers

-   `Vat.slip` updates a users `<gem>` collateral balance for a given `ilk` manually.
-   `Vat.flux` transfers `<gem>` collateral between users.

**NOTE**: We assume that the given `ilk` for that user has already been initialized.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "slip" Int Address Wad
 // ---------------------------------------------
    rule <k> Vat . slip ILKID ADDRTO NEWCOL => . ... </k>
         <gem>
           ...
           { ILKID , ADDRTO } |-> ( COL => COL +Int NEWCOL )
           ...
         </gem>

    syntax VatStep ::= "flux" Int Address Address Wad
 // -------------------------------------------------
    rule <k> Vat . flux ILKID ADDRFROM ADDRTO COL => Vat . wish ADDRFROM ... </k>
         <gem>
           ...
           { ILKID , ADDRFROM } |-> ( COLFROM => COLFROM -Int COL )
           { ILKID , ADDRTO   } |-> ( COLTO   => COLTO   +Int COL )
           ...
         </gem>
```

-   `Vat.move`

### `<dai>` manipulation and transfer

`Vat.move` transfers Dai between users.
**TODO**: Should be `note`.

```k
    syntax VatStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Vat . move ADDRFROM ADDRTO DAI => Vat . wish ADDRFROM ... </k>
         <dai>
           ...
           ADDRFROM |-> (DAIFROM => DAIFROM -Int DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Int DAI)
           ...
         </dai>
```

### CDP Maintenance

`Vat.fork` splits a given CDP up.
**TODO**: Factor out `TABFROM == RATE *Int (ARTFROM -Int DART)` and `TABTO == RAT *Int (ARTTO +Int DART)` for requires.
**TODO**: Should have `note`, `safe`, non-`dusty`.
**TODO**: Should we swap `Vat.wish` for `Vat.consent` here?

```k
    syntax VatStep ::= "fork" Int Address Address Int Int
 // -----------------------------------------------------
    rule <k> Vat . fork ILKID ADDRFROM ADDRTO DINK DART
          => Vat . wish ADDRFROM ~> Vat . wish ADDRTO
         ...
         </k>
         <urns>
           ...
           { ILKID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Int DINK , ARTFROM => ARTFROM -Int DART )
           { ILKID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Int DINK , ARTTO   => ARTFROM +Int DART )
           ...
         </urns>
         <ilks>
           ...
           ILKID |-> Ilk ( ILKART , RATE , SPOT , LINE , DUST )
           ...
         </ilks>
```

`Vat.grab` confiscates a given CDP for liquidation.
**TODO**: Factor out `dtab == RATE *Int DART`.
**TODO**: Should be `note`.
**TODO**: Looks remarkably similar to `frob`, can we factor out a common smaller change for both?

```k
    syntax VatAuthStep ::= "grab" Int Address Address Address Int Int
 // -----------------------------------------------------------------
    rule <k> Vat . grab ILKID ADDRU ADDRV ADDRW DINK DART => . ... </k>
         <vice> VICE => VICE -Int (RATE *Int DART) </vice>
         <urns>
           ...
           { ILKID , ADDRU } |-> Urn ( INK => INK +Int DINK , URNART => URNART +Int DART )
           ...
         </urns>
         <ilks>
           ...
           ILKID |-> Ilk ( ILKART => ILKART +Int DART , RATE , SPOT , LINE , DUST )
           ...
         </ilks>
         <gem>
           ...
           { ILKID , ADDRV } |-> ( ILKV => ILKV -Int DINK )
           ...
         </gem>
         <sin>
           ...
           USERW |-> ( SINW => SINW -Int (RATE *Int DART) )
           ...
         </sin>
```

`Vat.heal` cancels a users Debt using their Dai.
**TODO**: Only `VatStep` using `<msgSender>` directly (not via `auth`).
**TODO**: Should have `note`.

```k
    syntax VatStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vat . heal AMOUNT => . ... </k>
         <msgSender> ADDRFROM </msgSender>
         <debt> DEBT => DEBT -Int AMOUNT </debt>
         <vice> VICE => VICE -Int AMOUNT </vice>
         <sin> ... ADDRFROM |-> (SIN => SIN -Int AMOUNT) ... </sin>
         <dai> ... ADDRFROM |-> (DAI => DAI -Int AMOUNT) ... </dai>
```

`Vat.suck` mints unbacked Dai.
**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "suck" Address Address Rad
 // -------------------------------------------------
    rule <k> Vat . suck ADDRFROM ADDRTO AMOUNT => . ... </k>
         <debt> DEBT => DEBT +Int AMOUNT </debt>
         <vice> VICE => VICE +Int AMOUNT </vice>
         <sin> ... ADDRFROM |-> (SIN => SIN +Int AMOUNT) ... </sin>
         <dai> ... ADDRFROM |-> (DAI => DAI +Int AMOUNT) ... </dai>
```

### CDP Manipulation

`Vat.cage` disables access to this instance of MCD.
**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "cage"
 // -----------------------------
    rule <k> Vat . cage => . ... </k>
         <live> _ => false </live>
```

`Vat.frob` "manipulates" the CDP of a given user.
**TODO**: Factor out `dtab == RATE *Int DART` and `tab == RATE *Int URNART`.
**TODO**: Should have `note`, `cool`, `firm`, `safe`, `live`.

```k
    syntax VatStep ::= "frob" Int Address Address Address Int Int
 // -------------------------------------------------------------
    rule <k> frob ILKID ADDRU ADDRV ADDRW DINK DART
          => Vat . wish ADDRU ~> Vat . wish ADDRV ~> Vat . wish ADDRW
         ...
         </k>
         <live> true </live>
         <debt> DEBT => DEBT +Int (RATE *Int DART) </debt>
         <urns>
           ...
           { ILKID , ADDRU } |-> Urn ( INK => INK +Int DINK , URNART => URNART +Int DART )
           ...
         </urns>
         <ilks>
           ...
           ILKID |-> Ilk ( ILKART => ILKART +Int DART , RATE , SPOT , LINE , DUST )
           ...
         </ilks>
         <gem>
           ...
           { ILKID , ADDRV } |-> ( ILKV => ILKV -Int DINK )
           ...
         </gem>
         <dai>
           ...
           USERW |-> ( DAIW => DAIW +Int (RATE *Int DART) )
           ...
         </dai>
```

`Vat.fold` modifies the debt multiplier and injects Dai for the user.
**TODO**: Should be `note`.
**TODO**: Only step requiring `<live>` exlpcitely.
**TODO**: Factor out `RAD == ILKART *Int RATE`.
**TODO**: Should we be using `RATE` or `ILKRATE +Int RATE`.

```k
    syntax VatAuthStep ::= "fold" Int Address Int
 // ---------------------------------------------
    rule <k> Vat . fold ILKID ADDRTO RATE => . ... </k>
         <live> true </live>
         <debt> DEBT => DEBT +Int (ILKART *Int RATE) </debt>
         <ilks>
           ...
           ILKID |-> Ilk ( ILKART , ILKRATE => ILKRATE +Int RATE , SPOT , LINE , DUST )
           ...
         </ilks>
         <dai>
           ...
           ADDRTO |-> ( DAI => DAI +Int (ILKART *Int RATE) )
           ...
         </dai>
```

```k
endmodule
```
