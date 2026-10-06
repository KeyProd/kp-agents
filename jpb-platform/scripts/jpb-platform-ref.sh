#!/usr/bin/env bash
# jpb-platform-ref.sh — affiche le chemin d'une copie à jour du dépôt privé
# KeyProd/jpb-platform, où vivent les règles appliquées par les skills du plugin
# (référentiel de conformité, standards, chart, implémentation de référence).
#
#   1. $JPB_PLATFORM_DIR s'il est défini : un clone de travail (équipe DevOps) ;
#   2. sinon une copie peu profonde en cache, rafraîchie à chaque appel :
#      ${XDG_CACHE_HOME:-~/.cache}/jpb-platform — en lecture seule, ne jamais la modifier.
#
# L'accès passe par gh : il faut un compte membre de l'organisation KeyProd
# (gh auth login). Sortie : le chemin sur stdout, les erreurs sur stderr.
set -euo pipefail

if [[ -n "${JPB_PLATFORM_DIR:-}" ]]; then
    if [[ -f "$JPB_PLATFORM_DIR/docs/features/plateforme-vxrail/architect.md" ]]; then
        echo "$JPB_PLATFORM_DIR"; exit 0
    fi
    echo "JPB_PLATFORM_DIR=$JPB_PLATFORM_DIR ne contient pas le dépôt jpb-platform." >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "L'outil GitHub en ligne de commande (gh) n'est pas installé : https://cli.github.com" >&2
    exit 2
fi
if ! gh auth status >/dev/null 2>&1; then
    echo "gh n'est pas connecté à GitHub : lancer « gh auth login »." >&2
    exit 3
fi

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/jpb-platform"
# Git s'authentifie par gh lui-même, quel que soit l'assistant d'identification du poste.
git_gh() { git -c credential.helper= -c 'credential.helper=!gh auth git-credential' "$@"; }

if [[ -d "$CACHE/.git" ]]; then
    if ! git_gh -C "$CACHE" fetch --quiet --depth 1 origin main; then
        echo "Impossible de rafraîchir $CACHE (accès à KeyProd/jpb-platform ?)." >&2
        exit 4
    fi
    git -C "$CACHE" reset --quiet --hard FETCH_HEAD
else
    mkdir -p "$(dirname "$CACHE")"
    if ! gh repo clone KeyProd/jpb-platform "$CACHE" -- --quiet --depth 1 >/dev/null 2>&1; then
        echo "Accès refusé à KeyProd/jpb-platform : le compte GitHub connecté doit être membre de l'organisation KeyProd (à demander à l'équipe DevOps)." >&2
        exit 4
    fi
fi
echo "$CACHE"
