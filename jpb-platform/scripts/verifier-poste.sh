#!/usr/bin/env bash
# verifier-poste.sh — état du poste pour les skills du plugin jpb-platform :
# outils, compte GitHub, appartenance à KeyProd, référentiel lu, version du plugin.
#
# Une ligne par contrôle, séparateur « | » :  <✅|⚠️|❌>|<contrôle>|<constat, ou geste à faire>
# La ligne « Référentiel » donne le chemin de la copie de jpb-platform ($JPB des skills).
# Code de sortie : 1 si un contrôle bloquant (❌) échoue, 0 sinon.
# Lecture seule : ne modifie rien, hormis le rafraîchissement de la copie en cache du
# référentiel (jpb-platform-ref.sh).
set -uo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bloquant=0
ligne() {
    printf '%s|%s|%s\n' "$1" "$2" "$3"
    [[ "$1" == "❌" ]] && bloquant=1
    return 0
}

# Plugin
version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ICI/../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
ligne "✅" "Plugin jpb-platform" "version ${version:-inconnue}"

# Outils
if v="$(git --version 2>/dev/null)"; then
    ligne "✅" "git" "${v#git version }"
else
    ligne "❌" "git" "absent — macOS : xcode-select --install ; installation bloquée : ticket à support@jpb-systeme.com"
fi
if v="$(gh --version 2>/dev/null | head -1)"; then
    ligne "✅" "gh (GitHub en ligne de commande)" "$(awk '{print $3}' <<< "$v")"
else
    ligne "❌" "gh (GitHub en ligne de commande)" "absent — https://cli.github.com ; installation bloquée : ticket à support@jpb-systeme.com"
fi

# Compte GitHub et organisation
gh_ok=0
if command -v gh >/dev/null 2>&1 && login="$(gh api user --jq .login 2>/dev/null)" && [[ -n "$login" ]]; then
    ligne "✅" "Compte GitHub" "$login"
    if etat="$(gh api user/memberships/orgs/KeyProd --jq '.state + " " + .role' 2>/dev/null)"; then
        case "$etat" in
            active*) ligne "✅" "Organisation KeyProd" "membre (${etat#active })"; gh_ok=1 ;;
            pending*) ligne "❌" "Organisation KeyProd" "invitation en attente — l'accepter : https://github.com/orgs/KeyProd/invitation" ;;
            *) ligne "❌" "Organisation KeyProd" "état « $etat » — voir l'équipe DevOps" ;;
        esac
    else
        ligne "❌" "Organisation KeyProd" "non membre — demander l'invitation à l'équipe DevOps"
    fi
    case "$(gh api user --jq .two_factor_authentication 2>/dev/null)" in
        true)  ligne "✅" "Double authentification (2FA)" "active" ;;
        false) ligne "❌" "Double authentification (2FA)" "inactive — l'activer : github.com → Settings → Password and authentication (exigée par KeyProd)" ;;
        *)     ligne "⚠️" "Double authentification (2FA)" "non vérifiable depuis le poste (GitHub ne l'expose pas au jeton de gh) — s'assurer qu'elle est active : github.com → Settings → Password and authentication (exigée par KeyProd)" ;;
    esac
elif command -v gh >/dev/null 2>&1; then
    ligne "❌" "Compte GitHub" "gh n'est pas connecté — lancer : gh auth login"
fi

# Référentiel (dépôt privé KeyProd/jpb-platform)
if [[ $gh_ok == 1 || -n "${JPB_PLATFORM_DIR:-}" ]]; then
    if jpb="$("$ICI/jpb-platform-ref.sh" 2>/tmp/jpb-ref.$$)"; then
        rev="$(git -C "$jpb" log -1 --format='%h du %cs' 2>/dev/null)"
        branche="$(git -C "$jpb" rev-parse --abbrev-ref HEAD 2>/dev/null)"
        if [[ -n "${JPB_PLATFORM_DIR:-}" ]]; then
            ligne "✅" "Référentiel" "$jpb — clone de travail (JPB_PLATFORM_DIR), branche $branche @ $rev"
        else
            ligne "✅" "Référentiel" "$jpb — copie à jour de main @ $rev"
        fi
    else
        ligne "❌" "Référentiel" "$(head -1 /tmp/jpb-ref.$$)"
    fi
    rm -f /tmp/jpb-ref.$$
else
    ligne "❌" "Référentiel" "illisible tant que les contrôles GitHub ci-dessus échouent"
fi

exit "$bloquant"
