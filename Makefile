# Settings
# --------

BUILD_DIR := .build
DEPS_DIR  := deps

INSTALL_PREFIX  := /usr
INSTALL_BIN     ?= $(INSTALL_PREFIX)/bin
INSTALL_LIB     ?= $(INSTALL_PREFIX)/lib/kmcd
INSTALL_INCLUDE ?= $(INSTALL_LIB)/include

KEVM_SUBMODULE      := $(DEPS_DIR)/evm-semantics
KEVM_INSTALL_PREFIX := $(INSTALL_LIB)/kevm
KEVM_BIN            := $(KEVM_INSTALL_PREFIX)/bin
KEVM_MAKE           := $(MAKE) --directory $(KEVM_SUBMODULE) INSTALL_PREFIX=$(KEVM_INSTALL_PREFIX)
KEVM                := kevm

KMCD_BIN     := $(BUILD_DIR)$(INSTALL_BIN)
KMCD_LIB     := $(BUILD_DIR)$(INSTALL_LIB)
KMCD_INCLUDE := $(KMCD_LIB)/include
KMCD_K_BIN   := $(KMCD_LIB)/kframework/bin
KMCD         := kmcd

K_OPTS += -Xmx8G
export K_OPTS

PATH:=$(CURDIR)/$(KMCD_BIN):$(CURDIR)/$(KMCD_LIB)/kevm/bin:$(CURDIR)/$(KMCD_LIB)/kevm/lib/kevm/kframework/bin:/usr/lib/kevm/kframework/bin:$(PATH)
export PATH

PYTHONPATH:=$(KMCD_LIB)/kevm/lib/kevm/kframework/lib/kframework:/usr/lib/kevm/kframework/lib/kframework:/usr/lib/kframework:$(PYTHONPATH)
export PYTHONPATH

SOLIDITY_TESTS := tests/solidity-test

.PHONY: all clean clean-test                                    \
        deps deps-k deps-media                                  \
        build build-llvm build-haskell                          \
        test test-execution test-python-generator test-solidity
.SECONDARY:

all: build

clean: clean-test
	rm -rf $(BUILD_DIR)

clean-test:
	cd $(SOLIDITY_TESTS) && git clean -dffx ./

# Dependencies
# ------------

deps:
	$(KEVM_MAKE) -j4 deps
	$(KEVM_MAKE) -j4 build-llvm build-haskell
	$(KEVM_MAKE) -j4 install DESTDIR=$(CURDIR)/$(BUILD_DIR)

# Building
# --------

SOURCE_FILES := cat          \
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

includes = $(patsubst %, $(KMCD_INCLUDE)/kframework/%.md, $(SOURCE_FILES))

build: build-llvm build-haskell

KOMPILE_INCLUDES = $(KMCD_INCLUDE)/kframework $(INSTALL_INCLUDE)/kframework
KOMPILE_OPTS    += $(addprefix -I , $(KOMPILE_INCLUDES))

ifneq (,$(RELEASE))
    KOMPILE_OPTS += -O3
endif

KOMPILE_LLVM_OPTS :=

ifeq (,$(RELEASE))
    KOMPILE_LLVM_OPTS += -g
    KOMPILE_OPTS      += --debug
endif

KOMPILE_HASKELL_OPTS :=

$(KMCD_BIN)/$(KMCD): $(KMCD)
	@mkdir -p $(dir $@)
	install $< $@

$(KMCD_INCLUDE)/kframework/%.md: %.md
	@mkdir -p $(dir $@)
	install $< $@

# LLVM Backend

llvm_dir           := llvm
llvm_main_module   := KMCD-GEN
llvm_syntax_module := $(llvm_main_module)
llvm_main_file     := kmcd-prelude.md
llvm_main_filename := $(basename $(notdir $(llvm_main_file)))
llvm_kompiled      := $(llvm_dir)/$(llvm_main_filename)-kompiled/interpreter

build-llvm: $(KMCD_LIB)/$(llvm_kompiled) $(KMCD_BIN)/$(KMCD)

$(KMCD_LIB)/$(llvm_kompiled): $(includes)
	$(KEVM) kompile --backend llvm $(llvm_main_file)              \
	    --directory $(KMCD_LIB)/$(llvm_dir)                       \
	    --main-module $(llvm_main_module)                         \
	    --syntax-module $(llvm_syntax_module)                     \
	    $(KOMPILE_OPTS) $(addprefix -ccopt ,$(KOMPILE_LLVM_OPTS))

# Haskell Backend

haskell_dir           := haskell
haskell_main_module   := VAT
haskell_syntax_module := $(haskell_main_module)
haskell_main_file     := vat.md
haskell_main_filename := $(basename $(notdir $(llvm_main_file)))
haskell_kompiled      := $(haskell_dir)/$(haskell_main_filename)-kompiled/definition.kore

build-haskell: $(KMCD_LIB)/$(haskell_kompiled) $(KMCD_BIN)/$(KMCD)

$(KMCD_LIB)/$(haskell_kompiled): $(includes)
	$(KEVM) kompile --backend haskell $(haskell_main_file) \
	    --directory $(KMCD_LIB)/$(haskell_dir)             \
	    --main-module $(haskell_main_module)               \
	    --syntax-module $(haskell_syntax_module)           \
	    $(KOMPILE_OPTS) $(KOMPILE_HASKELL_OPTS)

# Test
# ----

KMCD_RANDOMSEED := ""

test: test-execution test-python-generator test-solidity

execution_tests_random := $(wildcard tests/*/*.random.mcd)
execution_tests := $(wildcard tests/*/*Test.mcd)

test-execution: $(execution_tests:=.run)
test-python-generator: $(execution_tests_random:=.python-gen)

test-solidity: $(patsubst %, $(SOLIDITY_TESTS)/src/%.t.sol, 01 02 03 04 05 06 07 08 09 10)
	#cd $(SOLIDITY_TESTS) \
	#    && dapp build    \
	#    && dapp test

### Testing Parameters

TEST_BACKEND := llvm
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

tests/%.mcd.python-gen: mcd-pyk.py
	python3 $< random-test 0 1 $(KMCD_RANDOMSEED) 2>&1 > $@.out

tests/%.mcd.run: tests/%.mcd
	$(KMCD) run --backend $(TEST_BACKEND) --random-seed $(KMCD_RANDOMSEED) $< > $@.out
	$(CHECK) $@.out $@.expected
	rm -rf $@.out

$(SOLIDITY_TESTS)/%.t.sol: mcd-pyk.py
	@mkdir -p $(dir $@)
	python3 $< random-test $(RANDOM_TEST_DEPTH) $(RANDOM_TEST_RUNS) $(KMCD_RANDOMSEED) --emit-solidity --emit-solidity-file $@
