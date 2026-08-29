# niffler-stocks

A [Niffler](https://github.com/gokr/niffler) component package: real-time
quotes for US-listed tickers (NASDAQ, NYSE, AMEX) via
[Nasdaq's public API](https://api.nasdaq.com). No API key, no configuration.

## Install

From a running Niffler harness, just say:

> Install the package `gokr/niffler-stocks`

The agent's `plugins` component searches GitHub (`topic:niffler-component`),
clones this repo and compiles it from source via the `builder` component
using your own toolchain, then spawns it — the tools appear in the
conversation immediately and come back on every boot. Each spawn is
human-approved.

One new tool:

- `stock_quote {symbol}` — latest price, change, change percent, volume and
  52-week range for a US-listed ticker

The component also declares a slash command for interactive UIs: once
installed, the TUI (or any UI following `docs/WIRE.md`) offers `/quote
<symbol>` with argument completion, implemented as a thin alias for the
same `stock_quote` tool.

## Uninstall / update

> Remove the niffler-stocks package
> Update the niffler-stocks package

## Publishing your own package

This repo is the layout convention:

```
niffler.json        # package manifest (required)
<comp>/main.nim     # one directory per component (Nim)
<comp>/main.go      # ... or Go
.github/workflows/  # optional: compile-check the package in CI; no binaries
                    # are published — installs always build from source
```

`niffler.json`:

```json
{
  "name": "my-package",
  "version": "1.0.0",
  "components": [
    {"name": "mything", "lang": "nim", "main": "mything/main.nim"}
  ]
}
```

- `name` is the package name users pass to `plugin_remove`/`plugin_update`.
- Each component gets one binary; `name`, `lang` (`nim` or `go`), `main`
  (entry source file) are required, `env` (required env var names) optional.
- To make the package discoverable, add the GitHub topic
  [`niffler-component`](https://github.com/topics/niffler-component) to
  your repo.
- Tag releases (`v0.1.0`) so installs pin to them. The included workflow
  then *verifies the package by running Niffler itself*: it boots a fresh
  harness, installs the package through `plugin_install` over the bus and
  calls the stock tool — so every release tag proves the package compiles
  and installs cleanly on Linux, and every PR gets the compile check. It
  publishes no binaries: each install compiles from source via the
  harness's `builder`, so every platform builds with its own toolchain.

Components are plain Niffler components — the SDK pattern is in
[Niffler's README](https://github.com/gokr/niffler#writing-a-component).
They run with the harness the moment they're spawned: doc comments become
the LLM's tool descriptions.

## License

MIT — see [LICENSE](LICENSE).
