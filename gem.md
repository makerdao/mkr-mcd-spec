```k
requires "kmcd-driver.md"

module GEM
    imports KMCD-DRIVER
```

Gem Configuration
-----------------

```k
    configuration
      <gems>
        <gem multiplicity="*" type="Map">
          <gem-id>       "":String </gem-id>
          <gem-wards>    .Set      </gem-wards>
          <gem-balances> .Map      </gem-balances> // mapping (address => uint256) Address |-> Wad
        </gem>
      </gems>
```

```k
    syntax MCDContract ::= GemContract
    syntax GemContract ::= "Gem" String
    syntax MCDStep ::= GemContract "." GemStep [klabel(gemStep)]

    syntax CallStep ::= GemStep
    syntax Op       ::= GemOp
    syntax Args     ::= GemArgs
 // ------------------------------------------------------------
    rule contract(Gem GEMID . _) => Gem GEMID
```

Gem Initialization
------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `init`: Creates the blank contract data for a new gem of a given ilk.
-   `initUser`: Creates a new account for a given user in a given ilk.

```k
    syntax GemInitOp ::= "init"
    syntax GemInitUserOp ::= "initUser"
    syntax GemOp ::= GemInitOp | GemInitUserOp
    syntax GemAddressArgs ::= Address
    syntax GemArgs ::= GemAddressArgs

    syntax GemStep ::= GemAuthStep
    syntax GemAuthStep ::= GemInitOp
                         | GemInitUserOp GemAddressArgs
 // -----------------------------------------
    rule <k> Gem GEMID . init => . ... </k>
         <gems> ... ( .Bag => <gem> <gem-id> GEMID </gem-id> ... </gem> ) ... </gems>

    rule <k> Gem GEMID . initUser ADDR => . ... </k>
         <gem>
            <gem-id> GEMID </gem-id>
            <gem-balances> BALS => BALS [ ADDR <- wad(0) ] </gem-balances>
            ...
         </gem>
      requires notBool ADDR in_keys(BALS)

    rule <k> Gem GEMID . initUser ADDR => . ... </k>
         <gem>
            <gem-id> GEMID </gem-id>
            <gem-balances> ... ADDR |-> _ ... </gem-balances>
            ...
         </gem>

    rule <k> (. => Gem GEMID . init) ~> Gem GEMID . initUser _ ... </k> [owise]
```

Gem Semantics
-------------

```k
    syntax GemTransferFromOp ::= "transferFrom"
    syntax GemOp ::= GemTransferFromOp
    syntax GemFromToAmtArgs ::= Address Address Wad
    syntax GemArgs ::= GemFromToAmtArgs
    syntax GemStep ::= GemTransferFromOp GemFromToAmtArgs
 // -----------------------------------------------------
    rule <k> Gem GEMID . transferFrom ACCTSRC ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>
             ...
             ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Wad VALUE )
             ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Wad VALUE )
             ...
           </gem-balances>
           ...
         </gem>
      requires VALUE >=Wad wad(0)
       andBool ACCTSRC =/=K ACCTDST
       andBool VALUE >=Wad wad(0)
       andBool BALANCE_SRC >=Wad VALUE

    rule <k> Gem GEMID . transferFrom ACCTSRC ACCTSRC VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances> ... ACCTSRC |-> BALANCE_SRC ... </gem-balances>
           ...
         </gem>
      requires VALUE >=Wad wad(0)
       andBool BALANCE_SRC >=Wad VALUE

    syntax GemMoveOp ::= "move"
    syntax GemOp ::= GemMoveOp
    syntax GemStep ::= GemMoveOp GemFromToAmtArgs
 // ---------------------------------------------
    rule <k> Gem _ . (move ACCTSRC ACCTDST VALUE => transferFrom ACCTSRC ACCTDST VALUE) ... </k>
      requires VALUE >=Wad wad(0)

    syntax GemPushOp ::= "push"
    syntax GemOp ::= GemPushOp
    syntax GemUsrAmtArgs ::= Address Wad
    syntax GemArgs ::= GemUsrAmtArgs
    syntax GemStep ::= GemPushOp GemUsrAmtArgs
 // -------------------------------------
    rule <k> Gem _ . (push ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires VALUE >=Wad wad(0)

    syntax GemPullOp ::= "pull"
    syntax GemOp ::= GemPullOp
    syntax GemStep ::= GemPullOp GemUsrAmtArgs
 // -------------------------------------
    rule <k> Gem _ . (pull ACCTSRC VALUE => transferFrom ACCTSRC MSGSENDER VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires VALUE >=Wad wad(0)

    syntax GemTransferOp ::= "transfer"
    syntax GemOp ::= GemTransferOp
    syntax GemStep ::= GemTransferOp GemUsrAmtArgs
 // -----------------------------------------
    rule <k> Gem _ . (transfer ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires VALUE >=Wad wad(0)

    syntax GemMintOp ::= "mint"
    syntax GemOp ::= GemMintOp
    syntax GemStep ::= GemMintOp GemUsrAmtArgs
 // -------------------------------------
    rule <k> Gem GEMID . mint ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances> ... ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Wad VALUE ) ... </gem-balances>
           ...
         </gem>
      requires VALUE >=Wad wad(0)

    syntax GemBurnOp ::= "burn"
    syntax GemOp ::= GemBurnOp
    syntax GemStep ::= GemBurnOp GemUsrAmtArgs
 // -------------------------------------
    rule <k> Gem GEMID . burn ACCTSRC VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances> ... ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Wad VALUE ) ... </gem-balances>
           ...
         </gem>
      requires VALUE >=Wad wad(0)
       andBool BALANCE_SRC >=Wad VALUE
```

```k
endmodule
```
