#!/bin/bash
set -euxo pipefail

## kind
kind delete cluster --name argocd
