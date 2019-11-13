KMCD Attack Prelude
===================

```k
requires "kmcd-props.k"

module KMCD-PRELUDE
    imports KMCD-PROPS

    syntax MCDStep ::= STEPS ( MCDSteps )
 // -------------------------------------
    rule <k> STEPS ( MCDSTEPS ) => MCDSTEPS ... </k>

    syntax MCDSteps ::= "ATTACK-PRELUDE" [klabel(ATTACK-PRELUDE), symbol]
 // ---------------------------------------------------------------------
    rule ATTACK-PRELUDE
      =>
         // Contract Authorizations
         // -----------------------

         // Auhthorize Pot/End for Vat
         transact ADMIN Vat . rely Pot
         transact ADMIN Vat . rely End

         // Authorize End for Pot
         transact ADMIN Pot . rely End

         // Auhthorize Pot/End for Vow
         transact ADMIN Vow . rely Pot
         transact ADMIN Vow . rely End

         // Authorize End for Cat/Pot
         transact ADMIN Cat . rely End

         // Authorize Vow for Flap
         transact ADMIN Flap . rely Vow

         // Authorize Vow for Flop
         transact ADMIN Flop . rely Vow

         // Account Initializations
         // -----------------------

         // Initialize Vat accounts for Vow/Pot/Flap/End
         transact ADMIN Vat . initUser Vow
         transact ADMIN Vat . initUser Pot
         transact ADMIN Vat . initUser Flap
         transact ADMIN Vat . initUser End

         // File Vow contract for Pot (since Pot doesn't depend on Vow?)
         transact ADMIN Pot . file vow-file Vow

         // Collateral Setup
         // ----------------

         // "gold" collateral and joiner
         transact ADMIN Gem "gold" . init
         transact ADMIN GemJoin "gold" . init

         // Initialize "gold" for Vat
         transact ADMIN Vat . rely GemJoin "gold"
         transact ADMIN Vat . initGem "gold" End
         transact ADMIN Vat . initGem "gold" Flip "gold"
         transact ADMIN Vat . initCDP "gold" End

         // Initialize Spot for gold
         transact ADMIN Spot . init     "gold"
         transact ADMIN Spot . setPrice "gold" 1

         // Initialize Flipper for gold
         transact ADMIN Flip "gold" . init
         transact ADMIN Flip "gold" . rely End

         // Initialize "gold" for End
         transact ADMIN End . initGap "gold"

         // MKR Collateral Setup
         // --------------------

         // "MKR" collateral and joiner
         transact ADMIN Gem "MKR" . init
         transact ADMIN GemJoin "MKR" . init

         // Setup Flap account on MKR
         transact ADMIN Gem "MKR" . initUser Flap
         transact ADMIN Gem "MKR" . mint Flap 20

         // File Parameters
         // ---------------

         // Setup Vat
         transact ADMIN Vat . file Line 1000 ether
         transact ADMIN Vat . initIlk "gold"
         transact ADMIN Vat . file spot "gold" 3 ether
         transact ADMIN Vat . file line "gold" 1000 ether

         // Setup Vow
         transact ADMIN Vow . file bump 1 ether

         // User Setup
         // ----------

         // Initialize gold Gem and GemJoin
         transact ADMIN Gem "gold" . initUser "Alice"
         transact ADMIN Gem "gold" . initUser "Bobby"
         transact ADMIN Gem "gold" . mint "Alice" 20
         transact ADMIN Gem "gold" . mint "Bobby" 20

         transact ADMIN Gem "MKR" . initUser "Alice"
         transact ADMIN Gem "MKR" . initUser "Bobby"

         // Initialize Pot
         transact ADMIN Pot . initUser "Alice"
         transact ADMIN Pot . initUser "Bobby"

         // Initialize users Alice and Bob with gold Gem
         transact ADMIN Vat . initUser "Alice"
         transact ADMIN Vat . initGem "gold" "Alice"
         transact ADMIN Vat . initCDP "gold" "Alice"

         transact ADMIN Vat . initUser "Bobby"
         transact ADMIN Vat . initGem "gold" "Bobby"
         transact ADMIN Vat . initCDP "gold" "Bobby"

         transact "Alice" Vat . hope Pot
         transact "Alice" Vat . hope Flip "gold"
         transact "Alice" Vat . hope End

         transact "Bobby" Vat . hope Pot
         transact "Bobby" Vat . hope Flip "gold"
         transact "Bobby" Vat . hope End

         // Setup CDPs
         transact "Alice" GemJoin "gold" . join "Alice" 10
         transact "Bobby" GemJoin "gold" . join "Bobby" 10
         transact "Alice" Vat . frob "gold" "Alice" "Alice" "Alice" 10 10
         transact "Bobby" Vat . frob "gold" "Bobby" "Bobby" "Bobby" 10 10

         // Initialize End for Users
         transact ADMIN End . initBag "Alice"
         transact ADMIN End . initBag "Bobby"
         transact ADMIN End . initOut "gold" "Alice"
         transact ADMIN End . initOut "gold" "Bobby"
         .MCDSteps
      [macro]
endmodule
```

```k
module KMCD-GEN
    imports KMCD-PRELUDE

    configuration
      <kmcd-random>
        <kmcd-properties/>
        <kmcd-gen>
          <random> $RANDOMSEED:Int </random>
          <generator-depth-bound> $GENDEPTH:DepthBound </generator-depth-bound>
          <generator-next> 0 </generator-next>
          <generator-current> 0 </generator-current>
          <generator-remainder> .GenStep </generator-remainder>
          <generators>
            <generator multiplicity="*" type="Map">
              <generator-id> 0 </generator-id>
              <generator-steps> .GenStep </generator-steps>
            </generator>
          </generators>
          <end-gen> .GenStep </end-gen>
        </kmcd-gen>
      </kmcd-random>

    syntax DepthBound ::= Int | "*"
                        | decrement ( DepthBound ) [function]
 // ---------------------------------------------------------
    rule decrement(*) => *
    rule decrement(N) => N -Int 1

    syntax Int ::= randIntBounded ( Int , Int ) [function]
 // ------------------------------------------------------
    rule randIntBounded(RAND, 0)     => 0
    rule randIntBounded(RAND, BOUND) => RAND modInt BOUND requires BOUND =/=Int 0

    syntax Rat ::= randRat ( Int ) [function]
 // -----------------------------------------
    rule randRat(I) => (I modInt 100) /Rat 100

    syntax Rat ::= randRatBounded ( Int , Rat ) [function]
 // ------------------------------------------------------
    rule randRatBounded(I, BOUND) => BOUND *Rat randRat(I)

    syntax Int     ::= chooseInt     ( Int , List ) [function]
    syntax String  ::= chooseString  ( Int , List ) [function]
    syntax Address ::= chooseAddress ( Int , List ) [function]
    syntax CDPID   ::= chooseCDPID   ( Int , List ) [function]
 // ----------------------------------------------------------
    rule chooseInt    (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>Int
    rule chooseString (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>String
    rule chooseAddress(I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>Address
    rule chooseCDPID  (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>CDPID

    syntax AdminStep ::= AddGenerator ( GenStep )
 // ---------------------------------------------
    rule <k> AddGenerator ( GSS ) => . ... </k>
         <generator-next> I => I +Int 1 </generator-next>
         <generators>
           ...
           ( .Bag
          => <generator>
               <generator-id> I </generator-id>
               <generator-steps> GSS </generator-steps>
             </generator>
           )
           ...
         </generators>

    syntax AdminStep ::= GenStep
    syntax GenStep ::= "GenStep"
                     | "GenStepLoad"
                     | "GenStepReplace"
 // -----------------------------------
    rule <k> GenStep => GenStepLoad ~> GenStepReplace ... </k>
         <random> I => randInt(I) </random>
         <generator-next> N </generator-next>
         <generator-current> _ => I modInt N </generator-current>
         <generator-remainder> GSS => .GenStep </generator-remainder>
         <generator-depth-bound> DB => decrement(DB) </generator-depth-bound>
         <violation> false </violation>
      requires DB =/=K 0

    rule <k> GenStepLoad => GSS ... </k>
         <generator-current> I </generator-current>
         <generator>
           <generator-id> I </generator-id>
           <generator-steps> GSS => .GenStep </generator-steps>
         </generator>

    rule <k> GenStepReplace => . ... </k>
         <generator-remainder> GSS => .GenStep </generator-remainder>
         <generator-current> I </generator-current>
         <generator>
           <generator-id> I </generator-id>
           <generator-steps> _ => GSS </generator-steps>
         </generator>

    syntax AdminStep ::= LogGen ( MCDStep )
    syntax Event ::= GenStep ( MCDStep )
                   | GenStepFailed ( GenStep )
 // ------------------------------------------
    rule <k> LogGen(MCDSTEP) => MCDSTEP ... </k>
         <events> ... (.List => ListItem(GenStep(MCDSTEP))) </events>

    rule <k> GS => . ... </k>
         <events> ... (.List => ListItem(GenStepFailed(GS))) </events>
      [owise]

    syntax GenStep ::= ".GenStep"
                     | GenStep DepthBound
                     > GenStep "|" GenStep [left]
                     > GenStep ";" GenStep [left]
 // ---------------------------------------------
    rule <k> .GenStep => . ... </k>

    rule <k> .GenStep ; GSS => GSS ... </k> [priority(49)]
    rule <k> GSS ; .GenStep => GSS ... </k> [priority(49)]
    rule <k> .GenStep | GSS => GSS ... </k> [priority(49)]
    rule <k> GSS | .GenStep => GSS ... </k> [priority(49)]

    rule <k> GSS DB:DepthBound => #if DB ==K 0 #then . #else (GSS ; (GSS decrement(DB))) | .GenStep #fi ... </k>

    rule <k> GSS ; GSS' => GSS ... </k>
         <generator-remainder> GSS'' => GSS' ; GSS'' </generator-remainder>

    rule <k> GSS | GSS' => #if R modInt 2 ==K 0 #then GSS #else GSS' #fi ... </k>
         <random> R => randInt(R) </random>
endmodule
```
