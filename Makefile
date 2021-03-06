# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn

DEPS_DIR    := deps
K_SUBMODULE := $(DEPS_DIR)/k

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

SOLIDITY_TESTS := tests/solidity-test

.PHONY: all clean clean-test                                                \
        deps deps-k deps-media                                              \
        build build-llvm build-haskell                                      \
        test test-execution test-python-generator test-random test-solidity
.SECONDARY:

all: build

clean: clean-test
	rm -rf $(BUILD_DIR)

clean-test:
	cd $(SOLIDITY_TESTS) && git clean -dffx ./

# Dependencies
# ------------

K_JAR := $(K_SUBMODULE)/k-distribution/target/release/k/lib/java/kernel-1.0-SNAPSHOT.jar

deps: deps-k
deps-k: $(K_JAR)

$(K_JAR):
	cd $(K_SUBMODULE) && mvn package -DskipTests -Dproject.build.type=$(K_BUILD_TYPE)

# Building
# --------

SOURCE_FILES       := cat          \
                      dai          \
                      end          \
                      fixed-int    \
                      flap         \
                      flip         \
                      flop         \
                      gem          \
                      join         \
                      jug          \
                      kmcd         \
                      kmcd-data    \
                      kmcd-driver  \
                      kmcd-prelude \
                      kmcd-props   \
                      pot          \
                      spot         \
                      vat          \
                      vow

EXTRA_SOURCE_FILES :=

ALL_FILES          := $(patsubst %, %.md, $(SOURCE_FILES)) $(EXTRA_SOURCE_FILES)

tangle_concrete := k & (concrete | ! symbolic)
tangle_symbolic := k & (symbolic | ! concrete)

build: build-llvm build-haskell

KOMPILE_OPTS += --emit-json

ifneq (,$(RELEASE))
    KOMPILE_OPTS += -O3
endif

KOMPILE_LLVM_OPTS :=

ifeq (,$(RELEASE))
    KOMPILE_LLVM_OPTS += -g
    KOMPILE_OPTS      += --debug
endif

KOMPILE_HASKELL_OPTS :=

KOMPILE_LLVM    := kompile --backend llvm    --md-selector "$(tangle_concrete)" \
                   $(KOMPILE_OPTS) $(addprefix -ccopt ,$(KOMPILE_LLVM_OPTS))

KOMPILE_HASKELL := kompile --backend haskell --md-selector "$(tangle_symbolic)" \
                   $(KOMPILE_OPTS) $(KOMPILE_HASKELL_OPTS)

# LLVM Backend

llvm_main_module   := KMCD-GEN
llvm_syntax_module := $(llvm_main_module)
llvm_main_file     := kmcd-prelude
llvm_dir           := $(DEFN_DIR)/llvm
llvm_files         := $(ALL_FILES)
llvm_kompiled      := $(llvm_dir)/$(llvm_main_file)-kompiled/interpreter

build-llvm: $(llvm_kompiled)

$(llvm_kompiled): $(llvm_files)
	$(KOMPILE_LLVM) $(llvm_main_file).md          \
	        --main-module $(llvm_main_module)     \
	        --syntax-module $(llvm_syntax_module) \
	        --directory $(llvm_dir) -I $(CURDIR)

# Haskell Backend

haskell_main_module   := KMCD-GEN
haskell_syntax_module := $(haskell_main_module)
haskell_main_file     := kmcd-prelude
haskell_dir           := $(DEFN_DIR)/haskell
haskell_files         := $(ALL_FILES)
haskell_kompiled      := $(haskell_dir)/$(haskell_main_file)-kompiled/definition.kore

build-haskell: $(haskell_kompiled)

$(haskell_kompiled): $(haskell_files)
	$(KOMPILE_HASKELL) $(haskell_main_file).md       \
	        --main-module $(haskell_main_module)     \
	        --syntax-module $(haskell_syntax_module) \
	        --directory $(haskell_dir) -I $(CURDIR)

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

test-solidity: $(patsubst %, $(SOLIDITY_TESTS)/src/%.t.sol, 01 02 03 04 05 06 07 08 09 10)
	cd $(SOLIDITY_TESTS) \
	    && dapp build    \
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

$(SOLIDITY_TESTS)/%.t.sol: mcd-pyk.py $(TEST_KOMPILED)
	@mkdir -p $(dir $@)
	python3 $< random-test $(RANDOM_TEST_DEPTH) $(RANDOM_TEST_RUNS) $(KMCD_RANDOMSEED) --emit-solidity --emit-solidity-file $@
