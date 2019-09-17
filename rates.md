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
          <pot-pies> .Map      </pot-pies> // mapping (address => uint256) Address |-> Int
          <pot-pie>  0         </pot-pie>
          <pot-dsr>  0         </pot-dsr>
          <pot-chi>  0         </pot-chi>
          <pot-vow>  0:Address </pot-vow>
          <pot-rho>  0         </pot-rho>
        </pot>
      </rates>

    syntax MCDContract ::= PotContract
    syntax PotContract ::= "Pot"
    syntax MCDStep ::= PotContract "." PotStep [klabel(potStep)]
 // ------------------------------------------------------------
    rule contract(Pot . _) => Pot

    syntax PotStep ::= PotAuthStep
    syntax AuthStep ::= PotContract "." PotAuthStep [klabel(potStep)]
 // -----------------------------------------------------------------
    rule <k> Pot . _ => exception ... </k> [owise]

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

    syntax PotAuthStep ::= "cage"
 // -----------------------------

endmodule
```
