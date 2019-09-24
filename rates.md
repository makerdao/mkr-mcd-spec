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
          <pot-chi>  0:Rat     </pot-chi> // arbitrary precision
          <pot-vow>  0:Address </pot-vow>
          <pot-rho>  0         </pot-rho>
          <pot-live> false     </pot-live>
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
    rule <k> Pot . drip => call Vat . suck VOW THIS ( PIE *Rat CHI *Rat ( DSR ^Rat (TIME -Int RHO) -Rat 1 ) ) ... </k>
         <this> THIS </this>
         <currentTime> TIME </currentTime>
         <pot-chi> CHI => CHI *Rat DSR ^Rat (TIME -Int RHO) </pot-chi>
         <pot-rho> RHO => TIME </pot-rho>
         <pot-dsr> DSR </pot-dsr>
         <pot-vow> VOW </pot-vow>
         <pot-pie> PIE </pot-pie>
      requires TIME >=Int RHO
       andBool DSR >=Rat 1 // to ensure positive interest rate

    syntax PotStep ::= "join" Wad
 // -----------------------------
    rule <k> Pot . join WAD => call Vat . move MSGSENDER THIS ( CHI *Rat WAD ) ... </k>
         <this> THIS </this>
         <currentTime> TIME </currentTime>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-pies> ... MSGSENDER |-> ( MSGSENDER_PIE => MSGSENDER_PIE +Rat WAD ) ... </pot-pies>
         <pot-pie> PIE => PIE +Rat WAD </pot-pie>
         <pot-chi> CHI </pot-chi>
         <pot-rho> RHO </pot-rho>
      requires TIME ==Int RHO

    syntax PotStep ::= "exit" Wad
 // -----------------------------
    rule <k> Pot . exit WAD => call Vat . move THIS MSGSENDER ( CHI *Rat WAD ) ... </k>
         <this> THIS </this>
         <msg-sender> MSGSENDER </msg-sender>
         <pot-pies> ... MSGSENDER |-> ( MSGSENDER_PIE => MSGSENDER_PIE -Rat WAD ) ... </pot-pies>
         <pot-pie> PIE => PIE -Rat WAD </pot-pie>
         <pot-chi> CHI </pot-chi>

    syntax PotAuthStep ::= "cage"
 // -----------------------------
    rule <k> Pot . cage => . ... </k>
         <pot-live> _ => false </pot-live>
         <pot-dsr> _ => 1 </pot-dsr>

endmodule
```
