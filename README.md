KMCD - MKR Multi-Collateral Dai (MCD) KSpecification
====================================================

**UNDER CONSTRUCTION**

Useful Links
------------

-   Initial RFP for security audits: <https://www.notion.so/MCD-Security-Audit-ac578a595ac74958877106c77f1b85b0>
-   K-DSS bytecode verification: <https://dapp.ci/k-dss/>
-   DSS solidity sources: <https://github.com/makerdao/dss>
-   Useful invariants: <https://hackmd.io/lWCjLs9NSiORaEzaWRJdsQ> (maybe work `take` is out of date)

Potential Properties
--------------------

-   After executing method X of contract C, the suffix of the log will contain these events ...
-   Every time a `ward` changes, a log event should be emmitted which says so (and the log event should have the correct data).
    Will only apply to methods which have `note` modifier, but perhaps should be always.
-   Fundamental equation of Dai (invariant over CDPs + dai).

Order to Model
--------------

-   vat.sol
-   lib.sol

Second layer:

-   jug.sol
-   pot.sol
-   spot.sol

Collateral:

-   dai.sol
-   join.sol

Auctions:

-   vow.sol
-   cat.sol
-   flop.sol
-   flip.sol
-   flap.sol

Global:

-   end.sol
