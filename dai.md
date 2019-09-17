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
        <dai-stack> .List </dai-stack>
        <dai-state>
          <dai-totalSupply> 0    </dai-totalSupply>
          <dai-account-id>  0    </dai-account-id>
          <dai-balance>     .Map </dai-balance>     // mapping (address => uint)                      Address |-> Int
          <dai-allowance>   .Map </dai-allowance>   // mapping (address => mapping (address => uint))
          <dai-nonce>       .Map </dai-nonce>       // mapping (address => uint)                      Address |-> Int
        </dai-state>
      </dai>

    syntax AllowanceAddress ::= "{" Address "->" Address "}"
 // --------------------------------------------------------

    syntax MCDContract ::= DaiContract
    syntax DaiContract ::= "Dai"
    syntax MCDStep ::= DaiContract "." DaiStep [klabel(daiStep)]
 // ------------------------------------------------------------
    rule contract(Dai . _) => Dai

    syntax DaiStep ::= DaiAuthStep
    syntax AuthStep ::= DaiContract "." DaiAuthStep [klabel(daiStep)]
 // -----------------------------------------------------------------
    rule <k> Dai . _ => exception ... </k> [owise]

    syntax DaiStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Dai . transfer ACCOUNT_SRC AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> BALANCE_SRC
           ...
         </dai-balance>
      requires BALANCE_SRC >=Int AMOUNT

    rule <k> Dai . transfer ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Int AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
           ...
         </dai-balance>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Int AMOUNT

    syntax DaiStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------
    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_SRC AMOUNT => . ... </k>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> BALANCE_SRC
           ...
         </dai-balance>
      requires BALANCE_SRC >=Int AMOUNT

    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <dai-balance>
          ...
          ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Int AMOUNT)
          ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
          ...
        </dai-balance>
        <dai-allowance>
          ...
          { ACCOUNT_SRC -> ACCOUNT_DST } |-> (ALLOWANCE_SRC_DST => ALLOWANCE_SRC_DST -Int AMOUNT)
          ...
        </dai-allowance>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Int AMOUNT
       andBool ALLOWANCE_SRC_DST >=Int AMOUNT

    rule <k> Dai . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <dai-balance>
          ...
          ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Int AMOUNT)
          ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
          ...
        </dai-balance>
        <dai-allowance>
          ...
          { ACCOUNT_SRC -> ACCOUNT_DST } |-> -1
          ...
        </dai-allowance>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Int AMOUNT

    syntax DaiStep ::= "mint" Address Wad
 // -------------------------------------
    rule <k> Dai . mint ACCOUNT_DST AMOUNT => . ... </k>
         <dai-totalSupply> DAI_SUPPLY => DAI_SUPPLY +Int AMOUNT </dai-totalSupply>
         <dai-balance>
          ...
          ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
          ...
        </dai-balance>

    syntax DaiStep ::= "burn" Address Wad
 // -------------------------------------
    rule <k> Dai . burn ACCOUNT_SRC AMOUNT => . ... </k>
         <dai-totalSupply> DAI_SUPPLY => DAI_SUPPLY -Int AMOUNT </dai-totalSupply>
         <dai-balance>
           ...
           ACCOUNT_SRC |-> (AMOUNT_SRC => AMOUNT_SRC -Int AMOUNT)
           ...
         </dai-balance>

    syntax DaiStep ::= "approve" Address Wad
 // ----------------------------------------
    rule <k> Dai . approve ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <dai-allowance>
           ...
           { ACCOUNT_SRC -> ACCOUNT_DST } |-> (_ => AMOUNT)
           ...
         </dai-allowance>

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
