# Quick Start - Traefik v3.6 sur Docker Swarm

## Pré-requis

✓ Docker Swarm initialisé avec au moins **3 nœuds** (1 manager + 2 workers)

Vérifiez:
```bash
docker node ls
```

## Démarrage en 3 étapes

### 1️⃣ Déployer

```bash
cd ansible-demo/traefik
./deploy.sh
```

### 2️⃣ Vérifier

```bash
./check.sh
```

### 3️⃣ Accéder

- **Dashboard Traefik** : http://traefik.swarm.localhost
- **Service Whoami** : http://whoami.swarm.localhost

## Tester le Load Balancing

Chaque requête va à une instance différente:

```bash
# Voir quel conteneur répond
for i in {1..5}; do
  echo -n "Requête $i → "
  curl -s http://whoami.swarm.localhost/ | grep Hostname
done
```

## Commandes rapides

| Commande | Description |
|----------|-------------|
| `./deploy.sh` | Déployer Traefik et whoami |
| `./check.sh` | Vérifier l'état des services |
| `./cleanup.sh` | Arrêter et supprimer tout |
| `docker stack ps traefik` | Voir les tâches |
| `docker service logs traefik_traefik` | Logs Traefik |
| `docker service logs traefik_whoami` | Logs Whoami |

## Scaler les services

```bash
# Augmenter les répliques whoami
docker service scale traefik_whoami=5

# Vérifier
docker service ls | grep whoami
```

## Dépannage rapide

### Services ne répondent pas
```bash
docker stack ps traefik
docker service logs traefik_traefik
```

### Ajouter /etc/hosts manuellement
```bash
echo "127.0.0.1  traefik.swarm.localhost" | sudo tee -a /etc/hosts
echo "127.0.0.1  whoami.swarm.localhost" | sudo tee -a /etc/hosts
```

### Port 80 occupé?
Modifier `stacks/traefik-stack.yml`:
```yaml
ports:
  - "8000:80"  # Utiliser le port 8000
```

## Pour plus de détails

Voir `README.md` pour la documentation complète.
