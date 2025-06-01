MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: build clean help

help: ## Show available targets
	@echo "pforth - Available targets"
	@echo ""
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

build: ## Assemble Z80 sources into a binary
	@./.make/build.sh

clean: ## Remove build artifacts
	rm -f bin/pforth.bin bin/pforth.asm bin/*.lst bin/*_test.bin bin/*_test.asm
