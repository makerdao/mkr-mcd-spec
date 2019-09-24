Rate Setting
============

Rates are set by external oracles, which are modelled here.

```k
requires "cdp-core.k"

module RATES
    imports CDP-CORE

    configuration
      <rates>
        <pot>
          <pot-addr> 0:Address </pot-addr>
          <pot-pies> .Map      </pot-pies> // mapping (address => uint256) Address |-> Wad
          <pot-pie>  0:Wad     </pot-pie>
          <pot-dsr>  0:Ray     </pot-dsr>
          <pot-chi>  0:Ray     </pot-chi>
          <pot-vow>  0:Address </pot-vow>
          <pot-rho>  0         </pot-rho>
        </pot>
      </rates>

    syntax MCDContract ::= PotContract
    syntax PotContract ::= "Pot"
    syntax MCDStep ::= PotContract "." PotStep [klabel(potStep)]
 // ------------------------------------------------------------
    rule contract(Pot . _) => Pot
    rule [[ address(Pot) => ADDR ]] <pot-addr> ADDR </pot-addr>

    syntax PotStep ::= PotAuthStep
    syntax AuthStep ::= PotContract "." PotAuthStep [klabel(potStep)]
 // -----------------------------------------------------------------
    rule <k> Pot . _ => exception ... </k> [owise]

    syntax PotStep ::= "drip"
 // -------------------------
    rule <k> Pot . drip => call Vat . suck VOW THIS ( CHI +Rat (((DSR ^Rat (TIME -Int RHO) *Rat CHI) -Rat CHI) ) ) ... </k>
         <this> THIS </this>
         <currentTime> TIME </currentTime>
         <pot-chi> CHI => CHI +Rat (((DSR ^Rat (TIME -Int RHO) *Rat CHI) -Rat CHI) ) </pot-chi>
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
