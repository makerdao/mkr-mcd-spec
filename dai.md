Dai Token
=========

The Dai token represents an ERC20 fungible asset reflecting the current state of the vat.

**TODO**: Go over checks in dai.sol and make sure we implement the relevant ones.

```k
requires "kmcd-driver.k"

module DAI
    imports KMCD-DRIVER

    configuration
      <dai>
        <dai-wards>       .Set  </dai-wards>
        <dai-totalSupply> 0:Wad </dai-totalSupply>
        <dai-account-id>  0     </dai-account-id>
        <dai-balance>     .Map  </dai-balance>     // mapping (address => uint)                      Address |-> Wad
        <dai-allowance>   .Map  </dai-allowance>   // mapping (address => mapping (address => uint))
        <dai-nonce>       .Map  </dai-nonce>       // mapping (address => uint)                      Address |-> Wad
      </dai>
```

```k
    syntax MCDContract ::= DaiContract
    syntax DaiContract ::= "Dai"
    syntax MCDStep ::= DaiContract "." DaiStep [klabel(daiStep)]
 // ------------------------------------------------------------
    rule contract(Dai . _) => Dai
```

Dai Authorization
-----------------

```k
    syntax DaiStep  ::= DaiAuthStep
    syntax AuthStep ::= DaiContract "." DaiAuthStep [klabel(daiStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Dai) => WARDS ]] <dai-wards> WARDS </dai-wards>

    syntax DaiAuthStep ::= WardStep
 // -------------------------------
    rule <k> Dai . rely ADDR => . ... </k>
         <dai-wards> ... (.Set => SetItem(ADDR)) </dai-wards>

    rule <k> Dai . deny ADDR => . ... </k>
         <dai-wards> WARDS => WARDS -Set SetItem(ADDR) </dai-wards>
```

Dai Data
--------

-   `AllowanceAddress` is a tuple of two addresses, representing that a given account allows a certain amount to be `transferFrom`ed by another account.

```k
    syntax AllowanceAddress ::= "{" Address "->" Address "}"
 // --------------------------------------------------------
```

Dai Events
----------

```k
    syntax Event ::= Transfer(Address, Address, Wad)
                   | Approval(Address, Address, Wad)
 // ------------------------------------------------
```

Dai Semantics
-------------

The Dai token is a mintable/burnable ERC20 token.

```k
    syntax DaiStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Dai . transfer ACCOUNT_SRC AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-balance> ... ACCOUNT_SRC |-> BALANCE_SRC ... </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_SRC, AMOUNT)) </frame-events>
      requires BALANCE_SRC >=Rat AMOUNT

    rule <k> Dai . transfer ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Rat AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT)
           ...
         </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_DST, AMOUNT)) </frame-events>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Rat AMOUNT

    syntax DaiStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------
    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_SRC AMOUNT => . ... </k>
         <dai-balance> ... ACCOUNT_SRC |-> BALANCE_SRC ... </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_SRC, AMOUNT)) </frame-events>
      requires BALANCE_SRC >=Rat AMOUNT

    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <dai-allowance> ... { ACCOUNT_SRC -> ACCOUNT_DST } |-> (ALLOWANCE_SRC_DST => ALLOWANCE_SRC_DST -Rat AMOUNT) ... </dai-allowance>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Rat AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT)
           ...
         </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_DST, AMOUNT)) </frame-events>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Rat AMOUNT
       andBool ALLOWANCE_SRC_DST >=Rat AMOUNT

    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <dai-allowance> ... { ACCOUNT_SRC -> ACCOUNT_DST } |-> -1 ... </dai-allowance>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Rat AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT)
           ...
         </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_DST, AMOUNT)) </frame-events>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Rat AMOUNT

    syntax DaiAuthStep ::= "mint" Address Wad
 // -----------------------------------------
    rule <k> Dai . mint ACCOUNT_DST AMOUNT => . ... </k>
         <dai-totalSupply> DAI_SUPPLY => DAI_SUPPLY +Rat AMOUNT </dai-totalSupply>
         <dai-balance> ... ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT) ... </dai-balance>
         <frame-events> _ => ListItem(Transfer(0, ACCOUNT_DST, AMOUNT)) </frame-events>

    syntax DaiStep ::= "burn" Address Wad
 // -------------------------------------
    rule <k> Dai . burn ACCOUNT_SRC AMOUNT => . ... </k>
         <dai-totalSupply> DAI_SUPPLY => DAI_SUPPLY -Rat AMOUNT </dai-totalSupply>
         <dai-balance> ... ACCOUNT_SRC |-> (AMOUNT_SRC => AMOUNT_SRC -Rat AMOUNT) ... </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, 0, AMOUNT)) </frame-events>

    syntax DaiStep ::= "approve" Address Wad
 // ----------------------------------------
    rule <k> Dai . approve ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-allowance> ... { ACCOUNT_SRC -> ACCOUNT_DST } |-> (_ => AMOUNT) ... </dai-allowance>
         <frame-events> _ => ListItem(Approval(ACCOUNT_SRC, ACCOUNT_DST, AMOUNT)) </frame-events>

    syntax DaiStep ::= "push" Address Wad
 // -------------------------------------
    rule <k> Dai . push ACCOUNT_DST AMOUNT => Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>

    syntax DaiStep ::= "pull" Address Wad
 // -------------------------------------
    rule <k> Dai . pull ACCOUNT_SRC AMOUNT => Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT ... </k>
         <msg-sender> ACCOUNT_DST </msg-sender>

    syntax DaiStep ::= "move" Address Address Wad
 // ---------------------------------------------
    rule <k> Dai . move ACCOUNT_SRC ACCOUNT_DST AMOUNT => Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT ... </k>
```

**TODO**: `permit` logic, seems to be a time-locked allowance.

```
    syntax DaiStep ::= "permit" Address Address Int Int Bool Int Bytes Bytes
 // ------------------------------------------------------------------------
```

```k
endmodule
```
