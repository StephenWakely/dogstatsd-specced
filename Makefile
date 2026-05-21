DAFNY   := dafny
ENTRY   := src/Client.dfy
# Dafny appends -<lang> to the output prefix, so -o out/dogstatsd produces out/dogstatsd-go etc.
OUT     := out/dogstatsd

.PHONY: go rust python verify clean

go:
	$(DAFNY) translate go $(ENTRY) --no-verify -o $(OUT)

# Rust backend requires --enforce-determinism; current code uses :| (assign-such-that)
# in Sender.dfy and BufferPool.dfy which are non-deterministic. These must be rewritten
# with deterministic alternatives before Rust translation will succeed.
rust:
	$(DAFNY) translate rs $(ENTRY) --no-verify --enforce-determinism -o $(OUT)

python:
	$(DAFNY) translate py $(ENTRY) --no-verify -o $(OUT)

verify:
	$(DAFNY) verify $(ENTRY)

clean:
	rm -rf out
