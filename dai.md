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
        <dai-state>
          <dai-addr>        0:Address </dai-addr>
          <dai-totalSupply> 0:Wad      </dai-totalSupply>
          <dai-account-id>  0         </dai-account-id>
          <dai-balance>     .Map      </dai-balance>     // mapping (address => uint)                      Address |-> Wad
          <dai-allowance>   .Map      </dai-allowance>   // mapping (address => mapping (address => uint))
          <dai-nonce>       .Map      </dai-nonce>       // mapping (address => uint)                      Address |-> Wad
        </dai-state>
      </dai>

    syntax AllowanceAddress ::= "{" Address "->" Address "}"
 // --------------------------------------------------------

    syntax MCDContract ::= DaiContract
    syntax DaiContract ::= "Dai"
    syntax MCDStep ::= DaiContract "." DaiStep [klabel(daiStep)]
 // ------------------------------------------------------------
    rule contract(Dai . _) => Dai
    rule [[ address(Dai) => ADDR ]] <dai-addr> ADDR </dai-addr>

    syntax DaiStep ::= DaiAuthStep
    syntax AuthStep ::= DaiContract "." DaiAuthStep [klabel(daiStep)]
 // -----------------------------------------------------------------
    rule <k> Dai . _ => exception ... </k> [owise]

    syntax Event ::= Transfer(Address, Address, Wad)
                   | Approval(Address, Address, Wad)
 // ------------------------------------------------

    syntax DaiStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Dai . transfer ACCOUNT_SRC AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> BALANCE_SRC
           ...
         </dai-balance>
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
         <dai-balance>
           ...
           ACCOUNT_SRC |-> BALANCE_SRC
           ...
         </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_SRC, AMOUNT)) </frame-events>
      requires BALANCE_SRC >=Rat AMOUNT

    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Rat AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT)
           ...
         </dai-balance>
         <dai-allowance>
           ...
           { ACCOUNT_SRC -> ACCOUNT_DST } |-> (ALLOWANCE_SRC_DST => ALLOWANCE_SRC_DST -Rat AMOUNT)
           ...
         </dai-allowance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_DST, AMOUNT)) </frame-events>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Rat AMOUNT
       andBool ALLOWANCE_SRC_DST >=Rat AMOUNT

    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Rat AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT)
           ...
         </dai-balance>
         <dai-allowance>
           ...
           { ACCOUNT_SRC -> ACCOUNT_DST } |-> -1
           ...
         </dai-allowance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, ACCOUNT_DST, AMOUNT)) </frame-events>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Rat AMOUNT

    syntax DaiAuthStep ::= "mint" Address Wad
 // -----------------------------------------
    rule <k> Dai . mint ACCOUNT_DST AMOUNT => . ... </k>
         <dai-totalSupply> DAI_SUPPLY => DAI_SUPPLY +Rat AMOUNT </dai-totalSupply>
         <dai-balance>
           ...
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Rat AMOUNT)
           ...
         </dai-balance>
         <frame-events> _ => ListItem(Transfer(0, ACCOUNT_DST, AMOUNT)) </frame-events>

    syntax DaiStep ::= "burn" Address Wad
 // -------------------------------------
    rule <k> Dai . burn ACCOUNT_SRC AMOUNT => . ... </k>
         <dai-totalSupply> DAI_SUPPLY => DAI_SUPPLY -Rat AMOUNT </dai-totalSupply>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (AMOUNT_SRC => AMOUNT_SRC -Rat AMOUNT)
           ...
         </dai-balance>
         <frame-events> _ => ListItem(Transfer(ACCOUNT_SRC, 0, AMOUNT)) </frame-events>

    syntax DaiStep ::= "approve" Address Wad
 // ----------------------------------------
    rule <k> Dai . approve ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-allowance>
           ...
           { ACCOUNT_SRC -> ACCOUNT_DST } |-> (_ => AMOUNT)
           ...
         </dai-allowance>
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

```k
    syntax DaiStep ::= "permit" Address Address Int Int Bool Int Bytes Bytes
 // ------------------------------------------------------------------------

endmodule
```
