```k
requires "kmcd-driver.k"

module VAT
    imports KMCD-DRIVER
```

CDP Data
--------

-   `VatIlk` tracks several parameters of a given `Ilk`:

    -   `Art`: Total debt across all `Address` for this `Ilk`.
    -   `rate`: Debt scaling factor.
    -   `spot`: Collateral scaling factor.
    -   `line`: Maximum allowed scaled debt for this `Ilk`.
    -   `dust`: Effectively zero (minimum) amount of debt allowed in this `Ilk`.

```k
    syntax VatIlk ::= Ilk ( Art: Wad , rate: Ray , spot: Ray , line: Rad , dust: Rad ) [klabel(#VatIlk), symbol]
 // ------------------------------------------------------------------------------------------------------------
```

-   `CDPID`: Identifies a given `Ilk` (collateral type) for a given `Address` (user).
-   `VatUrn` trackes a given CDP (collateralized-debt position) with parameters:

    -   `ink`: Total amount of collateral supporting the CDP.
    -   `art`: Total amount of debt against the CDP.

```k
    syntax CDPID ::= "{" String "," Address "}"
 // -------------------------------------------

    syntax VatUrn ::= Urn ( ink: Wad , art: Wad ) [klabel(#VatUrn), symbol]
 // -----------------------------------------------------------------------
```

### CDP Measurables

-   `urnBalance` takes an `Urn` and it's corresponding `Ilk` and returns the "balance" of the `Urn` (`collateral - debt`).
-   `urnDebt` calculates the `RATE`-scaled `ART` of an `Urn`.
-   `urnCollateral` calculates the `SPOT`-scaled `INK` of an `Urn`.

```k
    syntax Rad ::= urnBalance    ( VatIlk , VatUrn ) [function, functional]
                 | urnDebt       ( VatIlk , VatUrn ) [function, functional]
                 | urnCollateral ( VatIlk , VatUrn ) [function, functional]
 // -----------------------------------------------------------------------
    rule urnBalance(ILK, URN) => urnCollateral(ILK, URN) -Rat urnDebt(ILK, URN)

    rule urnDebt      (ILK, URN) => rate(ILK) *Rat art(URN)
    rule urnCollateral(ILK, URN) => spot(ILK) *Rat ink(URN)
```

Vat Configuration
-----------------

```k
    configuration
      <vat>
        <vat-addr> 0:Address </vat-addr>
        <vat-can>  .Map      </vat-can>  // mapping (address (address => uint))       Address |-> Set
        <vat-ilks> .Map      </vat-ilks> // mapping (bytes32 => Ilk)                  String  |-> VatIlk
        <vat-urns> .Map      </vat-urns> // mapping (bytes32 => (address => Urn))     CDPID   |-> VatUrn
        <vat-gem>  .Map      </vat-gem>  // mapping (bytes32 => (address => uint256)) CDPID   |-> Wad
        <vat-dai>  .Map      </vat-dai>  // mapping (address => uint256)              Address |-> Rad
        <vat-sin>  .Map      </vat-sin>  // mapping (address => uint256)              Address |-> Rad
        <vat-debt> 0:Rad     </vat-debt> // Total Dai Issued
        <vat-vice> 0:Rad     </vat-vice> // Total Unbacked Dai
        <vat-Line> 0:Rad     </vat-Line> // Total Debt Ceiling
        <vat-live> true      </vat-live> // Access Flag
      </vat>
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
    syntax MCDContract ::= VatContract
    syntax VatContract ::= "Vat"
    syntax MCDStep ::= VatContract "." VatStep [klabel(vatStep)]
 // ------------------------------------------------------------
    rule contract(Vat . _) => Vat
    rule [[ address(Vat) => ADDR ]] <vat-addr> ADDR </vat-addr>

    syntax VatStep ::= VatAuthStep
    syntax AuthStep ::= VatContract "." VatAuthStep [klabel(vatStep)]
 // -----------------------------------------------------------------
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
    syntax VatStep ::= "safe" String Address
 // ----------------------------------------
    rule <k> Vat . safe ILKID ADDR => . ... </k>
         <vat>
           <vat-ilks> ...   ILKID          |-> ILK ... </vat-ilks>
           <vat-urns> ... { ILKID , ADDR } |-> URN ... </vat-urns>
           ...
         </vat>
      requires 0 <=Rat urnBalance(ILK, URN)
       andBool urnDebt(ILK, URN) <=Rat line(ILK)

    syntax VatStep ::= "nondusty" String Address
 // --------------------------------------------
    rule <k> Vat . nondusty ILKID ADDR => . ... </k>
         <vat>
           <vat-ilks> ...   ILKID          |-> ILK ... </vat-ilks>
           <vat-urns> ... { ILKID , ADDR } |-> URN ... </vat-urns>
           ...
         </vat>
      requires dust(ILK) <=Rat urnDebt(ILK, URN) orBool 0 ==Rat urnDebt(ILK, URN)
```

### Ilk Initialization (`<vat-ilks>`)

-   `Vat.init` creates a new `ilk` collateral type, failing if the given `ilk` already exists.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= InitStep
 // -------------------------------
    rule <k> Vat . init ILKID => . ... </k>
         <vat-ilks> ILKS => ILKS [ ILKID <- 1 ] </vat-ilks>
      requires notBool ILKID in_keys(ILKS)
```

### Collateral manipulation (`<vat-gem>`)

-   `Vat.slip` adds to a users `<vat-gem>` collateral balance.
-   `Vat.flux` transfers `<vat-gem>` collateral between users.

    **NOTE**: We assume that the given `ilk` for that user has already been initialized.

    **TODO**: Should be `note`.
    **TODO**: Should `Vat.slip` use `Vat.consent` or `Vat.wish`?
    **TODO**: Should `Vat.flux` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatAuthStep ::= "slip" String Address Wad
 // ------------------------------------------------
    rule <k> Vat . slip ILKID ADDRTO NEWCOL => . ... </k>
         <vat-gem>
           ...
           { ILKID , ADDRTO } |-> ( COL => COL +Rat NEWCOL )
           ...
         </vat-gem>

    syntax VatStep ::= "flux" String Address Address Wad
 // ----------------------------------------------------
    rule <k> Vat . flux ILKID ADDRFROM ADDRTO COL => .
         ...
         </k>
         <vat-gem>
           ...
           { ILKID , ADDRFROM } |-> ( COLFROM => COLFROM -Rat COL )
           { ILKID , ADDRTO   } |-> ( COLTO   => COLTO   +Rat COL )
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
           ADDRFROM |-> (DAIFROM => DAIFROM -Rat DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Rat DAI)
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
    syntax VatStep ::= "fork" String Address Address Wad Wad
 // --------------------------------------------------------
    rule <k> Vat . fork ILKID ADDRFROM ADDRTO DINK DART
          => Vat . safe     ILKID ADDRFROM ~> Vat . safe     ILKID ADDRTO
          ~> Vat . nondusty ILKID ADDRFROM ~> Vat . nondusty ILKID ADDRTO
         ...
         </k>
         <vat-urns>
           ...
           { ILKID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Rat DINK , ARTFROM => ARTFROM -Rat DART )
           { ILKID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Rat DINK , ARTTO   => ARTFROM +Rat DART )
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
    syntax VatAuthStep ::= "grab" String Address Address Address Wad Wad
 // --------------------------------------------------------------------
    rule <k> Vat . grab ILKID ADDRU ADDRV ADDRW DINK DART => . ... </k>
         <vat-vice> VICE => VICE -Rat (RATE *Rat DART) </vat-vice>
         <vat-urns>
           ...
           { ILKID , ADDRU } |-> Urn ( INK => INK +Rat DINK , URNART => URNART +Rat DART )
           ...
         </vat-urns>
         <vat-ilks>
           ...
           ILKID |-> Ilk ( ILKART => ILKART +Rat DART , RATE , _ , _ , _ )
           ...
         </vat-ilks>
         <vat-gem>
           ...
           { ILKID , ADDRV } |-> ( ILKV => ILKV -Rat DINK )
           ...
         </vat-gem>
         <vat-sin>
           ...
           USERW |-> ( SINW => SINW -Rat (RATE *Rat DART) )
           ...
         </vat-sin>

    syntax VatStep ::= "frob" String Address Address Address Wad Wad
 // ----------------------------------------------------------------
    rule <k> Vat . frob ILKID ADDRU ADDRV ADDRW DINK DART => .
         ...
         </k>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Rat (RATE *Rat DART) </vat-debt>
         <vat-urns>
           ...
           { ILKID , ADDRU } |-> Urn ( INK => INK +Rat DINK , URNART => URNART +Rat DART )
           ...
         </vat-urns>
         <vat-ilks>
           ...
           ILKID |-> Ilk (... Art: ILKART => ILKART +Rat DART , rate: RATE , spot: SPOT, line: ILKLINE, dust: DUST )
           ...
         </vat-ilks>
         <vat-gem>
           ...
           { ILKID , ADDRV } |-> ( ILKV => ILKV -Rat DINK )
           ...
         </vat-gem>
         <vat-dai>
           ...
           USERW |-> ( DAIW => DAIW +Rat (RATE *Rat DART) )
           ...
         </vat-dai>
         <vat-Line> LINE </vat-Line>
      requires      ( DART <=Rat 0
               orBool ((ILKART +Rat DART) *Rat RATE <=Rat ILKLINE andBool DEBT +Rat (RATE *Rat DART) <=Rat LINE)
                    )
       andBool      ( (DART <=Rat 0 andBool DINK >=Rat 0)
               orBool (URNART +Rat DART) *Rat RATE <=Rat (INK +Rat DINK) *Rat SPOT
                    )
       andBool      ( (DART <=Rat 0 andBool DINK >=Rat 0)
               orBool wish ADDRU
                    )
       andBool (DINK <=Rat 0 orBool wish ADDRV)
       andBool (DART >=Rat 0 orBool wish ADDRW)
       andBool (URNART +Rat DART ==Rat 0 orBool (URNART +Rat DART) *Rat RATE >=Rat DUST)
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
         <vat-debt> DEBT => DEBT -Rat AMOUNT </vat-debt>
         <vat-vice> VICE => VICE -Rat AMOUNT </vat-vice>
         <vat-sin> ... ADDRFROM |-> (SIN => SIN -Rat AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRFROM |-> (DAI => DAI -Rat AMOUNT) ... </vat-dai>

    syntax VatAuthStep ::= "suck" Address Address Rad
 // -------------------------------------------------
    rule <k> Vat . suck ADDRU ADDRV AMOUNT => . ... </k>
         <vat-debt> DEBT => DEBT +Rat AMOUNT </vat-debt>
         <vat-vice> VICE => VICE +Rat AMOUNT </vat-vice>
         <vat-sin> ... ADDRU |-> (SIN => SIN +Rat AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRV |-> (DAI => DAI +Rat AMOUNT) ... </vat-dai>
```

### CDP Manipulation

-   `Vat.fold` modifies the debt multiplier for a given ilk having user `U` absort the difference in `<vat-dai>`.

**TODO**: Should be `note`.

```k
    syntax VatAuthStep ::= "fold" String Address Ray
 // ------------------------------------------------
    rule <k> Vat . fold ILKID ADDRU RATE => . ... </k>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Rat (ILKART *Rat RATE) </vat-debt>
         <vat-ilks>
           ...
           ILKID |-> Ilk ( ILKART , ILKRATE => ILKRATE +Rat RATE , _ , _ , _ )
           ...
         </vat-ilks>
         <vat-dai>
           ...
           ADDRU |-> ( DAI => DAI +Rat (ILKART *Rat RATE) )
           ...
         </vat-dai>
```

```k
endmodule
```
