#!/bin/zsh

workDir="${HOME}/.aria2"
logPath="${workDir}/update_trackers.log"
confPath="${workDir}/aria2.conf"
write_to_log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") $1" >> "${logPath}"
}

echo -n > "${logPath}"
write_to_log "start updating"

file="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt"

while :; do
  trackers=$(curl -m 5 -fsSL "${file}" 2>/dev/null | awk NF | paste -d , -s -)
  if [[ -z ${trackers} ]]; then
    write_to_log "wait for internet connection"
    sleep 5
  else
    break
  fi
done

uuid=${$(uuidgen 2>/dev/null):-$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}' | tr '[a-z]' '[A-Z]')}
rpc_secret=$(perl -ne 'print if s/^rpc-secret=(.+$)/${1}/' "${confPath}")
rpc_listen_port=${$(perl -ne 'print if s/^rpc-listen-port=([0-9]+$)/${1}/' "${confPath}"):-6800}
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

while :; do
  ret=$(curl -H "Accept: application/json" -H "Content-type: application/json" -X "POST" -d "$json" -m 5 -s "localhost:${rpc_listen_port}/jsonrpc" 2>/dev/null)
  if [[ -z ${ret} ]]; then
    write_to_log "wait for server response"
    sleep 5
  else
    write_to_log "localhost:${rpc_listen_port} respond with ${ret}"
    break
  fi
done
