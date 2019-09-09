Collateral Manipulation
=======================

This module provides the link between collateral types and the [cdp-core].

```k
requires "cdp-core.k"
requires "dai.k"

module COLLATERAL
    imports CDP-CORE
    imports DAI

    configuration
      <collateral>
        <flip>
          <flip-ward> .Map </flip-ward> // mapping (address => uint) Address |-> Bool
          <flip-bids> .Map </flip-bids> // mapping (uint => Bid)     Int     |-> Bid
          <flip-kicks> 0 </flip-kicks>
        </flip>
      </collateral>

    syntax Bid ::= Bid ( Int, Int, Address, Int, Int, Address, Address, Int )
 // -------------------------------------------------------------------------

    syntax MCDStep ::= "Flip" "." FlipStep
 // --------------------------------------

    syntax FlipStep ::= FlipAuthStep
 // --------------------------------

    syntax FlipAuthStep ::= AuthStep
 // --------------------------------

    syntax FlipAuthStep ::= WardStep
 // --------------------------------

    syntax FlipAuthStep ::= "init" Address Address
 // ----------------------------------------------

    syntax FlipStep ::= StashStep
 // -----------------------------

    syntax FlipStep ::= ExceptionStep
 // ---------------------------------

    syntax FlipStep ::= "kick" Address Address Int Int Int
 // ------------------------------------------------------

    syntax FlipStep ::= "tick" Int
 // ------------------------------

    syntax FlipStep ::= "tend" Int Int Int
 // --------------------------------------

    syntax FlipStep ::= "dent" Int Int Int
 // --------------------------------------

    syntax FlipStep ::= "deal" Int
 // ------------------------------

    syntax FlipStep ::= "yank" Int
 // ------------------------------

endmodule
```
