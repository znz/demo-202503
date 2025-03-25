#!/bin/bash
set -euxo pipefail
kind_cluster_name=argocd

## kind
# brew install kind
# brew install cilium-cli
if ! [[ " $(kind get clusters -q) " =~ " ${kind_cluster_name} " ]]; then
    cat <<EOF | kind create cluster --name "${kind_cluster_name}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 80
    listenAddress: 127.0.0.1
    protocol: TCP
  - containerPort: 30443
    hostPort: 443
    listenAddress: 127.0.0.1
    protocol: TCP
  - containerPort: 30080
    hostPort: 20080
    protocol: TCP
  - containerPort: 30443
    hostPort: 20443
    protocol: TCP
- role: worker
- role: worker
networking:
  ipFamily: dual
  disableDefaultCNI: true
  kubeProxyMode: none
EOF
fi

if [ -z "$(kubectl get ns -l 'kubernetes.io/metadata.name=cilium-secrets' -o name)" ]; then
    awk '/serviceMonitor:/,/^$/{$0=""}1' cilium/values.yaml > cilium/values.yaml.tmp
    cilium install --values cilium/values.yaml.tmp
    rm -f cilium/values.yaml.tmp
    # helm get -n kube-system values cilium
    cilium status --wait
    # open http://hubble.localhost:20080/

    #cilium connectivity test
    #cilium hubble enable
    #cilium hubble enable --ui
    #cilium status --wait
    #cilium hubble ui --open-browser=false
fi

# brew install helm
# brew install jsonnet
if [ -z "$(kubectl get ns -l 'kubernetes.io/metadata.name=argocd' -o name)" ]; then
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f argocd/values.yaml --wait
    #helm search repo -r argo-cd -o json | jq -r '.[0].version'
    jsonnet -y argocd/app.jsonnet | kubectl apply -f -
    #kubectl get secret/argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo
    #kubectl port-forward svc/argocd-server -n argocd 8080:443
fi

# docker pull ubuntu
# docker tag ubuntu registry.localhost:20080/ubuntu
# docker push registry.localhost:20080/ubuntu
# kubectl describe pod/ubuntu
# kubectl delete pod/ubuntu

kubectl apply -f argocd/ingress.yaml
argocd login argocd.localhost:20080 --username admin --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)" --plaintext

repo="https://github.com/znz/demo-202503"

# Create GitHub App
# see https://www.cncf.io/blog/2023/10/27/using-github-apps-with-argocd/ for details
# or https://zenn.dev/mille_feuille/articles/efd4411ad4474b for Japanese
GITHUB_APP_PRIVATE_KEY="$HOME/Downloads/argocd-demo-202503.2025-03-24.private-key.pem"
if [ -f "$GITHUB_APP_PRIVATE_KEY" ]; then
  argocd repo add "$repo" --github-app-id 1191117 --github-app-installation-id 63279757 --github-app-private-key-path "$GITHUB_APP_PRIVATE_KEY" --project default
elif ! argocd repo get "$repo"; then
  argocd repo add "$repo" --project default
fi

argocd app create demo1-argocd --repo "$repo" --path argocd --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
argocd app create demo1-cilium --repo "$repo" --path cilium --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
argocd app create demo1-kube-prometheus-stack --repo "$repo" --path kube-prometheus-stack --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
argocd app create demo1-loki --repo "$repo" --path loki --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
argocd app create demo1-k8s-monitoring --repo "$repo" --path k8s-monitoring --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
argocd app create demo1-redmine --repo "$repo" --path redmine --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
