[{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'k8s-monitoring',
    namespace: 'argocd',
    finalizers: [
      'resources-finalizer.argocd.argoproj.io'
    ]
  },
  spec: {
    destination: {
      namespace: 'logging',
      server: 'https://kubernetes.default.svc'
    },
    source: {
      helm: {
        releaseName: 'k8s-monitoring',
        values: importstr './values.yaml'
      },
      repoURL: 'https://grafana.github.io/helm-charts',
      targetRevision: '2.0.18',
      chart: 'k8s-monitoring'
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
