# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn

DEPS_DIR:=deps
K_SUBMODULE:=$(abspath $(DEPS_DIR)/k)
PANDOC_TANGLE_SUBMODULE:=$(DEPS_DIR)/pandoc-tangle

K_RELEASE := $(K_SUBMODULE)/k-distribution/target/release/k
K_BIN     := $(K_RELEASE)/bin
K_LIB     := $(K_RELEASE)/lib
export K_RELEASE

K_BUILD_TYPE := FastBuild

PATH:=$(K_BIN):$(PATH)
export PATH

PYTHONPATH:=$(K_LIB)
export PYTHONPATH

TANGLER:=$(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH:=$(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

.PHONY: all clean                                              \
        deps deps-k deps-tangle deps-media                     \
        defn defn-llvm defn-haskell                            \
        build build-llvm build-haskell build-java              \
        test test-python-config test-python-run test-execution \
        update-test-execution
.SECONDARY:

all: build

clean:
	rm -rf $(BUILD_DIR)

clean-submodules:
	rm -rf $(DEPS_DIR)/k/submodule.timestamp $(DEPS_DIR)/k/mvn.timestamp $(DEPS_DIR)/pandoc-tangle/submodule.timestamp tests/eth2.0-specs/submodule.timestamp

# Dependencies
# ------------

deps: deps-k deps-tangle
deps-k: $(K_SUBMODULE)/mvn.timestamp
deps-tangle: $(PANDOC_TANGLE_SUBMODULE)/submodule.timestamp

%/submodule.timestamp:
	git submodule update --init --recursive -- $*
	touch $@

$(K_SUBMODULE)/mvn.timestamp: $(K_SUBMODULE)/submodule.timestamp
	cd $(K_SUBMODULE) && mvn package -DskipTests -Dproject.build.type=$(K_BUILD_TYPE)
	touch $(K_SUBMODULE)/mvn.timestamp

# Building
# --------

MAIN_MODULE    := KMCD-GEN
SYNTAX_MODULE  := $(MAIN_MODULE)
MAIN_DEFN_FILE := kmcd-prelude

KOMPILE_OPTS      :=
LLVM_KOMPILE_OPTS := $(KOMPILE_OPTS) -ccopt -O2

k_files := $(MAIN_DEFN_FILE).k kmcd-prelude.k kmcd-props.k kmcd.k kmcd-driver.k cat.k dai.k end.k flap.k flip.k flop.k gem.k join.k jug.k pot.k spot.k vat.k vow.k

llvm_dir    := $(DEFN_DIR)/llvm
haskell_dir := $(DEFN_DIR)/haskell
java_dir    := $(DEFN_DIR)/java

llvm_files    := $(patsubst %,$(llvm_dir)/%,$(k_files))
haskell_files := $(patsubst %,$(haskell_dir)/%,$(k_files))
java_files    := $(patsubst %,$(java_dir)/%,$(k_files))

llvm_kompiled    := $(llvm_dir)/$(MAIN_DEFN_FILE)-kompiled/interpreter
haskell_kompiled := $(haskell_dir)/$(MAIN_DEFN_FILE)-kompiled/definition.kore
java_kompiled    := $(java_dir)/$(MAIN_DEFN_FILE)-kompiled/timestamp

build: build-llvm build-haskell build-java
build-llvm:    $(llvm_kompiled)
build-haskell: $(haskell_kompiled)
build-java:    $(java_kompiled)

# Generate definitions from source files

defn: defn-llvm defn-haskell defn-java
defn-llvm:    $(llvm_files)
defn-haskell: $(haskell_files)
defn-java:    $(java_files)

$(llvm_dir)/%.k: %.md
	@mkdir -p $(llvm_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

$(haskell_dir)/%.k: %.md
	@mkdir -p $(haskell_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

$(java_dir)/%.k: %.md
	@mkdir -p $(java_dir)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

# LLVM Backend

$(llvm_kompiled): $(llvm_files)
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend llvm              \
	                 --syntax-module $(SYNTAX_MODULE) $(llvm_dir)/$(MAIN_DEFN_FILE).k \
	                 --directory $(llvm_dir) -I $(llvm_dir)                           \
	                 --emit-json                                                      \
	                 $(LLVM_KOMPILE_OPTS)

# Haskell Backend

$(haskell_kompiled): $(haskell_files)
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend haskell              \
	                 --syntax-module $(SYNTAX_MODULE) $(haskell_dir)/$(MAIN_DEFN_FILE).k \
	                 --directory $(haskell_dir) -I $(haskell_dir)                        \
	                 --emit-json                                                         \
	                 $(KOMPILE_OPTS)

# Java Backend

$(java_kompiled): $(java_files)
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend java              \
	                 --syntax-module $(SYNTAX_MODULE) $(java_dir)/$(MAIN_DEFN_FILE).k \
	                 --directory $(java_dir) -I $(java_dir)							  \
	                 --emit-json                                                      \
	                 $(KOMPILE_OPTS)

# Test
# ----

test: test-python-config test-python-run test-execution

### `pyk` tests

test-python-config:
	./mcd-pyk.py

test-python-run: tests/sneak-tx.json
	./mcd-pyk.py $<

### Execution tests

TEST_BACKEND := llvm
KMCD         := ./kmcd
CHECK        := git --no-pager diff --no-index
UPDATE       := cp

TEST_KOMPILED := $(llvm_kompiled)
ifeq ($(TEST_BACKEND), java)
    TEST_KOMPILED := $(java_kompiled)
endif
ifeq ($(TEST_BACKEND), haskell)
    TEST_KOMPILED := $(haskell_kompiled)
endif

tests/%.mcd.out: tests/%.mcd $(TEST_KOMPILED)
	$(KMCD) run --backend $(TEST_BACKEND) $< > $<.out

tests/%.mcd.run: tests/%.mcd.out
	$(CHECK) tests/$*.mcd.expected tests/$*.mcd.out

tests/%.mcd.update: tests/%.mcd.out
	$(UPDATE) tests/$*.mcd.out tests/$*.mcd.expected

execution_tests := $(wildcard tests/*/*.mcd)

test-execution: $(execution_tests:=.run)
update-test-execution: $(execution_tests:=.update)
