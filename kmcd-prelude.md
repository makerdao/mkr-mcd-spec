KMCD Attack Prelude
===================

```k
requires "kmcd.k"

module KMCD-PRELUDE
    imports KMCD

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
         transact ADMIN Gem "MKR" . initUser Flap
         transact ADMIN Gem "MKR" . mint Flap 20

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
        <kmcd/>
        <violation> false </violation>
        <kmcd-gen>
          <step-counter> $GENDEPTH:Int </step-counter>
          <random> $RANDOMSEED:Int </random>
          <generator-next> 0 </generator-next>
          <generators>
            <generator multiplicity="*" type="Map">
              <generator-id> 0 </generator-id>
              <generator-steps> .GenSteps </generator-steps>
            </generator>
          </generators>
          <end-gen> .GenSteps </end-gen>
        </kmcd-gen>
      </kmcd-random>

    syntax Rat ::= randRat ( Int , Int , Rat ) [function]
 // -----------------------------------------------------
    rule randRat(I, RAND, BOUND) => BOUND *Rat ((RAND modInt I) /Rat I)

    syntax Int     ::= chooseInt     ( Int , List ) [function]
    syntax String  ::= chooseString  ( Int , List ) [function]
    syntax Address ::= chooseAddress ( Int , List ) [function]
    syntax CDPID   ::= chooseCDPID   ( Int , List ) [function]
 // ----------------------------------------------------------
    rule chooseInt    (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>Int
    rule chooseString (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>String
    rule chooseAddress(I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>Address
    rule chooseCDPID  (I, ITEMS) => { ITEMS [ I modInt size(ITEMS) ] }:>CDPID

    syntax AdminStep ::= AddGenerator ( GenSteps )
 // ----------------------------------------------
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

    syntax AdminStep ::= "GenStep"
                       | next ( Int )
 // ---------------------------------
    rule <k> GenStep => next(I modInt N) ... </k>
         <random> I => randInt(I) </random>
         <generator-next> N </generator-next>
         <step-counter> GENDEPTH => GENDEPTH -Int 1 </step-counter>
         <violation> false </violation>
      requires GENDEPTH >Int 0

    rule <k> next(I) => derive(I, GSS) ... </k>
         <generator>
           <generator-id> I </generator-id>
           <generator-steps> GSS => .GenSteps </generator-steps>
         </generator>

    syntax GenSteps ::= GenStep
                      | ".GenSteps"
                      | GenSteps ";" GenSteps
                      | GenSteps "|" GenSteps
                      | GenSteps "*"
 // --------------------------------

    syntax AdminStep ::= derive ( Int , GenSteps )
 // ----------------------------------------------
    rule <k> derive(_, GS:GenStep) => GS ... </k>

    rule <k> derive(_, .GenSteps) => . ... </k>

    rule <k> derive(_, .GenSteps ; GSS => GSS) ... </k> [priority(49)]
    rule <k> derive(_, GSS ; .GenSteps => GSS) ... </k> [priority(49)]
    rule <k> derive(_, .GenSteps | GSS => GSS) ... </k> [priority(49)]
    rule <k> derive(_, GSS | .GenSteps => GSS) ... </k> [priority(49)]

    rule <k> derive(_, GSS * => GSS | .GenSteps) ... </k>

    rule <k> derive(I, GSS ; GSS') => derive(I, GSS) ... </k>
         <generator>
           <generator-id> I </generator-id>
           <generator-steps> GSS'' => GSS' ; GSS'' </generator-steps>
         </generator>

    rule <k> derive(I, GSS | GSS') => derive(I, GSS) ... </k>
         <random> R => randInt(R) </random>
      requires R modInt 2 ==K 0

    rule <k> derive(I, GSS | GSS') => derive(I, GSS') ... </k>
         <random> R => randInt(R) </random>
      requires R modInt 2 ==K 1
endmodule
```
