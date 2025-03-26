nix-shell -p bitwarden-cli -p nodejs_18 -p borgbackup --run './backup.sh backup_prune'
