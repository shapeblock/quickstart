defaultImage: ${image}
defaultImageTag: ${tag}
defaultImagePullPolicy: Always
deployments:
  django:
    serviceAccountName: shapeblock-admin
    initContainers:
    - name: migrate
      command: ['python', 'manage.py', 'migrate']
      envConfigmaps:
      - envs
      envSecrets:
      - secret-envs
      resources:
        limits:
          cpu: "500m"
          memory: "512Mi"
        requests:
          cpu: 5m
          memory: 128M
    - name: create-user
      command: ['python', 'manage.py', 'create_sb_user']
      envConfigmaps:
      - envs
      envSecrets:
      - secret-envs
      resources:
        limits:
          cpu: "500m"
          memory: "512Mi"
        requests:
          cpu: 5m
          memory: 128M
    containers:
    - envConfigmaps:
      - envs
      envSecrets:
      - secret-envs
      name: django
      command: ['uvicorn', '--host', '0.0.0.0', '--port', '8000', '--workers', '1', 'shapeblock.asgi:application']
      ports:
      - containerPort: 8000
        name: app
      resources:
        limits:
          cpu: "1"
          memory: 2Gi
        requests:
          cpu: 5m
          memory: 128M
    podLabels:
      app: shapeblock
      release: backend
    replicas: 1
enabled: true
envs:
  DEBUG: "False"
  DATABASE_URL: postgres://${database_user}:${database_password}@database-postgresql/${database_name}
  POSTGRES_DB: shapeblock
  POSTGRES_USER: shapeblock
  POSTGRES_PASSWORD: xyTYDRE20blju6Qrywidumlt
  DATABASE_HOST: database-postgresql
  REDIS_HOST: redis-master
  %{ if cluster_dns != null }
  CLUSTER_DOMAIN: "${cluster_dns}"
  %{ endif }
  ALLOWED_HOSTS: "*"
  DEFAULT_FROM_EMAIL: ${email}
  SB_USERNAME: ${user}
  SB_USER_EMAIL: ${email}

generic:
  extraImagePullSecrets:
  - name: registry-creds
  labels:
    app: shapeblock
    release: backend
  usePredefinedAffinity: false

releasePrefix: shapeblock
secretEnvs:
  SECRET_KEY: "${secret_key}"
  GH_TOKEN: "${github_token}"
  FERNET_KEYS: "${fernet_keys}"
  SB_USER_PASSWORD: "${password}"

services:
  api:
    extraSelectorLabels:
      app: shapeblock
      release: backend
    ports:
    - port: 8000
    type: ClusterIP

%{ if cluster_dns != null }
ingresses:
  sb.${cluster_dns}:
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    certManager:
      originalIssuerName: letsencrypt-prod
      issuerType: cluster-issuer
    hosts:
    - paths:
      - serviceName: api
        servicePort: 8000
    ingressClassName: nginx
    name: backend
%{ endif }


serviceAccount:
  admin:
    clusterRole:
      name: cluster-admin
