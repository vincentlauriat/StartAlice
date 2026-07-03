# PLAN — StartAlice

## Phase 1 — MVP fonctionnel  ✅ (en cours de vérif build)
- [x] `project.yml` xcodegen (bundle `fr.lauriat.StartAlice`, Team KFLACS69T9)
- [x] App SwiftUI : panneau de statut + boutons update / dev / packaged / backup
- [x] `actions.sh` embarqué : status / update / dev / packaged / backup / restore
- [x] Chemin du repo éditable + persistant
- [x] Build vérifié via `xcodebuild` (BUILD SUCCEEDED, actions.sh embarqué dans le bundle)
- [x] Chaîne critique testée : bundle → actions.sh status → parse OK ; app se lance
- [ ] Test manuel interactif : cliquer update / dev / packaged

## Phase 2 — Finitions UX
- [x] Icône d'app (dégradé bleu→indigo + triangle « play ») — `Scripts/make-icon.swift`
      → `Resources/Assets.xcassets/AppIcon.appiconset`, câblée + reconstruite en `.icns` au build
- [ ] Historique / rollback des backups de config (liste + bouton restore ciblé)
- [ ] Détecter automatiquement le checkout si le chemin par défaut est absent
- [ ] Afficher la sortie de `update` in-app (au lieu de Terminal uniquement) — optionnel

## Phase 3 — Distribution (pipeline DevApps standard)
- [x] `Scripts/release.sh` (inspiré de MarkdownViewer, sans Sparkle/QL) :
      staging ditto → codesign Developer ID + Hardened Runtime → DMG à layout Finder
      → notarisation `AppliMacVincentGithub` → staple
- [x] `Scripts/make-dmg-background.swift` (fond installeur + flèche)
- [ ] **Exécuter** une vraie release signée/notarisée : `./Scripts/release.sh 0.1.0`
- [ ] Vérif indépendante : `spctl -a -t exec -vv`, `stapler validate`
- Note : Hardened Runtime activé au moment du codesign (`--options runtime`),
  `ENABLE_HARDENED_RUNTIME` reste NO dans project.yml (comme MarkdownViewer).

## Notes techniques
- Actions longues ouvertes dans **Terminal.app** (osascript) pour la visibilité des logs
  et pour survivre à la fermeture de l'app.
- `actions.sh` utilise un **login shell** (via `zsh -lc` côté Runner) pour hériter
  du PATH (node/pnpm/gh).
- La config utilisateur (`~/.openalice/`) est hors repo → jamais impactée par un merge ;
  `backup_config` la copie par précaution avant chaque update.
