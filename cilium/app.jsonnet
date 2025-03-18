std.manifestYamlDoc({
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'cilium',
    namespace: 'argocd',
    finalizers: [
      'resources-finalizer.argocd.argoproj.io'
    ]
  },
  spec: {
    destination: {
      namespace: 'kube-system',
      server: 'https://kubernetes.default.svc'
    },
    source: {
      helm: {
        releaseName: 'cilium',
        values: importstr './values.yaml'
      },
      repoURL: 'https://helm.cilium.io/',
      chart: 'cilium',
      targetRevision: '1.17.0'
    },
    project: 'default',
    syncPolicy: {
      automated: {
        prune: true,
        selfHeal: true
      },
      syncOptions: [
        "CreateNamespace=true",
        "ServerSideApply=true"
      ]
    }
  }
})
