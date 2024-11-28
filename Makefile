# Frontend to  dune.

.PHONY: default build install uninstall test fmt clean

default: build

build:
		dune build

test:
		dune runtest -f

install:
		dune install

uninstall:
		dune uninstall

fmt:
		dune fmt

clean:
		dune clean
# Optionally, remove all files/folders ignored by git as defined in .gitignore (-X).
		git clean -dfXq
