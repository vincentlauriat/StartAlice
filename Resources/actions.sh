#!/usr/bin/env bash
#
# StartAlice — actions déléguées, exécutées soit en capture (status) soit dans Terminal.app.
#
# Usage : actions.sh <status|update|dev|packaged|backup|restore> [chemin-repo]
#
# La config utilisateur d'OpenAlice vit dans ~/.openalice (data/, provider-keys.json,
# sealing.key) — HORS du checkout git. Ni le merge ni le rebuild n'y touchent ;
# `backup` en fait quand même une copie horodatée par sécurité.

set -uo pipefail

CMD="${1:-status}"
REPO="${2:-$HOME/DevApps/FinancesTools/OpenAlice}"
OA_HOME="${OPENALICE_HOME:-$HOME/.openalice}"

# --- backup / restore de la config utilisateur (~/.openalice) ---

backup_config() {
  local stamp dest
  stamp="$(date +%Y%m%d-%H%M%S)"
  dest="$OA_HOME/_config-backup-$stamp"
  mkdir -p "$dest"
  [ -d "$OA_HOME/data" ]                 && cp -a "$OA_HOME/data" "$dest/"
  [ -f "$OA_HOME/provider-keys.json" ]   && cp -a "$OA_HOME/provider-keys.json" "$dest/"
  [ -f "$OA_HOME/sealing.key" ]          && cp -a "$OA_HOME/sealing.key" "$dest/"
  echo "→ Config sauvegardée : $dest"
}

restore_latest() {
  local latest
  latest="$(ls -dt "$OA_HOME"/_config-backup-* 2>/dev/null | head -1)"
  if [ -z "$latest" ]; then echo "Aucun backup trouvé dans $OA_HOME."; return 1; fi
  echo "Restauration depuis : $latest"
  [ -d "$latest/data" ]               && cp -a "$latest/data" "$OA_HOME/"
  [ -f "$latest/provider-keys.json" ] && cp -a "$latest/provider-keys.json" "$OA_HOME/"
  [ -f "$latest/sealing.key" ]        && cp -a "$latest/sealing.key" "$OA_HOME/"
  echo "→ Config restaurée."
}

pause_end() {
  echo
  echo "— Terminé. Tu peux fermer cette fenêtre —"
}

case "$CMD" in
  status)
    if [ ! -d "$REPO/.git" ]; then
      echo "REPO_MISSING=$REPO"
      echo "LOCAL=?"; echo "LATEST=?"; echo "BEHIND=-1"; echo "BRANCH=?"
      exit 0
    fi
    cd "$REPO" || { echo "REPO_MISSING=$REPO"; exit 0; }
    echo "LOCAL=$(node -p "require('./package.json').version" 2>/dev/null || echo '?')"
    latest="$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null | sed 's/^v//')"
    echo "LATEST=${latest:-?}"
    git fetch origin --quiet 2>/dev/null || true
    if git rev-parse --verify --quiet origin/master >/dev/null 2>&1; then
      echo "BEHIND=$(git rev-list --count HEAD..origin/master 2>/dev/null || echo -1)"
    else
      echo "BEHIND=-1"
    fi
    echo "BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    ;;

  backup)  backup_config; pause_end ;;
  restore) restore_latest; pause_end ;;

  install)
    echo "=== StartAlice — installation d'OpenAlice ==="
    echo "Cible : $REPO"
    if [ -d "$REPO/.git" ]; then
      echo "✓ Déjà installé à cet emplacement."
      pause_end; exit 0
    fi
    for tool in git pnpm; do
      command -v "$tool" >/dev/null 2>&1 || {
        echo "✗ '$tool' introuvable dans le PATH."
        echo "  Installe Node/pnpm (ex: 'brew install node && npm i -g pnpm') puis relance."
        pause_end; exit 1
      }
    done
    mkdir -p "$(dirname "$REPO")"
    echo "→ git clone https://github.com/TraderAlice/OpenAlice.git"
    git clone https://github.com/TraderAlice/OpenAlice.git "$REPO" || { echo "✗ clone échoué."; pause_end; exit 1; }
    cd "$REPO" || exit 1
    echo "→ pnpm install (peut prendre plusieurs minutes)…"
    pnpm install || { echo "✗ pnpm install échoué."; pause_end; exit 1; }
    echo
    echo "✓ OpenAlice installé — version : $(node -p "require('./package.json').version" 2>/dev/null)"
    echo "  Reviens dans StartAlice et clique « Revérifier »."
    pause_end
    ;;

  update)
    echo "=== StartAlice — mise à jour d'OpenAlice ==="
    echo "Repo : $REPO"
    backup_config
    cd "$REPO" || { echo "✗ Repo introuvable."; exit 1; }
    echo
    echo "→ git fetch origin…"
    git fetch origin || { echo "✗ fetch échoué."; exit 1; }
    # On ne bloque que sur des modifs SUIVIES non-committées (elles pourraient être
    # écrasées par le merge). Les fichiers non suivis (.omc/, scripts perso…)
    # n'interfèrent pas avec un merge → on les laisse passer.
    if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
      echo "⚠️ Des modifications suivies non-committées bloquent le merge :"
      git status --short --untracked-files=no
      echo "   Commit ou stash ces changements puis relance."
      echo "   (Les fichiers non suivis sont ignorés — ils ne gênent pas la mise à jour.)"
      pause_end; exit 1
    fi
    echo "→ git merge origin/master…"
    if ! git merge origin/master; then
      echo "✗ Conflit de merge — à résoudre manuellement dans $REPO."
      pause_end; exit 1
    fi
    echo "→ pnpm install…"
    pnpm install || { echo "✗ pnpm install échoué."; pause_end; exit 1; }
    echo
    echo "✓ À jour — version : $(node -p "require('./package.json').version" 2>/dev/null)"
    pause_end
    ;;

  dev)
    cd "$REPO" || { echo "✗ Repo introuvable : $REPO"; exit 1; }
    echo "=== OpenAlice — mode dev (pnpm dev) ==="
    echo "L'interface s'ouvrira automatiquement dans ton navigateur dès qu'elle est prête."
    echo "(Garde cette fenêtre ouverte : elle fait tourner Alice. Ctrl-C pour arrêter.)"
    echo
    # On capture l'URL de l'interface depuis le banner Guardian
    #   [guardian] UI       →  http://localhost:<port>
    # puis on ouvre le navigateur quand Vite annonce qu'il est prêt ([vite] … localhost:<port>).
    # Tout passe par un pipe : les vars persistent dans l'unique subshell du while.
    esc=$(printf '\033')                       # pour retirer les codes couleur ANSI
    ui_url=""
    opened=0
    pnpm dev 2>&1 | while IFS= read -r line; do
      printf '%s\n' "$line"
      clean=$(printf '%s' "$line" | sed "s/${esc}\[[0-9;]*m//g")
      if [ -z "$ui_url" ] && printf '%s' "$clean" | grep -qE 'UI[[:space:]]*(→|->)'; then
        ui_url=$(printf '%s' "$clean" | grep -oE 'https?://localhost:[0-9]+' | head -1)
      fi
      if [ "$opened" -eq 0 ] && [ -n "$ui_url" ] && printf '%s' "$clean" | grep -qiE '\[vite\][^Z]*localhost:[0-9]+'; then
        open "$ui_url" && opened=1
        printf '\n>>> Interface ouverte : %s\n\n' "$ui_url"
      fi
    done
    ;;

  packaged)
    cd "$REPO" || { echo "✗ Repo introuvable : $REPO"; exit 1; }
    echo "=== OpenAlice — build + app packagée ==="
    echo "→ pnpm build…"
    pnpm build || { echo "✗ build échoué."; pause_end; exit 1; }
    echo "→ pnpm electron:dev…"
    exec pnpm electron:dev
    ;;

  *)
    echo "Commande inconnue : $CMD"
    echo "Usage : actions.sh <status|update|dev|packaged|backup|restore> [repo]"
    exit 2
    ;;
esac
