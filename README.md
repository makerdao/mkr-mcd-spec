KMCD - MKR Multi-Collateral Dai (MCD) KSpecification
====================================================

**UNDER CONSTRUCTION**

Useful Links
------------

-   Initial RFP for security audits: <https://www.notion.so/MCD-Security-Audit-ac578a595ac74958877106c77f1b85b0>
-   K-DSS bytecode verification: <https://dapp.ci/k-dss/>
-   DSS solidity sources: <https://github.com/makerdao/dss>
-   Useful invariants: <https://hackmd.io/lWCjLs9NSiORaEzaWRJdsQ> (maybe work `take` is out of date)
-   MCD Documentation: <https://www.notion.so/MCD-Documentation-WIP-2ec33e10c4704243b1c473ec44f42576>
-   MCD Wiki: <https://github.com/makerdao/dss/wiki/Actions>

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

Potential Properties
--------------------

-   After executing method X of contract C, the suffix of the log will contain these events ...
-   Every time a `ward` changes, a log event should be emmitted which says so (and the log event should have the correct data).
    Will only apply to methods which have `note` modifier, but perhaps should be always.
-   Fundamental equation of Dai (invariant over CDPs + dai).
-   What happens if the "maintenance" functions like `drip` are not called for too long of a timeframe?
    Drip is called by `jug.sol` and `pot.sol`, and if not called frequently enough, system could act funny.

One of the architecture decisions made was to make `*Like` interfaces for actually accessing functions/data of the underlying implementations.
For example, `Cat` has `Urn` defined just to have access to the getters/setters from other contracts.

For inverting storage of `vat` so that we have some implicit account (`msg.sender`), we should inspect `frob` as a test-case, because it access `wish` on three different passed in addresses.
