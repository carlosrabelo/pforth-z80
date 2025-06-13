MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: build clean help run test

Z80_BIN := bin/pforth.bin

help: ## Show available targets
	@echo "pforth - Available targets"
	@echo ""
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

build: ## Assemble Z80 sources into a binary
	@./.make/build.sh

test: ## Build, check sources and labels; run assembly tests if z88dk-ticks is installed
	@./.make/test.sh

run: build ## Build and run on z88dk-ticks
	z88dk-ticks -iochar=1 -l 0 -pc 0 $(Z80_BIN)

clean: ## Remove build artifacts
	rm -f $(Z80_BIN) bin/pforth.asm bin/*.lst bin/*_test.bin bin/*_test.asm
