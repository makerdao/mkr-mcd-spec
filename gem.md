```k
requires "kmcd-driver.k"

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
 // ------------------------------------------------------------
    rule contract(Gem GEMID . _) => Gem GEMID
```

Gem Initialization
------------------

Because data isn't explicitely initialized to 0 in KMCD, we need explicit initializers for various pieces of data.

-   `init`: Creates the blank contract data for a new gem of a given ilk.
-   `initUser`: Creates a new account for a given user in a given ilk.

```k
    syntax GemStep ::= GemAuthStep
    syntax GemAuthStep ::= "init"
                         | "initUser" Address
 // -----------------------------------------
    rule <k> Gem GEMID . init => . ... </k>
         <gems> ... ( .Bag => <gem> <gem-id> GEMID </gem-id> ... </gem> ) ... </gems>

    rule <k> Gem GEMID . initUser ADDR => . ... </k>
         <gem>
            <gem-id> GEMID </gem-id>
            <gem-balances> BALS => BALS [ ADDR <- 0 ] </gem-balances>
            ...
         </gem>
      requires notBool ADDR in_keys(BALS)
```

Gem Semantics
-------------

```k
    syntax GemStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------
    rule <k> Gem GEMID . transferFrom ACCTSRC ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>
             ...
             ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Rat VALUE )
             ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Rat VALUE )
             ...
           </gem-balances>
           ...
         </gem>
      requires VALUE >=Rat 0
       andBool ACCTSRC =/=K ACCTDST
       andBool VALUE >=Rat 0
       andBool BALANCE_SRC >=Rat VALUE

    rule <k> Gem GEMID . transferFrom ACCTSRC ACCTSRC VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances> ... ACCTSRC |-> BALANCE_SRC ... </gem-balances>
           ...
         </gem>
      requires VALUE >=Rat 0
       andBool BALANCE_SRC >=Rat VALUE

    syntax GemStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Gem _ . (move ACCTSRC ACCTDST VALUE => transferFrom ACCTSRC ACCTDST VALUE) ... </k>
      requires VALUE >=Rat 0

    syntax GemStep ::= "push" Address Wad
 // -------------------------------------
    rule <k> Gem _ . (push ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires VALUE >=Rat 0

    syntax GemStep ::= "pull" Address Wad
 // -------------------------------------
    rule <k> Gem _ . (pull ACCTSRC VALUE => transferFrom ACCTSRC MSGSENDER VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires VALUE >=Rat 0

    syntax GemStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Gem _ . (transfer ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>
      requires VALUE >=Rat 0

    syntax GemStep ::= "mint" Address Wad
 // -------------------------------------
    rule <k> Gem GEMID . mint ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances> ... ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Rat VALUE ) ... </gem-balances>
           ...
         </gem>
      requires VALUE >=Rat 0

    syntax GemStep ::= "burn" Address Wad
 // -------------------------------------
    rule <k> Gem GEMID . burn ACCTSRC VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances> ... ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Rat VALUE ) ... </gem-balances>
           ...
         </gem>
      requires VALUE >=Rat 0
       andBool BALANCE_SRC >=Rat VALUE
```

```k
endmodule
```
