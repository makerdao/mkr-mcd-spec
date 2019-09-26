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
          <gem-addr>     0:Address </gem-addr>
          <gem-balances> .Map      </gem-balances> // mapping (address => uint256) Address |-> Wad
        </gem>
      </gems>
```

Gem Semantics
-------------

```k
    syntax MCDContract ::= GemContract
    syntax GemContract ::= "Gem" String
    syntax MCDStep ::= GemContract "." GemStep [klabel(gemStep)]
 // ------------------------------------------------------------
    rule contract(Gem GEMID . _) => Gem GEMID
    rule [[ address(Gem GEMID) => ACCTGEM ]] <gem-id> GEMID </gem-id> <gem-addr> ACCTGEM </gem-addr>

    syntax GemAuthStep
    syntax GemStep ::= GemAuthStep
    syntax AuthStep ::= GemContract "." GemAuthStep [klabel(gemStep)]
 // -----------------------------------------------------------------
    rule <k> Gem _ . _ => exception ... </k> [owise]

    syntax GemStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------
    rule <k> Gem GEMID . transferFrom ACCTSRC ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>...
             ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Rat VALUE )
             ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Rat VALUE )
           ...</gem-balances>
         ...
         </gem>
      requires VALUE >=Rat 0
       andBool BALANCE_SRC >=Rat VALUE

    syntax GemStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Gem _ . (move ACCTSRC ACCTDST VALUE => transferFrom ACCTSRC ACCTDST VALUE) ... </k>

    syntax GemStep ::= "push" Address Wad
 // -------------------------------------
    rule <k> Gem _ . (push ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax GemStep ::= "pull" Address Wad
 // -------------------------------------
    rule <k> Gem _ . (pull ACCTSRC VALUE => transferFrom ACCTSRC MSGSENDER VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax GemStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Gem _ . (transfer ACCTDST VALUE => transferFrom MSGSENDER ACCTDST VALUE) ... </k>
         <msg-sender> MSGSENDER </msg-sender>

    syntax GemStep ::= "mint" Address Wad
 // -------------------------------------
    rule <k> Gem GEMID . mint ACCTDST VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>...
             ACCTDST |-> ( BALANCE_DST => BALANCE_DST +Rat VALUE )
           ...</gem-balances>
         ...
         </gem>
      requires VALUE >=Rat 0

    syntax GemStep ::= "burn" Address Wad
 // -------------------------------------
    rule <k> Gem GEMID . burn ACCTSRC VALUE => . ... </k>
         <gem>
           <gem-id> GEMID </gem-id>
           <gem-balances>...
             ACCTSRC |-> ( BALANCE_SRC => BALANCE_SRC -Rat VALUE )
           ...</gem-balances>
         ...
         </gem>
      requires VALUE >=Rat 0
```

```k
endmodule
```
