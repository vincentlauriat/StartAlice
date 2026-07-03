# StartAlice

Launcher / updater natif macOS pour **OpenAlice**. Une petite app SwiftUI qui,
en un clic :

- **vérifie** si ton checkout OpenAlice est à jour (version locale vs dernière
  release GitHub, et retard de la branche sur `origin/master`) ;
- **met à jour** : sauvegarde ta config, `git merge origin/master`, `pnpm install` ;
- **lance** OpenAlice, au choix en **mode dev** (`pnpm dev`) ou en **app packagée**
  (`pnpm build && pnpm electron:dev`) ;
- **sauvegarde ta config** (`~/.openalice/`) à la demande.

## Où vivent tes paramètres

Tes réglages (brokers, credentials, providers) sont dans `~/.openalice/`
(`data/`, `provider-keys.json`, `sealing.key`) — **hors** du checkout git.
Ni la mise à jour ni le rebuild n'y touchent : tu ne reconfigures jamais rien.
StartAlice en fait quand même une copie horodatée (`~/.openalice/_config-backup-<date>`)
avant chaque mise à jour, par sécurité.

## Build & lancement

```bash
xcodegen generate
open StartAlice.xcodeproj      # puis Cmd+R
# ou en ligne de commande :
xcodebuild -scheme StartAlice -configuration Debug build
```

Au 1er lancement, macOS demandera l'autorisation **« Automation »** pour piloter
Terminal.app (les actions longues s'y exécutent pour que tu voies les logs).

## Configuration

Le chemin du checkout OpenAlice est éditable en bas de la fenêtre (défaut :
`~/DevApps/FinancesTools/OpenAlice`) et mémorisé.

## Architecture

- `Sources/StartAliceApp.swift` — point d'entrée SwiftUI.
- `Sources/ContentView.swift` — le panneau de contrôle.
- `Sources/AliceController.swift` — état + orchestration.
- `Sources/Runner.swift` — exécution shell (capture) et Terminal.app (osascript).
- `Resources/actions.sh` — **toute la logique** (status/update/dev/packaged/backup/restore),
  embarquée dans le bundle. Éditable sans recompiler l'app pour l'itération.

## Roadmap

Voir [PLAN.md](PLAN.md). À terme : icône, signature Developer ID + notarisation +
DMG (pipeline standard DevApps).
