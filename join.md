```k
requires "kmcd-driver.md"
requires "dai.md"
requires "gem.md"
requires "vat.md"

module JOIN
    imports KMCD-DRIVER
    imports DAI
    imports GEM
    imports VAT
```

Join Configuration
------------------

```k
    configuration
      <join-state>
        <gem-joins>
          <gem-join multiplicity="*" type="Map">
            <gem-join-gem> "":String </gem-join-gem>
            <gem-join-vat> 0:Address </gem-join-vat>
            <gem-join-gem-addr> 0:Address </gem-join-gem-addr>
            <gem-join-wards> .Set </gem-join-wards>
            <gem-join-live> true </gem-join-live>
          </gem-join>
        </gem-joins>
        <dai-join>
          <dai-join-vat> 0:Address </dai-join-vat>
          <dai-join-gem-addr> 0:Address </dai-join-gem-addr>
          <dai-join-wards> .Set </dai-join-wards>
          <dai-join-live> true </dai-join-live>
        </dai-join>
      </join-state>
```

```k
    syntax MCDContract ::= GemJoinContract
    syntax GemJoinContract ::= "GemJoin" String
    syntax MCDStep ::= GemJoinContract "." GemJoinStep [klabel(gemJoinStep)]
 // ------------------------------------------------------------------------
    rule contract(GemJoin GEMID . _) => GemJoin GEMID

    syntax MCDContract ::= DaiJoinContract
    syntax DaiJoinContract ::= "DaiJoin"
    syntax MCDStep ::= DaiJoinContract "." DaiJoinStep [klabel(daiJoinStep)]
 // ------------------------------------------------------------------------
    rule contract(DaiJoin . _) => DaiJoin
```

Join Authorization
------------------

```k
    syntax GemJoinStep ::= GemJoinAuthStep
    syntax AuthStep    ::= GemJoinContract "." GemJoinAuthStep [klabel(gemJoinStep)]
 // --------------------------------------------------------------------------------
    rule [[ wards(GemJoin GEMID) => WARDS ]] <gem-join> <gem-join-gem> GEMID </gem-join-gem> <gem-join-wards> WARDS </gem-join-wards> ... </gem-join>

    syntax GemJoinAuthStep ::= WardStep
 // -----------------------------------
    rule <k> GemJoin GEMID . rely ADDR => . ... </k>
         <gem-join>
           <gem-join-gem> GEMID </gem-join-gem>
           <gem-join-wards> ... (.Set => SetItem(ADDR)) </gem-join-wards>
           ...
         </gem-join>

    rule <k> GemJoin GEMID . deny ADDR => . ... </k>
         <gem-join>
           <gem-join-gem> GEMID </gem-join-gem>
           <gem-join-wards> WARDS => WARDS -Set SetItem(ADDR) </gem-join-wards>
           ...
         </gem-join>

    syntax DaiJoinStep ::= DaiJoinAuthStep
    syntax AuthStep    ::= DaiJoinContract "." DaiJoinAuthStep [klabel(daiJoinStep)]
 // --------------------------------------------------------------------------------
    rule [[ wards(DaiJoin) => WARDS ]] <dai-join-wards> WARDS </dai-join-wards>

    syntax DaiJoinAuthStep ::= WardStep
 // -----------------------------------
    rule <k> DaiJoin . rely ADDR => . ... </k>
         <dai-join-wards> ... (.Set => SetItem(ADDR)) </dai-join-wards>

    rule <k> DaiJoin . deny ADDR => . ... </k>
         <dai-join-wards> WARDS => WARDS -Set SetItem(ADDR) </dai-join-wards>
```

Join Initialization
-------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `init`: Creates the joins account in the given gem for users to join their collateral to.

```k
    syntax GemJoinAuthStep ::= "init"
 // ---------------------------------
    rule <k> GemJoin GEMID . init => Gem GEMID . initUser GemJoin GEMID ... </k>
         <gem-joins> ... ( .Bag => <gem-join> <gem-join-gem> GEMID </gem-join-gem> ... </gem-join> ) ... </gem-joins>
```

Join Semantics
--------------

```k
    syntax GemJoinStep ::= "join" Address Wad
 // -----------------------------------------
    rule <k> GemJoin GEMID . join USR AMOUNT
          => call GEM_JOIN_VAT . slip GEMID USR AMOUNT
          ~> call GEM_JOIN_GEM . transferFrom MSGSENDER THIS AMOUNT
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <gem-join>
           <gem-join-gem> GEMID </gem-join-gem>
           <gem-join-vat> GEM_JOIN_VAT:VatContract </gem-join-vat>
           <gem-join-gem-addr> GEM_JOIN_GEM:GemContract </gem-join-gem-addr>
           <gem-join-live> true </gem-join-live>
           ...
         </gem-join>
      requires AMOUNT >=Wad wad(0)

    syntax GemJoinStep ::= "exit" Address Wad
 // -----------------------------------------
    rule <k> GemJoin GEMID . exit USR AMOUNT
          => call GEM_JOIN_VAT . slip GEMID MSGSENDER (wad(0) -Wad AMOUNT)
          ~> call GEM_JOIN_GEM . transfer USR AMOUNT
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <gem-join>
           <gem-join-gem> GEMID </gem-join-gem>
           <gem-join-vat> GEM_JOIN_VAT:VatContract </gem-join-vat>
           <gem-join-gem-addr> GEM_JOIN_GEM:GemContract </gem-join-gem-addr>
           ...
         </gem-join>
      requires AMOUNT >=Wad wad(0)

    syntax DaiJoinStep ::= "join" Address Wad
 // -----------------------------------------
    rule <k> DaiJoin . join USR AMOUNT
          => call DAI_JOIN_VAT . move THIS USR Wad2Rad(AMOUNT)
          ~> call DAI_JOIN_GEM . burn MSGSENDER AMOUNT
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <dai-join-live> true </dai-join-live>
         <dai-join-vat> DAI_JOIN_VAT:VatContract </dai-join-vat>
         <dai-join-gem-addr> DAI_JOIN_GEM:DaiContract </dai-join-gem-addr>
      requires AMOUNT >=Wad wad(0)

    syntax DaiJoinStep ::= "exit" Address Wad
 // -----------------------------------------
    rule <k> DaiJoin . exit USR AMOUNT
          => call DAI_JOIN_VAT . move MSGSENDER THIS Wad2Rad(AMOUNT)
          ~> call DAI_JOIN_GEM . mint USR AMOUNT
         ...
         </k>
         <msg-sender> MSGSENDER </msg-sender>
         <this> THIS </this>
         <dai-join-vat> DAI_JOIN_VAT:VatContract </dai-join-vat>
         <dai-join-gem-addr> DAI_JOIN_GEM:DaiContract </dai-join-gem-addr>
      requires AMOUNT >=Wad wad(0)
```

Join Deactivation
-----------------

-   `GemJoin.cage` disables access to this instance of GemJoin.
-   `DaiJoin.cage` disables access to this instance of DaiJoin.

```k
    syntax GemJoinAuthStep ::= "cage" [klabel(#GemJoinCage), symbol]
 // ----------------------------------------------------------------
    rule <k> GemJoin GEMID . cage => . ... </k>
         <gem-join>
           <gem-join-gem> GEMID </gem-join-gem>
           <gem-join-live> _ => false </gem-join-live>
           ...
         </gem-join>

    syntax DaiJoinAuthStep ::= "cage" [klabel(#DaiJoinCage), symbol]
 // ----------------------------------------------------------------
    rule <k> DaiJoin . cage => . ... </k>
         <dai-join-live> _ => false </dai-join-live>
```

```k
endmodule
```
