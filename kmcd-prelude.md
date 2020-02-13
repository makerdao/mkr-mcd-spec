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
                      | "DEPLOY-PRELUDE" [klabel(DEPLOY-PRELUDE), symbol]
 // ---------------------------------------------------------------------
    rule DEPLOY-PRELUDE
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

         // MKR Token Setup
         // ---------------

         // "MKR" collateral and joiner
         transact ADMIN Gem "MKR" . init
         transact ADMIN GemJoin "MKR" . init

         // Setup Flap account on MKR
         transact ADMIN Gem "MKR" . initUser Vow
         transact ADMIN Gem "MKR" . initUser Flap

         // Miscellaneous Setup
         // -------------------

         // File Vow contract for Pot
         transact ADMIN Pot . file vow-file Vow

         // Allow the Flap to manipulate the Vow's balances
         transact Vow Vat . hope Flap

         .MCDSteps
      [macro]

    rule ATTACK-PRELUDE
      =>
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

         // File Parameters
         // ---------------

         // Setup Vat
         transact ADMIN Vat . file Line 1000 ether
         transact ADMIN Vat . initIlk "gold"
         transact ADMIN Vat . file spot "gold" 3 ether
         transact ADMIN Vat . file line "gold" 1000 ether

         // Setup Vow
         transact ADMIN Vow . file bump 1 ether
         transact ADMIN Vow . file hump 0

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

Random Choices
--------------

```k
module KMCD-RANDOM-CHOICES
    imports KMCD-PRELUDE
```

```k
    syntax Int ::= randIntBounded ( Int , Int ) [function]
 // ------------------------------------------------------
    rule randIntBounded(RAND, BOUND) => 0                          requires         BOUND <Int 0
    rule randIntBounded(RAND, BOUND) => RAND modInt (BOUND +Int 1) requires notBool BOUND <Int 0

    syntax Rat ::= randRat ( Int ) [function]
 // -----------------------------------------
    rule randRat(I) => I /Rat 256

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
```

```k
endmodule
```

Random Sequence Generation
--------------------------

```k
module KMCD-GEN
    imports KMCD-RANDOM-CHOICES
    imports BYTES

    configuration
      <kmcd-random>
        <kmcd-properties/>
        <kmcd-snapshots> .List </kmcd-snapshots>
        <kmcd-gen>
          <random> $RANDOMSEED:Bytes </random>
          <used-random> .Bytes </used-random>
          <generator-next> 0 </generator-next>
          <generator-current> 0 </generator-current>
          <generator-remainder> .GenStep </generator-remainder>
          <generators>
            <generator multiplicity="*" type="Map">
              <generator-id> 0 </generator-id>
              <generator-steps> .GenStep </generator-steps>
            </generator>
          </generators>
        </kmcd-gen>
      </kmcd-random>

    syntax AdminStep ::= "snapshot"
 // -------------------------------
    rule <k> snapshot => . ... </k>
         <kmcd-state> STATE </kmcd-state>
         <kmcd-snapshots> ... (.List => ListItem(<kmcd-state> STATE </kmcd-state>)) </kmcd-snapshots>

    syntax Int ::= #timeStepMax() [function]
                 | #dsrSpread()   [function]
 // ----------------------------------------
    rule #timeStepMax() => 2  [macro]
    rule #dsrSpread()   => 20 [macro]

    syntax Int   ::= head        ( Bytes ) [function]
    syntax Bytes ::= tail        ( Bytes ) [function]
                   | headAsBytes ( Bytes ) [function]
 // -------------------------------------------------
    rule head(BS)        => BS [ 0 ]                            requires lengthBytes(BS) >Int 0
    rule tail(BS)        => substrBytes(BS, 1, lengthBytes(BS)) requires lengthBytes(BS) >Int 0
    rule headAsBytes(BS) => substrBytes(BS, 0, 1)               requires lengthBytes(BS) >Int 0

    syntax DepthBound ::= Int | "*"
                        | decrement ( DepthBound ) [function, functional]
 // ---------------------------------------------------------------------
    rule decrement(*) => *
    rule decrement(N) => N -Int 1 requires N  >Int 0
    rule decrement(N) => 0        requires N <=Int 0

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
         <random> BS => tail(BS) </random>
         <used-random> _ => headAsBytes(BS) </used-random>
         <generator-next> N </generator-next>
         <generator-current> _ => head(BS) modInt N </generator-current>
         <generator-remainder> GSS => .GenStep </generator-remainder>
      requires lengthBytes(BS) >Int 0
       andBool N >Int 0

    rule <k> GenStep => . ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <generator-next> N </generator-next>
      requires lengthBytes(BS) >Int 0
       andBool notBool N >Int 0

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

    syntax MCDSteps ::= "GenSteps"
 // ------------------------------
    rule <k> GenSteps => #if lengthBytes(BS) >Int 0 #then GenStep ~> GenSteps #else assert #fi ... </k>
         <random> BS </random>

    syntax AdminStep ::= LogGen ( MCDStep )
    syntax Event ::= GenStep       ( Bytes , MCDStep ) [klabel(LogGenStep)      , symbol]
                   | GenStepFailed ( Bytes , GenStep ) [klabel(LogGenStepFailed), symbol]
 // -------------------------------------------------------------------------------------
    rule <k> LogGen(MCDSTEP) => MCDSTEP ... </k>
         <used-random> BS => .Bytes </used-random>
         <events> ... (.List => ListItem(GenStep(BS, MCDSTEP))) </events>

    rule <k> GS => . ... </k>
         <used-random> BS =>.Bytes </used-random>
         <events> ... (.List => ListItem(GenStepFailed(BS, GS))) </events>
      [owise]

    syntax GenStep ::= ".GenStep"
                     | GenStep DepthBound
                     > GenStep "|" GenStep [right]
                     > GenStep ";" GenStep [right]
 // ----------------------------------------------
    rule <k> .GenStep => . ... </k>

    rule <k> .GenStep ; GSS => GSS ... </k> [priority(49)]
    rule <k> GSS ; .GenStep => GSS ... </k> [priority(49)]
    rule <k> .GenStep | GSS => GSS ... </k> [priority(49)]
    rule <k> GSS | .GenStep => GSS ... </k> [priority(49)]

    rule <k> .GenStep DB:DepthBound => . ... </k> [priority(49)]

    rule <k> GSS DB:DepthBound => #if DB ==K 0 #then . #else (GSS ; (GSS decrement(DB))) | .GenStep #fi ... </k>

    rule <k> GSS ; GSS' => GSS ... </k>
         <generator-remainder> GSS'' => GSS' ; GSS'' </generator-remainder>

    rule <k> GSS | GSS' => #if head(BS) modInt 2 ==K 0 #then GSS #else GSS' #fi ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
      requires lengthBytes(BS) >Int 0

    syntax GenStep ::= GenTimeStep
    syntax GenTimeStep ::= "GenTimeStep"
 // ------------------------------------
    rule <k> GenTimeStep => LogGen ( TimeStep ((head(BS) modInt #timeStepMax()) +Int 1) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
      requires lengthBytes(BS) >Int 0

    syntax GenStep ::= GenVatStep
    syntax GenVatStep ::= "GenVatFrob"
                        | "GenVatFrob" CDPID
                        | "GenVatFrob" CDPID Wad [prefer]
                        | "GenVatMove"
                        | "GenVatMove" Address
                        | "GenVatMove" Address Address
                        | "GenVatHope"
                        | "GenVatHope" Address
                        | "GenVatHope" Address Address
 // --------------------------------------------------
    rule <k> GenVatFrob => GenVatFrob chooseCDPID(head(BS), keys_list(VAT_URNS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-urns> VAT_URNS </vat-urns>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_URNS) >Int 0

    rule <k> GenVatFrob CDPID => GenVatFrob CDPID ((2 *Rat randRatBounded(head(BS), VAT_GEM)) -Rat VAT_GEM) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-gem> ... CDPID |-> VAT_GEM ... </vat-gem>
      requires lengthBytes(BS) >Int 0

    rule <k> GenVatFrob { ILKID , ADDRESS } DINK
          => #fun( DARTBOUND
                => LogGen ( transact ADDRESS Vat . frob ILKID ADDRESS ADDRESS ADDRESS DINK ((2 *Rat randRatBounded(head(BS), DARTBOUND)) -Rat DARTBOUND) )
                 ) (((SPOT *Rat (URNINK +Rat DINK)) /Rat RATE) -Rat URNART)
         ...
         </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-ilks>
           ...
           ILKID |-> Ilk ( ... rate: RATE, spot: SPOT )
           ...
         </vat-ilks>
         <vat-urns>
           ...
           { ILKID , ADDRESS } |-> Urn ( ... ink: URNINK, art: URNART )
           ...
         </vat-urns>
      requires lengthBytes(BS) >Int 0

    rule <k> GenVatMove => GenVatMove chooseAddress(head(BS), keys_list(VAT_DAIS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAIS </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAIS) >Int 0

    rule <k> GenVatMove ADDRSRC => GenVatMove ADDRSRC chooseAddress(head(BS), keys_list(VAT_DAIS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAIS </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAIS) >Int 0

    rule <k> GenVatMove ADDRSRC ADDRDST => LogGen ( transact ADDRSRC Vat . move ADDRSRC ADDRDST randRatBounded(head(BS), VAT_DAI) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai>
           ...
           ADDRSRC |-> VAT_DAI
           ...
         </vat-dai>
      requires lengthBytes(BS) >Int 0

    rule <k> GenVatHope => GenVatHope chooseAddress(head(BS), keys_list(VAT_DAI)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAI </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAI) >Int 0

    rule <k> GenVatHope ADDRSRC => GenVatHope ADDRSRC chooseAddress(head(BS), keys_list(VAT_DAI)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAI </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAI) >Int 0

    rule <k> GenVatHope ADDRSRC ADDRDST => LogGen ( transact ADDRSRC Vat . hope ADDRDST ) ... </k>

    syntax GenStep ::= GenGemJoinStep
    syntax GenGemJoinStep ::= "GenGemJoinJoin"
                            | "GenGemJoinJoin" String
                            | "GenGemJoinJoin" String Address
 // ---------------------------------------------------------
    // **TODO**: Would be better to choose from an ILK with <gem-id>
    rule <k> GenGemJoinJoin => GenGemJoinJoin chooseString(head(BS), (ListItem("MKR") ListItem("gold"))) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
      requires lengthBytes(BS) >Int 0
//         <gem-joins> GEM_JOINS </gem-joins>
//      requires size(GEM_JOINS) >Int 0

    rule <k> GenGemJoinJoin GEM_JOIN_ID => GenGemJoinJoin GEM_JOIN_ID chooseAddress(head(BS), keys_list(GEM_BALANCES)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <gem>
           <gem-id> GEM_JOIN_ID </gem-id>
           <gem-balances> GEM_BALANCES </gem-balances>
           ...
         </gem>
      requires lengthBytes(BS) >Int 0
       andBool size(GEM_BALANCES) >Int 0

    rule <k> GenGemJoinJoin GEM_JOIN_ID ADDRESS => LogGen ( transact ADDRESS GemJoin GEM_JOIN_ID . join ADDRESS randRatBounded(head(BS), GEM_BALANCE) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <gem>
           <gem-id> GEM_JOIN_ID </gem-id>
           <gem-balances> ... ADDRESS |-> GEM_BALANCE ... </gem-balances>
           ...
         </gem>
      requires lengthBytes(BS) >Int 0

    syntax GenStep ::= GenFlapStep
    syntax GenFlapStep ::= "GenFlapKick"
                         | "GenFlapKick" Address
                         | "GenFlapKick" Address Rad
                         | "GenFlapKick" Address Rad Wad
                         | "GenFlapYank"
 // ------------------------------------
    rule <k> GenFlapKick => GenFlapKick chooseAddress(head(BS), keys_list(VAT_DAIS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAIS </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAIS) >Int 0

    rule <k> GenFlapKick ADDRESS => GenFlapKick ADDRESS randRatBounded(head(BS), VOW_DAI) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> ... ADDRESS |-> VOW_DAI ... </vat-dai>
      requires lengthBytes(BS) >Int 0

    rule <k> GenFlapKick ADDRESS LOT => GenFlapKick ADDRESS LOT randRatBounded(head(BS), FLAP_MKR) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <gem>
           <gem-id> "MKR" </gem-id>
           <gem-balances> ... Flap |-> FLAP_MKR ... </gem-balances>
           ...
         </gem>
      requires lengthBytes(BS) >Int 0

    rule <k> GenFlapKick ADDRESS LOT BID => LogGen ( transact ADDRESS Flap . kick LOT BID ) ... </k>

    rule <k> GenFlapYank => LogGen ( transact ANYONE Flap . yank chooseInt(head(BS), keys_list(FLAP_BIDS)) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <flap-bids> FLAP_BIDS </flap-bids>
      requires lengthBytes(BS) >Int 0
       andBool size(FLAP_BIDS) >Int 0

    syntax GenStep ::= GenFlipStep
    syntax GenFlipStep ::= "GenFlipKick"
                         | "GenFlipKick" CDPID
                         | "GenFlipKick" CDPID Address
                         | "GenFlipKick" CDPID Address Address
                         | "GenFlipKick" CDPID Address Address Rad
                         | "GenFlipKick" CDPID Address Address Rad Wad
 // ------------------------------------------------------------------
    rule <k> GenFlipKick => GenFlipKick chooseCDPID(head(BS), keys_list(VAT_GEMS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-gem> VAT_GEMS </vat-gem>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_GEMS) >Int 0

    rule <k> GenFlipKick CDPID => GenFlipKick CDPID chooseAddress(head(BS), keys_list(VAT_DAIS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAIS </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAIS) >Int 0

    rule <k> GenFlipKick CDPID STORAGE => GenFlipKick CDPID STORAGE chooseAddress(head(BS), keys_list(VAT_DAIS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> VAT_DAIS </vat-dai>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_DAIS) >Int 0

    rule <k> GenFlipKick CDPID STORAGE BENEFICIARY => GenFlipKick CDPID STORAGE BENEFICIARY randRatBounded(head(BS), VAT_GEM) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-gem> ... CDPID |-> VAT_GEM ... </vat-gem>
      requires lengthBytes(BS) >Int 0

    rule <k> GenFlipKick CDPID STORAGE BENEFICIARY LOT => GenFlipKick CDPID STORAGE BENEFICIARY LOT randRatBounded(head(BS), 1000) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
      requires lengthBytes(BS) >Int 0

    rule <k> GenFlipKick { ILKID , ADDRESS } STORAGE BENEFICIARY LOT BID => LogGen ( transact ADDRESS Flip ILKID . kick STORAGE BENEFICIARY 1000 LOT BID ) ... </k>

    syntax GenStep ::= GenPotStep
    syntax GenPotStep ::= "GenPotJoin"
                        | "GenPotJoin" Address
                        | "GenPotFileDSR"
                        | "GenPotDrip"
                        | "GenPotExit"
                        | "GenPotExit" Address
                        | "GenPotCage"
 // ----------------------------------
    rule <k> GenPotCage => LogGen ( transact ADMIN  Pot . cage ) ... </k>
    rule <k> GenPotDrip => LogGen ( transact ANYONE Pot . drip ) ... </k>

    rule <k> GenPotJoin => GenPotJoin chooseAddress(head(BS), keys_list(POT_PIES)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <pot-pies> POT_PIES </pot-pies>
      requires lengthBytes(BS) >Int 0
       andBool size(POT_PIES) >Int 0

    rule <k> GenPotJoin ADDRESS => LogGen ( transact ADDRESS Pot . join randRatBounded(head(BS), VAT_DAI /Rat POT_CHI) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> ... ADDRESS |-> VAT_DAI ... </vat-dai>
         <pot-chi> POT_CHI </pot-chi>
      requires lengthBytes(BS) >Int 0

    rule <k> GenPotFileDSR => LogGen ( transact ADMIN Pot . file dsr (randRatBounded(head(BS), #dsrSpread() /Rat 100) +Rat 1) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
      requires lengthBytes(BS) >Int 0

    rule <k> GenPotExit => GenPotExit chooseAddress(head(BS), keys_list(POT_PIES)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <pot-pies> POT_PIES </pot-pies>
      requires lengthBytes(BS) >Int 0
       andBool size(POT_PIES) >Int 0

    rule <k> GenPotExit ADDRESS => LogGen ( transact ADDRESS Pot . exit (VAT_DAI /Rat CHI) ) ... </k>
         <vat-dai> ... Pot |-> VAT_DAI ... </vat-dai>
         <pot-chi> CHI </pot-chi>

    syntax GenStep ::= GenEndStep
    syntax GenEndStep ::= "GenEndCage"
                        | "GenEndCageIlk"
                        | "GenEndSkim"
                        | "GenEndSkim" CDPID
                        | "GenEndThaw"
                        | "GenEndFlow"
                        | "GenEndSkip"
                        | "GenEndSkip" String
                        | "GenEndPack"
                        | "GenEndPack" Address
                        | "GenEndCash"
                        | "GenEndCash" CDPID
 // ----------------------------------------
    rule <k> GenEndCage => LogGen ( transact ADMIN  End . cage ) ... </k>
    rule <k> GenEndThaw => LogGen ( transact ANYONE End . thaw ) ... </k>

    rule <k> GenEndCageIlk => LogGen ( transact ANYONE End . cage chooseString(head(BS), keys_list(ILKS)) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-ilks> ILKS </vat-ilks>
      requires lengthBytes(BS) >Int 0
       andBool size(ILKS) >Int 0

    // **TODO**: Would be better to choose from an ILK with <end-tag> and <end-gap> too
    rule <k> GenEndSkim => GenEndSkim chooseCDPID(head(BS), keys_list(VAT_URNS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-urns> VAT_URNS </vat-urns>
      requires lengthBytes(BS) >Int 0
       andBool size(VAT_URNS) >Int 0

    rule <k> GenEndSkim { ILKID , ADDRESS } => LogGen ( transact ANYONE End . skim ILKID ADDRESS ) ... </k>

    rule <k> GenEndFlow => LogGen ( transact ANYONE End . flow chooseString(head(BS), keys_list(ILKS)) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-ilks> ILKS </vat-ilks>
      requires lengthBytes(BS) >Int 0
       andBool size(ILKS) >Int 0

    // **TODO**: Would be better to pick an ILKID from <flips>
    rule <k> GenEndSkip => GenEndSkip chooseString(head(BS), keys_list(ILKS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-ilks> ILKS </vat-ilks>
      requires lengthBytes(BS) >Int 0
       andBool size(ILKS) >Int 0

    rule <k> GenEndSkip ILKID => LogGen ( transact ANYONE End . skip ILKID chooseInt(head(BS), keys_list(FLIP_BIDS)) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <flip>
           <flip-ilk> ILKID </flip-ilk>
           <flip-bids> FLIP_BIDS </flip-bids>
           ...
         </flip>
      requires lengthBytes(BS) >Int 0
       andBool size(FLIP_BIDS) >Int 0

    rule <k> GenEndPack => GenEndPack chooseAddress(head(BS), keys_list(END_BAGS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <end-bag> END_BAGS </end-bag>
      requires lengthBytes(BS) >Int 0
       andBool size(END_BAGS) >Int 0

    rule <k> GenEndPack ADDRESS => LogGen ( transact ADDRESS End . pack randIntBounded(head(BS), VAT_DAI) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <vat-dai> ... ADDRESS |-> VAT_DAI ... </vat-dai>
      requires lengthBytes(BS) >Int 0

    rule <k> GenEndCash => GenEndCash chooseCDPID(head(BS), keys_list(END_OUTS)) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <end-out> END_OUTS </end-out>
      requires lengthBytes(BS) >Int 0
       andBool size(END_OUTS) >Int 0

    rule <k> GenEndCash { ILKID , ADDRESS } => LogGen ( transact ADDRESS End . cash ILKID randRatBounded(head(BS), BAG -Rat OUT) ) ... </k>
         <random> BS => tail(BS) </random>
         <used-random> BS' => BS' +Bytes headAsBytes(BS) </used-random>
         <end-out> ... { ILKID , ADDRESS } |-> OUT ... </end-out>
         <end-bag> ... ADDRESS |-> BAG ... </end-bag>
      requires lengthBytes(BS) >Int 0
endmodule
```
