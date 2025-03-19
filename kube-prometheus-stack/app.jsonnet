[{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'kube-prometheus-stack',
    namespace: 'argocd',
    finalizers: [
      'resources-finalizer.argocd.argoproj.io'
    ]
  },
  spec: {
    destination: {
      namespace: 'monitoring',
      server: 'https://kubernetes.default.svc'
    },
    source: {
      helm: {
        releaseName: 'kube-prometheus-stack',
        values: importstr './values.yaml'
      },
      repoURL: 'https://prometheus-community.github.io/helm-charts',
      targetRevision: '70.0.2',
      chart: 'kube-prometheus-stack'
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
