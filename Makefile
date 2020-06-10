# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn

DEPS_DIR                := deps
K_SUBMODULE             := $(DEPS_DIR)/k
PANDOC_TANGLE_SUBMODULE := $(DEPS_DIR)/pandoc-tangle
SOLTEST_SUBMODULE       := tests/mkr-mcd-spec-sol-tests

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

.PHONY: all clean clean-test                                                \
        deps deps-k deps-media                                              \
        defn defn-llvm defn-haskell                                         \
        build build-llvm build-haskell                                      \
        test test-execution test-python-generator test-random test-solidity
.SECONDARY:

all: build

clean: clean-test
	rm -rf $(BUILD_DIR)

clean-test:
	cd $(SOLTEST_SUBMODULE) && git clean -dffx ./

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

ALL_FILES          := $(patsubst %, %.k, $(SOURCE_FILES)) $(EXTRA_SOURCE_FILES)

defn:  defn-llvm  defn-haskell
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

KOMPILE_LLVM    := kompile --backend llvm    $(KOMPILE_OPTS) $(addprefix -ccopt ,$(KOMPILE_LLVM_OPTS))
KOMPILE_HASKELL := kompile --backend haskell $(KOMPILE_OPTS) $(KOMPILE_HASKELL_OPTS)

concrete_tangle := .k:not(.symbolic),.concrete
symbolic_tangle := .k:not(.concrete),.symbolic

# LLVM Backend


llvm_main_module   := KMCD-GEN
llvm_syntax_module := $(llvm_main_module)
llvm_main_file     := kmcd-prelude
llvm_dir           := $(DEFN_DIR)/llvm
llvm_files         := $(patsubst %,$(llvm_dir)/%,$(ALL_FILES))
llvm_kompiled      := $(llvm_dir)/$(llvm_main_file)-kompiled/interpreter

defn-llvm:  $(llvm_files)
build-llvm: $(llvm_kompiled)

$(llvm_dir)/%.k: %.md
	@mkdir -p $(llvm_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(concrete_tangle)" $< > $@

$(llvm_kompiled): $(llvm_files)
	$(KOMPILE_LLVM) $(llvm_dir)/$(llvm_main_file).k \
	        --main-module $(llvm_main_module)       \
	        --syntax-module $(llvm_syntax_module)   \
	        --directory $(llvm_dir) -I $(llvm_dir)

# Haskell Backend

haskell_main_module   := KMCD-GEN
haskell_syntax_module := $(haskell_main_module)
haskell_main_file     := kmcd-prelude
haskell_dir           := $(DEFN_DIR)/haskell
haskell_files         := $(patsubst %,$(haskell_dir)/%,$(ALL_FILES))
haskell_kompiled      := $(haskell_dir)/$(haskell_main_file)-kompiled/definition.kore

defn-haskell:  $(haskell_files)
build-haskell: $(haskell_kompiled)

$(haskell_dir)/%.k: %.md
	@mkdir -p $(haskell_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(symbolic_tangle)" $< > $@

$(haskell_kompiled): $(haskell_files)
	$(KOMPILE_HASKELL) $(haskell_dir)/$(haskell_main_file).k \
	        --main-module $(haskell_main_module)             \
	        --syntax-module $(haskell_syntax_module)         \
	        --directory $(haskell_dir) -I $(haskell_dir)

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

test-solidity: $(patsubst %, $(SOLTEST_SUBMODULE)/src/%.t.sol, 01 02 03 04 05 06 07 08 09 10)
	cd tests/mkr-mcd-spec-sol-tests \
	    && dapp build               \
	    && dapp test                \
	    || true

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

$(SOLTEST_SUBMODULE)/%.t.sol: mcd-pyk.py $(TEST_KOMPILED)
	python3 $< random-test $(RANDOM_TEST_DEPTH) $(RANDOM_TEST_RUNS) $(KMCD_RANDOMSEED) --emit-solidity --emit-solidity-file $@
