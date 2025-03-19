{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'argocd',
    namespace: 'argocd',
    finalizers: [
      'resources-finalizer.argocd.argoproj.io'
    ]
  },
  spec: {
    destination: {
      namespace: 'argocd',
      server: 'https://kubernetes.default.svc'
    },
    source: {
      helm: {
        releaseName: 'argocd',
        values: importstr './values.yaml'
      },
      repoURL: 'https://argoproj.github.io/argo-helm',
      targetRevision: '7.8.11',
      chart: 'argo-cd'
    },
    project: 'default',
    syncPolicy: {
      automated: {
        prune: true,
        selfHeal: true
      }
    }
  }
}
