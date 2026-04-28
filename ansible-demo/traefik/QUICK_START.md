# Quick Start - Traefik avec Docker Compose

## Démarrage rapide

### 1. Lancez le déploiement

```bash
cd ansible-demo/traefik
./deploy.sh
```

### 2. Vérifiez l'état

```bash
./check.sh
```

### 3. Accédez aux services

- **Dashboard Traefik** : http://traefik.swarm.localhost:8080/
- **Service Whoami** : http://whoami.swarm.localhost

## Commandes utiles

### Voir les logs
```bash
docker compose logs -f traefik
docker compose logs -f whoami1
```

### Redémarrer un service
```bash
docker compose restart traefik
```

### Arrêter tous les services
```bash
./cleanup.sh
```

## Informations de déploiement

- **3 instances** de whoami pour le load balancing
- **Traefik v1.7** comme reverse proxy et load balancer
- **Réseau bridge** pour la communication inter-conteneurs
- **Localhost** pour le développement local

## Dépannage

### Les services ne sont pas accessibles

1. Vérifiez que le /etc/hosts est correct :
   ```bash
   cat /etc/hosts | grep swarm
   ```

2. Redémarrez les services :
   ```bash
   docker compose down && docker compose up -d
   ```

3. Attendez 30 secondes que Traefik découvre les services

### Traefik affiche 404

- Cela signifie que Traefik fonctionne mais n'a pas découvert les services
- Redémarrez Traefik : `docker compose restart traefik`
- Vérifiez les logs : `docker compose logs traefik`

### Port 80 déjà utilisé

Si le port 80 est occupé, modifiez le docker-compose.yml :
```yaml
ports:
  - "8000:80"  # utiliser le port 8000 à la place
```

## Pour plus d'informations

Consultez `README.md` pour une documentation complète.
