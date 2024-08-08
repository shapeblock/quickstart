apiVersion: apps/v1
kind: Deployment
metadata:
  name: sb-operator
  namespace: ${namespace}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      application: sb-operator
  template:
    metadata:
      labels:
        application: sb-operator
    spec:
      serviceAccountName: sb-admin
      containers:
      - name: sb-operator
        image: ${image}:${tag}
        imagePullPolicy: Always
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 30
        env:
          - name: SB_URL
            value: ${sb_url}
          - name: CLUSTER_ID
            value: ${cluster_uuid}
