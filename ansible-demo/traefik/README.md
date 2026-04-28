# Exercice 1 - Déployer Traefik v3.6 sur Docker Swarm

Cet exercice guide le déploiement de **Traefik v3.6**, un reverse proxy et load balancer moderne, sur un cluster **Docker Swarm** avec au moins 3 nœuds interconnectés.

## À propos de Traefik v3.6

**Traefik** est un reverse proxy/load balancer cloud-native avec:

- **Service Discovery** : détecte automatiquement les services via Docker Swarm, Kubernetes, etc.
- **Load Balancing** : répartit le trafic entre les instances
- **Dynamic Routing** : met à jour les routes en temps réel
- **Dashboard** : interface de monitoring et debugging
- **API Native** : configuration via labels Docker Swarm

## Architecture de l'exercice

```
Internet (Client)
    ↓
traefik.swarm.localhost:80 (Port 80)
    ↓
┌──────────────────────────────┐
│   Traefik v3.6 Reverse Proxy │
│   - Service Discovery        │
│   - Load Balancing           │
│   - Dashboard :8080          │
└──────────────────────────────┘
    ↓           ↓           ↓
┌────────┐ ┌────────┐ ┌────────┐
│ whoami │ │ whoami │ │ whoami │
│   #1   │ │   #2   │ │   #3   │
└────────┘ └────────┘ └────────┘

Tous les services communiquent via le réseau overlay "web"
```

## Prérequis

### 1. Docker Swarm initialisé avec au moins 3 nœuds

Vérifiez:
```bash
docker node ls
```

Si ce n'est pas fait:
```bash
# Sur le manager
docker swarm init --advertise-addr <MANAGER_IP>

# Sur chaque worker
docker swarm join --token <TOKEN> <MANAGER_IP>:2377
```

Vous devez avoir:
- 1 manager (ou plus)
- Au moins 2 workers (total ≥ 3 nœuds)

### 2. Vérifier la connectivité

```bash
# Depuis le manager, vérifier que les workers répondent
docker node ls

# Tous les nœuds doivent être en état "Ready"
```

## Déploiement rapide

### 1. Lancer le déploiement automatique

```bash
cd ansible-demo/traefik
./deploy.sh
```

Le script va:
- Vérifier que Docker Swarm est actif
- Créer le réseau overlay "web" (VXLAN)
- Déployer Traefik sur le manager
- Déployer 3 instances whoami
- Configurer le /etc/hosts
- Afficher les URLs pour accéder

### 2. Vérifier le déploiement

```bash
./check.sh
```

### 3. Accéder aux services

- **Dashboard Traefik** : http://traefik.swarm.localhost
- **Service Whoami** : http://whoami.swarm.localhost

Chaque appel sera routé par Traefik via load balancing round-robin.

## Déploiement manuel

### Étape 1: Vérifier que Swarm est prêt

```bash
docker node ls
docker info | grep -A 5 Swarm
```

### Étape 2: Créer le réseau overlay

```bash
docker network create --driver overlay \
  --opt com.docker.network.driver.overlay.vxlanid=4096 \
  web
```

Vérifiez:
```bash
docker network ls | grep web
```

### Étape 3: Déployer la stack

```bash
cd ansible-demo/traefik
docker stack deploy -c stacks/traefik-stack.yml traefik
```

### Étape 4: Configurer /etc/hosts

```bash
sudo bash -c 'cat >> /etc/hosts << EOF
127.0.0.1  traefik.swarm.localhost
127.0.0.1  whoami.swarm.localhost
EOF'
```

### Étape 5: Vérifier le déploiement

```bash
docker stack ps traefik
docker service ls
```

## Structure des fichiers

```
traefik/
├── README.md                      # Ce fichier
├── QUICK_START.md                # Guide de démarrage rapide
├── deploy.sh                     # Script de déploiement (Docker Stack)
├── check.sh                      # Script de vérification
├── cleanup.sh                    # Script de nettoyage
├── stacks/
│   └── traefik-stack.yml        # Stack pour Docker Swarm
└── ansible/                      # Configuration Ansible (optionnel)
    ├── deploy_traefik.yml
    ├── inventory.ini
    └── ansible.cfg
```

## Commandes utiles

### Voir l'état de la stack

```bash
# Tous les services et conteneurs
docker stack ps traefik

# Services uniquement
docker service ls

# Services d'une stack
docker service ls | grep traefik
```

### Voir les logs

```bash
# Logs Traefik
docker service logs traefik_traefik

# Logs Whoami
docker service logs traefik_whoami

# Suivi en temps réel
docker service logs -f traefik_traefik
```

### Tester les services

```bash
# Test simple
curl http://whoami.swarm.localhost/

# Voir le balancing (chaque appel va à une instance différente)
for i in {1..9}; do
  echo "Appel $i:"
  curl -s http://whoami.swarm.localhost/ | grep Hostname
done

# Test du dashboard
curl http://traefik.swarm.localhost/

# Avec header Host explicite
curl -H "Host: whoami.swarm.localhost" http://localhost/
```

### Scaling

```bash
# Augmenter le nombre d'instances whoami
docker service scale traefik_whoami=5

# Diminuer
docker service scale traefik_whoami=2

# Vérifier
docker service ls
```

### Redémarrer

```bash
# Redémarrer un service
docker service update --force traefik_traefik

# Redémarrer whoami
docker service update --force traefik_whoami
```

### Inspecter un service

```bash
# Détails du service Traefik
docker service inspect traefik_traefik

# Tâches/conteneurs d'un service
docker service ps traefik_traefik

# Réseaux
docker network inspect web
```

## Concepts clés

### 1. Docker Swarm

Docker Swarm est un orchestrateur de conteneurs qui permet:
- Déployer des services sur un cluster
- Gérer les ressources et la distribution
- Fournir du networking overlay
- Load balancer natif

```bash
# Mode Swarm
docker service create --name test nginx

# Vs mode standalone
docker run --name test nginx
```

### 2. Service Discovery

Traefik découvre les services via leurs **labels**:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.whoami.rule=Host(`whoami.swarm.localhost`)"
  - "traefik.http.services.whoami.loadbalancer.server.port=80"
```

### 3. Réseau Overlay

Le réseau "web" est de type **overlay** = accessible sur tous les nœuds:

```bash
docker network create --driver overlay web

# Propriétés:
# - Encryptage optionnel
# - Disponible sur tous les nœuds
# - Services découvrent les services via DNS interne (whoami → 10.x.x.x)
```

### 4. Load Balancing

Traefik répartit le trafic entre les répliques:

```bash
# 3 instances
docker service ls
# traefik_whoami   replicated   3/3

# Chaque appel va à une instance différente (round-robin)
curl http://whoami.swarm.localhost/
```

### 5. Dashboard

Traefik offre un dashboard pour visualiser:
- Les routes configurées
- Les services découverts
- Les instances actives
- Les statistiques

Accès: http://traefik.swarm.localhost:8080/dashboard/

## Exemple de réponse Whoami

```
Hostname: traefik_whoami.2.a1b2c3d4e5f6g7h8 (conteneur)
GET / HTTP/1.1
Host: whoami.swarm.localhost
User-Agent: curl/7.68.0
Accept: */*
Accept-Encoding: gzip, deflate
X-Forwarded-For: 127.0.0.1
X-Forwarded-Host: whoami.swarm.localhost
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Server: traefik_traefik.1.xyz
```

Les headers `X-Forwarded-*` sont ajoutés par Traefik.

## Dépannage

### Services ne démarrent pas

```bash
# Vérifier les logs
docker service logs traefik_traefik
docker service logs traefik_whoami

# Vérifier les tâches
docker service ps traefik_traefik
docker service ps traefik_whoami

# Si une tâche est en "Failed", voir le détail
docker service ps --no-trunc traefik_traefik
```

### Services répondent 404

Cela signifie:
- Traefik fonctionne ✓
- Mais ne trouve pas la route ✗

Solutions:
```bash
# 1. Vérifier les labels
docker service inspect traefik_whoami | grep -A 10 Labels

# 2. Redémarrer Traefik
docker service update --force traefik_traefik

# 3. Vérifier les logs
docker service logs traefik_traefik | grep -i "route\|whoami"
```

### Services ne se découvrent pas

Le provider Swarm a besoin:
- Access au `/var/run/docker.sock` ✓
- Les services ont les labels `traefik.enable=true` ✓
- Les services sont sur le réseau "web" ✓

Vérifiez:
```bash
# Labels
docker service inspect traefik_whoami | jq '.[0].Spec.Labels'

# Réseau
docker network inspect web | jq '.[0].Containers'
```

### Problème DNS

```bash
# Vérifier /etc/hosts
cat /etc/hosts | grep swarm

# Tester la résolution
ping traefik.swarm.localhost
nslookup whoami.swarm.localhost

# Si ça échoue, ajouter manuellement
sudo bash -c 'echo "127.0.0.1  traefik.swarm.localhost" >> /etc/hosts'
```

### Port 80 occupé

```bash
# Trouver ce qui utilise le port 80
sudo lsof -i :80

# Arrêter le processus ou modifier le port dans la stack
# ports:
#   - "8000:80"  # au lieu de "80:80"
```

## Avancé: Modifying the Stack

Editer et redéployer:

```bash
# Modifier le fichier
vim stacks/traefik-stack.yml

# Redéployer (met à jour ou crée)
docker stack deploy -c stacks/traefik-stack.yml traefik

# Vérifier les changements
docker service ps traefik_traefik
```

## Nettoyage

```bash
# Arrêter et supprimer
./cleanup.sh

# Ou manuellement
docker stack rm traefik
docker network rm web
```

## Notes importantes

- **Traefik v3.6** : syntaxe moderne pour router/services
- **Docker Swarm** : provider natif, pas besoin de socket accessible en lecture
- **Overlay Network** : encryptage et isolation des services
- **Dashboard** : disponible sur le port 8080
- **3 répliques whoami** : pour démontrer le load balancing

## Ressources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Traefik Swarm Provider](https://doc.traefik.io/traefik/v3.6/providers/swarm/)
- [Docker Networking](https://docs.docker.com/network/)
