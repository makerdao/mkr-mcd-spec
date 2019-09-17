CDP Core
========

This module represents the CDP core accounting engine, mostly encompassed by state in and operations over `<vat>`.

```k
requires "kmcd-driver.k"

module CDP-CORE
    imports KMCD-DRIVER
```

CDP Data
--------

-   `CDPID`: Identifies a given users `ilk` or `urn`.

```k
    syntax CDPID ::= "{" Int "," Address "}"
 // ----------------------------------------
```

-   `VatIlk`: `ART`, `RATE`, `SPOT`, `LINE`, `DUST`.
-   `JugIlk`: `DUTY`, `RHO`.
-   `CatIlk`: `FLIP`, `CHOP`, `LUMP`
-   `SpotIlk`: `VALUE`, `MAT`

`Ilk` is a collateral with certain risk parameters.
Vat doesn't care about parameters for auctions, so only has stuff like debt ceiling, penalty, etc.
Cat has stuff like penalty.
Ok to say "this is the VatIlk, this is the CatIlk".
"Could have one big `Ilk` type with all the parameters, but there are different types to project out relevant parts to those contracts."
Getters and setters for `Ilk` should be permissioned, and different combinations of Contract + User might have `file` access to different fields (might be non-`file` access methods).

```k
    syntax VatIlk ::= Ilk ( Art: Wad , rate: Ray , spot: Ray , line: Rad , dust: Rad ) [klabel(#VatIlk), symbol]
 // ------------------------------------------------------------------------------------------------------------

    syntax JugIlk ::= Ilk ( Int, Int )                    [klabel(#JugIlk), symbol]
 // -------------------------------------------------------------------------------

    syntax CatIlk ::= Ilk ( Address, Int, Int )           [klabel(#CatIlk), symbol]
 // -------------------------------------------------------------------------------

    syntax SpotIlk ::= SpotIlk ( Value, Int )            [klabel(#SpotIlk), symbol]
 // -------------------------------------------------------------------------------
```

-   `ilkLine` returns the `LINE` associated with an `Ilk`.
-   `ilkDust` returns the `DUST` associated with an `Ilk`.

```k
    syntax Int ::= ilkLine ( VatIlk ) [function, functional]
                 | ilkDust ( VatIlk ) [function, functional]
 // --------------------------------------------------------
    rule ilkLine(Ilk(_, _, _, LINE, _   )) => LINE
    rule ilkDust(Ilk(_, _, _, _,    DUST)) => DUST
```

-   `VatUrn`: `INK`, `ART`

`Urn` is individual CDP of a certain `Ilk` for a certain address (actual data that comprises a CDP).
`Urn` has the exact same definition everywhere, so we can get away with a single definition.

```k
    syntax VatUrn ::= Urn ( Wad , Wad ) [klabel(#VatUrn), symbol]
 // -------------------------------------------------------------
```

-   `urnBalance` takes an `Urn` and it's corresponding `Ilk` and returns the "balance" of the `Urn` (`collateral - debt`).
-   `urnDebt` calculates the `RATE`-scaled `ART` of an `Urn`.
-   `urnCollateral` calculates the `SPOT`-scaled `INK` of an `Urn`.

```k
    syntax Int ::= urnBalance    ( VatIlk , VatUrn ) [function, functional]
                 | urnDebt       ( VatIlk , VatUrn ) [function, functional]
                 | urnCollateral ( VatIlk , VatUrn ) [function, functional]
 // -----------------------------------------------------------------------
    rule urnBalance(ILK, URN) => urnCollateral(ILK, URN) -Int urnDebt(ILK, URN)

    rule urnDebt      (Ilk(_ , RATE , _    , _ , _), Urn( _   , ART )) => ART *Int RATE
    rule urnCollateral(Ilk(_ , _    , SPOT , _ , _), Urn( INK , _   )) => INK *Int SPOT
```

Vat CDP State
-------------

```k
    configuration
      <cdp-core>
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
        <catStack> .List </catStack>
        <cat>
          <cat-ward> .Map </cat-ward>
          <cat-ilks> .Map </cat-ilks>
          <cat-live> 1    </cat-live>
        </cat>
        <spotStack> .List </spotStack>
        <spot>
          <spot-ward> .Map </spot-ward> // mapping (address => uint) Address |-> Bool
          <spot-ilks> .Map </spot-ilks> // mapping (bytes32 => ilk)  Int     |-> SpotIlk
          <spot-par>  0    </spot-par>
        </spot>
      </cdp-core>
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
-   Check that the `Vat.check` holds, and
-   Roll back state on failure.

**TODO**: Should every `notBool isAuthStep` be subject to `Vat . live`?

```k
    syntax MCDStep ::= "Vat" "." VatStep
 // ------------------------------------
    rule <k> step [ Vat . VAS:VatAuthStep ] => Vat . push ~> Vat . auth ~> Vat . VAS ~> Vat . catch ... </k>
    rule <k> step [ Vat . VS              ] => Vat . push ~>               Vat . VS  ~> Vat . catch ... </k>
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
    syntax VatAuthStep ::= AuthStep
 // -------------------------------
    rule <k> Vat . auth => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-ward> ... MSGSENDER |-> true ... </vat-ward>

    rule <k> Vat . auth => Vat . exception ... </k>
         <msg-sender> MSGSENDER </msg-sender>
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
    syntax VatAuthStep ::= "cage" [klabel(#VatCage), symbol]
 // --------------------------------------------------------
    rule <k> Vat . cage => . ... </k>
         <vat-live> _ => false </vat-live>
```

### Vat Safety Checks

Vat safety is enforced by adding specific checks on the `<vat>` state updates.

By setting `<vat-can>` for an account, you are authorizing it to manipulate your `<vat-gem>`, `<vat-dai>`, and `<vat-urns>` directly.
This is quite permissive, and would allow the account to drain all your locked collateral and assets, for example.

-   `Vat.wish` checks that the current account has been authorized by the given account to manipulate their positions.
-   `Vat.nope` and `Vat.hope` toggle the permissions of the current account, adding/removing another account to the authorized account set.

**NOTE**: It is assumed that `<vat-can>` has already been initialized with the relevant accounts.

```k
    syntax Bool ::= "wish" Address [function]
 // -----------------------------------------
    rule [[ wish ADDRFROM => true ]]
         <msg-sender> MSGSENDER </msg-sender>
      requires ADDRFROM ==K MSGSENDER

    rule [[ wish ADDRFROM => true ]]
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> ... ADDRFROM |-> CANADDRS:Set ... </vat-can>
      requires MSGSENDER in CANADDRS

    rule wish _ => false [owise]

    syntax VatStep ::= "hope" Address | "nope" Address
 // --------------------------------------------------
    rule <k> Vat . hope ADDRTO => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> ... MSGSENDER |-> (CANADDRS => CANADDRS SetItem(ADDRTO)) ... </vat-can>

    rule <k> Vat . nope ADDRTO => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> ... MSGSENDER |-> (CANADDRS => CANADDRS -Set SetItem(ADDRTO)) ... </vat-can>
```

-   `Vat.safe` checks that a given `Urn` of a certain `ilk` is not over-leveraged.

```k
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
    rule <k> Vat . flux ILKID ADDRFROM ADDRTO COL => .
         ...
         </k>
         <vat-gem>
           ...
           { ILKID , ADDRFROM } |-> ( COLFROM => COLFROM -Int COL )
           { ILKID , ADDRTO   } |-> ( COLTO   => COLTO   +Int COL )
           ...
         </vat-gem>
      requires wish ADDRFROM
```

-   `Vat.move` transfers Dai between users.

    **TODO**: Should be `note`.
    **TODO**: Should `Vat.move` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Vat . move ADDRFROM ADDRTO DAI => .
         ...
         </k>
         <vat-dai>
           ...
           ADDRFROM |-> (DAIFROM => DAIFROM -Int DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Int DAI)
           ...
         </vat-dai>
      requires wish ADDRFROM
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
          => Vat . safe     ILKID ADDRFROM ~> Vat . safe     ILKID ADDRTO
          ~> Vat . nondusty ILKID ADDRFROM ~> Vat . nondusty ILKID ADDRTO
         ...
         </k>
         <vat-urns>
           ...
           { ILKID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Int DINK , ARTFROM => ARTFROM -Int DART )
           { ILKID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Int DINK , ARTTO   => ARTFROM +Int DART )
           ...
         </vat-urns>
      requires wish ADDRFROM
       andBool wish ADDRTO
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
           ILKID |-> Ilk (... Art: ILKART => ILKART +Int DART , rate: RATE , spot: SPOT, line: ILKLINE, dust: DUST )
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
         <vat-Line> LINE </vat-Line>
      requires (DART <=Int 0
        orBool ((ILKART +Int DART) *Int RATE <=Int ILKLINE andBool DEBT +Int (RATE *Int DART) <=Int LINE))
       andBool ((DART <=Int 0 andBool DINK >=Int 0) orBool (URNART +Int DART) *Int RATE <=Int (INK +Int DINK) *Int SPOT)
       andBool ((DART <=Int 0 andBool DINK >=Int 0) orBool wish ADDRU)
       andBool (DINK <=Int 0 orBool wish ADDRV)
       andBool (DART >=Int 0 orBool wish ADDRW)
       andBool (URNART +Int DART ==Int 0 orBool (URNART +Int DART) *Int RATE >=Int DUST)
```

### Debt/Dai manipulation (`<vat-debt>`, `<vat-dai>`, `<vat-vice>`, `<vat-sin>`)

-   `Vat.heal` cancels a users anticoins `<vat-sin>` using their `<vat-dai>`.
-   `Vat.suck` mints `<vat-dai>` for user `V` via anticoins `<vat-sin>` for user `U`.

**TODO**: Should have `note`.

```k
    syntax VatStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vat . heal AMOUNT => . ... </k>
         <msg-sender> ADDRFROM </msg-sender>
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
         <msg-sender> MSGSENDER </msg-sender>
         <jug-ward> ... MSGSENDER |-> true ... </jug-ward>

    rule <k> Jug . auth => Jug . exception ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <jug-ward> ... MSGSENDER |-> false ... </jug-ward>

    syntax JugAuthStep ::= WardStep
 // -------------------------------
    rule <k> Jug . rely ADDR => . ... </k>
         <jug-ward> ... ADDR |-> (_ => true) ... </jug-ward>

    rule <k> Jug . deny ADDR => . ... </k>
         <jug-ward> ... ADDR |-> (_ => false) ... </jug-ward>

    syntax JugStep ::= InitStep
 // ---------------------------
    rule <k> Jug . init ILK => . ... </k>
         <currentTime> TIME </currentTime>
         <jug-ilks> ... ILK |-> Ilk ( ILKDUTY => ilk_init, _ => TIME ) ... </jug-ilks>
      requires ILKDUTY ==Int 0

    rule <k> Jug . init _ => Jug . exception ... </k> [owise]
```

```k
    syntax JugStep ::= "drip" Int
 // -----------------------------
    rule <k> Jug . drip ILK => Vat . fold ILK ADDRESS ( #pow( BASE +Int ILKDUTY, TIME -Int ILKRHO ) *Int ILKRATE ) -Int ILKRATE ... </k>
         <currentTime> TIME </currentTime>
         <vat-ilks> ... ILK |-> Ilk ( _, ILKRATE, _, _, _ ) ... </vat-ilks>
         <jug-ilks> ... ILK |-> Ilk ( ILKDUTY, ILKRHO => TIME ) ... </jug-ilks>
         <jug-vow> ADDRESS </jug-vow>
         <jug-base> BASE </jug-base>
      requires TIME >=Int ILKRHO

    rule <k> Jug . drip ILK => Jug . exception ... </k>
         <currentTime> TIME </currentTime>
         <jug-ilks> ... ILK |-> Ilk ( _, ILKRHO ) ... </jug-ilks>
      requires TIME <Int ILKRHO
```

Cat Semantics
-------------

```k
    syntax MCDStep ::= "Cat" "." CatStep
 // ------------------------------------

    syntax CatStep ::= CatAuthStep
 // ------------------------------

    syntax CatAuthStep ::= AuthStep
 // -------------------------------

    syntax CatAuthStep ::= WardStep
 // -------------------------------

    syntax CatAuthStep ::= "init" Address
 // -------------------------------------

    syntax CatStep ::= StashStep
 // ----------------------------

    syntax CatStep ::= ExceptionStep
 // --------------------------------

    syntax CatStep ::= "bite" Int Address
 // -------------------------------------

    syntax CatStep ::= "cage" [klabel(#CatCage), symbol]
 // ----------------------------------------------------
```

Spot Semantics
--------------

```k
    syntax MCDStep ::= "Spot" "." SpotStep
 // --------------------------------------
    rule <k> step [ Spot . SAS:SpotAuthStep ] => Spot . push ~> Spot . auth ~> Spot . SAS ~> Spot . catch ... </k>
    rule <k> step [ Spot . SS               ] => Spot . push ~>                Spot . SS  ~> Spot . catch ... </k>
      requires notBool isSpotAuthStep(SS)

    syntax SpotStep ::= SpotAuthStep
 // --------------------------------

    syntax SpotAuthStep ::= AuthStep
 // --------------------------------
    rule <k> Spot . auth => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <spot-ward> ... MSGSENDER |-> true ... </spot-ward>

    rule <k> Spot . auth => Spot . exception ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <spot-ward> ... MSGSENDER |-> false ... </spot-ward>

    syntax SpotAuthStep ::= WardStep
 // --------------------------------
    rule <k> Spot . rely ADDR => . ... </k>
         <spot-ward> ... ADDR |-> (_ => true) ... </spot-ward>

    rule <k> Spot . deny ADDR => . ... </k>
         <spot-ward> ... ADDR |-> (_ => false) ... </spot-ward>

    syntax SpotAuthStep ::= InitStep
 // --------------------------------
    rule <k> Spot . init MSGSENDER => . ... </k>
         <spot-ward> M => M[MSGSENDER <- true] </spot-ward>
         <spot-par> _ => ilk_init </spot-par>

    syntax SpotStep ::= StashStep
 // -----------------------------
    rule <k> Spot . push => . ... </k>
         <spotStack> (.List => ListItem(SPOT)) ... </spotStack>
         <spot> SPOT </spot>

    rule <k> Spot . pop => . ... </k>
         <spotStack> (ListItem(SPOT) => .List) ... </spotStack>
         <spot> _ => SPOT </spot>

    rule <k> Spot . drop => . ... </k>
         <spotStack> (ListItem(_) => .List) ... </spotStack>

    syntax SpotStep ::= ExceptionStep
 // ---------------------------------
    rule <k>                      Spot . catch => Spot . drop ... </k>
    rule <k> Spot . exception ~>  Spot . catch => Spot . pop  ... </k>
    rule <k> Spot . exception ~> (Spot . SS    => .)          ... </k>
      requires SS =/=K catch

    syntax SpotStep ::= "poke" Int
 // ------------------------------
    rule <k> Spot . poke ILK => . ... </k>
         <vat-ilks> ... ILK |-> Ilk ( _, _, ( _ => ((VALUE *Int 1000000000) /Int PAR) /Int MAT ), _, _ ) ... </vat-ilks>
         <spot-ilks> ... ILK |-> SpotIlk ( VALUE, MAT ) ... </spot-ilks>
         <spot-par> PAR </spot-par>
      requires VALUE =/=K .Value

    rule <k> Spot . poke ILK => . ... </k>
         <spot-ilks> ... ILK |-> SpotIlk ( .Value, _ ) ... </spot-ilks>
```

```k
endmodule
```
