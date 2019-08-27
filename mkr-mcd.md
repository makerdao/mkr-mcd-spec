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
-   `<sin>`: Debt balances (anticoin, "negative Dai").

For convenience, total Dai/Sin are tracked:

-   `<debt>`: Total issued `<dai>`.
-   `<vice>`: Total issued `<sin>`.

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
    syntax VatStep ::= "push" | "pop" | "drop"
 // ------------------------------------------
    rule <k> Vat . push => . ... </k>
         <vatStack> (.List => ListItem(<vat> VAT </vat>)) ... </vatStack>
         <vat> VAT </vat>

    rule <k> Vat . pop => . ... </k>
         <vatStack> (ListItem(<vat> VAT </vat>) => .List) ... </vatStack>
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

Warding allows controlling which versions of a smart contract are allowed to call into this one.
By adjusting the `<ward>`, you can upgrade contracts in place by deploying a new contract for some part of the MCD system.

-   `Vat.auth` checks that the given account has been `ward`ed.
-   `Vat.rely` sets authorization for a user.
-   `Vat.deny` removes authorization for a user.

**TODO**: `rely` and `deny` should be `note`.

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

### Deactivation

-   `Vat.cage` disables access to this instance of MCD.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "cage"
 // -----------------------------
    rule <k> Vat . cage => . ... </k>
         <live> _ => false </live>
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
                        <debt> DEBT:Int </debt>
                        <Line> LINE:Int </Line>
                        <vice> VICE:Int </vice>
                        <dai>  DAI      </dai>
                        <sin>  SIN      </sin>
                        ...
                      </vat>
                    )
           ...
         </vatStack>
         <vat>
           <debt> DEBT':Int </debt>
           <Line> LINE':Int </Line>
           <vice> VICE':Int </vice>
           <dai>  DAI'      </dai>
           <sin>  SIN'      </sin>
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
                        <ilks> ...   ILKID          |-> ILK' ... </ilks>
                        <urns> ... { ILKID , ADDR } |-> URN' ... </urns>
                        <gem>  ... { ILKID , ADDR } |-> COL' ... </gem>
                        <dai>  ...           ADDR   |-> DAI' ... </dai>
                        ...
                      </vat>
                    )
           ...
         </vatStack>
         <vat>
           <ilks> ...   ILKID          |-> ILK ... </ilks>
           <urns> ... { ILKID , ADDR } |-> URN ... </urns>
           <gem>  ... { ILKID , ADDR } |-> COL ... </gem>
           <dai>  ...           ADDR   |-> DAI ... </dai>
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
                        <ilks> ...   ILKID          |-> ILK' ... </ilks>
                        <urns> ... { ILKID , ADDR } |-> URN' ... </urns>
                        ...
                      </vat>
                    )
           ...
         </vatStack>
         <vat>
           <ilks> ...   ILKID          |-> ILK ... </ilks>
           <urns> ... { ILKID , ADDR } |-> URN ... </urns>
           ...
         </vat>
      requires urnBalance(ILK, URN) <=Int urnBalance(ILK', URN')

    syntax VatStep ::= "safe" Int Address
 // -------------------------------------
    rule <k> Vat . safe ILKID ADDR => Vat . exception ... </k> [owise]
    rule <k> Vat . safe ILKID ADDR => .               ... </k>
         <vat>
           <ilks> ...   ILKID          |-> ILK ... </ilks>
           <urns> ... { ILKID , ADDR } |-> URN ... </urns>
           ...
         </vat>
      requires 0 <=Int urnBalance(ILK, URN)
       andBool urnDebt(ILK, URN) <=Int ilkLine(ILK)

    syntax VatStep ::= "nondusty" Int Address
 // -----------------------------------------
    rule <k> Vat . nondusty ILKID ADDR => Vat . exception ... </k> [owise]
    rule <k> Vat . nondusty ILKID ADDR => .               ... </k>
         <vat>
           <ilks> ...   ILKID          |-> ILK ... </ilks>
           <urns> ... { ILKID , ADDR } |-> URN ... </urns>
           ...
         </vat>
      requires ilkDust(ILK) <=Int urnDebt(ILK, URN) orBool 0 ==Int urnDebt(ILK, URN)
```

### Ilk Initialization (`<ilks>`)

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

### Collateral manipulation (`<gem>`)

-   `Vat.slip` adds to a users `<gem>` collateral balance.
-   `Vat.flux` transfers `<gem>` collateral between users.

    **NOTE**: We assume that the given `ilk` for that user has already been initialized.

    **TODO**: Should be `note`.
    **TODO**: Should `Vat.slip` use `Vat.consent` or `Vat.wish`?
    **TODO**: Should `Vat.flux` use `Vat.consent` or `Vat.wish`?

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
    rule <k> Vat . flux ILKID ADDRFROM ADDRTO COL
          => Vat . wish ADDRFROM
         ...
         </k>
         <gem>
           ...
           { ILKID , ADDRFROM } |-> ( COLFROM => COLFROM -Int COL )
           { ILKID , ADDRTO   } |-> ( COLTO   => COLTO   +Int COL )
           ...
         </gem>
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
         <dai>
           ...
           ADDRFROM |-> (DAIFROM => DAIFROM -Int DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Int DAI)
           ...
         </dai>
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
         <urns>
           ...
           { ILKID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Int DINK , ARTFROM => ARTFROM -Int DART )
           { ILKID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Int DINK , ARTTO   => ARTFROM +Int DART )
           ...
         </urns>
```

-   `Vat.grab` uses collateral from user `V` to burn `<sin>` for user `W` via one of `U`s CDPs.
-   `Vat.frob` uses collateral from user `V` to mint `<dai>` for user `W` via one of `U`s CDPs.

**TODO**: Should be `note`.
**TODO**: Factor out common step of "uses collateral from user `V` via one of `U`s CDPs"?
**TODO**: Double-check implemented checks for `Vat.frob`.

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
           ILKID |-> Ilk ( ILKART => ILKART +Int DART , RATE , _ , _ , _ )
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

    syntax VatStep ::= "frob" Int Address Address Address Int Int
 // -------------------------------------------------------------
    rule <k> frob ILKID ADDRU ADDRV ADDRW DINK DART
          => Vat . consent    ILKID ADDRU ~> Vat . consent ILKID ADDRV ~> Vat . consent ILKID ADDRW
          ~> Vat . less-risky ILKID ADDRU
          ~> Vat . nondusty   ILKID ADDRU
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
           ILKID |-> Ilk ( ILKART => ILKART +Int DART , RATE , _ , _ , _ )
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

### Debt/Dai manipulation (`<debt>`, `<dai>`, `<vice>`, `<sin>`)

-   `Vat.heal` cancels a users anticoins `<sin>` using their `<dai>`.
-   `Vat.suck` mints `<dai>` for user `V` via anticoins `<sin>` for user `U`.

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

    syntax VatAuthStep ::= "suck" Address Address Rad
 // -------------------------------------------------
    rule <k> Vat . suck ADDRU ADDRV AMOUNT => . ... </k>
         <debt> DEBT => DEBT +Int AMOUNT </debt>
         <vice> VICE => VICE +Int AMOUNT </vice>
         <sin> ... ADDRU |-> (SIN => SIN +Int AMOUNT) ... </sin>
         <dai> ... ADDRV |-> (DAI => DAI +Int AMOUNT) ... </dai>
```

### CDP Manipulation

-   `Vat.fold` modifies the debt multiplier for a given ilk having user `U` absort the difference in `<dai>`.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "fold" Int Address Int
 // ---------------------------------------------
    rule <k> Vat . fold ILKID ADDRU RATE => . ... </k>
         <live> true </live>
         <debt> DEBT => DEBT +Int (ILKART *Int RATE) </debt>
         <ilks>
           ...
           ILKID |-> Ilk ( ILKART , ILKRATE => ILKRATE +Int RATE , _ , _ , _ )
           ...
         </ilks>
         <dai>
           ...
           ADDRU |-> ( DAI => DAI +Int (ILKART *Int RATE) )
           ...
         </dai>
```

```k
endmodule
```
