# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn

DEPS_DIR                := deps
K_SUBMODULE             := $(DEPS_DIR)/k
PANDOC_TANGLE_SUBMODULE := $(DEPS_DIR)/pandoc-tangle

ifneq (,$(wildcard $(K_SUBMODULE)/k-distribution/target/release/k/bin/*))
    K_RELEASE ?= $(abspath $(K_SUBMODULE)/k-distribution/target/release/k)
else
    K_RELEASE ?= $(dir $(shell which kompile))..
endif
K_BIN := $(K_RELEASE)/bin
K_LIB := $(K_RELEASE)/lib/kframework
export K_RELEASE

ifneq (,$(RELEASE))
    K_BUILD_TYPE := Release
else
    K_BUILD_TYPE := FastBuild
endif

K_OPTS += -Xmx8G
export K_OPTS

PATH:=$(K_BIN):$(PATH)
export PATH

PYTHONPATH:=$(K_LIB)
export PYTHONPATH

TANGLER:=$(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH:=$(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

.PHONY: all clean                                                           \
        deps deps-k deps-media                                              \
        defn defn-llvm defn-haskell                                         \
        build build-llvm build-haskell                                      \
        test test-execution test-python-generator test-random test-solidity
.SECONDARY:

all: build

clean:
	rm -rf $(BUILD_DIR)

# Dependencies
# ------------

K_JAR := $(K_SUBMODULE)/k-distribution/target/release/k/lib/java/kernel-1.0-SNAPSHOT.jar

deps: deps-k
deps-k: $(K_JAR)

$(K_JAR):
	cd $(K_SUBMODULE) && mvn package -DskipTests -Dproject.build.type=$(K_BUILD_TYPE)

# Building
# --------

MAIN_MODULE    := KMCD-GEN
SYNTAX_MODULE  := $(MAIN_MODULE)
MAIN_DEFN_FILE := kmcd-prelude

KOMPILE_OPTS :=

ifneq (,$(RELEASE))
    KOMPILE_OPTS += -O3
endif

k_files := $(MAIN_DEFN_FILE).k kmcd-prelude.k kmcd-props.k kmcd.k fixed-int.k kmcd-data.k kmcd-driver.k cat.k dai.k end.k flap.k flip.k flop.k gem.k join.k jug.k pot.k spot.k vat.k vow.k

llvm_dir    := $(DEFN_DIR)/llvm
haskell_dir := $(DEFN_DIR)/haskell

llvm_files    := $(patsubst %,$(llvm_dir)/%,$(k_files))
haskell_files := $(patsubst %,$(haskell_dir)/%,$(k_files))

llvm_kompiled    := $(llvm_dir)/$(MAIN_DEFN_FILE)-kompiled/interpreter
haskell_kompiled := $(haskell_dir)/$(MAIN_DEFN_FILE)-kompiled/definition.kore

build: build-llvm build-haskell
build-llvm:    $(llvm_kompiled)
build-haskell: $(haskell_kompiled)

# Generate definitions from source files

defn: defn-llvm defn-haskell
defn-llvm:    $(llvm_files)
defn-haskell: $(haskell_files)

concrete_tangle := .k:not(.symbolic),.concrete
symbolic_tangle := .k:not(.concrete),.symbolic

$(llvm_dir)/%.k: %.md
	@mkdir -p $(llvm_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(concrete_tangle)" $< > $@

$(haskell_dir)/%.k: %.md
	@mkdir -p $(haskell_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(symbolic_tangle)" $< > $@

# LLVM Backend

$(llvm_kompiled): $(llvm_files)
	kompile --debug --main-module $(MAIN_MODULE) --backend llvm              \
	        --syntax-module $(SYNTAX_MODULE) $(llvm_dir)/$(MAIN_DEFN_FILE).k \
	        --directory $(llvm_dir) -I $(llvm_dir)                           \
	        --emit-json                                                      \
	        $(KOMPILE_OPTS)

# Haskell Backend

$(haskell_kompiled): $(haskell_files)
	kompile --debug --main-module $(MAIN_MODULE) --backend haskell              \
	        --syntax-module $(SYNTAX_MODULE) $(haskell_dir)/$(MAIN_DEFN_FILE).k \
	        --directory $(haskell_dir) -I $(haskell_dir)                        \
	        --emit-json                                                         \
	        $(KOMPILE_OPTS)

# Test
# ----

KMCD_RANDOMSEED := ""

test: test-execution test-python-generator test-random test-solidity

execution_tests_random := $(wildcard tests/*/*.random.mcd)
execution_tests := $(wildcard tests/*/*.mcd)

test-execution: $(execution_tests:=.run)
test-python-generator: $(execution_tests_random:=.python-out)

init_random_seeds :=

test-random: mcd-pyk.py
	python3 $< random-test 1 1 $(init_random_seeds) --emit-solidity

test-solidity: $(patsubst %, tests/mkr-mcd-spec-sol-tests/src/%.t.sol, 01 02 03 04 05 06 07 08 09 10)
	cd tests/mkr-mcd-spec-sol-tests \
	    && dapp build               \
	    && dapp test

### Testing Parameters

TEST_BACKEND := llvm
KMCD         := ./kmcd
CHECK        := git --no-pager diff --no-index --ignore-all-space -R

RANDOM_TEST_RUNS  := 5
RANDOM_TEST_DEPTH := 200

TEST_KOMPILED := $(llvm_kompiled)
ifeq ($(TEST_BACKEND), haskell)
    TEST_KOMPILED := $(haskell_kompiled)
endif

tests/attacks/lucash-pot-end.random.mcd.%:  KMCD_RANDOMSEED="ddaddddadadadadd"
tests/attacks/lucash-pot.random.mcd.%:      KMCD_RANDOMSEED="aaaaaaaa"
tests/attacks/lucash-flap-end.random.mcd.%: KMCD_RANDOMSEED="b0b3bb0Zbba"
tests/attacks/lucash-flip-end.random.mcd.%: KMCD_RANDOMSEED="caccacaccacaaca"

### Testing Harnesses

tests/%.mcd.out: tests/%.mcd $(TEST_KOMPILED)
	RANDOMSEED=$(KMCD_RANDOMSEED) $(KMCD) run --backend $(TEST_BACKEND) $< > $@

tests/%.mcd.python-out: mcd-pyk.py $(TEST_KOMPILED)
	python3 $< random-test 0 1 $(KMCD_RANDOMSEED) 2>&1 > $@

tests/%.mcd.run: tests/%.mcd.out
	$(CHECK) tests/$*.mcd.out tests/$*.mcd.expected

tests/mkr-mcd-spec-sol-tests/%.t.sol: mcd-pyk.py
	python3 $< random-test $(RANDOM_TEST_DEPTH) $(RANDOM_TEST_RUNS) $(KMCD_RANDOMSEED) --emit-solidity --emit-solidity-file $@
