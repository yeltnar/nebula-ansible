remote_date=$(curl -k https://hot.mini.lan/nebula/drew-lin-lap.date 2>/dev/null )
local_date=$(date -r /etc/nebula/ca.crt "+%s")

test "$remote_date" > "$local_date" && echo true || echo false
