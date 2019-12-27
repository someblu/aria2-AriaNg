#!/bin/zsh

if ! type aria2c &>/dev/null; then
  brew install aria2
fi

workDir="${HOME}/.aria2"
confPath="${workDir}/aria2.conf"
sessPath="${workDir}/aria2.session"
set_key_value() {
  perl -pi -e "s|^#*$1=.*|$1=$2|" "${confPath}"
}

mkdir -p "${workDir}"
cp ./update_trackers.zsh "${workDir}"
cp ./aria2.default.conf "${confPath}"
touch "${sessPath}"

set_key_value "continue" "true"
set_key_value "enable-mmap" "true"
set_key_value "split" "$(sysctl -n hw.ncpu)"
set_key_value "max-connection-per-server" "5"
set_key_value "optimize-concurrent-downloads" "true"
set_key_value "save-session-interval" "60"
set_key_value "enable-rpc" "true"
set_key_value "rpc-allow-origin-all" "true"
set_key_value "bt-enable-lpd" "true"
set_key_value "bt-seed-unverified" "true"
set_key_value "bt-save-metadata" "true"
set_key_value "bt-require-crypto" "true"
set_key_value "peer-id-prefix" "-TR2770-"
set_key_value "user-agent" "Transmission/2.77"
set_key_value "input-file" "${sessPath}"
set_key_value "save-session" "${sessPath}"

set_key_value "dir" "${HOME}/Downloads"
set_key_value "rpc-secret" "${1:-$(whoami)}"
# set_key_value "http-proxy" "http-proxy=127.0.0.1:6152"

# set_key_value "daemon" "true"
# set_key_value "log" "${HOME}/.aria2/aria2.log"
# set_key_value "rpc-listen-all" "true"
# set_key_value "rpc-secure" "true"
# set_key_value "rpc-certificate" "/path/to/certificate.pem"
# set_key_value "rpc-private-key" "/path/to/certificate.key"

echo "all configured settings are listed below:"
echo "================"
echo "$(perl -ne 'print if /^(?!#)/' "${confPath}" | awk NF)"
echo "================"

tee "/usr/local/opt/aria2/homebrew.mxcl.aria2.plist" << END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>homebrew.mxcl.aria2</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/opt/aria2/bin/aria2c</string>
    </array>
    <key>ProcessType</key>
    <string>Adaptive</string>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false/>
      <key>Crashed</key>
      <true/>
      <key>AfterInitialDemand</key>
      <true/>
    </dict>
    <key>Sockets</key>
    <dict>
        <key>Listeners</key>
        <dict>
            <key>SockNodeName</key>
            <string>${$(perl -ne 'print if s/^rpc-listen-all=true/0.0.0.0/' "${confPath}"):-"127.0.0.1"}</string>
            <key>SockServiceName</key>
            <string>${$(perl -ne 'print if s/^rpc-listen-port=([0-9]+$)/${1}/' "${confPath}"):-6800}</string>
        </dict>
    </dict>
    <key>inetdCompatibility</key>
    <dict>
        <key>Wait</key>
        <true/>
    </dict>
  </dict>
</plist>
END

brew services start aria2

brew cask install ariang

tee "${HOME}/Library/LaunchAgents/aria2.updatetrackers.plist" << END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>aria2.updatetrackers</string>
    <key>ProgramArguments</key>
    <array>
      <string>${workDir}/update_trackers.zsh</string>
    </array>
    <key>ProcessType</key>
    <string>Background</string>
    <key>KeepAlive</key>
    <dict>
      <key>OtherJobEnabled</key>
      <dict>
        <key>homebrew.mxcl.aria2</key>
        <true/>
      </dict>
    </dict>
    <key>ThrottleInterval</key>
    <integer>1800</integer>
  </dict>
</plist>
END

launchctl load -w "${HOME}/Library/LaunchAgents/aria2.updatetrackers.plist"
