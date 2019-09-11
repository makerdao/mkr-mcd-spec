Dai Token
=========

The Dai token represents an ERC20 fungible asset reflecting the current state of the vat.

```k
requires "kmcd.k"

module DAI
    imports KMCD-DRIVER
    imports CDP-CORE

    configuration
      <dai>
        <dai-stack> .List </dai-stack>
        <dai-coin>
          <dai-ward>        .Map </dai-ward>        // mapping (address => uint)                      Address |-> Bool
          <dai-totalSupply> 0    </dai-totalSupply>
          <dai-balanceOf>   .Map </dai-balanceOf>   // mapping (address => uint)                      Address |-> Int
          <dai-allowance>   .Map </dai-allowance>   // mapping (address => mapping (address => uint))
          <dai-nonce>       .Map </dai-nonce>       // mapping (address => uint)                      Address |-> Int
        </dai-coin>
      </dai>

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

    syntax DaiStep ::= "transfer" Address Wad
 // -----------------------------------------

    syntax DaiStep ::= "transferFrom" Address Address Wad
 // -----------------------------------------------------

    syntax DaiStep ::= "mint" Address Wad
 // -------------------------------------

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
