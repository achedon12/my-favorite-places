# Exercice 1 - Déployer Traefik sur Docker Swarm

Cet exercice guide le déploiement de Traefik et d'un service whoami sur un cluster Docker Swarm avec 3 noeuds.

## Prérequis

- Docker Swarm initialisé avec au moins 3 noeuds (1 manager + 2 workers)
- Ansible installé sur le machine hôte
- SSH accès aux noeuds Swarm
- Fichier hosts modifiable

## Étapes

### 1. Initialiser le cluster Docker Swarm (si pas déjà fait)

```bash
# Sur le manager
docker swarm init --advertise-addr <MANAGER_IP>

# Sur chaque worker
docker swarm join --token <TOKEN> <MANAGER_IP>:2377
```

Vérifiez avec :
```bash
docker node ls
```

### 2. Créer le réseau overlay "web"

```bash
docker network create --driver overlay --opt com.docker.network.driver.overlay.vxlanid=4096 web
```

### 3. Déployer la stack Traefik avec Docker

```bash
# Depuis le manager
docker stack deploy -c stacks/traefik-stack.yml traefik
```

Vérifiez le déploiement :
```bash
docker stack ls
docker service ls
docker ps
```

### 4. Mettre à jour le fichier hosts

Ajoutez les lignes suivantes au fichier `/etc/hosts` :

```
127.0.0.1  traefik.swarm.localhost
127.0.0.1  whoami.swarm.localhost
```

Sur Linux/Mac :
```bash
sudo bash -c 'echo "127.0.0.1  traefik.swarm.localhost" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1  whoami.swarm.localhost" >> /etc/hosts'
```

### 5. Accéder aux services

Ouvrez votre navigateur :

- **Traefik Dashboard** : http://traefik.swarm.localhost:8080/dashboard/
- **Whoami Service** : http://whoami.swarm.localhost

### 6. (Optionnel) Déployer avec Ansible

```bash
cd ansible
ansible-playbook -i inventory.ini deploy_traefik.yml
```

## Structure des fichiers

```
traefik/
├── README.md              # Ce fichier
├── ansible/
│   ├── ansible.cfg       # Configuration Ansible
│   ├── inventory.ini     # Inventaire des machines
│   └── deploy_traefik.yml # Playbook de déploiement
└── stacks/
    └── traefik-stack.yml # Stack Docker Compose pour Traefik
```

## Vérification

### Vérifier l'état de la stack

```bash
docker stack ps traefik
docker service logs traefik_traefik
docker service logs traefik_whoami
```

### Vérifier la résolution DNS

```bash
# Linux
nslookup traefik.swarm.localhost
ping traefik.swarm.localhost

# macOS
ping traefik.swarm.localhost
```

## Dépannage

### Traefik ne démarre pas

- Vérifiez que le manager a les contraintes de placement : `docker node inspect <MANAGER_ID>`
- Vérifiez les logs : `docker service logs traefik_traefik`

### Les services ne répondent pas

1. Vérifiez que le réseau overlay est bien créé :
   ```bash
   docker network ls | grep web
   ```

2. Vérifiez que les services sont en cours d'exécution :
   ```bash
   docker service ls
   ```

3. Vérifiez les logs des services :
   ```bash
   docker service logs traefik_traefik
   docker service logs traefik_whoami
   ```

### Problème DNS / hosts

- Vérifiez que `/etc/hosts` est bien rempli :
  ```bash
  cat /etc/hosts | grep swarm
  ```
- Sur Windows, modifiez `C:\Windows\System32\drivers\etc\hosts`

## Nettoyage

Pour supprimer la stack :

```bash
docker stack rm traefik
```

Pour quitter le Swarm (sur un worker) :

```bash
docker swarm leave
```

Pour quitter le Swarm (sur le manager) :

```bash
docker swarm leave --force
```
