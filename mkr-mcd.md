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
        <currentTime> 0 </currentTime>
        <vatStack> .List </vatStack>
        <vat>
          <vat-ward> .Map  </vat-ward> // mapping (address => uint)                 Address |-> Bool
          <vat-can>  .Map  </vat-can>  // mapping (address (address => uint))       Address |-> Set
          <vat-ilks> .Map  </vat-ilks> // mapping (bytes32 => Ilk)                  Int     |-> VatIlk
          <vat-urns> .Map  </vat-urns> // mapping (bytes32 => (address => Urn))     CDPID   |-> VatUrn
          <vat-gem>  .Map  </vat-gem>  // mapping (bytes32 => (address => uint256)) CDPID   |-> Wad
          <vat-dai>  .Map  </vat-dai>  // mapping (address => uint256)              Address |-> Rad
          <vat-sin>  .Map  </vat-sin>  // mapping (address => uint256)              Address |-> Rad
          <vat-debt> 0:Rad </vat-debt> // Total Dai Issued
          <vat-vice> 0:Rad </vat-vice> // Total Unbacked Dai
          <vat-Line> 0:Rad </vat-Line> // Total Debt Ceiling
          <vat-live> true  </vat-live> // Access Flag
        </vat>
        <jugStack> .List </jugStack>
        <jug>
          <jug-ward> .Map      </jug-ward> // mapping (address => uint)   Address |-> Bool
          <jug-ilks> .Map      </jug-ilks> // mapping (bytes32 => JugIlk) Int     |-> JugIlk
          <jug-vow>  0:Address </jug-vow>  //                             Address
          <jug-base> 0         </jug-base> //                             Int
        </jug>
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

Different contracts use the same names for external functions, so we declare them here.

```k
    syntax InitStep ::= "init" Int
 // ------------------------------

    syntax WardStep ::= "rely" Address | "deny" Address
 // ---------------------------------------------------

    syntax AuthStep ::= "auth"
 // --------------------------

    syntax StashStep ::= "push" | "pop" | "drop"
 // --------------------------------------------

    syntax ExceptionStep ::= "catch" | "exception"
 // ----------------------------------------------
```

Some methods rely on a timestamp. We simulate that here.

```k
    syntax MCDStep ::= "TimeStep"
 // -----------------------------
    rule <k> TimeStep => . ... </k>
         <currentTime> TIME => TIME +Int 1 </currentTime>
```

Vat Semantics
-------------

The `Vat` implements the core accounting for MCD, allowing manipulation of `<vat-gem>`, `<vat-urns>`, `<vat-dai>`, and `<vat-sin>` in pre-specified ways.

-   `<vat-gem>`: Locked collateral which can be used for collateralizing debt.
-   `<vat-urns>`: Collateralized debt positions (CDPs), marking how much collateral is backing a given piece of debt.
-   `<vat-dai>`: Stable-coin balances.
-   `<vat-sin>`: Debt balances (anticoin, "negative Dai").

For convenience, total Dai/Sin are tracked:

-   `<vat-debt>`: Total issued `<vat-dai>`.
-   `<vat-vice>`: Total issued `<vat-sin>`.

### Vat Steps

Updating the `<vat>` happens in phases:

-   Save off the current `<vat>`,
-   Check if either (i) this step does not need admin authorization or (ii) we are authorized to take this step,
-   Check that the `Vat.invariant` holds, and
-   Roll back state on failure.

**TODO**: Should every `notBool isAuthStep` be subject to `Vat . live`?

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
    syntax VatStep ::= StashStep
 // ----------------------------
    rule <k> Vat . push => . ... </k>
         <vatStack> (.List => ListItem(<vat> VAT </vat>)) ... </vatStack>
         <vat> VAT </vat>

    rule <k> Vat . pop => . ... </k>
         <vatStack> (ListItem(<vat> VAT </vat>) => .List) ... </vatStack>
         <vat> _ => VAT </vat>

    rule <k> Vat . drop => . ... </k>
         <vatStack> (ListItem(_) => .List) ... </vatStack>

    syntax VatStep ::= ExceptionStep
 // --------------------------------
    rule <k>                     Vat . catch => Vat . drop ... </k>
    rule <k> Vat . exception ~>  Vat . catch => Vat . pop  ... </k>
    rule <k> Vat . exception ~> (Vat . VS    => .)         ... </k>
      requires VS =/=K catch
```

### Warding Control

Warding allows controlling which versions of a smart contract are allowed to call into this one.
By adjusting the `<vat-ward>`, you can upgrade contracts in place by deploying a new contract for some part of the MCD system.

-   `Vat.auth` checks that the given account has been `ward`ed.
-   `Vat.rely` sets authorization for a user.
-   `Vat.deny` removes authorization for a user.

**TODO**: `rely` and `deny` should be `note`.

```k
    syntax VatStep ::= AuthStep
 // ---------------------------
    rule <k> Vat . auth => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <vat-ward> ... MSGSENDER |-> true ... </vat-ward>

    rule <k> Vat . auth => Vat . exception ... </k>
         <msgSender> MSGSENDER </msgSender>
         <vat-ward> ... MSGSENDER |-> false ... </vat-ward>

    syntax VatAuthStep ::= WardStep
 // -------------------------------
    rule <k> Vat . rely ADDR => . ... </k>
         <vat-ward> ... ADDR |-> (_ => true) ... </vat-ward>

    rule <k> Vat . deny ADDR => . ... </k>
         <vat-ward> ... ADDR |-> (_ => false) ... </vat-ward>
```

### Deactivation

-   `Vat.cage` disables access to this instance of MCD.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "cage"
 // -----------------------------
    rule <k> Vat . cage => . ... </k>
         <vat-live> _ => false </vat-live>
```

### Vat Safety Checks

Vat safety is enforced by adding specific checks on the `<vat>` state updates.

-   `Vat.invariant` states basic invariants of the `Vat` quanities and is checked after every `VatStep`.

```k
    syntax VatStep ::= "invariant"
 // ------------------------------
    rule <k> Vat . invariant => Vat . exception ... </k> [owise]
    rule <k> Vat . invariant => .               ... </k>
         <vatStack>
           ListItem ( <vat>
                        <vat-debt> DEBT:Int </vat-debt>
                        <vat-Line> LINE:Int </vat-Line>
                        <vat-vice> VICE:Int </vat-vice>
                        <vat-dai>  DAI      </vat-dai>
                        <vat-sin>  SIN      </vat-sin>
                        ...
                      </vat>
                    )
           ...
         </vatStack>
         <vat>
           <vat-debt> DEBT':Int </vat-debt>
           <vat-Line> LINE':Int </vat-Line>
           <vat-vice> VICE':Int </vat-vice>
           <vat-dai>  DAI'      </vat-dai>
           <vat-sin>  SIN'      </vat-sin>
           ...
         </vat>
      requires DEBT' >=Int 0 andBool (DEBT' >Int DEBT impliesBool DEBT' <=Int LINE')
       andBool VICE' >=Int 0
       andBool allPositive(values(DAI'))
       andBool allPositive(values(SIN'))

    syntax Bool ::= allPositive ( List ) [function]
 // -----------------------------------------------
    rule allPositive(.List         ) => true
    rule allPositive(ListItem(V) VS) => false           requires notBool V >=Int 0
    rule allPositive(ListItem(V) VS) => allPositive(VS) requires         V >=Int 0
```

By setting `<vat-can>` for an account, you are authorizing it to manipulate your `<vat-gem>`, `<vat-dai>`, and `<vat-urns>` directly.
This is quite permissive, and would allow the account to drain all your locked collateral and assets, for example.

-   `Vat.wish` checks that the current account has been authorized by the given account to manipulate their positions.
-   `Vat.nope` and `Vat.hope` toggle the permissions of the current account, adding/removing another account to the authorized account set.

**NOTE**: It is assumed that `<vat-can>` has already been initialized with the relevant accounts.

```k
    syntax VatStep ::= "wish" Address
 // ---------------------------------
    rule <k> Vat . wish ADDRFROM => . ... </k>
         <msgSender> MSGSENDER </msgSender>
      requires ADDRFROM ==K MSGSENDER

    rule <k> Vat . wish ADDRFROM => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <vat-can> ... ADDRFROM |-> CANADDRS:Set ... </vat-can>
      requires MSGSENDER in CANADDRS

    rule <k> Vat . wish ADDRFROM => Vat . exception ... </k>
         <msgSender> MSGSENDER </msgSender>
         <vat-can> ... ADDRFROM |-> CANADDRS:Set ... </vat-can>
      requires ADDRFROM =/=K MSGSENDER
       andBool notBool MSGSENDER in CANADDRS

    syntax VatStep ::= "hope" Address | "nope" Address
 // --------------------------------------------------
    rule <k> Vat . hope ADDRTO => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <vat-can> ... MSGSENDER |-> (CANADDRS => CANADDRS SetItem(ADDRTO)) ... </vat-can>

    rule <k> Vat . nope ADDRTO => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <vat-can> ... MSGSENDER |-> (CANADDRS => CANADDRS -Set SetItem(ADDRTO)) ... </vat-can>
```

-   `Vat.consent` checks whether a transaction was beneficial for a given account, otherwise makes sure that `Vat.wish` is set.
    This encodes that "rational actors consent to actions which benefit them".

-   `Vat.safe` checks that a given `Urn` of a certain `ilk` is not over-leveraged.

-   `Vat.nondusty` checks that a given `Urn` has either exactly 0 on a non-dusty amount of debt.
    **TODO**: Currently we use `urnDebt ==Int 0`, whereas Solidity implementation uses `urnArt ==Int 0`.
              Does it matter? They are equivalent as long as `urnRate =/=Int 0`.

```k
    syntax VatStep ::= "consent" Int Address
 // ----------------------------------------
    rule <k> Vat . consent _     ADDR => Vat . wish ADDR ... </k> [owise]
    rule <k> Vat . consent ILKID ADDR => .               ... </k>
         <vatStack>
           ListItem ( <vat>
                        <vat-ilks> ...   ILKID          |-> ILK' ... </vat-ilks>
                        <vat-urns> ... { ILKID , ADDR } |-> URN' ... </vat-urns>
                        <vat-gem>  ... { ILKID , ADDR } |-> COL' ... </vat-gem>
                        <vat-dai>  ...           ADDR   |-> DAI' ... </vat-dai>
                        ...
                      </vat>
                    )
           ...
         </vatStack>
         <vat>
           <vat-ilks> ...   ILKID          |-> ILK ... </vat-ilks>
           <vat-urns> ... { ILKID , ADDR } |-> URN ... </vat-urns>
           <vat-gem>  ... { ILKID , ADDR } |-> COL ... </vat-gem>
           <vat-dai>  ...           ADDR   |-> DAI ... </vat-dai>
           ...
         </vat>
      requires COL                  <=Int COL'
       andBool DAI                  <=Int DAI'
       andBool urnBalance(ILK, URN) <=Int urnBalance(ILK', URN')

    syntax VatStep ::= "less-risky" Int Address
 // -------------------------------------------
    rule <k> Vat . less-risky ILKID ADDR => Vat . safe ILKID ADDR ... </k> [owise]
    rule <k> Vat . less-risky ILKID ADDR => .                     ... </k>
         <vatStack>
           ListItem ( <vat>
                        <vat-ilks> ...   ILKID          |-> ILK' ... </vat-ilks>
                        <vat-urns> ... { ILKID , ADDR } |-> URN' ... </vat-urns>
                        ...
                      </vat>
                    )
           ...
         </vatStack>
         <vat>
           <vat-ilks> ...   ILKID          |-> ILK ... </vat-ilks>
           <vat-urns> ... { ILKID , ADDR } |-> URN ... </vat-urns>
           ...
         </vat>
      requires urnBalance(ILK, URN) <=Int urnBalance(ILK', URN')

    syntax VatStep ::= "safe" Int Address
 // -------------------------------------
    rule <k> Vat . safe ILKID ADDR => Vat . exception ... </k> [owise]
    rule <k> Vat . safe ILKID ADDR => .               ... </k>
         <vat>
           <vat-ilks> ...   ILKID          |-> ILK ... </vat-ilks>
           <vat-urns> ... { ILKID , ADDR } |-> URN ... </vat-urns>
           ...
         </vat>
      requires 0 <=Int urnBalance(ILK, URN)
       andBool urnDebt(ILK, URN) <=Int ilkLine(ILK)

    syntax VatStep ::= "nondusty" Int Address
 // -----------------------------------------
    rule <k> Vat . nondusty ILKID ADDR => Vat . exception ... </k> [owise]
    rule <k> Vat . nondusty ILKID ADDR => .               ... </k>
         <vat>
           <vat-ilks> ...   ILKID          |-> ILK ... </vat-ilks>
           <vat-urns> ... { ILKID , ADDR } |-> URN ... </vat-urns>
           ...
         </vat>
      requires ilkDust(ILK) <=Int urnDebt(ILK, URN) orBool 0 ==Int urnDebt(ILK, URN)
```

### Ilk Initialization (`<vat-ilks>`)

-   `Vat.init` creates a new `ilk` collateral type, failing if the given `ilk` already exists.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= InitStep
 // -------------------------------
    rule <k> Vat . init ILKID => . ... </k>
         <vat-ilks> ILKS => ILKS [ ILKID <- ilk_init ] </vat-ilks>
      requires notBool ILKID in_keys(ILKS)

    rule <k> Vat . init ILKID => Vat . exception ... </k>
         <vat-ilks> ... ILKID |-> _ ... </vat-ilks>
```

### Collateral manipulation (`<vat-gem>`)

-   `Vat.slip` adds to a users `<vat-gem>` collateral balance.
-   `Vat.flux` transfers `<vat-gem>` collateral between users.

    **NOTE**: We assume that the given `ilk` for that user has already been initialized.

    **TODO**: Should be `note`.
    **TODO**: Should `Vat.slip` use `Vat.consent` or `Vat.wish`?
    **TODO**: Should `Vat.flux` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatAuthStep ::= "slip" Int Address Wad
 // ---------------------------------------------
    rule <k> Vat . slip ILKID ADDRTO NEWCOL => . ... </k>
         <vat-gem>
           ...
           { ILKID , ADDRTO } |-> ( COL => COL +Int NEWCOL )
           ...
         </vat-gem>

    syntax VatStep ::= "flux" Int Address Address Wad
 // -------------------------------------------------
    rule <k> Vat . flux ILKID ADDRFROM ADDRTO COL
          => Vat . wish ADDRFROM
         ...
         </k>
         <vat-gem>
           ...
           { ILKID , ADDRFROM } |-> ( COLFROM => COLFROM -Int COL )
           { ILKID , ADDRTO   } |-> ( COLTO   => COLTO   +Int COL )
           ...
         </vat-gem>
```

-   `Vat.move` transfers Dai between users.

    **TODO**: Should be `note`.
    **TODO**: Should `Vat.move` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Vat . move ADDRFROM ADDRTO DAI
          => Vat . wish ADDRFROM
         ...
         </k>
         <vat-dai>
           ...
           ADDRFROM |-> (DAIFROM => DAIFROM -Int DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Int DAI)
           ...
         </vat-dai>
```

### CDP Manipulation

-   `Vat.fork` splits a given CDP up.

    **TODO**: Factor out `TABFROM == RATE *Int (ARTFROM -Int DART)` and `TABTO == RAT *Int (ARTTO +Int DART)` for requires.
    **TODO**: Should have `note`, `safe`, non-`dusty`.
    **TODO**: Should `Vat.fork` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatStep ::= "fork" Int Address Address Int Int
 // -----------------------------------------------------
    rule <k> Vat . fork ILKID ADDRFROM ADDRTO DINK DART
          => Vat . wish           ADDRFROM ~> Vat . wish           ADDRTO
          ~> Vat . safe     ILKID ADDRFROM ~> Vat . safe     ILKID ADDRTO
          ~> Vat . nondusty ILKID ADDRFROM ~> Vat . nondusty ILKID ADDRTO
         ...
         </k>
         <vat-urns>
           ...
           { ILKID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Int DINK , ARTFROM => ARTFROM -Int DART )
           { ILKID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Int DINK , ARTTO   => ARTFROM +Int DART )
           ...
         </vat-urns>
```

-   `Vat.grab` uses collateral from user `V` to burn `<vat-sin>` for user `W` via one of `U`s CDPs.
-   `Vat.frob` uses collateral from user `V` to mint `<vat-dai>` for user `W` via one of `U`s CDPs.

**TODO**: Should be `note`.
**TODO**: Factor out common step of "uses collateral from user `V` via one of `U`s CDPs"?
**TODO**: Double-check implemented checks for `Vat.frob`.

```k
    syntax VatAuthStep ::= "grab" Int Address Address Address Int Int
 // -----------------------------------------------------------------
    rule <k> Vat . grab ILKID ADDRU ADDRV ADDRW DINK DART => . ... </k>
         <vat-vice> VICE => VICE -Int (RATE *Int DART) </vat-vice>
         <vat-urns>
           ...
           { ILKID , ADDRU } |-> Urn ( INK => INK +Int DINK , URNART => URNART +Int DART )
           ...
         </vat-urns>
         <vat-ilks>
           ...
           ILKID |-> Ilk ( ILKART => ILKART +Int DART , RATE , _ , _ , _ )
           ...
         </vat-ilks>
         <vat-gem>
           ...
           { ILKID , ADDRV } |-> ( ILKV => ILKV -Int DINK )
           ...
         </vat-gem>
         <vat-sin>
           ...
           USERW |-> ( SINW => SINW -Int (RATE *Int DART) )
           ...
         </vat-sin>

    syntax VatStep ::= "frob" Int Address Address Address Int Int
 // -------------------------------------------------------------
    rule <k> frob ILKID ADDRU ADDRV ADDRW DINK DART
          => Vat . consent    ILKID ADDRU ~> Vat . consent ILKID ADDRV ~> Vat . consent ILKID ADDRW
          ~> Vat . less-risky ILKID ADDRU
          ~> Vat . nondusty   ILKID ADDRU
         ...
         </k>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Int (RATE *Int DART) </vat-debt>
         <vat-urns>
           ...
           { ILKID , ADDRU } |-> Urn ( INK => INK +Int DINK , URNART => URNART +Int DART )
           ...
         </vat-urns>
         <vat-ilks>
           ...
           ILKID |-> Ilk ( ILKART => ILKART +Int DART , RATE , _ , _ , _ )
           ...
         </vat-ilks>
         <vat-gem>
           ...
           { ILKID , ADDRV } |-> ( ILKV => ILKV -Int DINK )
           ...
         </vat-gem>
         <vat-dai>
           ...
           USERW |-> ( DAIW => DAIW +Int (RATE *Int DART) )
           ...
         </vat-dai>
```

### Debt/Dai manipulation (`<vat-debt>`, `<vat-dai>`, `<vat-vice>`, `<vat-sin>`)

-   `Vat.heal` cancels a users anticoins `<vat-sin>` using their `<vat-dai>`.
-   `Vat.suck` mints `<vat-dai>` for user `V` via anticoins `<vat-sin>` for user `U`.

**TODO**: Should have `note`.

```k
    syntax VatStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vat . heal AMOUNT => . ... </k>
         <msgSender> ADDRFROM </msgSender>
         <vat-debt> DEBT => DEBT -Int AMOUNT </vat-debt>
         <vat-vice> VICE => VICE -Int AMOUNT </vat-vice>
         <vat-sin> ... ADDRFROM |-> (SIN => SIN -Int AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRFROM |-> (DAI => DAI -Int AMOUNT) ... </vat-dai>

    syntax VatAuthStep ::= "suck" Address Address Rad
 // -------------------------------------------------
    rule <k> Vat . suck ADDRU ADDRV AMOUNT => . ... </k>
         <vat-debt> DEBT => DEBT +Int AMOUNT </vat-debt>
         <vat-vice> VICE => VICE +Int AMOUNT </vat-vice>
         <vat-sin> ... ADDRU |-> (SIN => SIN +Int AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRV |-> (DAI => DAI +Int AMOUNT) ... </vat-dai>
```

### CDP Manipulation

-   `Vat.fold` modifies the debt multiplier for a given ilk having user `U` absort the difference in `<vat-dai>`.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "fold" Int Address Int
 // ---------------------------------------------
    rule <k> Vat . fold ILKID ADDRU RATE => . ... </k>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Int (ILKART *Int RATE) </vat-debt>
         <vat-ilks>
           ...
           ILKID |-> Ilk ( ILKART , ILKRATE => ILKRATE +Int RATE , _ , _ , _ )
           ...
         </vat-ilks>
         <vat-dai>
           ...
           ADDRU |-> ( DAI => DAI +Int (ILKART *Int RATE) )
           ...
         </vat-dai>
```

Jug Semantics
-------------

```k
    syntax MCDStep ::= "Jug" "." JugStep
 // ------------------------------------
    rule <k> step [ Jug . JAS:JugAuthStep ] => Jug . push ~> Jug . auth ~> Jug . JAS ~> Jug . catch ... </k>
    rule <k> step [ Jug . JS              ] => Jug . push ~>               Jug . JS  ~> Jug . catch ... </k>
      requires notBool isJugAuthStep(JS)

    syntax JugStep ::= JugAuthStep
 // ------------------------------

    syntax JugStep ::= StashStep
 // ----------------------------
    rule <k> Jug . push => . ... </k>
         <jugStack> (.List => ListItem(JUG)) ... </jugStack>
         <jug> JUG </jug>

    rule <k> Jug . pop => . ... </k>
         <jugStack> (ListItem(JUG) => .List) ... </jugStack>
         <jug> _ => JUG </jug>

    rule <k> Jug . drop => . ... </k>
         <jugStack> (ListItem(_) => .List) ... </jugStack>
```

**TODO**: Should we make cells for call stacks and exceptions?
```k
    syntax JugStep ::= ExceptionStep
 // --------------------------------
    rule <k>                     Jug . catch => Jug . drop ... </k>
    rule <k> Jug . exception ~>  Jug . catch => Jug . pop  ... </k>
    rule <k> Jug . exception ~> (Jug . JS    => .)         ... </k>
      requires JS =/=K catch

    syntax JugStep ::= AuthStep
 // ---------------------------
    rule <k> Jug . auth => . ... </k>
         <msgSender> MSGSENDER </msgSender>
         <jug-ward> ... MSGSENDER |-> true ... </jug-ward>

    rule <k> Jug . auth => Jug . exception ... </k>
         <msgSender> MSGSENDER </msgSender>
         <jug-ward> ... MSGSENDER |-> false ... </jug-ward>

    syntax JugAuthStep ::= WardStep
 // -------------------------------
    rule <k> Jug . rely ADDR => . ... </k>
         <jug-ward> ... ADDR |-> (_ => true) ... </jug-ward>

    rule <k> Jug . deny ADDR => . ... </k>
         <jug-ward> ... ADDR |-> (_ => false) ... </jug-ward>

    syntax JugStep ::= InitStep
 // ---------------------------
    rule <k> Jug . init ILK => TimeStep ... </k>
         <currentTime> TIME </currentTime>
         <jug-ilks> ... ILK |-> Ilk ( ILKDUTY => ilk_init, _ => TIME ) ... </jug-ilks>
      requires ILKDUTY ==Int 0

    rule <k> Jug . init _ => Jug . exception ... </k> [owise]
```

**TODO**: Add Vat.fold to Jug.drip
```k
    syntax JugStep ::= "drip" Int
 // -----------------------------
    rule <k> Jug . drip ILK ... </k>
         <currentTime> TIME </currentTime>
         <vat-ilks> ... ILK |-> Ilk ( _, ILKRATE, _, _, _ ) ... </vat-ilks>
         <jug-ilks> ... ILK |-> Ilk ( ILKDUTY, ILKRHO => TIME ) ... </jug-ilks>
         <jug-vow> ADDRESS </jug-vow>
         <jug-base> BASE </jug-base>
      requires TIME >=Int ILKRHO
```

```k
endmodule
```
