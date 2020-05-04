[![CircleCI](https://circleci.com/gh/makerdao/mkr-mcd-spec.svg?style=svg)](https://circleci.com/gh/makerdao/mkr-mcd-spec)

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
-   [kmcd-props](kmcd-props.md) - statement of properties that we would like to hold for the model.
-   [kmcd-prelude](kmcd-prelude.md) - random testing harness.

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

Whenever you update the K submodule (which happens regularly automatically on CI), you may need to do:

```sh
rm -rf deps
git submodule update --init --recursive
make deps
make build -j4
```

Running Simple Tests
--------------------

In directory `tests/`, we have some example runs of the system.
You can run on these simulations directly to get an idea of what the output of the system looks like.

```sh
./kmcd run --backend llvm tests/attacks/lucash-flip-end.mcd
```

If you want to run all the attack tests (and check their output), run:

```sh
make test-execution -j4
```

Running Random Tester
---------------------

### Environment Setup

Make sure that `pyk` library is on `PYTHONPATH`, and `krun` is on `PATH`:

```sh
export PYTHONPATH=./deps/k/k-distribution/target/release/k/lib
export PATH=./deps/k/k-distribution/target/release/k/bin:$PATH
```

### `mcd-pyk.py` Usage

You can ask the random tester for help:

```sh
./mcd-pyk.py random-test --help
```

Then you can start the random tester running, with depth 100, up to 3000 times:

```sh
./mcd-pyk.py random-test 100 3000 &> random-test.out
```

Then you can watch `random-test.out` for assertion violations it finds (search for `Violation Found`).

Additionally, the option `--emit-solidity` is supported, which will make best-effort emissions of Solidity code:

```sh
./mcd-pyk.py random-test 100 3000 --emit-solidity &> random-test.out
```

This emitted Solidity code can be used for conformance testing the Solidity implementation.

### Speed up with `kserver`

By running KServer while working with `mcd-pyk.py`, you will see about 4x the throughput in simulations.
This basically keeps a "warmed up" JVM around, so that we don't have to start over each time.

To start the KServer run:

```sh
spawn-kserver kserver.log
```

And to stop the KServer, run:

```sh
stop-kserver
```

You can make sure that the KServer is being used by running `tail -F kserver.log`.
As `mcd-pyk.py` is running, you should see entries like this being added:

```kserver.log
NGSession 10: org.kframework.main.Main exited with status 0
NGSession 12: org.kframework.main.Main exited with status 0
NGSession 14: org.kframework.main.Main exited with status 0
NGSession 16: org.kframework.main.Main exited with status 0
```
