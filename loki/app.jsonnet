std.manifestYamlDoc({
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'loki',
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
        releaseName: 'loki',
        values: importstr './values.yaml'
      },
      repoURL: 'https://grafana.github.io/helm-charts',
      targetRevision: '6.28.0',
      chart: 'loki'
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
