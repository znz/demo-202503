#!/bin/bash
set -euxo pipefail
D=$(dirname "$0")
repos=(
    demo1
)

## git-server
{
    pushd "$D/git-server"

    if [ ! -f id_git ]; then
        ssh-keygen -f id_git -N '' -t ed25519
    fi

    docker compose build
    mkdir -p repos
    for repo in "${repos[@]}"; do
        if [ ! -d "repos/$repo" ]; then
            docker compose run -t --rm sshd git init -q --bare "/repos/$repo"
        fi
    done
    docker compose up -d

    popd
}

## kind
# brew install kind
# brew install cilium-cli
if [ -z "$(kind get clusters -q)" ]; then
    kind create cluster --name argocd --config kind.yaml
    cilium install
    cilium status --wait
    #cilium connectivity test
    #cilium hubble enable
    cilium hubble enable --ui
    cilium status --wait
    #cilium hubble ui --open-browser=false
fi

# brew install helm
# brew install jsonnet
if [ -z "$(kubectl get ns -l 'kubernetes.io/metadata.name=argocd' -o name)" ]; then
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f argocd/values.yaml --wait
    #helm search repo -r argo-cd -o json | jq -r '.[0].version'
    jsonnet -S argocd/app.jsonnet | kubectl apply -f -
    #kubectl get secret/argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo
    #kubectl port-forward svc/argocd-server -n argocd 8080:443
fi
