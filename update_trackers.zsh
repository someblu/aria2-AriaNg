#!/bin/zsh

workDir="${HOME}/.aria2"
logPath="${workDir}/update_trackers.log"
confPath="${workDir}/aria2.conf"
write_to_log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") $1" >> "${logPath}"
}

echo -n > "${logPath}"
write_to_log "start updating"

until curl -IfsL https://github.com &>/dev/null; do
    write_to_log "wait for internet connection"
    sleep 5
done

file="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt"
trackers=$(curl -fsSL "${file}" | awk NF | paste -d , -s -)
write_to_log "new trackers: ${trackers}"

uuid=${$(uuidgen 2>/dev/null):-$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}' | tr '[a-z]' '[A-Z]')}
rpc_secret=$(perl -ne 'print if s/^rpc-secret=(.+$)/${1}/' "${confPath}")
rpc_listen_port=${$(perl -ne 'print if s/^rpc-listen-port=([0-9]+$)/${1}/' "${confPath}"):-6800}

send_to_server() {
  curl -H "Accept: application/json" -H "Content-type: application/json" -X "POST" -d "$json" -m 5 -s "localhost:${rpc_listen_port}/jsonrpc"
}

write_to_log "validate rpc server: localhost:${rpc_listen_port}"
json='{
  "jsonrpc": "2.0",
  "method": "aria2.getVersion",
  "id": "'${uuid}'",
  "params": [
    "token:'${rpc_secret}'"
  ]
}'
until send_to_server &>/dev/null; do
    write_to_log "wait for server response"
    sleep 5
done

json='{
  "jsonrpc": "2.0",
  "method": "aria2.changeGlobalOption",
  "id": "'${uuid}'",
  "params": [
    "token:'${rpc_secret}'",
    {
      "bt-tracker": "'${trackers}'"
    }
  ]
}'
write_to_log "prepare to send json:\n${json}"

write_to_log "localhost:${rpc_listen_port} respond with $(send_to_server)"
