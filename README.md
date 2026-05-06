# Infection test-framework playground

This repository is a testing environment for Infection developers working on
changes that affect Infection test-framework integrations.

Without it, verifying a change across Infection, the adapters, the extension
installer, and the adapter fixtures requires manually cloning projects, editing
Composer repositories, and wiring local symlinks, which is time-consuming and
error-prone. This repository automates that wiring so that local source
checkouts are used consistently by Composer.

## Layout

The repository is organised into two main areas:

- `sources/`: Git submodules containing the projects under development.
- `tests/`: end-to-end test fixtures copied from the adapter repositories.

The fixtures are copies, not submodules. They are generated from the adapter
repositories and adjusted so that their `composer.json` files reference the
local projects under `sources/`.

## Usage

Run all test-framework checks:

```shell
make test
```

To list the available commands, run:

```shell
make
# or
make help
```
