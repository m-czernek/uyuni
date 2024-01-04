#!/bin/env -S bash -euo pipefail

ENGINE="${CONTAINER_ENGINE:-podman}"
IMAGE='registry.opensuse.org/home/mczernek/containers/opensuse_factory_containerfile/uyuni-lint'
TAG='latest'
GITROOT="$(git rev-parse --show-toplevel)"
MOUNT="/mgr"

function help() {
  echo ""
  echo "This script lints Uyuni Python code with Black and Pylint"
  echo ""
  echo "Syntax: "
  echo ""
  echo "  $(basename ${0}) <FILE1> [FILE2 FILE3 ..]"
  echo ""
  echo "Files must provide path relative to the repository root, for example:"
  echo ""
  echo "  $(basename ${0}) python/spacewalk/satellite_tools/xmlWireSource.py"
  echo ""
  echo "You can provide a Python directory, in which case Black lints and Pylint" \
       "checks every Python file in the directory, for example:"
  echo ""
  echo "  $(basename ${0}) python"
}

function execute_black() {
  "$ENGINE" run --rm -v ${GITROOT}:${MOUNT} ${IMAGE}:${TAG} black -t py36 "$@"
}

function execute_lint() {
  "$ENGINE" run --rm -v ${GITROOT}:${MOUNT} ${IMAGE}:${TAG} pylint --rcfile /root/.pylintrc "$@"
}

function main() {
  if [[ $# -eq 0 ]]; then
    help
    exit 1
  fi
  execute_black "$@"
  execute_lint "$@"
}

main "$@"
