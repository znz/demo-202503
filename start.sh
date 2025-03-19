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
    cat <<EOF | kind create cluster --name argocd --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 20080
    listenAddress: 127.0.0.1
    protocol: TCP
  - containerPort: 30443
    hostPort: 20443
    listenAddress: 127.0.0.1
    protocol: TCP
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF
    cilium install --values ./cilium/values.yaml
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
    jsonnet -S argocd/app.jsonnet | kubectl apply -f -
    #kubectl get secret/argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo
    #kubectl port-forward svc/argocd-server -n argocd 8080:443
fi

# git config core.sshCommand "ssh -F /dev/null -i $(pwd)/git-server/id_git -o IdentitiesOnly=yes -o NoHostAuthenticationForLocalhost=yes"
# git remote add demo1 ssh://git@localhost:20022/repos/demo1
# git push --set-upstream demo1 @

# https://kind.sigs.k8s.io/docs/user/local-registry/
reg_name='registry.registry.svc.cluster.local'
reg_port='5000'
REGISTRY_DIR="/etc/containerd/certs.d/${reg_name}:${reg_port}"
for node in $(kind get nodes -n argocd); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:${reg_port}"]
EOF
done

# 5. Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "${reg_name}:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

kubectl apply -f registry/namespace.yaml
kubectl apply -f registry

# docker pull ubuntu
# docker tag ubuntu registry.localhost:20080/ubuntu
# docker push registry.localhost:20080/ubuntu
# kubectl describe pod/ubuntu
# kubectl delete pod/ubuntu

kubectl apply -f argocd/ingress.yaml
argocd login argocd.localhost:20080 --username admin --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)" --plaintext
argocd repo add "ssh://git@$(ifconfig en0 | awk '$1=="inet"{print $2}'):20022/repos/demo1" --insecure-skip-server-verification --ssh-private-key-path ./git-server/id_git --project default
# argocd app create demo1 --repo "ssh://git@$(ifconfig en0 | awk '$1=="inet"{print $2}'):20022/repos/demo1" --path . --dest-namespace default --dest-server https://kubernetes.default.svc --sync-policy auto --auto-prune --self-heal
