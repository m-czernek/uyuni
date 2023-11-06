#!/bin/bash
set -xe

if [ $# -ne 1 ];
then
	echo "Usage: ${0} server_id"
	echo "server_id is used for creating a unique folder"
	exit 1
fi

src_dir=$(cd $(dirname "$0")/../.. && pwd -P)
server_id=${1}
rm -rfv /tmp/test-all-in-one/server-logs/${server_id}
mkdir -p /tmp/test-all-in-one/server-logs/${server_id}
sudo -i podman exec uyuni-server-all-in-one-test bash -c "supportconfig -R /tmp/server-logs/${server_id} && chmod 644 /tmp/server-logs/${server_id}/scc_uyuni-server-all-in-one-test*.txz*"

