Dai Token
=========

The Dai token represents an ERC20 fungible asset reflecting the current state of the vat.

```k
requires "kmcd-driver.k"

module DAI
    imports KMCD-DRIVER

    configuration
      <dai>
        <dai-stack> .List </dai-stack>
        <dai-state>
          <dai-ward>        .Map </dai-ward>        // mapping (address => uint)                      Address |-> Bool
          <dai-totalSupply> 0    </dai-totalSupply>
          <dai-account-id>  0    </dai-account-id>
          <dai-balance>     .Map </dai-balance>     // mapping (address => uint)                      Address |-> Int
          <dai-allowance>   .Map </dai-allowance>   // mapping (address => mapping (address => uint))
          <dai-nonce>       .Map </dai-nonce>       // mapping (address => uint)                      Address |-> Int
        </dai-state>
      </dai>

    syntax AllowanceAddress ::= "{" Address "->" Address "}"
 // --------------------------------------------------------

    syntax MCDStep ::= "Dai" "." DaiStep
 // ------------------------------------

    syntax DaiStep ::= DaiAuthStep
 // ------------------------------

    syntax DaiAuthStep ::= AuthStep
 // -------------------------------

    syntax DaiAuthStep ::= WardStep
 // -------------------------------

    syntax DaiAuthStep ::= "init" Int
 // ---------------------------------

    syntax DaiStep ::= StashStep
 // ----------------------------

    syntax DaiStep ::= ExceptionStep
 // --------------------------------
    rule <k> Dai . _:DaiStep => Dai . exception ... </k> [owise]

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
           ACCOUNT_DST |-> (BALANCE_SRC => BALANCE_SRC +Int AMOUNT)
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

    syntax DaiStep ::= "approve" Address Wad
 // ----------------------------------------

    syntax DaiStep ::= "push" Address Wad
 // -------------------------------------

    syntax DaiStep ::= "pull" Address Wad
 // -------------------------------------

    syntax DaiStep ::= "move" Address Address Wad
 // ---------------------------------------------

    syntax DaiStep ::= "permit" Address Address Int Int Bool Int Bytes Bytes
 // ------------------------------------------------------------------------

endmodule
```
