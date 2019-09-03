# Settings
# --------

BUILD_DIR   := .build
DEFN_DIR    := $(BUILD_DIR)/defn
BUILD_LOCAL := $(CURDIR)/$(BUILD_DIR)/local

LIBRARY_PATH       := $(BUILD_LOCAL)/lib
C_INCLUDE_PATH     := $(BUILD_LOCAL)/include
CPLUS_INCLUDE_PATH := $(BUILD_LOCAL)/include
PKG_CONFIG_PATH    := $(LIBRARY_PATH)/pkgconfig

export LIBRARY_PATH
export C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH

DEPS_DIR                   := deps
K_SUBMODULE                := $(abspath $(DEPS_DIR)/k)
PANDOC_TANGLE_SUBMODULE    := $(DEPS_DIR)/pandoc-tangle
K_EDITOR_SUPPORT_SUBMODULE := $(DEPS_DIR)/k-editor-support

K_RELEASE := $(K_SUBMODULE)/k-distribution/target/release/k
K_BIN     := $(K_RELEASE)/bin
K_LIB     := $(K_RELEASE)/lib

PATH := $(K_BIN):$(PATH)
export PATH

PYTHONPATH := $(K_LIB)
export PYTHONPATH

TANGLER  := $(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH := $(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

.PHONY: all clean                                 \
        deps deps-k deps-tangle deps-media        \
        defn defn-llvm defn-haskell               \
        build build-llvm build-haskell build-java \
        test test-python-config                   \
        media media-sphinx
.SECONDARY:

all: build

clean:
	rm -rf $(BUILD_DIR)

clean-submodules:
	rm -rf $(DEPS_DIR)/k/submodule.timestamp $(DEPS_DIR)/k/mvn.timestamp $(DEPS_DIR)/pandoc-tangle/submodule.timestamp tests/eth2.0-specs/submodule.timestamp

# Dependencies
# ------------

deps: deps-k deps-tangle
deps-k:      $(K_SUBMODULE)/mvn.timestamp
deps-tangle: $(PANDOC_TANGLE_SUBMODULE)/submodule.timestamp

%/submodule.timestamp:
	git submodule update --init --recursive -- $*
	touch $@

$(K_SUBMODULE)/mvn.timestamp: $(K_SUBMODULE)/submodule.timestamp
	cd $(K_SUBMODULE) && mvn package -DskipTests
	touch $(K_SUBMODULE)/mvn.timestamp

# Building
# --------

MAIN_MODULE       := MKR-MCD
SYNTAX_MODULE     := $(MAIN_MODULE)
MAIN_DEFN_FILE    := mkr-mcd
KOMPILE_OPTS      ?=
LLVM_KOMPILE_OPTS := $(KOMPILE_OPTS) -ccopt -O2

k_files       = $(MAIN_DEFN_FILE).k mkr-mcd.k mkr-mcd-data.k
llvm_files    = $(patsubst %,$(DEFN_DIR)/llvm/%,$(k_files))
haskell_files = $(patsubst %,$(DEFN_DIR)/haskell/%,$(k_files))
java_files    = $(patsubst %,$(DEFN_DIR)/java/%,$(k_files))

llvm_kompiled    := $(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE)-kompiled/interpreter
haskell_kompiled := $(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE)-kompiled/definition.kore
java_kompiled    := $(DEFN_DIR)/java/$(MAIN_DEFN_FILE)-kompiled/timestamp

build: build-llvm build-haskell build-java
build-llvm:    $(llvm_kompiled)
build-haskell: $(haskell_kompiled)
build-java:    $(java_kompiled)

# Generate definitions from source files

defn: defn-llvm defn-haskell defn-java
defn-llvm:    $(llvm_files)
defn-haskell: $(haskell_files)
defn-java:    $(java_files)

$(DEFN_DIR)/llvm/%.k: %.md
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

$(DEFN_DIR)/haskell/%.k: %.md
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

$(DEFN_DIR)/java/%.k: %.md
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

# LLVM Backend

$(llvm_kompiled): $(llvm_files)
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend llvm                   \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/llvm -I $(DEFN_DIR)/llvm                      \
	                 $(LLVM_KOMPILE_OPTS)

# Haskell Backend

$(haskell_kompiled): $(haskell_files)
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend haskell                   \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/haskell -I $(DEFN_DIR)/haskell

# Java Backend

$(java_kompiled): $(java_files)
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend java                   \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/java/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/java -I $(DEFN_DIR)/java

# Test
# ----

test: test-python-config

test-python-config:
	./mcd-pyk.py

# Media
# -----

media: media-sphinx

deps-media: $(K_EDITOR_SUPPORT_SUBMODULE)/submodule.timestamp
	cd $(K_EDITOR_SUPPORT_SUBMODULE)/pygments && python3 setup.py install --user

# Sphinx Documentation

SPHINX_OPTS      :=
SPHINX_BUILD     := sphinx-build
SPHINX_DIR       := mkr-mcd-rtd
SPHINX_BUILD_DIR := $(BUILD_DIR)/$(SPHINX_DIR)
SPHINX_INDEX     := $(SPHINX_BUILD_DIR)/html/index.html
SPHINX_TAR       := $(SPHINX_BUILD_DIR).tar

SPHINX_INCLUDE := README.rst $(k_files:.k=.rst)
SPHINX_FILES   := $(patsubst %, $(SPHINX_BUILD_DIR)/%, $(SPHINX_INCLUDE))

ALLSPHINXOPTS := -d ../$(SPHINX_BUILD_DIR)/doctrees $(SPHINX_OPTS) .

media-sphinx: $(SPHINX_TAR)

$(SPHINX_TAR): $(SPHINX_INDEX)
	tar --directory $(BUILD_DIR) --create --verbose --file $@ $(SPHINX_DIR)

$(SPHINX_INDEX): $(SPHINX_FILES)
	mkdir -p $(SPHINX_BUILD_DIR)
	cp -r media/sphinx-docs/* $(SPHINX_BUILD_DIR)/
	cd $(SPHINX_BUILD_DIR)                                    \
	    && $(SPHINX_BUILD) -b dirhtml $(ALLSPHINXOPTS) html   \
	    && $(SPHINX_BUILD) -b text $(ALLSPHINXOPTS) html/text

$(SPHINX_BUILD_DIR)/%.rst: %.md $(SPHINX_BUILD_DIR)
	pandoc --from markdown --to rst $< | sed 's/.. code::/.. code-block::/' > $@

$(SPHINX_BUILD_DIR):
	mkdir -p $@
