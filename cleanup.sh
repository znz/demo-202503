#!/bin/bash
set -euxo pipefail
D=$(dirname "$0")

## git-server
{
    pushd "$D/git-server"
    docker compose down --remove-orphans --rmi local --volumes
    popd
}

## kind
kind delete cluster --name argocd
