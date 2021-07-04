```k
requires "kmcd-driver.md"

module ABACI
    imports KMCD-DRIVER
```

Abacus Configuration
-----------------

```k
    configuration
    <abaci>
      <abacus multiplicity="*" type="Map">
         <abacus-address> 0:Address </abacus-address>
         <abacus-type>    ""        </abacus-type>
         <abacus-wards>   .Set      </abacus-wards>
         <abacus-tau>     0         </abacus-tau>
         <abacus-step>    0         </abacus-step>
         <abacus-cut>     ray(0)    </abacus-cut>
      </abacus>
   </abaci>
```

```k
    syntax MCDContract ::= AbacusContract
    syntax AbacusContract ::= "Abacus" String
    syntax MCDStep ::= AbacusContract "." AbacusStep [klabel(abacusStep)]
 // ---------------------------------------------------------------------
    rule contract(Abacus ABACUS_ADDRESS . _) => Abacus ABACUS_ADDRESS
```

### Constructor

```k
    syntax AbacusStep ::= "constructor" String
 // ------------------------------------------
    rule <k> Abacus ABACUS_ADDRESS . constructor _ ... </k>
      (<abacus> <abacus-address> ABACUS_ADDRESS </abacus-address> ... </abacus> => .Bag )

    rule <k> Abacus ABACUS_ADDRESS . constructor ABACUS_TYPE => . ... </k>
         <msg-sender> MSGSENDER </msg-sender>
         ( .Bag
        => <abacus>
            <abacus-address> ABACUS_ADDRESS     </abacus-address>
            <abacus-type>    ABACUS_TYPE        </abacus-type>
            <abacus-wards>   SetItem(MSGSENDER) </abacus-wards>
            ...
           </abacus>
         )
         [owise]
```

Abacus Authorization
------------------

```k
    syntax AbacusStep ::= AbacusAuthStep
    syntax AuthStep   ::= AbacusContract "." AbacusAuthStep [klabel(abacusStep)]
 // ----------------------------------------------------------------------------
    rule [[ wards(Abacus ABACUS_ADDRESS) => WARDS ]] <abaci> <abacus-address> ABACUS_ADDRESS </abacus-address> <abacus-wards> WARDS </abacus-wards> ... </abaci>

    syntax AbacusAuthStep ::= WardStep
 // ----------------------------------
    rule <k> Abacus ABACUS_ADDRESS . rely ADDR => . ... </k>
         <abacus>
           <abacus-address>   ABACUS_ADDRESS              </abacus-address>
           <abacus-wards>     ... (.Set => SetItem(ADDR)) </abacus-wards>
           ...
         </abacus>

    rule <k> Abacus ABACUS_ADDRESS . deny ADDR => . ... </k>
         <abacus>
           <abacus-address>   ABACUS_ADDRESS                    </abacus-address>
           <abacus-wards>     WARDS => WARDS -Set SetItem(ADDR) </abacus-wards>
           ...
         </abacus>
```

File-able Fields
----------------

These parameters are controlled by governance:

-   `tau`:  Seconds after auction start when the price reaches zeroe
-   `step`: Length of time between price drops
-   `cut`:  Per-step multiplicative factor


```k
    syntax AbacusAuthStep ::= "file" AbacusFile
 // --------------------------------------------

    syntax AbacusFile ::= "tau"  Int
                        | "step" Int
                        | "cut"  Ray
 // --------------------------------
    rule <k> Abacus ABACUS_ADDRESS . file tau TAU => . ... </k>
         <abacus>
            <abacus-address> ABACUS_ADDRESS </abacus-address>
            <abacus-tau>     _ => TAU       </abacus-tau>
            ...
         </abacus>

    rule <k> Abacus ABACUS_ADDRESS . file step STEP => . ... </k>
         <abacus>
            <abacus-address> ABACUS_ADDRESS </abacus-address>
            <abacus-step>    _ => STEP      </abacus-step>
            ...
         </abacus>

    rule <k> Abacus ABACUS_ADDRESS . file cut CUT => . ... </k>
         <abacus>
            <abacus-address> ABACUS_ADDRESS </abacus-address>
            <abacus-cut>     _ => CUT       </abacus-cut>
            ...
         </abacus>
```

Abacus Semantics
----------------

- `LinearDecrease` abacus:

```k
   syntax AbacusStep ::= "price" Ray Int
 // ------------------------------------
   rule <k> Abacus ABACUS_ADDRESS . price TOP DUR => ( TOP *Ray ray( ( ABACUS_TAU -Int DUR ) /Int ABACUS_TAU ) ) ... </k>
      <abacus>
         <abacus-address> ABACUS_ADDRESS   </abacus-address>
         <abacus-type>    "LinearDecrease" </abacus-type>
         <abacus-tau>     ABACUS_TAU       </abacus-tau>
         ...
      </abacus>
      requires DUR <=Int ABACUS_TAU

    rule <k> Abacus ABACUS_ADDRESS . price TOP DUR => ray(0) ... </k>
      <abacus>
         <abacus-address> ABACUS_ADDRESS   </abacus-address>
         <abacus-type>    "LinearDecrease" </abacus-type>
         <abacus-tau>     ABACUS_TAU       </abacus-tau>
         ...
      </abacus>
        requires DUR >Int ABACUS_TAU
```

- `StairstepExponentialDecrease` abacus:

```k
   rule <k> Abacus ABACUS_ADDRESS . price TOP DUR => ( TOP *Ray ( ABACUS_CUT ^Ray ( DUR /Int ABACUS_STEP ) ) ) ... </k>
      <abacus>
         <abacus-address> ABACUS_ADDRESS                 </abacus-address>
         <abacus-type>    "StairstepExponentialDecrease" </abacus-type>
         <abacus-step>    ABACUS_STEP                    </abacus-step>
         <abacus-cut>     ABACUS_CUT                     </abacus-cut>
         ...
      </abacus>
```

- `ExponentialDecrease` abacus:

```k
   rule <k> Abacus ABACUS_ADDRESS . price TOP DUR => TOP *Ray ( ABACUS_CUT ^Ray DUR ) ... </k>
      <abacus>
         <abacus-address> ABACUS_ADDRESS        </abacus-address>
         <abacus-type>    "ExponentialDecrease" </abacus-type>
         <abacus-cut>     ABACUS_CUT            </abacus-cut>
         ...
      </abacus>
```

```k
endmodule
```
