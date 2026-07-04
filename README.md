<div align="center">

![StartAlice](docs/banner.png)

# StartAlice

**One-click updater & launcher for [OpenAlice](https://github.com/TraderAlice/OpenAlice) — the open-source AI trading agent.**

[![Latest release](https://img.shields.io/github/v/release/vincentlauriat/StartAlice?include_prereleases&sort=semver)](https://github.com/vincentlauriat/StartAlice/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-black?logo=apple)](https://github.com/vincentlauriat/StartAlice/releases)
[![Languages](https://img.shields.io/badge/i18n-EN%20%2F%20FR-blue)](#languages)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

🇬🇧 English · [🇫🇷 Français](README.fr.md)

</div>

---

## Why StartAlice?

OpenAlice moves fast — new betas ship almost every day. Keeping a local checkout
current normally means remembering to `git fetch`, merge `master`, re-run
`pnpm install`, and *then* relaunch the app. StartAlice turns that whole ritual
into **a single window with a single button**.

Open it and you instantly see whether you're on the latest version. One click
updates you (config safely backed up first), another launches OpenAlice — in
development mode or as the packaged desktop app. Not installed yet? StartAlice
clones and sets it up for you.

<div align="center">

| Without StartAlice | With StartAlice |
|---|---|
| `git fetch && git merge origin/master` | Click **Update** |
| `pnpm install` | *(done automatically)* |
| `pnpm dev` *or* build the app | Click **Launch** |
| "Am I even up to date?" | A green dot says so |

</div>

## What is OpenAlice?

[**OpenAlice**](https://github.com/TraderAlice/OpenAlice) is an open-source **AI
trading agent**. Instead of a rigid bot, it gives an AI a managed workspace where
it can research, iterate on quantitative strategies, and act — with live
**market data, technical analysis, and news** injected as context, and broker
connections isolated in a separate, hardware-wallet-style process.

- 🧠 **Native agent CLIs** (`claude`, `codex`, `opencode`, …) run inside
  persistent, sandboxable workspaces.
- 📈 **Trading context on tap** — market data, indicators, news, and a broker SDK
  surfaced over MCP.
- 🔐 **Separation of concerns** — credentials and trading state live in their own
  process; all state is plain files, no database.

StartAlice is the friendliest way to run it on your Mac and keep it current.

## Features

- ✅ **Live status** — local version vs. latest GitHub release, current branch,
  and how many commits you are behind `master`, at a glance.
- ⬇️ **One-click update** — backs up your config, merges `master`, reinstalls
  dependencies.
- ▶️ **Launch either way** — development mode (`pnpm dev`) or the packaged
  Electron app.
- 📦 **Guided install** — no checkout yet? StartAlice clones OpenAlice and runs
  the first install for you.
- 💾 **Config-safe by design** — your settings live in `~/.openalice/` (brokers,
  API keys, providers), *outside* the repo, so updates never touch them.
  StartAlice also snapshots them before every update.
- 🌍 **Bilingual** — English & French, following your Mac's language by default,
  switchable anytime.

## Install

1. Download the latest **`StartAlice-x.y.z.dmg`** from the
   [Releases page](https://github.com/vincentlauriat/StartAlice/releases).
2. Open the DMG and drag **StartAlice** into **Applications**.
3. Launch it. The app is **signed with a Developer ID and notarized by Apple**,
   so it opens with no security warning.

> **First action prompt:** the first time you click an action button, macOS asks
> for permission to control **Terminal** (Automation). Allow it — long-running
> commands run in a visible Terminal window so you can watch the logs.

### Requirements

- macOS 13 (Ventura) or later.
- [Node.js](https://nodejs.org) + [pnpm](https://pnpm.io) and `git` on your PATH
  (needed by OpenAlice itself). `git` ships with the Xcode Command Line Tools.

## Usage

| Button | What it does |
|---|---|
| **Update** | Backs up config → `git merge origin/master` → `pnpm install` |
| **Launch (dev)** | `pnpm dev` — Guardian spawns UTA + Alice + Vite (http://localhost:5173) |
| **Launch (app)** | `pnpm build` then the packaged Electron shell |
| **Back up my config** | Timestamped copy of `~/.openalice/` |
| **Install OpenAlice** | *(shown if no checkout found)* clones the repo + first install |

The checkout path is editable at the bottom of the window (default:
`~/DevApps/FinancesTools/OpenAlice`) and remembered between launches.

<a name="languages"></a>
## Languages

StartAlice ships in **English and French**. It follows your Mac's language on
first run (French if your system is French, English otherwise) and you can
override it anytime from **Settings → Language** (System / Français / English).
The switch is instant — no relaunch.

## Build from source

```bash
brew install xcodegen
git clone https://github.com/vincentlauriat/StartAlice.git
cd StartAlice
xcodegen generate
open StartAlice.xcodeproj      # then Cmd+R
```

Regenerate the icon or the release DMG:

```bash
swift Scripts/make-icon.swift preview          # preview the app icon
./Scripts/release.sh 0.1.0                      # signed + notarized DMG
```

## How it works

A small SwiftUI app. The UI is a thin control panel; all the heavy lifting
(status checks, git, pnpm, install, launch) lives in a single `actions.sh`
embedded in the app bundle and run inside Terminal.app for visible logs.

```
Sources/
  StartAliceApp.swift    entry point
  ContentView.swift      control panel + settings
  AliceController.swift   orchestration + status
  Localization.swift     EN/FR strings + language switch
  Runner.swift           shell (capture) & Terminal (osascript)
Resources/
  actions.sh             status / update / dev / packaged / backup / install
Scripts/
  make-icon.swift · make-banner.swift · make-dmg-background.swift · release.sh
```

The release pipeline (`Scripts/release.sh`) mirrors the proven flow of its sister
app *MarkdownViewer*: staged `ditto` copy, Developer ID codesign with Hardened
Runtime, Finder-laid-out DMG, Apple notarization, and staple.

## Contributing

Issues and ideas are welcome. StartAlice is intentionally small — a launcher,
not a framework — so the best contributions are focused: a bug fix, a new
locale, a UX refinement.

## License

[MIT](LICENSE) © Vincent Lauriat
