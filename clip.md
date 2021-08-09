```k
requires "kmcd-driver.md"
requires "abaci.md"
requires "dog.md"
requires "spot.md"
requires "vat.md"
requires "vow.md"

module PRE-CLIP
    imports KMCD-DRIVER
    imports CLIP-EXTERNAL
    imports ABACI
    imports SPOT
    imports VOW
```

Clip Configuration
-----------------

```k
    configuration
      <clip-state>
        <clip-vat>     0:Address  </clip-vat>
        <clip-ilk>     ""         </clip-ilk>
        <clip-abacus>  0:Address  </clip-abacus>
        <clip-dog>     0:Address  </clip-dog>
        <clip-vow>     0:Address  </clip-vow>
        <clip-spot>    0:Address  </clip-spot>
        <clip-calc>    0:Address  </clip-calc>
        <clip-buf>     ray(1)     </clip-buf>
        <clip-tail>    0          </clip-tail>
        <clip-cusp>    ray(1)     </clip-cusp>
        <clip-chip>    wad(1)     </clip-chip>
        <clip-tip>     rad(0)     </clip-tip>
        <clip-chost>   rad(0)     </clip-chost>
        <clip-kicks>   0          </clip-kicks>
        <clip-active>  .List      </clip-active>
        <clip-sales>   .Map       </clip-sales>    // mapping (uint => Sales) Int |-> ClipSale
        <clip-locked>  false      </clip-locked>
        <clip-stopped> noBreaker:ClipStop  </clip-stopped>
        <clip-wards>   .Set       </clip-wards>
        <clip-external/>
      </clip-state>
```

```k
    syntax MCDContract  ::= ClipContract
    syntax ClipContract ::= "Clip"
    syntax MCDStep      ::= ClipContract "." ClipStep [klabel(clipStep)]
 // --------------------------------------------------------------------
    rule contract(Clip . _) => Clip
```

### Constructor

```k
    syntax ClipStep ::= "constructor" Address Address Address Address
 // -----------------------------------------------------------------
    rule <k> Clip . constructor CLIP_VAT CLIP_SPOT CLIP_DOG CLIP_ILK => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <clip-state> _ </clip-state>
        => <clip-state>
             <clip-vat>   CLIP_VAT           </clip-vat>
             <clip-spot>  CLIP_SPOT          </clip-spot>
             <clip-dog>   CLIP_DOG           </clip-dog>
             <clip-ilk>   CLIP_ILK           </clip-ilk>
             <clip-wards> SetItem(MSGSENDER) </clip-wards>
             ...
           </clip-state>
         )
```

Clip Breaker
------------

```k
   syntax ClipStop ::= "noBreaker"
                     | "noNewKick"
                     | "noNewKickOrRedo"
                     | "noNewKickOrRedoOrTake"

   syntax Bool ::= ClipStop "<ClipStop" ClipStop [function]
 // -------------------------------------------------------
   rule noBreaker       <ClipStop noBreaker             => false
   rule noBreaker       <ClipStop _                     => true   [owise]

   rule noNewKick       <ClipStop noBreaker             => false
   rule noNewKick       <ClipStop noNewKick             => false
   rule noNewKick       <ClipStop _                     => true   [owise]

   rule noNewKickOrRedo <ClipStop noNewKickOrRedoOrTake => true
   rule noNewKickOrRedo <ClipStop _                     => false  [owise]

   rule _               <ClipStop _                     => false  [owise]
```

Clip Authorization
-----------------

```k
    syntax ClipStep  ::= ClipAuthStep
    syntax AuthStep  ::= ClipContract "." ClipAuthStep [klabel(clipStep)]
 // ---------------------------------------------------------------------
    rule [[ wards(Clip) => WARDS ]] <clip-wards> WARDS </clip-wards>

    syntax ClipAuthStep ::= WardStep
 // --------------------------------
    rule <k> Clip . rely ADDR => . ... </k>
         <clip-wards> ... (.Set => SetItem(ADDR)) </clip-wards>

    rule <k> Clip . deny ADDR => . ... </k>
         <clip-wards> WARDS => WARDS -Set SetItem(ADDR) </clip-wards>

   syntax ClipAuthLockStep
   syntax ClipStep     ::= ClipLockStep
   syntax ClipAuthStep ::= ClipAuthLockStep
   syntax ClipLockStep ::= ClipAuthLockStep
   syntax LockStep     ::= ClipContract "." ClipLockStep [klabel(clipStep)]
   syntax LockAuthStep ::= ClipContract "." ClipAuthLockStep [klabel(clipStep)]
// ----------------------------------------------------------------------------
   rule <k> lock Clip . _ => . ... </k>
         <clip-locked> false => true </clip-locked>

   rule <k> unlock Clip . _ => . ... </k>
         <clip-locked> true => false </clip-locked>
```

Clip Data
---------

-   `ClipSale` tracks the parameters of an auction:

    -   `pos`: Index in active array.
    -   `tab`: Dai to raise, rad
    -   `lot`: collateral to sell, wad
    -   `usr`: Liquidated CDP
    -   `tic`: Auction start time
    -   `top`: Starting price, ray

```k
    syntax ClipSale ::= ClipSale ( pos: Int, tab: Rad, lot: Wad, usr: Address, tic: Int, top: Ray )
 // -----------------------------------------------------------------------------------
```

Clip Events
----------

```k
    syntax CustomEvent ::= Kick(id: Int, top: Ray, tab: Rad, lot: Wad, usr: Address, kpr: Address, coin: Wad) [klabel(Kick), symbol]
 // --------------------------------------------------------------------------------------------------------------------------------

    syntax ClipStep ::= "emitKick" Int Ray Rad Wad Address Address Wad
 // ------------------------------------------------------------------
    rule <k> emitKick KICK_ID TOP TAB LOT USR KPR COIN => KICK_ID ... </k>
         <return-value> KICK_ID:Int </return-value>
         <frame-events> ... (.List => ListItem(Kick(KICK_ID, TOP, TAB, LOT, USR, KPR, COIN))) </frame-events>

    syntax CustomEvent ::= Redo(id: Int, top: Ray, tab: Rad, lot: Wad, usr: Address, kpr: Address, coin: Wad) [klabel(Redo), symbol]
 //---------------------------------------------------------------------------------------------------------------------------------

    syntax ClipStep ::= "emitRedo" Int Ray Rad Wad Address Address Wad
 // ------------------------------------------------------------------
    rule <k> emitRedo REDO_ID TOP TAB LOT USR KPR COIN => REDO_ID ... </k>
         <return-value> REDO_ID:Int </return-value>
         <frame-events> ... (.List => ListItem(Redo(REDO_ID, TOP, TAB, LOT, USR, KPR, COIN))) </frame-events>

    syntax CustomEvent ::= Take(id: Int, max: Ray, price: Ray, owe: Wad, tab: Rad, lot: Wad, usr: Address) [klabel(Take), symbol]
 // -----------------------------------------------------------------------------------------------------------------------------

    syntax ClipStep ::= "emitTake" Int Ray Ray Wad Rad Wad Address
 // --------------------------------------------------------------
    rule <k> emitTake TAKE_ID MAX PRICE OWE TAB LOT USR => TAKE_ID ... </k>
         <return-value> TAKE_ID:Int </return-value>
         <frame-events> ... (.List => ListItem(Take(TAKE_ID, MAX, PRICE, OWE, TAB, LOT, USR))) </frame-events>
```

File-able Fields
----------------

These parameters are controlled by governance:

-   `buf`: Multiplicative factor to increase starting price
-   `tail`: Time elapsed before auction reset
-   `cusp`: Percentage drop before auction reset
-   `chip`: Percentage of tab to suck from vow to incentivize keepers
-   `tip`: Flat fee to suck from vow to incentivize keepers
-   `stopped`: Levels for circuit breaker
-   `spotter`: Collateral price module
-   `dog`: Liquidation module
-   `vow`: Recipient of dai raised in auctions
-   `calc`: Current price calculator

```k
    syntax ClipAuthStep ::= "file" ClipFile
 // ---------------------------------------

    syntax ClipFile ::= "buf"  Ray
                      | "tail" Int
                      | "cusp" Ray
                      | "chip" Wad
                      | "tip"  Rad
                      | "stopped" ClipStop
                      | "spot-file"   Address
                      | "dog-file"    Address
                      | "vow-file"    Address
                      | "abacus-file" Address
 // -----------------------------------------
    rule <k> Clip . file buf BUF => . ... </k>
         <clip-buf> _ => BUF </clip-buf>
      requires BUF >=Ray ray(0)

    rule <k> Clip . file tail TAIL => . ... </k>
         <clip-tail> _ => TAIL </clip-tail>
      requires TAIL >=Int 0

    rule <k> Clip . file cusp CUSP => . ... </k>
         <clip-cusp> _ => CUSP </clip-cusp>
      requires CUSP >=Ray ray(0)

    rule <k> Clip . file chip CHIP => . ... </k>
         <clip-chip> _ => CHIP </clip-chip>
      requires CHIP >=Wad wad(0)

    rule <k> Clip . file tip TIP => . ... </k>
         <clip-tip> _ => TIP </clip-tip>
      requires TIP >=Rad rad(0)

    rule <k> Clip . file stopped STOPPED => . ... </k>
         <clip-stopped> _ => STOPPED </clip-stopped>

    rule <k> Clip . file spot-file ADDR => . ... </k>
         <clip-spot> _ => ADDR </clip-spot>

    rule <k> Clip . file dog-file ADDR => . ... </k>
         <clip-dog> _ => ADDR </clip-dog>

    rule <k> Clip . file vow-file ADDR => . ... </k>
         <clip-vow> _ => ADDR </clip-vow>

    rule <k> Clip . file abacus-file ADDR => . ... </k>
         <clip-abacus> _ => ADDR </clip-abacus>
```

Clip Semantics
-------------

```k
   syntax ClipAuthLockStep ::= "kick" Rad Wad Address Address
 // ---------------------------------------------------------
    rule <k> Clip . kick TAB LOT USR KPR
    => #let TOP = ( ( Wad2Ray(VALUE) ) /Ray SPOT_PAR )  /Ray CLIP_BUF #in (
       #let COIN = ( #if ( CLIP_TIP >Rad rad(0) orBool CLIP_CHIP >Wad wad(0) ) #then ( CLIP_TIP +Wad (    Rad2Wad(TAB) *Wad CLIP_CHIP ) ) #else wad(0) #fi )  #in  (
    #if ( CLIP_TIP >Rad rad(0) orBool CLIP_CHIP >Wad wad(0) ) #then call CLIP_VAT . suck CLIP_VOW KPR COIN #else . #fi
    ~> emitKick (KICKS +Int 1) TOP TAB LOT USR KPR COIN ) )
    ... </k>
         <clip-kicks> KICKS => KICKS +Int 1 </clip-kicks>
         <clip-active> CLIP_ACTIVE => CLIP_ACTIVE ListItem(KICKS +Int 1)  </clip-active>
         <clip-sales> ... KICKS +Int 1 |-> ClipSale( ... pos: (_ =>  size(CLIP_ACTIVE)),    tab: (_ => TAB), usr: (_ => USR), tic: (_ => NOW), top: (_=> ( ( ( Wad2Ray(VALUE)      ) /Ray SPOT_PAR )  *Ray CLIP_BUF ))  ) </clip-sales>
         <clip-stopped> CLIP_STOPPED </clip-stopped>
         <clip-vow> CLIP_VOW </clip-vow>
         <clip-buf> CLIP_BUF </clip-buf>
         <clip-vat> CLIP_VAT </clip-vat>
         <clip-ilk> CLIP_ILK </clip-ilk>
         <spot-ilks> CLIP_ILK |-> SpotIlk(... pip: VALUE ) </spot-ilks>
         <spot-par> SPOT_PAR </spot-par>
         <clip-tip> CLIP_TIP </clip-tip>
         <clip-chip> CLIP_CHIP </clip-chip>
         <current-time> NOW </current-time>
      requires CLIP_STOPPED <ClipStop noNewKick
      andBool TAB >Rad rad(0)
      andBool LOT >Wad wad(0)
      andBool USR =/=K 0:Address
      andBool KICKS +Int 1 >Int 0
      andBool ( ( ( Wad2Ray(VALUE) ) /Ray SPOT_PAR )  *Ray CLIP_BUF ) >Ray ray(0)
```

```k
endmodule
```

A PRE module was introduced to avoid circular imports.

```k
module CLIP
    import DOG
    import PRE-CLIP
```

```k
   syntax ClipStep ::= "upchost"
// -----------------------------
    rule <k> Clip . upchost => . ... </k>
         <clip-chost> _ => DUST *Rad Wad2Rad(CHOP) </clip-chost>
         <clip-ilk> CLIP_ILK </clip-ilk>
         <vat-ilks> ... CLIP_ILK |-> Ilk( ... dust: DUST) ... </vat-ilks>
         <dog-ilks> ... CLIP_ILK |-> Ilk( ... chop: CHOP) ... </dog-ilks>
```

```k
    syntax ClipLockStep ::= "redo" Int Address
// ------------------------------------------
    rule <k> Clip . redo REDO_ID KPR
    => #let PRICE = Abacus CLIP_ABACUS . price TOP (NOW -Int TIC) #in  (
       #let DONE = ( (NOW -Int TIC ) >Int CLIP_TAIL ) orBool ( (PRICE /Ray TOP) <Ray CLIP_CUSP ) #in (
       #let TOP_FINAL = ( Wad2Ray(VALUE) /Ray SPOT_PAR ) *Ray CLIP_BUF #in (
       #let COIN = ( #if ( CLIP_TIP >Rad rad(0) orBool CLIP_CHIP >Wad wad(0) )  #then ( #if ( TAB >=Rad CLIP_CHOST andBool ( Wad2Ray(LOT) *Ray ( Wad2Ray(VALUE) /Ray SPOT_PAR ) ) >=Ray CLIP_CHOST ) #then CLIP_TIP +Rad ( Rad2Wad(TAB) *Wad CLIP_CHIP ) #else wad(0) #fi ) #else wad(0) #fi ) #in (
    ( #if ( CLIP_TIP >Rad rad(0) orBool CLIP_CHIP >Wad wad(0) ) #then ( #if ( TAB >=Rad CLIP_CHOST andBool ( Wad2Ray(LOT) *Ray ( Wad2Ray(VALUE) /Ray SPOT_PAR ) ) >=Ray CLIP_CHOST ) #then call CLIP_VAT . suck CLIP_VOW KPR COIN #else . #fi ) #else . #fi )
    ~> DONE
    ~> emitRedo REDO_ID TOP_FINAL TAB LOT USR KPR COIN ) ) ) )
    ... </k>
         <clip-abacus> CLIP_ABACUS </clip-abacus>
         <clip-buf> CLIP_BUF </clip-buf>
         <clip-chip> CLIP_CHIP </clip-chip>
         <clip-chost> CLIP_CHOST </clip-chost>
         <clip-cusp> CLIP_CUSP </clip-cusp>
         <clip-ilk> CLIP_ILK </clip-ilk>
         <clip-tail> CLIP_TAIL </clip-tail>
         <clip-tip> CLIP_TIP </clip-tip>
         <clip-sales> ... REDO_ID |-> ClipSale( ... tab: TAB, lot: LOT, usr: USR, tic: (TIC => NOW),top: (TOP => ( ( Wad2Ray(VALUE) /Ray SPOT_PAR ) *Ray CLIP_BUF ) ) ) ... </clip-sales>
         <clip-vat> CLIP_VAT </clip-vat>
         <clip-vow> CLIP_VOW </clip-vow>
         <current-time> NOW </current-time>
         <spot-ilks> CLIP_ILK |-> SpotIlk(... pip: VALUE ) </spot-ilks>
         <spot-par> SPOT_PAR </spot-par>
         <clip-stopped> CLIP_STOPPED </clip-stopped>
      requires CLIP_STOPPED <ClipStop noNewKickOrRedo
      andBool USR =/=K 0:Address
      andBool ( ( Wad2Ray(VALUE) /Ray SPOT_PAR ) *Ray CLIP_BUF ) >Ray ray(0)

    rule <k> DONE:Bool ~> emitRedo REDO_ID TOP_FINAL TAB LOT USR KPR COIN => emitRedo REDO_ID TOP_FINAL TAB LOT USR KPR COIN ... </k>
      requires DONE
```

```k
    syntax ClipLockStep ::= "take" Int Wad Ray Address String
 // ---------------------------------------------------------
    rule <k> Clip . take TAKE_ID AMT MAX WHO DATA
    =>  #let PRICE = Abacus CLIP_ABACUS . price TOP (NOW -Int TIC) #in (
        #let DONE = ( (NOW -Int TIC ) >Int CLIP_TAIL ) orBool ( (PRICE /Ray TOP) <Ray CLIP_CUSP ) #in (
        #let SLICE_INITIAL = minWad(LOT, AMT) #in ( 
        #let OWE_INITIAL = SLICE_INITIAL *Wad Ray2Wad(PRICE) #in (
        #let OWE_FINAL = ( #if (OWE_INITIAL >Wad Rad2Wad(TAB)) #then Rad2Wad(TAB) #else ( #if (OWE_INITIAL <Wad Rad2Wad(TAB) andBool SLICE_INITIAL <Wad LOT ) #then (#if ( ( Rad2Wad(TAB) -Wad OWE_INITIAL ) <Wad Ray2Wad(CLIP_CHOST) ) #then (Rad2Wad(TAB) -Wad Ray2Wad(CLIP_CHOST) ) #else OWE_INITIAL #fi ) #else OWE_INITIAL #fi ) #fi ) #in (  
        #let SLICE_FINAL =  ( #if (OWE_INITIAL >Wad Rad2Wad(TAB)) #then OWE_FINAL /Wad PRICE #else ( #if (OWE_INITIAL <Wad Rad2Wad(TAB) andBool SLICE_INITIAL <Wad LOT ) #then (#if ( ( Rad2Wad(TAB) -Wad OWE_INITIAL ) <Wad Ray2Wad(CLIP_CHOST) ) #then ( OWE_FINAL /Wad PRICE ) #else SLICE_INITIAL #fi ) #else SLICE_INITIAL #fi ) #fi ) #in (
        #let TAB_FINAL = TAB -Rad Wad2Rad(OWE_FINAL) #in (
        #let LOT_FINAL = LOT -Wad SLICE_FINAL #in (
        call CLIP_VAT . flux CLIP_ILK THIS WHO SLICE_FINAL
    ~> ( #if lengthString(DATA) >Int 0 andBool WHO =/=K CLIP_VAT andBool WHO =/=K CLIP_DOG #then call ClipExternalContract . clipperCall MSG_SENDER OWE_FINAL SLICE_FINAL DATA #else . #fi )
    ~> call CLIP_VAT . move MSG_SENDER CLIP_VOW OWE_FINAL
    ~> call CLIP_DOG . digs CLIP_ILK ( #if LOT_FINAL ==Wad wad(0) #then TAB_FINAL +Rad Wad2Rad(OWE_FINAL) #else Wad2Rad(OWE_FINAL) #fi )
    ~> (#if LOT_FINAL ==Wad wad(0) #then Clip . remove TAKE_ID #else ( #if TAB_FINAL ==Rad rad(0) #then call CLIP_VAT . flux CLIP_ILK THIS USR LOT_FINAL #else . #fi )  #fi)
    ~> (#if LOT_FINAL ==Wad wad(0) #then .                #else ( #if TAB_FINAL ==Rad rad(0) #then Clip . remove TAKE_ID #else .                                 #fi )  #fi)
    ~> (#if LOT_FINAL ==Wad wad(0) #then false            #else ( #if TAB_FINAL ==Rad rad(0) #then false            #else true                              #fi )  #fi)
    ~> TAB
    ~> SLICE_INITIAL
    ~> OWE_FINAL
    ~> PRICE
    ~> DONE
    ~> emitTake TAKE_ID MAX PRICE OWE_FINAL TAB_FINAL LOT_FINAL USR ) ) ) ) ) ) ) )
    ... </k>
         <clip-sales> ... TAKE_ID |-> ClipSale( ... tab: TAB, lot: LOT, usr: USR, tic: TIC, top: TOP ) ... </clip-sales>
         <clip-chost>    CLIP_CHOST    </clip-chost>
         <clip-ilk>      CLIP_ILK      </clip-ilk>
         <clip-vat>      CLIP_VAT      </clip-vat>
         <clip-dog>      CLIP_DOG      </clip-dog>
         <clip-vow>      CLIP_VOW      </clip-vow>
         <clip-tail>     CLIP_TAIL     </clip-tail>
         <clip-cusp>     CLIP_CUSP     </clip-cusp>
         <clip-abacus>   CLIP_ABACUS   </clip-abacus>
         <clip-stopped>  CLIP_STOPPED  </clip-stopped>
         <current-time> NOW </current-time>
         <this>       THIS       </this>
         <msg-sender> MSG_SENDER </msg-sender>
      requires CLIP_STOPPED <ClipStop noNewKickOrRedoOrTake
      andBool USR =/=K 0:Address

    rule <k> UPDATE:Bool ~> TAB:Rad ~> SLICE_INITIAL:Wad ~> OWE_INITIAL:Wad ~> PRICE:Ray ~> DONE:Bool ~> emitTake TAKE_ID MAX PRICE OWE_FINAL TAB_FINAL LOT_FINAL USR => emitTake TAKE_ID MAX PRICE OWE_FINAL TAB_FINAL LOT_FINAL USR ... </k>
         <clip-sales> ... TAKE_ID |-> ClipSale( ... tab: (TAB => #if UPDATE #then TAB_FINAL #else TAB #fi), lot:(LOT => #if UPDATE #then LOT_FINAL #else LOT #fi) ) ... </clip-sales>
         <clip-chost> CLIP_CHOST </clip-chost>
      requires notBool DONE
      andBool MAX >=Ray PRICE
      andBool ( #if (OWE_INITIAL >Wad TAB) #then true #else ( #if (OWE_INITIAL <Wad TAB andBool SLICE_INITIAL <Wad LOT ) #then (#if ( ( TAB -Wad OWE_INITIAL ) <Wad Ray2Wad(CLIP_CHOST) ) #then ( TAB >Wad Ray2Wad(CLIP_CHOST) ) #else true #fi ) #else true #fi ) #fi )
```

```k
   syntax ClipStep ::= "remove" Int
// --------------------------------
   rule <k> Clip . remove REMOVE_ID => . ... </k>
      <clip-active> CLIP_ACTIVE => (#if (REMOVE_ID =/=K (size(CLIP_ACTIVE) -Int 1)) #then range(CLIP_ACTIVE[POS <- (size(CLIP_ACTIVE) -Int 1)], 0, 1) #else range(CLIP_ACTIVE,0,1) #fi) </clip-active>
      <clip-sales> ...
      REMOVE_ID |-> ClipSale( ... pos: (POS => 0), tab: (_ => rad(0)), lot: (_ => wad(0)), usr: (_ => 0:Address), tic: (_ => 0), top: (_ => ray(0)) )
      (size(CLIP_ACTIVE) -Int 1) |-> ClipSale(... pos: (MOVE_POS => #if (REMOVE_ID =/=K (size(CLIP_ACTIVE) -Int 1)) #then POS #else MOVE_POS #fi) )
      ...
      </clip-sales>
```

```k
    syntax ClipAuthLockStep ::= "yank" Int
// --------------------------------------
    rule <k> Clip . yank YANK_ID =>
    call CLIP_DOG . digs CLIP_ILK TAB
    ~> call CLIP_VAT . flux CLIP_ILK THIS MSG_SENDER LOT
    ~> call Clip . remove YANK_ID
    ... </k>
         <this> THIS </this>
         <msg-sender> MSG_SENDER </msg-sender>
         <clip-sales> ... YANK_ID |-> ClipSale( ... tab: TAB, lot: LOT, usr: USR ) ... </clip-sales>
         <clip-dog> CLIP_DOG </clip-dog>
         <clip-vat> CLIP_VAT </clip-vat>
         <clip-ilk> CLIP_ILK </clip-ilk>
      requires USR =/=K 0:Address
```

```k
endmodule
```

#### Dummy Contract for Mocking an External Call

Clip External Contract Configuration
------------------------------------

```k
module CLIP-EXTERNAL
    imports KMCD-DRIVER

    configuration
      <clip-external>
        <mock-variable> 0 </mock-variable>
      </clip-external>
```

```k
    syntax MCDContract          ::= ClipExternalContract
    syntax ClipExternalContract ::= "ClipExternalContract"
    syntax MCDStep              ::= ClipExternalContract "." ClipExternalStep [klabel(clipExternalStep)]
    syntax ClipExternalStep
 // ----------------------------------------------------------------------------------------------------
    rule contract(ClipExternalContract . _) => ClipExternalContract
```

Clip External Contract Mock Functions
-------------------------------------

This may be changed to study different behaviours and possible effects of an external call to the system.

```k
   syntax ClipExternalStep ::= "clipperCall" Address Wad Wad String
// ----------------------------------------------------------------
    rule <k> ClipExternalContract . clipperCall _MSG_SENDER _OWE _SLICE _DATA => . ... </k>
         <mock-variable> MOCK_VARIABLE => MOCK_VARIABLE +Int 1 </mock-variable>
```

```k
endmodule
```
