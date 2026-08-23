#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [[ ! -f secrets/stakecenter.yaml ]]; then
  echo "secrets/stakecenter.yaml does not exist; create and encrypt it during bootstrap." >&2
  exit 1
fi

tunnel_token="$(pulumi --cwd infra/cloudflare-gcp stack output --show-secrets tunnelToken)"
echo "::add-mask::$tunnel_token"

sops set secrets/stakecenter.yaml '["cloudflared"]["tunnelToken"]' "\"$tunnel_token\""

if git diff --quiet -- secrets/stakecenter.yaml; then
  echo "No SOPS secret changes."
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add secrets/stakecenter.yaml
git commit -m "Update encrypted appliance secrets"
git push
