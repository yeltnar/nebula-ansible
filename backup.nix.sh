nix-shell -p bitwarden-cli -p nodejs_18 -p borgbackup --command './backup.sh backup_prune'
