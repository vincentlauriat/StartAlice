# TODOS — StartAlice

## En cours
- (rien)

## À faire (proche)
- [ ] Tester manuellement en cliquant : update, lancement dev/packaged
- [ ] Ajouter une vraie capture d'écran de l'app dans docs/ (TCC bloque la capture auto)

## Backlog
- [ ] Historique des backups de config avec restore ciblé
- [ ] Wall des contributeurs / CONTRIBUTORS.md quand la communauté grandit

## Fait
- [x] Ossature projet (project.yml, Sources, Resources/actions.sh, docs)
- [x] Build MVP vérifié (xcodebuild) + actions.sh correctement bundlé
- [x] Icône (make-icon.swift → iconset → .icns au build)
- [x] Pipeline release (release.sh + make-dmg-background.swift, inspiré MarkdownViewer)
- [x] git init + premier commit
- [x] Release 0.1.0 notarisée Apple + vérifiée
- [x] i18n EN/FR (défaut = langue machine, switch runtime dans Paramètres)
- [x] Détection + installation guidée d'OpenAlice (verbe `install` → git clone + pnpm install)
- [x] README EN + README.fr.md + LICENSE MIT + bannière (make-banner.swift)
