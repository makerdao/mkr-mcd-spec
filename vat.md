```k
requires "kmcd-driver.md"
requires "abi.md"
requires "edsl.md"
requires "lemmas/infinite-gas.k"
requires "lemmas/mcd/bin_runtime.k"
requires "lemmas/mcd/verification.k"

module VAT
    imports KMCD-DRIVER
    imports DSS-BIN-RUNTIME
    imports EDSL
    imports INFINITE-GAS
    imports LEMMAS-MCD
```

Vat Configuration
-----------------

```k
    configuration
    <main-vat>
      <kmcd-driver/>
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
    </main-vat>
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

### Vat Serialization/Deserialization

```k
    syntax MCDStorage ::= #storageVat(VatCell)

 // -------------------------------------------------------------
    rule <k> #serializeContract ( Vat ) => . ... </k>
        <vat> VAT_CONFIG </vat>
        <account>
          <acctID> 1000 </acctID>
          <storage> _ => #storageVat(<vat> VAT_CONFIG </vat>) </storage>
          ...
        </account>

    syntax VatIlk ::= #lookupIlks (Map, Int) [function, functional]
    syntax VatIlk ::= "EmptyIlk"
// ----------------------------------------------------------------

    rule  #lookupIlks( (KEY |-> ILK:VatIlk ) _M, KEY ) => ILK
    rule  #lookupIlks(                        M, KEY ) => EmptyIlk
    requires notBool KEY in_keys(M)
    rule  #lookupIlks( (KEY |-> VAL        ) _M, KEY ) => EmptyIlk
    requires notBool isVatIlk(VAL)

    syntax VatUrn ::= #lookupUrns (Map, Int) [function, functional]
    syntax VatUrn ::= "EmptyUrn"
// ----------------------------------------------------------------

    rule  #lookupUrns( (KEY |-> URN:VatUrn ) _M, KEY ) => URN
    rule  #lookupUrns(                        M, KEY ) => EmptyUrn
    requires notBool KEY in_keys(M)
    rule  #lookupUrns( (KEY |-> VAL        ) _M, KEY ) => EmptyUrn
    requires notBool isVatUrn(VAL)


    syntax Int ::= #lookupIlk (VatIlk, Int) [function, functional]
                 | #lookupUrn (VatUrn, Int) [function, functional]
 // -------------------------------------------------------------

    rule #lookupIlk(Ilk(... Art:  ART ) , 0) => value(ART)
    rule #lookupIlk(Ilk(... rate: RATE) , 1) => value(RATE)
    rule #lookupIlk(Ilk(... spot: SPOT) , 2) => value(SPOT)
    rule #lookupIlk(Ilk(... line: LINE) , 3) => value(LINE)
    rule #lookupIlk(Ilk(... dust: DUST) , 4) => value(DUST)
    rule #lookupIlk(EmptyIlk, _) => 0

    rule #lookupUrn(Urn(... ink: INK), 0) => value(INK)
    rule #lookupUrn(Urn(... art: ART), 1) => value(ART)
    rule #lookupUrn(EmptyUrn, _) => 0


    rule <k> #deserializeContract ( Vat ) => . ... </k>
        <vat> _ => VAT_CONFIG </vat>
        <account>
            <acctID> 1000 </acctID>
            <storage> #storageVat(<vat> VAT_CONFIG </vat>) </storage>
            ...
        </account>


```

### Constructor

```
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

```
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

```
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

```
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

```
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

```
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

```
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

```
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

```
    syntax VatAuthStep ::= "slip" String Address Wad
 // ------------------------------------------------
    rule <k> Vat . slip ILK_ID ADDRTO NEWCOL => . ... </k>
         <vat-gem> ... { ILK_ID , ADDRTO } |-> ( COL => COL +Wad NEWCOL ) ... </vat-gem>
      requires NEWCOL >=Wad wad(0)

    syntax VatStep ::= "flux" String Address Address Wad
 // ----------------------------------------------------
    rule <k> Vat . flux ILK_ID ADDRFROM ADDRTO COL => . ... </k>
         <vat-gem>
           ...
           { ILK_ID , ADDRFROM } |-> ( COLFROM => COLFROM -Wad COL )
           { ILK_ID , ADDRTO   } |-> ( COLTO   => COLTO   +Wad COL )
           ...
         </vat-gem>
      requires COL     >=Wad wad(0)
       andBool COLFROM >=Wad COL
       andBool wish ADDRFROM

    rule <k> Vat . flux ILK_ID ADDRFROM ADDRFROM COL => . ... </k>
         <vat-gem> ... { ILK_ID , ADDRFROM } |-> COLFROM ... </vat-gem>
      requires COL     >=Wad wad(0)
       andBool COLFROM >=Wad COL
       andBool wish ADDRFROM
```

-   `Vat.move` transfers Dai between users.

    **TODO**: Should `Vat.move` use `Vat.consent` or `Vat.wish`?

```
    syntax VatStep ::= "move" Address Address Rad
 // ---------------------------------------------
    rule <k> Vat . move ADDRFROM ADDRTO DAI => . ... </k>
         <vat-dai>
           ...
           ADDRFROM |-> (DAIFROM => DAIFROM -Rad DAI)
           ADDRTO   |-> (DAITO   => DAITO   +Rad DAI)
           ...
         </vat-dai>
      requires DAI     >=Rad rad(0)
       andBool DAIFROM >=Rad DAI
       andBool wish ADDRFROM

    rule <k> Vat . move ADDRFROM ADDRFROM DAI => . ... </k>
         <vat-dai> ... ADDRFROM |-> DAIFROM ... </vat-dai>
      requires DAI     >=Rad rad(0)
       andBool DAIFROM >=Rad DAI
       andBool wish ADDRFROM
```

### CDP Manipulation

-   `Vat.fork` splits a given CDP up.

    **TODO**: Factor out `TABFROM == RATE *Int (ARTFROM -Int DART)` and `TABTO == RAT *Int (ARTTO +Int DART)` for requires.
    **TODO**: Should have `safe`, non-`dusty`.
    **TODO**: Should `Vat.fork` use `Vat.consent` or `Vat.wish`?

```
    syntax VatStep ::= "fork" String Address Address Wad Wad
 // --------------------------------------------------------
    rule <k> Vat . fork ILK_ID ADDRFROM ADDRTO DINK DART
          => Vat . safe     ILK_ID ADDRFROM ~> Vat . safe     ILK_ID ADDRTO
          ~> Vat . nondusty ILK_ID ADDRFROM ~> Vat . nondusty ILK_ID ADDRTO
         ...
         </k>
         <vat-urns>
           ...
           { ILK_ID , ADDRFROM } |-> Urn ( INKFROM => INKFROM -Wad DINK , ARTFROM => ARTFROM -Wad DART )
           { ILK_ID , ADDRTO   } |-> Urn ( INKTO   => INKTO   +Wad DINK , ARTTO   => ARTTO   +Wad DART )
           ...
         </vat-urns>
      requires INKFROM >=Wad DINK
       andBool ARTFROM >=Wad DART
       andBool wish ADDRFROM
       andBool wish ADDRTO

    rule <k> Vat . fork ILK_ID ADDRFROM ADDRFROM DINK DART
          => Vat . safe     ILK_ID ADDRFROM ~> Vat . safe     ILK_ID ADDRFROM
          ~> Vat . nondusty ILK_ID ADDRFROM ~> Vat . nondusty ILK_ID ADDRFROM
         ...
         </k>
         <vat-urns> ... { ILK_ID , ADDRFROM } |-> Urn ( INKFROM , ARTFROM ) ... </vat-urns>
      requires INKFROM >=Wad DINK
       andBool ARTFROM >=Wad DART
       andBool wish ADDRFROM
```

-   `Vat.grab` uses collateral from user `V` to burn `<vat-sin>` for user `W` via one of `U`s CDPs.
-   `Vat.frob` uses collateral from user `V` to mint `<vat-dai>` for user `W` via one of `U`s CDPs.

**TODO**: Factor out common step of "uses collateral from user `V` via one of `U`s CDPs"?
**TODO**: Double-check implemented checks for `Vat.frob`.

```
    syntax VatAuthStep ::= "grab" String Address Address Address Wad Wad
 // --------------------------------------------------------------------
    rule <k> Vat . grab ILK_ID ADDRU ADDRV ADDRW DINK DART => . ... </k>
         <vat-vice> VICE => VICE -Rad (DART *Rate RATE) </vat-vice>
         <vat-urns> ... { ILK_ID , ADDRU } |-> Urn ( INK => INK +Wad DINK , URNART => URNART +Wad DART ) ... </vat-urns>
         <vat-ilks> ... ILK_ID |-> Ilk ( ILKART => ILKART +Wad DART , RATE , _ , _ , _ ) ... </vat-ilks>
         <vat-gem> ... { ILK_ID , ADDRV } |-> ( ILKV => ILKV -Wad DINK ) ... </vat-gem>
         <vat-sin> ... ADDRW |-> ( SINW => SINW -Rad (DART *Rate RATE) ) ... </vat-sin>
      requires ILKV >=Wad DINK
       andBool SINW >=Rad (DART *Rate RATE)
       andBool VICE >=Rad (DART *Rate RATE)

    syntax VatStep ::= "frob" String Address Address Address Wad Wad
 // ----------------------------------------------------------------
    rule <k> Vat . frob ILK_ID ADDRU ADDRV ADDRW DINK DART => . ... </k>
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
               orBool wish ADDRU
                    )
       andBool (DINK <=Wad wad(0) orBool wish ADDRV)
       andBool (DART >=Wad wad(0) orBool wish ADDRW)
       andBool (URNART +Wad DART ==Wad wad(0) orBool (URNART +Wad DART) *Rate RATE >=Rad DUST)
```

### Debt/Dai manipulation (`<vat-debt>`, `<vat-dai>`, `<vat-vice>`, `<vat-sin>`)

-   `Vat.heal` cancels a users anticoins `<vat-sin>` using their `<vat-dai>`.
-   `Vat.suck` mints `<vat-dai>` for user `V` via anticoins `<vat-sin>` for user `U`.

```
    syntax VatStep ::= "heal" Rad
 // -----------------------------
    rule <k> Vat . heal AMOUNT => . ... </k>
         <msg-sender> ADDRFROM </msg-sender>
         <vat-debt> DEBT => DEBT -Rad AMOUNT </vat-debt>
         <vat-vice> VICE => VICE -Rad AMOUNT </vat-vice>
         <vat-sin> ... ADDRFROM |-> (SIN => SIN -Rad AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRFROM |-> (DAI => DAI -Rad AMOUNT) ... </vat-dai>
      requires AMOUNT >=Rad rad(0)
       andBool DEBT >=Rad AMOUNT
       andBool VICE >=Rad AMOUNT
       andBool SIN  >=Rad AMOUNT
       andBool DAI  >=Rad AMOUNT

    syntax VatAuthStep ::= "suck" Address Address Rad
 // -------------------------------------------------
    rule <k> Vat . suck ADDRU ADDRV AMOUNT => . ... </k>
         <vat-debt> DEBT => DEBT +Rad AMOUNT </vat-debt>
         <vat-vice> VICE => VICE +Rad AMOUNT </vat-vice>
         <vat-sin> ... ADDRU |-> (SIN => SIN +Rad AMOUNT) ... </vat-sin>
         <vat-dai> ... ADDRV |-> (DAI => DAI +Rad AMOUNT) ... </vat-dai>
      requires AMOUNT >=Rad rad(0)
```

### CDP Manipulation

-   `Vat.fold` modifies the debt multiplier for a given ilk having user `U` absort the difference in `<vat-dai>`.

```
    syntax VatAuthStep ::= "fold" String Address Ray
 // ------------------------------------------------
    rule <k> Vat . fold ILK_ID ADDRU RATE => . ... </k>
         <vat-live> true </vat-live>
         <vat-debt> DEBT => DEBT +Rad (ILKART *Rate RATE) </vat-debt>
         <vat-ilks> ... ILK_ID |-> Ilk ( ILKART , ILKRATE => ILKRATE +Ray RATE , _ , _ , _ ) ... </vat-ilks>
         <vat-dai> ... ADDRU |-> ( DAI => DAI +Rad (ILKART *Rate RATE) ) ... </vat-dai>
```

```k
    syntax KItem ::= "#runProof"

    rule <k> #runProof => #execute ... </k>

```

```k
endmodule
```

```k
module VAT-LEMMAS
    imports VAT

    rule #lookup(#storageVat(<vat> ... <vat-wards> VAT_WARDS </vat-wards> ... </vat>),  #hashedLocation("Solidity", 0, A) ) => #lookupWards(VAT_WARDS, A) [simplification]

    rule #write(#storageVat(<vat> ... <vat-wards> VAT_WARDS </vat-wards> ... </vat>),  #hashedLocation("Solidity", 0, A) , 1) => #storageVat(<vat> ... <vat-wards> VAT_WARDS |Set SetItem(A) </vat-wards> ... </vat>) [simplification]

    rule #write(#storageVat(<vat> ... <vat-wards> VAT_WARDS </vat-wards> ... </vat>),  #hashedLocation("Solidity", 0, A) , 0) => #storageVat(<vat> ... <vat-wards> VAT_WARDS -Set SetItem(A) </vat-wards> ... </vat>) [simplification]

    //rule #lookup(#storageVat(<vat> ... <vat-can> VAT_CAN </vat-can> ... </vat>), #Vat.can//[ACCT_ID][ACCT_PERMIT]) => #lookup(#lookupMap(VAT_CAN, ACCT_ID), ACCT_PERMIT)//[simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-ilks> VAT_ILKS </vat-ilks> ... </vat>), #Vat.ilks//[ILK].Art  ) => #lookupIlk(#lookupIlks(VAT_ILKS, ILK), 0) [simplification]
    //rule #lookup(#storageVat(<vat> ... <vat-ilks> VAT_ILKS </vat-ilks> ... </vat>), #Vat.ilks//[ILK].rate ) => #lookupIlk(#lookupIlks(VAT_ILKS, ILK), 1) [simplification]
    //rule #lookup(#storageVat(<vat> ... <vat-ilks> VAT_ILKS </vat-ilks> ... </vat>), #Vat.ilks//[ILK].spot ) => #lookupIlk(#lookupIlks(VAT_ILKS, ILK), 2) [simplification]
    //rule #lookup(#storageVat(<vat> ... <vat-ilks> VAT_ILKS </vat-ilks> ... </vat>), #Vat.ilks//[ILK].line ) => #lookupIlk(#lookupIlks(VAT_ILKS, ILK), 3) [simplification]
    //rule #lookup(#storageVat(<vat> ... <vat-ilks> VAT_ILKS </vat-ilks> ... </vat>), #Vat.ilks//[ILK].dust ) => #lookupIlk(#lookupIlks(VAT_ILKS, ILK), 4) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-urns> VAT_URNS </vat-urns> ... </vat>), #Vat.urns//[ILK][USR].ink ) => #lookupUrn(#lookupUrns(#lookupMap(VAT_URNS, ILK), USR), 0) //[simplification]
    //rule #lookup(#storageVat(<vat> ... <vat-urns> VAT_URNS </vat-urns> ... </vat>), #Vat.urns//[ILK][USR].art ) => #lookupUrn(#lookupUrns(#lookupMap(VAT_URNS, ILK), USR), 1) //[simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-gem> VAT_GEM </vat-gem> ... </vat>), #Vat.gem[ILK]//[USR]) => #lookup(#lookupMap(VAT_GEM, ILK), USR) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-dai> VAT_DAI </vat-dai> ... </vat>), #Vat.dai//[ACCT_ID]) => #lookup(VAT_DAI, ACCT_ID) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-sin> VAT_SIN </vat-sin> ... </vat>), #Vat.sin//[ACCT_ID]) => #lookup(VAT_SIN, ACCT_ID) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-debt> DEBT </vat-debt> ... </vat>), #Vat.debt) => //value(DEBT) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-vice> VICE </vat-vice> ... </vat>), #Vat.vice) => //value(VICE) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-Line> LINE </vat-Line> ... </vat>), #Vat.Line) => //value(LINE) [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-live> LIVE </vat-live> ... </vat>), #Vat.live) => //0
    //requires LIVE ==Bool false [simplification]
//
    //rule #lookup(#storageVat(<vat> ... <vat-live> LIVE </vat-live> ... </vat>), #Vat.live) => //1
    //requires LIVE ==Bool true [simplification]
//
endmodule
```

```k
module VAT-SPEC
    imports VAT-LEMMAS

    claim <k> #execute => #halt ... </k>
    <callState>
        <program> Vat_bin_runtime </program>
        <jumpDests> #computeValidJumpDests(Vat_bin_runtime) </jumpDests>
        <id> 1000 </id>
        <caller> 1 </caller>
        <callData> #abiCallData("rely", #uint256(1)) </callData>
        <gas> #gas(0) => ?_ </gas>
        <callGas> #gas(0) => ?_ </callGas>
        ...
    </callState>
    <activeAccounts> ... SetItem(1) SetItem(1000) ... </activeAccounts>
    <accounts>
        ...
        <account>
            <acctID> 1000 </acctID>
            <code> Vat_bin_runtime </code>
            <storage> #storageVat(<vat> <vat-wards> VAT_WARDS => VAT_WARDS |Set SetItem(1) </vat-wards> ... </vat>) </storage>
            ...
        </account>
        <account>
            <acctID> 1 </acctID>
            ...
        </account>
        ...
    </accounts>


endmodule
```
