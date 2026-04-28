# Quick Start - Traefik sur Docker Swarm

## Démarrage rapide

### 1. Assurez-vous que Docker Swarm est initialisé

```bash
# Vérifier l'état du Swarm
docker node ls

# Si le Swarm n'est pas initialisé
docker swarm init --advertise-addr <VOTRE_IP>
```

### 2. Lancez le déploiement

```bash
cd ansible-demo/traefik
./deploy.sh
```

### 3. Accessez les services

- **Dashboard Traefik** : http://traefik.swarm.localhost:8080/dashboard/
- **Service Whoami** : http://whoami.swarm.localhost

## Commandes utiles

### Vérifier l'état
```bash
./check.sh
```

### Voir les logs
```bash
docker service logs traefik_traefik
docker service logs traefik_whoami
```

### Nettoyer
```bash
./cleanup.sh
```

## Dépannage

### Les services ne démarre pas

1. Vérifiez que vous êtes sur le manager :
   ```bash
   docker info | grep "Is Manager"
   ```

2. Vérifiez les logs :
   ```bash
   docker service logs traefik_traefik
   ```

### Les services répondent 504/502

- Attends que les services soient complètement déployés (30-60 secondes)
- Vérifie que le réseau overlay est actif : `docker network ls | grep web`

### Problème /etc/hosts

- Sur Linux/Mac, utilisez `sudo cat /etc/hosts` pour vérifier
- Sur Windows, éditez `C:\Windows\System32\drivers\etc\hosts`

## Pour plus de détails

Consulter `README.md` pour la documentation complète.
