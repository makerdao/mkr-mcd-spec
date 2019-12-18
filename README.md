KMCD - Multi-Collateral Dai (MCD) KSpecification
====================================================

Useful Links
------------

-   K-DSS bytecode verification: [Reports](https://reports.makerfoundation.com/k-dss/) and [Repository](https://github.com/makerdao/k-dss)
-   DSS solidity sources: <https://github.com/makerdao/dss>
-   Useful invariants: <https://hackmd.io/lWCjLs9NSiORaEzaWRJdsQ> (note: `take` is out of date is currently represented in code as a Collateral's `spot` price)
-   MCD Documentation: <https://docs.makerdao.com/>
-   MCD Wiki: <https://github.com/makerdao/dss/wiki>

Structure
---------

The semantics is broken into several sub-modules.

### Utility Files

-   [kmcd-driver](kmcd-driver.md) - common functionality in all modules.
-   [kmcd](kmcd.md) - union all sub-modules.

### Accounting System

-   [vat](vat.md) - tracks deposited collateral, open CDPs, and borrowed Dai.
-   [pot](pot.md) - interest accumulation for saved Dai.
-   [jug](jug.md) - stability fee collection.

### Collateral

-   [dai](dai.md) - Dai ERC20 token standard.
-   [spot](spot.md) - price feed for collateral.
-   [gem](gem.md) - abstract implementation of collateral.
-   [join](join.md) - plug collateral into MCD system.

### Liquidation/Auction Houses

-   [cat](cat.md) - forcible liquidation of an over-leveraged CDP.
-   [vow](vow.md) - manage and trigger liquidations.
-   [flap](flap.md) - surplus auctions (Vat Dai for sale, bid increasing Gem MKR).
-   [flop](flop.md) - deficit auctions (Gem MKR for sale, lot decreasing Vat Dai).
-   [flip](flip.md) - general auction (Vat Gem for sale, bid increasing Vat Dai, lot decreasing Vat Dai).

### Global Settlement

-   [end](end.md) - close out all CDPs and auctions, attempt to re-distribute gems fairly according to internal accounting.

Building
--------

After installing all the dependencies needed for [K Framework](https://github.com/kframework/k), you can run:

```sh
make deps
make build -j4
```

If you are on Arch Linux, add `K_BUILD_TYPE=Release` to `make deps`, as the `Debug` and `FastBuild` versions do not work.

Running Attack Tests
--------------------

In directory `tests/attacks`, we have some example attacks on the system which should not go through.
In the fixed version of the system, they do not go through.
You can run an attack sequence with:

```sh
./kmcd run --backend llvm tests/attacks/lucash-flip-end.mcd
```

If you want to run all the attack tests (and check their output), run:

```sh
make test-execution -j4
```
