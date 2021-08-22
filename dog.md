```k
requires "kmcd-driver.md"
requires "clip.md"
requires "vat.md"
requires "vow.md"

module DOG
    imports KMCD-DRIVER
    imports PRE-CLIP
    imports VAT
    imports VOW
```

Dog Configuration
-----------------

```k
    configuration
      <dog-state>
         <dog-wards> .Set      </dog-wards>
         <dog-ilks>  .Map      </dog-ilks>   // mapping (bytes32 => Ilk) String |-> DogIlk
         <dog-vat>   0:Address </dog-vat>
         <dog-vow>   0:Address </dog-vow>
         <dog-live>  false     </dog-live>
         <dog-hole>  rad(0)    </dog-hole>
         <dog-dirt>  rad(0)    </dog-dirt>
      </dog-state>
```

```k
    syntax MCDContract ::= DogContract
    syntax DogContract ::= "Dog"
    syntax MCDStep     ::= DogContract "." DogStep [klabel(dogStep)]
 // ------------------------------------------------------------
    rule contract(Dog . _) => Dog
```

### Constructor

```k
    syntax DogStep ::= "constructor" Address
 // ----------------------------------------
    rule <k> Dog . constructor DOG_VAT => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( <dog-state> _ </dog-state>
        => <dog-state>
             <dog-vat>   DOG_VAT            </dog-vat>
             <dog-live>  true               </dog-live>
             <dog-wards> SetItem(MSGSENDER) </dog-wards>
             ...
           </dog-state>
         )
```

Dog Authorization
-----------------

```k
    syntax DogStep  ::= DogAuthStep
    syntax AuthStep ::= DogContract "." DogAuthStep [klabel(dogStep)]
 // -----------------------------------------------------------------
    rule [[ wards(Dog) => WARDS ]] <dog-wards> WARDS </dog-wards>

    syntax DogAuthStep ::= WardStep
 // -------------------------------
    rule <k> Dog . rely ADDR => . ... </k>
         <dog-wards> ... (.Set => SetItem(ADDR)) </dog-wards>

    rule <k> Dog . deny ADDR => . ... </k>
         <dog-wards> WARDS => WARDS -Set SetItem(ADDR) </dog-wards>
```

Dog Data
--------

-   `DogIlk` tracks parameters needed for `bite`ing CDPs.

    -   `clip`: Liquidator
    -   `chop`: Liquidation Penalty
    -   `hole`: Max DAI needed to cover debt+fees of active auctions per ilk
    -   `dirt`: Amt DAI needed to cover debt+fees of active auctions per ilk

```k
    syntax DogIlk ::= Ilk ( clip: Address, chop: Wad, hole: Rad, dirt: Rad ) [klabel(#DogIlk), symbol]
 // ---------------------------------------------------------------------------------------
```

Dog Events
----------

```k
    syntax CustomEvent ::= Bark(ilk: String, urn: Address, ink: Wad, art: Wad, due: FInt, clip: Address, Id: Int) [klabel(Bark), symbol]
 //-----------------------------------------------------------------------------------------------------------------------------------

    syntax DogStep ::= "emitBark" String Address Wad Wad FInt Address Int
 // --------------------------------------------------------
    rule <k> emitBark ILK URN INK ART DUE CLIP BARK_ID => BARK_ID ... </k>
         <return-value> BARK_ID:Int </return-value>
         <frame-events> ... (.List => ListItem(Bark(ILK, URN, INK, ART, DUE, CLIP, BARK_ID))) </frame-events>
```

File-able Fields
----------------

These parameters are controlled by governance:

-   `vow`:  Debt Engine
-   `hole`: Max DAI needed to cover debt+fees of active auctions
-   `chop`: Liquidation Penalty
-   `clip`: Liquidator

```k
    syntax DogAuthStep ::= "file" DogFile
 // -------------------------------------

    syntax DogFile ::= "vow"  Address
                     | "Hole" Rad
                     | "hole" String Rad
                     | "chop" String Wad
                     | "clip" String Address
 // -----------------------------------------
    rule <k> Dog . file vow DOG_VOW => . ... </k>
         <dog-vow> _ => DOG_VOW </dog-vow>

    rule <k> Dog . file Hole HOLE => . ... </k>
         <dog-hole> _ => HOLE </dog-hole>

    rule <k> Dog . file hole ILK HOLE => . ... </k>
         <dog-ilks> ... ILK |-> Ilk( ... hole: (_ => HOLE) ) ... </dog-ilks>

    rule <k> Dog . file chop ILK CHOP => . ... </k>
         <dog-ilks> ... ILK |-> Ilk( ... chop: (_ => CHOP) ) ... </dog-ilks>
      requires CHOP >=Wad wad(1)

    rule <k> Dog . file clip ILK CLIP => . ... </k>
         <dog-ilks> ... ILK |-> Ilk( ... clip: (_ => CLIP) ) ... </dog-ilks>
         <clip-ilk> CLIP_ILK </clip-ilk>
      requires ILK ==K CLIP_ILK
```

Dog Semantics
-------------

BLN < WAD < RAY < RAD
syntax Rad ::= Wad "*Rate" Ray [function]
syntax Wad ::= Rad "/Rate" Ray [function]

```k
    syntax DogStep ::= "bark" String Address Address
 // -----------------------------------------------
    rule <k> Dog . bark ILK URN KPR
    =>  #let ROOM = minRad( ( DOG_HOLE -Rad DOG_DIRT), (HOLE -Rad  DIRT) ) #in (
        #let DART_INITIAL = minWad( ART, ( ( ROOM /Rate RATE) /Wad CHOP) ) #in (
        #let DART_FINAL = (#if (ART >Wad DART_INITIAL) andBool ( ((ART -Wad DART_INITIAL) *Rate RATE) <Rad DUST ) #then ART #else   DART_INITIAL #fi) #in (
        #let DINK = (INK *Wad DART_FINAL) /Wad ART #in (
        #let DUE = DART_FINAL *Rate RATE #in (
        #let TAB = DUE *RadWad2Rad CHOP #in (
       call DOG_VAT . grab ILK URN CLIP DOG_VOW (wad(0) -Wad DINK) (wad(0) -Wad DART_FINAL)
    ~> call DOG_VOW . fess DUE
    ~> call CLIP . kick TAB DINK URN KPR
    ~> emitBark ILK URN DINK DART_FINAL DUE CLIP 0 ) ) ) ) ) )
    ... </k>
         <dog-vow>  DOG_VOW   </dog-vow>
         <dog-live> DOG_LIVE  </dog-live>
         <dog-vat>  DOG_VAT   </dog-vat>
         <dog-dirt> DOG_DIRT  </dog-dirt>
         <dog-hole> DOG_HOLE  </dog-hole>
         <vat-urns> ... { ILK, URN } |-> Urn( INK, ART ) ...                                                </vat-urns>
         <dog-ilks> ... ILK |-> Ilk( ... clip: CLIP:ClipContract, chop: CHOP, hole: HOLE,  dirt: DIRT ) ... </dog-ilks>
         <vat-ilks> ... ILK |-> Ilk( ... rate: RATE, spot: SPOT, dust: DUST ) ...                           </vat-ilks>
      requires DOG_LIVE ==Bool true
      andBool ( ( SPOT >Ray ray(0) )
      andBool ( (INK *Rate SPOT ) <Rad (ART *Rate RATE) ) )
      andBool ( (DOG_HOLE >Rad DOG_DIRT )
      andBool ( HOLE >Rad DIRT ) )



    rule <k> BARK_ID ~> emitBark ILK URN DINK DART DUE CLIP _ => emitBark ILK URN DINK DART DUE CLIP BARK_ID ... </k>
         <vat-urns> ... { ILK, URN } |-> Urn( _, ART) ...                     </vat-urns>
         <vat-ilks> ... ILK |-> Ilk( ... rate: RATE, spot: _, dust: DUST) ... </vat-ilks>
      requires (#if (ART >Wad DART) #then (#if ( ( ART -Wad DART ) *Rate RATE ) <Rad DUST #then true #else ( ( DART *Rate RATE ) >=Rad DUST ) #fi ) #else true #fi)
      andBool baseFInt(DART) <=Int pow255
      andBool baseFInt(DINK) <=Int pow255
      andBool DINK >Wad wad(0)
```


```k
    syntax DogAuthStep ::= "digs" String Rad
 // ---------------------------------------
    rule <k> Dog . digs ILK INP_RAD => . ... </k>
         <dog-dirt> DOG_DIRT => DOG_DIRT -Rad INP_RAD  </dog-dirt>
         <dog-ilks> ... ILK |-> Ilk( ... dirt: ILK_DIRT => ILK_DIRT -Rad INP_RAD) ... </dog-ilks>
```

```k
    syntax DogAuthStep ::= "cage"
 // ----------------------------
    rule <k> Dog . cage => . ... </k>
         <dog-live> _ => false </dog-live>
```

```k
endmodule
```
