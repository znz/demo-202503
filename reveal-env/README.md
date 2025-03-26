# reveal-env

```
docker build -t reveal-env:0.0.1 reveal-env
kind load docker-image reveal-env:0.0.1 --name argocd
kubectl apply -f reveal-env/namespace.yaml
kubectl apply -f reveal-env
```

open `http://reveal-env.localhost/`
