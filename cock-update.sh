#!/bin/bash

function state ()
{
  process=$1
  status=$(systemctl status "${process}" | grep "Active" | awk '{print $2}')
  loaded=$(systemctl status "${process}" | grep "Loaded" | awk '{print $2}')
  [[ "${loaded}" != "loaded" ]] && { echo "[-] Can't find this services"; exit 3; }
  [[ "${status}" == "active" ]] && return 1 || return 0
}

function stop ()
{
  process=$1
  state ${process}
  [[ $? == 1 ]] && { systemctl stop ${process}; echo "[+] ${process} stopped"; } || echo "[+] ${process} stopped"
}

function run ()
{
  process=$1
  state ${process}
  [[ $? == 0 ]] && { systemctl start ${process}; echo "[+] ${process} started"; }
  echo "[+] ${process} is $(systemctl status "${process}" | grep "Active" | awk '{print $2}')"
}

repo_path="/opt/code/github/jumpscale"
[[ $UID == 0 ]] && echo "[+] You login as root" || { echo "[-] You need to login as root"; exit 1; }
[[ -f '/etc/systemd/system/portal.service' ]] || { echo "[-] Can't find portal services"; exit 1; }
[[ -f '/etc/systemd/system/cockpit_main.service' ]] || { echo "[-] Can't find cockpit_main.service"; exit 1; }
[[ -f '/etc/systemd/system/cockpit_daemon_main.service' ]] || { echo "[-] Can't find cockpit_daemon_main.service"; exit 1; }

stop "portal.service"
stop "cockpit_main.service"
stop "cockpit_daemon_main.service"

[[ -d "${repo_path}/ays_jumpscale8" ]] && { cd "${repo_path}/ays_jumpscale8"; git pull; } || { echo "[-] can't find ${repo_path}/ays_jumpscale8"; exit 5; }
[[ -d "${repo_path}/jscockpit" ]] && { cd "${repo_path}/jscockpit"; git pull; } || { echo "[-] can't find ${repo_path}/jscockpit"; exit 5; }
[[ -d "${repo_path}/jumpscale_core8" ]] && { cd ${repo_path}/jumpscale_core8; git pull; } || { echo "[-] Can't find ${repo_path}/jumpscale_core8"; exit 5; }
[[ -d "${repo_path}/jumpscale_portal8" ]] && { cd ${repo_path}/jumpscale_portal8; git pull; } || {echo "[-] Can't find ${repo_path}/jumpscale_portal8"; exit 5; }

run "portal.service"
run "cockpit_main.service"
run "cockpit_daemon_main.service"

[[ -d "/optvar/cockpit_repos" ]] && cd /optvar/cockpit_repos" || echo "[-] Can't find dir /optvar/cockpit_repos"
ays discover
find /optvar/cockpit_repos/* -prune -type d | while read d; do cd "$d" && sleep 1 && ays restore; done

echo "[+] Update Finished :)"
exit 0
