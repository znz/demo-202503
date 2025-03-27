[{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'argo-workflows',
    namespace: 'argocd',
    finalizers: [
      'resources-finalizer.argocd.argoproj.io'
    ]
  },
  spec: {
    destination: {
      namespace: 'argo-workflows',
      server: 'https://kubernetes.default.svc'
    },
    source: {
      helm: {
        releaseName: 'argo-workflows',
        values: importstr './values.yaml'
      },
      repoURL: 'https://argoproj.github.io/argo-helm',
      targetRevision: '0.45.11',
      chart: 'argo-workflows'
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
}]
