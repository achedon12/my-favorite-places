# Exercice 1 - Déployer Traefik comme Reverse Proxy

Cet exercice guide le déploiement de Traefik, un reverse proxy et load balancer moderne, avec des services whoami sur Docker Compose.

## À propos de Traefik

**Traefik** est un reverse proxy et load balancer moderne conçu pour les architectures de conteneurs. Il offre :

- **Découverte automatique** : détecte les services via Docker, Kubernetes, etc.
- **Load balancing** : répartit le trafic entre les instances de service
- **HTTPS/TLS** : support natif des certificats
- **Dashboard** : interface de monitoring
- **Routage dynamique** : met à jour les routes automatiquement

## Architecture de l'exercice

```
┌─────────────────────────────────────────┐
│          Traefik (Port 80/8080)         │
│  - Reverse Proxy                        │
│  - Load Balancer                        │
│  - Dashboard sur :8080                  │
└─────────────────────────────────────────┘
          ↓                  ↓
   whoami1 (port 80) whoami2 (port 80) whoami3 (port 80)
   
   Tous les services communiquent via le réseau bridge 'web'
```

## Déploiement rapide

### 1. Lancer le déploiement automatique

```bash
cd ansible-demo/traefik
./deploy.sh
```

Le script va:
- Vérifier que Docker est actif
- Démarrer Traefik et 3 instances whoami
- Configurer le /etc/hosts
- Vérifier la disponibilité des services

### 2. Vérifier le déploiement

```bash
./check.sh
```

### 3. Accéder aux services

- **Traefik Dashboard** : http://traefik.swarm.localhost:8080
- **Service Whoami** : http://whoami.swarm.localhost

Chaque appel à whoami.swarm.localhost sera routé par Traefik vers l'une des 3 instances (load balancing round-robin).

## Déploiement manuel

### 1. Mettre à jour le /etc/hosts

```bash
sudo bash -c 'cat >> /etc/hosts << EOF
127.0.0.1  traefik.swarm.localhost
127.0.0.1  whoami.swarm.localhost
EOF'
```

### 2. Démarrer les services

```bash
cd ansible-demo/traefik
docker compose up -d
```

### 3. Vérifier le statut

```bash
docker compose ps
docker compose logs traefik
```

## Structure des fichiers

```
traefik/
├── README.md                    # Ce fichier
├── QUICK_START.md             # Guide de démarrage rapide
├── docker-compose.yml         # Configuration Docker Compose
├── deploy.sh                  # Script de déploiement automatique
├── check.sh                   # Script de vérification
├── cleanup.sh                 # Script de nettoyage
├── ansible/                   # Configuration Ansible (optionnel)
│   ├── deploy_traefik.yml
│   ├── inventory.ini
│   └── ansible.cfg
├── config/
│   ├── traefik.toml          # Configuration Traefik
│   └── traefik.yml           # Configuration alternative
└── stacks/
    └── traefik-stack.yml     # Stack Docker Swarm (optionnel)
```

## Concepts couverts

### 1. Reverse Proxy
Traefik reçoit les requêtes HTTP sur le port 80 et les forwarde vers les services appropriés selon l'hostname.

```
Client → traefik.swarm.localhost:80 → Traefik → whoami service
```

### 2. Load Balancing
Quand plusieurs instances du même service existent, Traefik les répartit automatiquement.

```
whoami.swarm.localhost → Load Balancer → [whoami1, whoami2, whoami3]
```

### 3. Service Discovery
Traefik détecte automatiquement les services via les labels Docker.

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.frontend.rule=Host:whoami.swarm.localhost"
```

### 4. DNS Local
Le fichier /etc/hosts permet la résolution locale sans serveur DNS externe.

```
127.0.0.1  traefik.swarm.localhost
127.0.0.1  whoami.swarm.localhost
```

## Commandes utiles

### Voir les logs
```bash
docker compose logs traefik
docker compose logs whoami1
docker compose logs -f traefik  # suivi en temps réel
```

### Inspecter les services
```bash
docker compose ps
docker compose exec whoami1 sh
```

### Tester les routes
```bash
# Test basique
curl -H "Host: whoami.swarm.localhost" http://localhost/

# Test du dashboard
curl http://localhost:8080/

# Voir l'équilibrage de charge
for i in {1..5}; do curl http://whoami.swarm.localhost/ | grep "Hostname"; done
```

### Redémarrer
```bash
docker compose restart traefik
docker compose restart whoami1 whoami2 whoami3
```

### Arrêter
```bash
./cleanup.sh
# ou
docker compose down
```

## Exemple de réponse whoami

Quand vous accédez à http://whoami.swarm.localhost, vous obtenez:

```
Hostname: whoami2
GET / HTTP/1.1
Host: whoami.swarm.localhost
User-Agent: curl/7.68.0
...
```

Cela montre:
- Quel conteneur a répondu (whoami1, whoami2, ou whoami3)
- Les détails de la requête HTTP
- Les headers reçus

## Avancé: Configuration Traefik

Le fichier `config/traefik.toml` configure Traefik:

```toml
[entryPoints]
  [entryPoints.web]
    address = ":80"

[providers]
  [providers.docker]
    endpoint = "unix:///var/run/docker.sock"
    exposedByDefault = false
```

Cela définit:
- **entryPoints.web** : Traefik écoute sur le port 80
- **providers.docker** : découverte automatique des services Docker
- **exposedByDefault** : seuls les services avec `traefik.enable=true` sont exposés

## Dépannage

### Services ne répondent pas

1. Vérifiez que les conteneurs tournent:
   ```bash
   docker compose ps
   ```

2. Vérifiez les logs de Traefik:
   ```bash
   docker compose logs traefik | tail -50
   ```

3. Testez la connectivité directe (sans Traefik):
   ```bash
   docker compose exec traefik curl http://whoami1:80/
   ```

### Traefik affiche 404

Cela signifie que:
- Traefik reçoit la requête (bon!)
- Mais ne trouve pas la route (mauvais)

Solutions:
1. Redémarrez Traefik: `docker compose restart traefik`
2. Vérifiez les labels sur les conteneurs: `docker inspect whoami1 | grep traefik`
3. Attendez 30 secondes que Traefik découvre les services

### Port 80 occupé

Si vous avez une autre application sur le port 80:

```bash
# Trouver ce qui utilise le port 80
sudo lsof -i :80

# Ou changer le port dans docker-compose.yml
# ports:
#   - "8000:80"  # au lieu de "80:80"
```

### Problèmes DNS

```bash
# Vérifier que /etc/hosts est correct
cat /etc/hosts | grep swarm

# Tester la résolution
ping traefik.swarm.localhost
nslookup whoami.swarm.localhost  # peut échouer si pas de DNS config
```

## Nettoyage

Pour arrêter et supprimer tous les services:

```bash
./cleanup.sh
# ou
docker compose down
```

Pour supprimer aussi les volumes:

```bash
docker compose down -v
```

## Ressources supplémentaires

- **Traefik Official Docs**: https://doc.traefik.io/
- **Docker Networking**: https://docs.docker.com/network/
- **Docker Compose**: https://docs.docker.com/compose/
- **Load Balancing Concepts**: https://en.wikipedia.org/wiki/Load_balancing_(computing)

## Notes

- Cette exercice utilise Traefik v1.7 pour la meilleure compatibilité
- Les services communicent via un réseau Docker bridge
- La découverte de services est automatique via les labels Docker
- Le dashboard Traefik affiche les routes et services en temps réel
