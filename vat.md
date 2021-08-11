```k
requires "kmcd-driver.md"

module VAT
    imports KMCD-DRIVER
```

Vat Configuration
-----------------

```k
    configuration
      <vat>
        <vat-wards> .Set   </vat-wards>
        <vat-can>   .Map   </vat-can>  // mapping (address (address => uint))       Address |-> Set
        <vat-ilks>  .Map   </vat-ilks> // mapping (bytes32 => Ilk)                  String  |-> VatIlk
        <vat-urns>  .Map   </vat-urns> // mapping (bytes32 => (address => Urn))     CDPID   |-> VatUrn
        <vat-gem>   .Map   </vat-gem>  // mapping (bytes32 => (address => uint256)) CDPID   |-> Wad
        <vat-dai>   .Map   </vat-dai>  // mapping (address => uint256)              Address |-> Rad
        <vat-sin>   .Map   </vat-sin>  // mapping (address => uint256)              Address |-> Rad
        <vat-debt>  rad(0) </vat-debt> // Total Dai Issued
        <vat-vice>  rad(0) </vat-vice> // Total Unbacked Dai
        <vat-Line>  rad(0) </vat-Line> // Total Debt Ceiling
        <vat-live>  true   </vat-live> // Access Flag
      </vat>
```

The `Vat` implements the core accounting for MCD, allowing manipulation of `<vat-gem>`, `<vat-urns>`, `<vat-dai>`, and `<vat-sin>` in pre-specified ways.

-   `<vat-gem>`: Locked collateral which can be used for collateralizing debt.
-   `<vat-urns>`: Collateralized debt positions (CDPs), marking how much collateral is backing a given piece of debt.
-   `<vat-dai>`: Stable-coin balances.
-   `<vat-sin>`: Debt balances (anticoin, "negative Dai").

For convenience, total Dai/Sin are tracked:

-   `<vat-debt>`: Total issued `<vat-dai>`.
-   `<vat-vice>`: Total issued `<vat-sin>`.

### Vat Steps

**TODO**: Should every `notBool isAuthStep` be subject to `Vat . live`?

```k
    syntax MCDContract ::= VatContract
    syntax VatContract ::= "Vat"
    syntax MCDStep ::= VatContract "." VatStep [klabel(vatStep)]
 // ------------------------------------------------------------
    rule contract(Vat . _) => Vat
```

### Constructor

```k
    syntax VatStep ::= "constructor"
 // --------------------------------
    rule <k> Vat . constructor => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <vat> _ </vat>
        => <vat>
             <vat-wards> SetItem(MSGSENDER) </vat-wards>
             <vat-live> true </vat-live>
             ...
           </vat>
         )
```

Vat Authorization
-----------------

```k
    syntax VatStep  ::= VatAuthStep
    syntax AuthStep ::= VatContract "." VatAuthStep [klabel(vatStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Vat) => WARDS ]] <vat-wards> WARDS </vat-wards>

    syntax VatAuthStep ::= WardStep
 // -------------------------------
    rule <k> Vat . rely ADDR => . ... </k>
         <vat-wards> ... (.Set => SetItem(ADDR)) </vat-wards>
         <vat-live> true </vat-live>

    rule <k> Vat . deny ADDR => . ... </k>
         <vat-wards> WARDS => WARDS -Set SetItem(ADDR) </vat-wards>
         <vat-live> true </vat-live>
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
    syntax CDPID ::= "{" String "," Address "}" [klabel(CDPID), symbol]
 // -------------------------------------------------------------------

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
    rule urnBalance(ILK, URN) => urnCollateral(ILK, URN) -Rad urnDebt(ILK, URN)

    rule urnDebt      (ILK, URN) => art(URN) *Rate rate(ILK)
    rule urnCollateral(ILK, URN) => ink(URN) *Rate spot(ILK)
```

File-able Fields
----------------

The parameters controlled by governance are:

-   `Line`: Global debt ceiling of the `vat`.
-   `spot`: Market rate for a given `Ilk`.
-   `line`: Debt ceiling for a given `Ilk`.
-   `dust`: Essentially zero amount for a given `Ilk`.

```k
    syntax VatAuthStep ::= "file" VatFile
 // -------------------------------------

    syntax VatFile ::= "Line" Rad
                     | "spot" String Ray
                     | "line" String Rad
                     | "dust" String Rad
 // ------------------------------------
    rule <k> Vat . file Line LINE => . ... </k>
         <vat-live> true </vat-live>
         <vat-Line> _ => LINE </vat-Line>
      requires LINE >=Rad rad(0)

    rule <k> Vat . file spot ILK_ID SPOT => . ... </k>
         <vat-live> true </vat-live>
         <vat-ilks> ... ILK_ID |-> Ilk ( ... spot: (_ => SPOT) ) ... </vat-ilks>
      requires SPOT >=Ray ray(0)

    rule <k> Vat . file line ILK_ID LINE => . ... </k>
         <vat-live> true </vat-live>
         <vat-ilks> ... ILK_ID |-> Ilk ( ... line: (_ => LINE) ) ... </vat-ilks>
      requires LINE >=Rad rad(0)

    rule <k> Vat . file dust ILK_ID DUST => . ... </k>
         <vat-live> true </vat-live>
         <vat-ilks> ... ILK_ID |-> Ilk ( ... dust: (_ => DUST) ) ... </vat-ilks>
      requires DUST >=Rad rad(0)
```

Vat Initialization
------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `initIlk`: Create a new `VatIlk` which starts with `rate == 1` and all other fields `0`.
-   `initUser`: Creates `can`, `dai`, and `sin` accounts for a given user in the vat.
-   `initGem`: Create a new gem of a given ilk for a given address.
-   `initCDP`: Create an empty CDP of a given ilk for a given user.

```k
    syntax VatAuthStep ::= "initUser" Address
                         | "initGem" String Address
                         | "initCDP" String Address
 // -----------------------------------------------
    rule <k> Vat . initUser ADDR => . ... </k>
         <vat-dai> DAI => DAI [ ADDR <- rad(0) ] </vat-dai>
         <vat-sin> SIN => SIN [ ADDR <- rad(0) ] </vat-sin>
      requires notBool ADDR in_keys(DAI)
       andBool notBool ADDR in_keys(SIN)

    rule <k> Vat . initGem ILK_ID ADDR => . ... </k>
         <vat-gem> GEMS => GEMS [ { ILK_ID , ADDR } <- wad(0) ] </vat-gem>
      requires notBool { ILK_ID , ADDR } in_keys(GEMS)

    rule <k> Vat . initCDP ILK_ID ADDR => . ... </k>
         <vat-urns> URNS => URNS [ { ILK_ID , ADDR } <- Urn( ... ink: wad(0) , art: wad(0) ) ] </vat-urns>
      requires notBool { ILK_ID , ADDR } in_keys(URNS)
```

Vat Semantics
-------------

### Deactivation

-   `Vat.cage` disables access to this instance of MCD.

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
    syntax Bool ::= wish(Address, Address, Map) [function, functional]
 // ------------------------------------------------------------------
    rule [wish.same]  : wish(ADDRFROM, MSGSENDER,        _) => true                                   requires ADDRFROM  ==K MSGSENDER
    rule [wish.check] : wish(ADDRFROM, MSGSENDER, CANADDRS) => MSGSENDER in {CANADDRS[ADDRFROM]}:>Set requires ADDRFROM =/=K MSGSENDER andBool ADDRFROM in_keys(CANADDRS)
    rule [wish.nope]  : wish(       _,         _,        _) => false                                  [owise]

    syntax VatStep ::= "hope" Address | "nope" Address
 // --------------------------------------------------
    rule <k> Vat . hope ADDRTO => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> ... MSGSENDER |-> (CANADDRS => CANADDRS SetItem(ADDRTO)) ... </vat-can>

    rule <k> Vat . nope ADDRTO => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> ... MSGSENDER |-> (CANADDRS => CANADDRS -Set SetItem(ADDRTO)) ... </vat-can>

    rule <k> Vat . hope _ADDRTO ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS => VAT_CANS [ MSGSENDER <- .Set ] </vat-can>
      requires notBool MSGSENDER in_keys(VAT_CANS)

    rule <k> Vat . nope _ADDRTO => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS </vat-can>
      requires notBool MSGSENDER in_keys(VAT_CANS)
```

-   `Vat.safe` checks that a given `Urn` of a certain `ilk` is not over-leveraged.
-   `Vat.nondusty` checks that a given `Urn` has the minumum deposit (is effectively non-zero).

```k
    syntax VatStep ::= "safe" String Address
 // ----------------------------------------
    rule <k> Vat . safe ILK_ID ADDR => . ... </k>
         <vat-ilks> ...   ILK_ID          |-> ILK ... </vat-ilks>
         <vat-urns> ... { ILK_ID , ADDR } |-> URN ... </vat-urns>
      requires rad(0) <=Rad urnBalance(ILK, URN)
       andBool urnDebt(ILK, URN) <=Rad line(ILK)

    syntax VatStep ::= "nondusty" String Address
 // --------------------------------------------
    rule <k> Vat . nondusty ILK_ID ADDR => . ... </k>
         <vat-ilks> ...   ILK_ID          |-> ILK ... </vat-ilks>
         <vat-urns> ... { ILK_ID , ADDR } |-> URN ... </vat-urns>
      requires dust(ILK) <=Rad urnDebt(ILK, URN) orBool rad(0) ==Rad urnDebt(ILK, URN)
```

### Ilk Initialization (`<vat-ilks>`)

-   `Vat.init` creates a new `ilk` collateral type, failing if the given `ilk` already exists.

```k
    syntax VatAuthStep ::= "init" String
 // ------------------------------------
    rule <k> Vat . init ILK_ID => . ... </k>
         <vat-ilks> ... ILK_ID |-> Ilk(... rate: ray(0) => ray(1)) ... </vat-ilks>

    rule <k> Vat . init ILK_ID ... </k>
         <vat-ilks> VAT_ILKS => VAT_ILKS [ ILK_ID <- Ilk (... Art: wad(0) , rate: ray(0) , spot: ray(0) , line: rad(0) , dust: rad(0) ) ] </vat-ilks>
      requires notBool ILK_ID in_keys(VAT_ILKS)
```

### Collateral manipulation (`<vat-gem>`)

-   `Vat.slip` adds to a users `<vat-gem>` collateral balance.
-   `Vat.flux` transfers `<vat-gem>` collateral between users.

    **NOTE**: We assume that the given `ilk` for that user has already been initialized.

    **TODO**: Should `Vat.slip` use `Vat.consent` or `Vat.wish`?
    **TODO**: Should `Vat.flux` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatAuthStep ::= "slip" String Address Wad
 // ------------------------------------------------
    rule <k> Vat . slip ILK_ID ADDRTO NEWCOL => . ... </k>
         <vat-gem> ... { ILK_ID , ADDRTO } |-> ( COL => COL +Wad NEWCOL ) ... </vat-gem>
      requires NEWCOL >=Wad wad(0)

    syntax VatStep ::= "flux" String Address Address Wad
 // ----------------------------------------------------
    rule <k> Vat . flux ILK_ID:String ADDRFROM:Address ADDRTO:Address COL:Wad => . ... </k>
         <msg-sender> MSGSENDER:Address </msg-sender>
         <vat-can> VAT_CANS:Map </vat-can>
         <vat-gem>
           ...
           { ILK_ID , ADDRFROM } |-> ( COLFROM => COLFROM -Wad COL )
           { ILK_ID , ADDRTO   } |-> ( COLTO   => COLTO   +Wad COL )
           ...
         </vat-gem>
      requires COL     >=Wad wad(0)
       andBool COLFROM >=Wad COL
       andBool wish(ADDRFROM, MSGSENDER, VAT_CANS)

    rule <k> Vat . flux ILK_ID ADDRFROM ADDRFROM COL => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS </vat-can>
         <vat-gem> ... { ILK_ID , ADDRFROM } |-> COLFROM ... </vat-gem>
      requires COL     >=Wad wad(0)
       andBool COLFROM >=Wad COL
       andBool wish(ADDRFROM, MSGSENDER, VAT_CANS)
```

-   `Vat.move` transfers Dai between users.

    **TODO**: Should `Vat.move` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatStep ::= "move" Address Address Rad
 // ---------------------------------------------
    rule <k> Vat . move ADDRFROM:Address ADDRTO:Address DAI:Rad => . ... </k>
         <msg-sender> MSGSENDER:Address </msg-sender>
         <vat-can> VAT_CANS:Map </vat-can>
         <vat-dai>
           ...
           ADDRFROM |-> (DAIFROM => DAIFROM -Rad DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Rad DAI)
           ...
         </vat-dai>
      requires DAI     >=Rad rad(0)
       andBool DAIFROM >=Rad DAI
       andBool wish(ADDRFROM, MSGSENDER, VAT_CANS)

    rule <k> Vat . move ADDRFROM ADDRFROM DAI => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS </vat-can>
         <vat-dai> ... ADDRFROM |-> DAIFROM ... </vat-dai>
      requires DAI     >=Rad rad(0)
       andBool DAIFROM >=Rad DAI
       andBool wish(ADDRFROM, MSGSENDER, VAT_CANS)
```

### CDP Manipulation

-   `Vat.fork` splits a given CDP up.

    **TODO**: Factor out `TABFROM == RATE *Int (ARTFROM -Int DART)` and `TABTO == RAT *Int (ARTTO +Int DART)` for requires.
    **TODO**: Should have `safe`, non-`dusty`.
    **TODO**: Should `Vat.fork` use `Vat.consent` or `Vat.wish`?

```k
    syntax VatStep ::= "fork" String Address Address Wad Wad
 // --------------------------------------------------------
    rule <k> Vat . fork ILK_ID ADDRFROM ADDRTO DINK DART
          => Vat . safe     ILK_ID ADDRFROM ~> Vat . safe     ILK_ID ADDRTO
          ~> Vat . nondusty ILK_ID ADDRFROM ~> Vat . nondusty ILK_ID ADDRTO
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS </vat-can>
         <vat-urns>
           ...
           { ILK_ID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Wad DINK , ARTFROM => ARTFROM -Wad DART )
           { ILK_ID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Wad DINK , ARTTO   => ARTTO   +Wad DART )
           ...
         </vat-urns>
      requires INKFROM >=Wad DINK
       andBool ARTFROM >=Wad DART
       andBool wish(ADDRFROM, MSGSENDER, VAT_CANS)
       andBool wish(ADDRTO,   MSGSENDER, VAT_CANS)

    rule <k> Vat . fork ILK_ID ADDRFROM ADDRFROM DINK DART
          => Vat . safe     ILK_ID ADDRFROM ~> Vat . safe     ILK_ID ADDRFROM
          ~> Vat . nondusty ILK_ID ADDRFROM ~> Vat . nondusty ILK_ID ADDRFROM
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS </vat-can>
         <vat-urns> ... { ILK_ID , ADDRFROM } |-> Urn ( INKFROM , ARTFROM ) ... </vat-urns>
      requires INKFROM >=Wad DINK
       andBool ARTFROM >=Wad DART
       andBool wish(ADDRFROM, MSGSENDER, VAT_CANS)
```

-   `Vat.grab` uses collateral from user `V` to burn `<vat-sin>` for user `W` via one of `U`s CDPs.
-   `Vat.frob` uses collateral from user `V` to mint `<vat-dai>` for user `W` via one of `U`s CDPs.

**TODO**: Factor out common step of "uses collateral from user `V` via one of `U`s CDPs"?
**TODO**: Double-check implemented checks for `Vat.frob`.

```k
    syntax VatAuthStep ::= "grab" String Address Address Address Wad Wad
 // --------------------------------------------------------------------
    rule <k> Vat . grab ILK_ID:String ADDRU:Address ADDRV:Address ADDRW:Address DINK:Wad DART:Wad => . ... </k>
         <vat-vice> VICE:Rad => VICE -Rad (DART *Rate RATE) </vat-vice>
         <vat-urns> ... { ILK_ID , ADDRU } |-> Urn ( INK => INK +Wad DINK , URNART => URNART +Wad DART ) ... </vat-urns>
         <vat-ilks> ... ILK_ID |-> Ilk ( ILKART => ILKART +Wad DART , RATE , _ , _ , _ ) ... </vat-ilks>
         <vat-gem> ... { ILK_ID , ADDRV } |-> ( ILKV => ILKV -Wad DINK ) ... </vat-gem>
         <vat-sin> ... ADDRW |-> ( SINW => SINW -Rad (DART *Rate RATE) ) ... </vat-sin>
      requires ILKV >=Wad DINK
       andBool SINW >=Rad (DART *Rate RATE)
       andBool VICE >=Rad (DART *Rate RATE)

    syntax VatStep ::= "frob" String Address Address Address Wad Wad
 // ----------------------------------------------------------------
    rule <k> Vat . frob ILK_ID:String ADDRU:Address ADDRV:Address ADDRW:Address DINK:Wad DART:Wad => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <vat-can> VAT_CANS </vat-can>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Rad (DART *Rate RATE) </vat-debt>
         <vat-urns> ... { ILK_ID , ADDRU } |-> Urn ( INK => INK +Wad DINK , URNART => URNART +Wad DART ) ... </vat-urns>
         <vat-ilks> ... ILK_ID |-> Ilk (... Art: ILKART => ILKART +Wad DART , rate: RATE , spot: SPOT, line: ILKLINE, dust: DUST ) ... </vat-ilks>
         <vat-gem> ... { ILK_ID , ADDRV } |-> ( ILKV => ILKV -Wad DINK ) ... </vat-gem>
         <vat-dai> ... ADDRW |-> ( DAIW => DAIW +Rad (DART *Rate RATE) ) ... </vat-dai>
         <vat-Line> LINE </vat-Line>
      requires ILKV >=Wad DINK
       andBool ( DART <=Wad wad(0)
               orBool ((ILKART +Wad DART) *Rate RATE <=Rad ILKLINE andBool DEBT +Rad (DART *Rate RATE) <=Rad LINE)
                    )
       andBool      ( (DART <=Wad wad(0) andBool DINK >=Wad wad(0))
               orBool (URNART +Wad DART) *Rate RATE <=Rad (INK +Wad DINK) *Rate SPOT
                    )
       andBool      ( (DART <=Wad wad(0) andBool DINK >=Wad wad(0))
               orBool wish(ADDRU, MSGSENDER, VAT_CANS)
                    )
       andBool (DINK <=Wad wad(0) orBool wish(ADDRV, MSGSENDER, VAT_CANS))
       andBool (DART >=Wad wad(0) orBool wish(ADDRW, MSGSENDER, VAT_CANS))
       andBool (URNART +Wad DART ==Wad wad(0) orBool (URNART +Wad DART) *Rate RATE >=Rad DUST)
```

### Debt/Dai manipulation (`<vat-debt>`, `<vat-dai>`, `<vat-vice>`, `<vat-sin>`)

-   `Vat.heal` cancels a users anticoins `<vat-sin>` using their `<vat-dai>`.
-   `Vat.suck` mints `<vat-dai>` for user `V` via anticoins `<vat-sin>` for user `U`.

```k
    syntax VatStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vat . heal AMOUNT:Rad => . ... </k>
         <msg-sender> ADDRFROM:Address </msg-sender>
         <vat-debt> DEBT:Rad => DEBT -Rad AMOUNT </vat-debt>
         <vat-vice> VICE:Rad => VICE -Rad AMOUNT </vat-vice>
         <vat-sin> ... ADDRFROM |-> (SIN => SIN -Rad AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRFROM |-> (DAI => DAI -Rad AMOUNT) ... </vat-dai>
      requires AMOUNT >=Rad rad(0)
       andBool DEBT >=Rad AMOUNT
       andBool VICE >=Rad AMOUNT
       andBool SIN  >=Rad AMOUNT
       andBool DAI  >=Rad AMOUNT

    syntax VatAuthStep ::= "suck" Address Address Rad
 // -------------------------------------------------
    rule <k> Vat . suck ADDRU:Address ADDRV:Address AMOUNT:Rad => . ... </k>
         <vat-debt> DEBT => DEBT +Rad AMOUNT </vat-debt>
         <vat-vice> VICE => VICE +Rad AMOUNT </vat-vice>
         <vat-sin> ... ADDRU |-> (SIN => SIN +Rad AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRV |-> (DAI => DAI +Rad AMOUNT) ... </vat-dai>
      requires AMOUNT >=Rad rad(0)
```

### CDP Manipulation

-   `Vat.fold` modifies the debt multiplier for a given ilk having user `U` absort the difference in `<vat-dai>`.

```k
    syntax VatAuthStep ::= "fold" String Address Ray
 // ------------------------------------------------
    rule <k> Vat . fold ILK_ID ADDRU RATE => . ... </k>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Rad (ILKART *Rate RATE) </vat-debt>
         <vat-ilks> ... ILK_ID |-> Ilk ( ILKART , ILKRATE => ILKRATE +Ray RATE , _ , _ , _ ) ... </vat-ilks>
         <vat-dai> ... ADDRU |-> ( DAI => DAI +Rad (ILKART *Rate RATE) ) ... </vat-dai>
```

```k
endmodule
```
