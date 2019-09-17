WETH Token
=========

The WETH token represents an ERC20 compatible version of ETH.

```k
requires "kmcd-driver.k"

module WETH
    imports KMCD-DRIVER

    configuration
      <weth>
        <weth-stack> .List </weth-stack>
        <weth-state>
          <weth-totalSupply> 0    </weth-totalSupply>
          <weth-account-id>  0    </weth-account-id>
          <weth-balance>     .Map </weth-balance>     // mapping (address => uint)                      Address |-> Int
          <weth-allowance>   .Map </weth-allowance>   // mapping (address => mapping (address => uint))
        </weth-state>
      </weth>

    syntax AllowanceAddress ::= "{" Address "->" Address "}"
 // --------------------------------------------------------

    syntax MCDStep ::= "Weth" "." WethStep
 // ------------------------------------

    syntax WethStep ::= WethAuthStep
 // ------------------------------

    syntax WethAuthStep ::= AuthStep
 // -------------------------------

    syntax WethAuthStep ::= "init" Int
 // ---------------------------------

    syntax WethStep ::= StashStep
 // ----------------------------

    syntax WethStep ::= ExceptionStep
 // --------------------------------
    rule <k> Weth . _:WethStep => Weth . exception ... </k> [owise]

    syntax WethStep ::= "transfer" Address Wad
 // -----------------------------------------
    rule <k> Weth . transfer ACCOUNT_SRC AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <weth-balance>
           ...
           ACCOUNT_SRC |-> BALANCE_SRC
           ...
         </weth-balance>
      requires BALANCE_SRC >=Int AMOUNT

    rule <k> Weth . transfer ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <weth-balance>
           ...
           ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Int AMOUNT)
           ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
           ...
         </weth-balance>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Int AMOUNT

    syntax WethStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------
    rule <k> Weth . transferFrom ACCOUNT_SRC ACCOUNT_SRC AMOUNT => . ... </k>
         <weth-balance>
           ...
           ACCOUNT_SRC |-> BALANCE_SRC
           ...
         </weth-balance>
      requires BALANCE_SRC >=Int AMOUNT

    rule <k> Weth . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <weth-balance>
          ...
          ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Int AMOUNT)
          ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
          ...
        </weth-balance>
        <weth-allowance>
          ...
          { ACCOUNT_SRC -> ACCOUNT_DST } |-> (ALLOWANCE_SRC_DST => ALLOWANCE_SRC_DST -Int AMOUNT)
          ...
        </weth-allowance>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Int AMOUNT
       andBool ALLOWANCE_SRC_DST >=Int AMOUNT

    rule <k> Weth . transferFrom ACCOUNT_SRC ACCOUNT_DST AMOUNT => . ... </k>
         <weth-balance>
          ...
          ACCOUNT_SRC |-> (BALANCE_SRC => BALANCE_SRC -Int AMOUNT)
          ACCOUNT_DST |-> (BALANCE_DST => BALANCE_DST +Int AMOUNT)
          ...
        </weth-balance>
        <weth-allowance>
          ...
          { ACCOUNT_SRC -> ACCOUNT_DST } |-> -1
          ...
        </weth-allowance>
      requires ACCOUNT_SRC =/=K ACCOUNT_DST
       andBool BALANCE_SRC >=Int AMOUNT

    syntax WethStep ::= "approve" Address Wad
 // ----------------------------------------
    rule <k> Weth . approve ACCOUNT_DST AMOUNT => . ... </k>
         <msg-sender> ACCOUNT_SRC </msg-sender>
         <weth-allowance>
           ...
           { ACCOUNT_SRC -> ACCOUNT_DST } |-> (_ => AMOUNT)
           ...
         </weth-allowance>

endmodule
```
