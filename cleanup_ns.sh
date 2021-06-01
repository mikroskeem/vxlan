#!/usr/bin/env bash
set -euo pipefail

for ns in $(ip netns list | cut -d' ' -f1); do
	for intf in $(ip netns exec "${ns}" ip --json link list | jq -r '.[] | .ifname'); do
		ip netns exec "${ns}" ip link set "${intf}" down
		if ! [ "${intf}" = "lo" ]; then
			ip netns exec "${ns}" ip link del "${intf}"
		fi
	done

	# Delete veth
	nsid="$(ip netns list | grep "^${ns}" | sed 's/.*(id: \(.\+\))/\1/')"
	if [ -n "${nsid}" ]; then
		for intf in $(ip --json link list | jq -r --argjson nsid "${nsid}" '.[] | select(.link_netnsid == $nsid) | .ifname'); do
			ip link del "${intf}"
		done
	fi

	ip netns del "${ns}" || true
done
