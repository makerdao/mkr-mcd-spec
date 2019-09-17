Rate Setting
============

Rates are set by external oracles, which are modelled here.

```k
requires "cdp-core.k"

module RATES
    imports CDP-CORE

    configuration
      <rates>
        <potStack> .List </potStack>
        <pot>
          <pot-ward> .Map      </pot-ward> // mapping (address => uint)    Address |-> Bool
          <pot-pies> .Map      </pot-pies> // mapping (address => uint256) Address |-> Int
          <pot-pie>  0         </pot-pie>
          <pot-dsr>  0         </pot-dsr>
          <pot-chi>  0         </pot-chi>
          <pot-vow>  0:Address </pot-vow>
          <pot-rho>  0         </pot-rho>
        </pot>
      </rates>

    syntax MCDStep ::= "Pot" "." PotStep
 // ------------------------------------

    syntax PotStep ::= PotAuthStep
 // ------------------------------

    syntax PotStep ::= StashStep
 // ----------------------------
    rule <k> Pot . push => . ... </k>
         <potStack> (.List => ListItem(POT)) ... </potStack>
         <pot> POT </pot>

    rule <k> Pot . pop => . ... </k>
         <potStack> (ListItem(POT) => .List) ... </potStack>
         <pot> _ => POT </pot>

    rule <k> Pot . drop => . ... </k>
         <potStack> (ListItem(_) => .List) ... </potStack>

    syntax PotStep ::= ExceptionStep
 // --------------------------------
    rule <k>                     Pot . catch => Pot . drop ... </k>
    rule <k> Pot . exception ~>  Pot . catch => Pot . pop  ... </k>
    rule <k> Pot . exception ~> (Pot . PS    => .)         ... </k>
      requires PS =/=K catch

    syntax PotStep ::= AuthStep
 // ---------------------------
    rule <k> Pot . auth => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-ward> ... MSGSENDER |-> true ... </pot-ward>

    rule <k> Pot . auth => Pot . exception ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-ward> ... MSGSENDER |-> false ... </pot-ward>

    syntax PotAuthStep ::= WardStep
 // -------------------------------
    rule <k> Pot . rely ADDR => . ... </k>
         <pot-ward> ... ADDR |-> (_ => true) ... </pot-ward>

    rule <k> Pot . deny ADDR => . ... </k>
         <pot-ward> ... ADDR |-> (_ => false) ... </pot-ward>

    syntax PotAuthStep ::= "init" Address
 // -------------------------------------
    rule <k> Pot . init ILK => . ... </k>
         <currentTime> TIME </currentTime>
         <pot-dsr> _ => ilk_init </pot-dsr>
         <pot-chi> _ => ilk_init </pot-chi>
         <pot-rho> _ => TIME </pot-rho>

    rule <k> Pot . init _ => Pot . exception ... </k> [owise]

    syntax PotStep ::= "drip"
 // -------------------------
    rule <k> Pot . drip => Vat . suck VOW THIS ( CHI +Int (((#pow(DSR, TIME -Int RHO) *Int CHI) -Int CHI) ) ) ... </k>
         <this> THIS </this>
         <currentTime> TIME </currentTime>
         <pot-chi> CHI => CHI +Int (((#pow(DSR, TIME -Int RHO) *Int CHI) -Int CHI) ) </pot-chi>
         <pot-rho> RHO => TIME </pot-rho>
         <pot-dsr> DSR </pot-dsr>
         <pot-vow> VOW </pot-vow>
      requires TIME >=Int RHO

    syntax PotStep ::= "join" Wad
 // -----------------------------

    syntax PotStep ::= "exit" Wad
 // -----------------------------

endmodule
```
