# Documentation — My Favorite Places (MFP)

Documentation du déploiement de la solution (CI / CD + infra Docker Swarm).

## 1. L'application

3 services :

- **client** : interface (Vite + nginx), écoute sur le port `80`, sert le site et proxy les appels `/api/` vers le server.
- **server** : API (Express / TypeScript), écoute sur le port `3000`, se connecte à la base.
- **db** : PostgreSQL 15 (user `postgres`, password `supersecret`, base `postgres`).

Le code est sur GitHub : `achedon12/my-favorite-places`.

## 2. Schéma CI / CD

![CI/CD MFP](ci_cd_mfp.png)

# 3. Travailler en local

1. Cloner le repo :
   ```bash
   git clone https://github.com/achedon12/my-favorite-places.git
   cd my-favorite-places/favorites-places
   ```

2. Lancer toute l'app en local (build des images depuis le code) :
   ```bash
   docker compose up --build -d
   ```

3. Accéder à l'app :
   - client : http://localhost:801
   - API : http://localhost:3000/api
   - test simple : http://localhost:3000/bonjour

4. Arrêter :
   ```bash
   docker compose down
   ```

# 4. Reproduire la production en local

Même app, mais avec les **images publiées par la CI** (aucun build, que `image:`) :

```bash
docker compose -f docker-compose.image.yml up -d
```

> Les images viennent de GHCR : `ghcr.io/achedon12/my-favorite-places-server:latest` et `...-client:latest`.

# 5. Les flows (CI)

Déclencheurs (dans `.github/workflows/ci-cd.yml`) :

- `git push` sur `main` / `master` → build + **push** des images sur GHCR.
- Pull Request vers `main` / `master` → build des images pour vérifier que ça compile (pas de push).

Le workflow a 2 jobs en parallèle :

- `build-client` : build l'image du client avec Docker Buildx.
- `build-server` : build l'image du server avec Docker Buildx.

# 6. Effets de bord des flows

- À chaque push sur `main`, 2 nouvelles images sont **poussées sur GHCR** (registry `ghcr.io`).
- Tags posés : `latest` + un tag basé sur le commit (`main-<sha>`).
- Un cache de build (`type=gha`) est stocké pour accélérer les builds suivants.

# 7. Les environnements

- **Local** : développer et tester → `docker compose up --build`.
- **CI** (GitHub Actions) : builder et publier les images → automatique au push.
- **Prod** (Docker Swarm) : faire tourner l'app sur le cluster → `docker stack deploy`.

# 8. Monter le cluster Docker Swarm (ansible-demo)

On simule un cluster avec 1 manager et 3 nodes (depuis le dossier `ansible-demo/`).

1. Lancer le manager et les 3 nodes :
   ```bash
   docker compose up --scale manager=1 --scale node=3 -d
   ```

2. Initialiser le swarm sur le manager :
   ```bash
   docker exec ansible-demo-manager-1 docker swarm init
   ```

3. Joindre les 3 nodes au manager (token donné par la commande `swarm init`, IP du manager = `172.80.11.3`) :
   ```bash
   docker exec ansible-demo-node-1 docker swarm join --token <TOKEN> 172.80.11.3:2377
   docker exec ansible-demo-node-2 docker swarm join --token <TOKEN> 172.80.11.3:2377
   docker exec ansible-demo-node-3 docker swarm join --token <TOKEN> 172.80.11.3:2377
   ```

4. Vérifier que les nodes sont dans le cluster :
   ```bash
   docker exec ansible-demo-manager-1 docker node ls
   ```

# 9. Déployer la stack (Traefik + Portainer + app)

1. Créer le réseau overlay de Traefik (une seule fois) :
   ```bash
   docker exec ansible-demo-manager-1 docker network create -d overlay --attachable web
   ```

2. Déployer la stack (Traefik + Portainer + services) :
   ```bash
   docker exec -i ansible-demo-manager-1 docker stack deploy -c - traefik < ansible-demo/traefik/stacks/traefik-stack.yml
   ```

3. Vérifier que tout tourne :
   ```bash
   docker exec ansible-demo-manager-1 docker stack services traefik
   ```

4. Mettre à jour le `/etc/hosts` puis ouvrir dans le navigateur :
   ```bash
   echo "127.0.0.1 traefik.swarm.localhost" | sudo tee -a /etc/hosts
   echo "127.0.0.1 portainer.swarm.localhost" | sudo tee -a /etc/hosts
   echo "127.0.0.1 whoami.swarm.localhost" | sudo tee -a /etc/hosts
   echo "127.0.0.1 vote.swarm.localhost" | sudo tee -a /etc/hosts
   echo "127.0.0.1 result.swarm.localhost" | sudo tee -a /etc/hosts
   echo "127.0.0.1 api_mfp.swarm.localhost" | sudo tee -a /etc/hosts
   ```
   - Traefik : http://traefik.swarm.localhost
   - Portainer : http://portainer.swarm.localhost
   - Whoami : http://whoami.swarm.localhost
   - Vote : http://vote.swarm.localhost
   - Result : http://result.swarm.localhost
   - api_mfp : http://api_mfp.swarm.localhost

> Traefik route les services via les URLs `*.swarm.localhost`. Portainer permet de superviser les stacks.


# 10. Ce que le dev doit surveiller

- Toujours travailler sur une branche, puis Pull Request : la PR build les images sans les publier.
- Un merge / push sur `main` publie automatiquement de nouvelles images `latest`.
- Vérifier que le pipeline GitHub Actions est **vert** avant de déployer.
- Ne pas mettre de secret en clair dans les fichiers (mots de passe DB = démo uniquement).

# 11. Pour déployer des stacks sur portainer :

1. Se connecter à Portainer (http://portainer.swarm.localhost, admin / password).
2. Aller dans "Stacks" → "Add stack".
3. Donner un nom à la stack, puis creer votre stack comme ceci :
    ```yaml
    services:
    
      db:
        image: postgres:15
        environment:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: supersecret
          POSTGRES_DB: postgres
        ports:
          - "5432:5432"
        volumes:
          - db-data:/var/lib/postgresql/data
        networks:
          - web
          - api_mfp
        deploy:
          replicas: 1
          placement:
            constraints:
              - node.role == manager
    
      server:
        image: ghcr.io/achedon12/my-favorite-places-server:latest
        ports:
          - 3000:3000
        depends_on:
          - db
        networks:
          - web
          - api_mfp
        deploy:
          replicas: 1
          placement:
            constraints:
              - node.role == manager
          labels:
            - "traefik.enable=true"
            - "traefik.http.routers.result.rule=Host(`api_mfp.swarm.localhost`)"
            - "traefik.http.routers.result.entrypoints=web"
            - "traefik.http.services.result.loadbalancer.server.port=3000"
    
    networks:
      web:
        external: true
      api_mfp:    
          driver: overlay
    
    volumes:
      db-data:
    ```
4. Cliquer sur "Deploy the stack" et vérifier que les services sont bien créés.
5. Accéder à l'API : http://api_mfp.swarm.localhost/api et http://api_mfp.swarm.localhost/bonjour

Exercices non traités : 

- Exercice 2 (Shepherd)


# Résultats exercices

# ansible-demo 🚀

Démonstration d'Ansible pour gérer un cluster **Docker Swarm** en utilisant **Docker-in-Docker (DinD)** pour simuler un cluster de plusieurs nœuds Docker.

## 📋 Vue d'ensemble

Ce projet montre comment :
- Lancer un cluster Docker Swarm composé d'1 manager et de plusieurs workers
- Utiliser Ansible pour automatiser l'initialisation du cluster
- Gérer rapidement une infrastructure multi-nœuds sans VMs physiques

**Architecture** : Containers Docker interconnectés via un réseau Docker, avec Python et sudo pré-installés pour la compatibilité Ansible.

---

## 🔧 Prérequis

### Requis
- **Docker** (version 20.10+)
- **Docker Compose** (version 1.29+)
- **Ansible** (version 2.10+)
- **Plugin Docker pour Ansible** : `community.docker`

### Installation rapide

```bash
# 1. Installer Ansible (si nécessaire)
sudo apt-get update
sudo apt-get install -y ansible

# 2. Installer le plugin Docker pour Ansible
ansible-galaxy collection install community.docker

# 3. Vérifier les installations
ansible --version
docker --version
docker compose version
```

---

## 🚀 lancer ansible-demo

### Étape 1 : Cloner/Accéder au répertoire

```bash
cd esgi-2603-my-favorite-places/ansible-demo
```

### Étape 2 : Construire les images Docker

```bash
docker compose up -d

# Ou avec une autre configuration (exemple : 1 manager + 3 workers)
docker compose up --scale manager=1 --scale node=3 -d
```

**Vérifier que les containers sont en cours d'exécution :**
```bash
docker ps
```

Vous devriez voir :
- `esgi-2603-my-favorite-places-manager-1`
- `esgi-2603-my-favorite-places-node-1`
- `esgi-2603-my-favorite-places-node-2`
- `esgi-2603-my-favorite-places-node-3`
- `esgi-2603-my-favorite-places-node-4`

### Étape 4 : Exécuter le playbook Ansible

```bash
# Option 1 : Utiliser le script fourni
bash ansible.sh

# Option 2 : Exécuter directement
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml

# Option 3 : Mode verbeux (pour voir les détails)
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml -v

# Option 4 : Mode très verbeux
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml -vv
```

**Ce que fait le playbook :**

1. **Initialise le Swarm sur le manager**
   ```bash
   docker swarm init
   ```

2. **Récupère le token de jointure des workers**
   ```bash
   docker swarm join-token worker -q
   ```

3. **Ajoute chaque worker au cluster**
   ```bash
   docker swarm join --token <TOKEN> 172.80.11.3:2377
   ```

### Étape 5 : Vérifier que le cluster est opérationnel

```bash
# Lister tous les nœuds du cluster
docker exec esgi-2603-my-favorite-places-manager-1 docker node ls

# Vérifier l'état du manager
docker exec esgi-2603-my-favorite-places-manager-1 docker info | grep -A 5 "Swarm"

# Vérifier l'état d'un worker
docker exec esgi-2603-my-favorite-places-node-1 docker info | grep -A 5 "Swarm"
```

**Sortie attendue :**
```
ID                            HOSTNAME                    STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
xxxxxxxxxxxxxxxxxxxxxxx       esgi-2603-...-manager-1    Ready     Active         Leader           29.x.x
yyyyyyyyyyyyyyyyyyyyyyy       esgi-2603-...-node-1       Ready     Active                          29.x.x
zzzzzzzzzzzzzzzzzzzzzzz       esgi-2603-...-node-2       Ready     Active                          29.x.x
...
```

---

## 📊 Fichier d'inventaire Ansible

Le fichier `ansible/inventory.ini` configure comment Ansible se connecte aux containers :

```ini
[managers]
# Nom du container manager (généré par Docker Compose)
esgi-2603-my-favorite-places-manager-1

[managers:vars]
# Utilise la connection Docker (via socket)
ansible_connection=community.docker.docker
# IP du manager (pour Docker Swarm)
manager_ip=172.80.11.3

[workers]
# Noms des containers workers
esgi-2603-my-favorite-places-node-1
esgi-2603-my-favorite-places-node-2
esgi-2603-my-favorite-places-node-3
esgi-2603-my-favorite-places-node-4

[workers:vars]
ansible_connection=community.docker.docker
```

---

## 📝 Résumé des commands essentielles

```bash
# Lancement complet (à partir de zéro)
cd ansible-demo
docker compose build
docker compose up -d
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml

# Vérification
docker exec esgi-2603-my-favorite-places-manager-1 docker node ls

# Arrêter le cluster
docker compose down

# Recommencer (nettoyer avant)
docker compose down -v
docker compose build
docker compose up -d
bash ansible.sh
```

# Exercice 1

1. Lancer le docker compose avec une configuration de 1 manager et 3 workers :
   ```bash
     docker compose up --scale manager=1 --scale node=3 -d
   ```

2. init le swarm cluster et joindre les nodes au manager :
   ```bash
      docker exec ansible-demo-manager-1 docker swarm init
   ```

3. ajouter les nodes au cluster :
   ```bash
   docker exec ansible-demo-node-1 docker swarm join --token SWMTKN-1-26nnxx8xx7b3kl9o8szwkeb599oz5zsfcbmhwbwdq5e5oppuim-64j9zro0ynztepa5rycysxk52 172.80.11.3:2377
   docker exec ansible-demo-node-2 docker swarm join --token SWMTKN-1-26nnxx8xx7b3kl9o8szwkeb599oz5zsfcbmhwbwdq5e5oppuim-64j9zro0ynztepa5rycysxk52 172.80.11.3:2377
   docker exec ansible-demo-node-3 docker swarm join --token SWMTKN-1-26nnxx8xx7b3kl9o8szwkeb599oz5zsfcbmhwbwdq5e5oppuim-64j9zro0ynztepa5rycysxk52 172.80.11.3:2377
   ```

   > docker exec ansible-demo-manager-1 docker node ls
   > Commande pour vérifier que les nodes sont bien dans le cluster

4. Ajouter l'overlay network pour traefik :
   ```bash
     docker exec ansible-demo-manager-1 docker network create -d overlay --attachable web
   ```

5. Déployer la stack traefik :
   ```bash
   docker exec -i ansible-demo-manager-1 docker stack deploy -c - traefik < traefik/stacks/traefik-stack.yml
   ```

6. Vérifier que les services sont en cours d'exécution :
   ```bash
     docker exec ansible-demo-manager-1 docker stack services traefik
   ```

# Exercice 2 et 3

Rajouté dans treafik-stack.yml

# Exercice 1

ajout de la route /bonjour dans le dossier [favorites-places](../favorites-places)

ajout du nouveau docker compose dans le dossier [favorites-places](../favorites-places)


```yaml
services:

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: supersecret
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - web
      - api_mfp
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

  server:
    image: ghcr.io/achedon12/my-favorite-places-server:latest
    ports:
      - 3000:3000
    depends_on:
      - db
    networks:
      - web
      - api_mfp
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.result.rule=Host(`api_mfp.swarm.localhost`)"
        - "traefik.http.routers.result.entrypoints=web"
        - "traefik.http.services.result.loadbalancer.server.port=3000"

networks:
  web:
    external: true
  api_mfp:    
      driver: overlay

volumes:
  db-data:


```

# Exercice 2 :

je ne suis pas allez jusqu'a Shepherds (exo 2) puisque mon http://api_mfp.swarm.localhost/bonjour ou http://api_mfp.swarm.localhost/api ne tourne pas

![image](img.png)
![image](img_1.png)
![image](img_2.png)

# stack traefik-stack.yml

```yaml
services:
  traefik:
    image: traefik:v3.6
    networks:
      - web
    ports:
      - 80:80
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    command:
      - "--entrypoints.web.address=:80"
      - "--providers.swarm.endpoint=unix:///var/run/docker.sock"
      - "--providers.swarm.watch=true"
      - "--providers.swarm.exposedbydefault=false"
      - "--providers.swarm.network=web"
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--log.level=INFO"
      - "--accesslog=true"
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.dashboard.rule=Host(`traefik.swarm.localhost`)"
        - "traefik.http.routers.dashboard.entrypoints=web"
        - "traefik.http.routers.dashboard.service=api@internal"
        - "traefik.http.services.dashboard.loadbalancer.server.port=8080"

  whoami:
    image: traefik/whoami
    networks:
      - web
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.whoami.rule=Host(`whoami.swarm.localhost`)"
        - "traefik.http.routers.whoami.entrypoints=web"
        - "traefik.http.services.whoami.loadbalancer.server.port=80"

  # --- Portainer ---
  agent:
    image: portainer/agent:lts
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - agent_network
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:lts
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer_data:/data
    networks:
      - agent_network
      - web
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.portainer.rule=Host(`portainer.swarm.localhost`)"
        - "traefik.http.routers.portainer.entrypoints=web"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"
        - "traefik.swarm.network=web"

  # --- Voting App ---
  redis:
    image: redis:alpine
    networks:
      - frontend

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
      POSTGRES_DB: "postgres"
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    command: |
      sh -c "
      mkdir -p /docker-entrypoint-initdb.d &&
      echo \"CREATE TABLE IF NOT EXISTS votes (id SERIAL PRIMARY KEY, vote_id VARCHAR(255) NOT NULL, vote VARCHAR(255) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);\" > /docker-entrypoint-initdb.d/init.sql &&
      docker-entrypoint.sh postgres
      "

  vote:
    image: dockersamples/examplevotingapp_vote
    networks:
      - frontend
      - web
    deploy:
      replicas: 2
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.vote.rule=Host(`vote.swarm.localhost`)"
        - "traefik.http.routers.vote.entrypoints=web"
        - "traefik.http.services.vote.loadbalancer.server.port=80"

  result:
    image: dockersamples/examplevotingapp_result
    networks:
      - backend
      - web
    deploy:
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.result.rule=Host(`result.swarm.localhost`)"
        - "traefik.http.routers.result.entrypoints=web"
        - "traefik.http.services.result.loadbalancer.server.port=80"

  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      replicas: 2

networks:
  web:
    external: true
  frontend:
  backend:
  agent_network:
    driver: overlay
    attachable: true

volumes:
  db-data:
  portainer_data:
```

# Exercice 2

1. Création du fichier [compose.yaml](./compose.yaml) avec le contenu suivant :
    ```yaml
    version: '3.8'
    
    services:
    
      manager:
        container_name: manager
        image: docker:dind
        privileged: true
    
      node-1:
        container_name: node-1
        image: docker:dind
        privileged: true
    
      node-2:
        container_name: node-2
        image: docker:dind
        privileged: true
    
      node-3:
        container_name: node-3
        image: docker:dind
        privileged: true
    ```

2. Vérification de des services

    ```bash
      docker ps
    ```

3. Installation de vim dans les containers

    ```bash
      docker exec -i manager apk add vim
      docker exec -i node-1 apk add vim
      docker exec -i node-2 apk add vim
      docker exec -i node-3 apk add vim
    ```
4. Rentrer dans les containers et vérifier que docker est installé

    ```bash
      docker exec -it manager ash
      docker exec -it node-1 ash
      docker exec -it node-2 ash
      docker exec -it node-3 ash
    ```

   ```bash
     docker --version
   ```

5. Création du cluster swarm

   > Attention : le cluster swarm doit être créé à partir du manager
    ```bash
      docker swarm init
    ```

   > Le retour :
   > ```text
   > Swarm initialized: current node (nueqo5oowvanekfruiep8tlff) is now a manager.
   > To add a worker to this swarm, run the following command:
   >
   > docker swarm join --token <token> 172.80.8.4:2377
   >
   > To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
   > ```

6. Ajouter les nodes au cluster swarm

   > Attention : les commandes suivantes doivent être exécutées à partir des nodes
    ```bash
      docker swarm join --token <token> manager:2377
    ```

7. Vérification du cluster swarm

   > Attention : la commande suivante doit être exécutée à partir du manager
    ```bash
      docker node ls
    ```

# Exercice 3

1. Aucune commande (si on a stoppé les containers, il faut les redémarrer)
   ```bash
      docker compose up --force-recreate
      docker service rm <my-service> # supprimer les anciens services
   ```

   > Commandes a éxécuter dans chaques nodes pour les faire quitter le cluster swarm,
   puis déconnecter les nodes du cluster swarm

   ```bash
      docker swarm leave
      docker swarm join --token <token> manager:2377
   ```

2. j'ai rajouté le mapping du dossier /home/manager puis j'ai redémarré les containers
3. J'ai copié collé mon [hello-world.compose.yaml](./hello-world.compose.yaml) dans le dossier [home mappé](./home) puis j'ai exécuté la commande suivante à partir du manager :
    ```bash
      docker stack deploy -c /home/manager/hello-world.compose.yaml hello-world --detach=false
    ```
4. Vérification des services

    ```bash
      docker service ls
    ```
5. Vérification du stack

    ```bash
      docker stack ls
    ```

6. Vérification via les noeuds

   > Attention : les commandes suivantes doivent être exécutées à partir des nodes
    ```bash
      docker ps
    ```

7. Variation de la clause deploy

   > Ajout de la clause deploy dans le fichier [hello-world.compose.yaml](./hello-world.compose.yaml) avec le contenu suivant :
   > ```yaml
   >   hello-world:
   >      image: nmatsui/hello-world-api
   >      deploy:
   >         replicas: 2
   >         placement:
   >            constraints: [node.role == manager]

8. Vérification des services

    ```bash
      docker service ls
    ```

9. Vérification du stack

    ```bash
      docker stack ls
    ```

10. Vérification via les noeuds

    > Attention : les commandes suivantes doivent être exécutées à partir des nodes
     ```bash
        docker ps
     ```

> Maintenant on ne voit plus les services sur les nodes, car ils sont placés uniquement sur le manager

# stack :

```yaml
version: '3.8'

services:

  manager:
    container_name: manager
    image: docker:dind
    privileged: true
    volumes:
      - ./home:/home/manager

  node-1:
    container_name: node-1
    image: docker:dind
    privileged: true

  node-2:
    container_name: node-2
    image: docker:dind
    privileged: true

  node-3:
    container_name: node-3
    image: docker:dind
    privileged: true
```

# ansible :

1. Démarrer les conteneurs:
    ```bash
    docker compose up -d
    ```

2. Exécuter le playbook Ansible:
    ```bash
      docker compose exec manager ansible-playbook -i /ansible/inventory.ini /ansible/init_swarm_cluster.yml
    ```

3. Vérifier les nœuds du Swarm

    ```bash
      docker compose exec manager docker node ls
    ```

4. Vérifier les services en cours

    ```bash
    docker compose exec manager docker service ls
    ```

## ansible stack

```yaml
version: '3.8'

services:
  manager:
    build: .
    container_name: swarm-manager
    privileged: true
    volumes:
      - ./ansible:/ansible
      - ./stacks:/stacks
    networks:
      - swarm-network
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=False

  node-1:
    build: .
    container_name: swarm-node-1
    privileged: true
    networks:
      - swarm-network
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=False

  node-2:
    build: .
    container_name: swarm-node-2
    privileged: true
    networks:
      - swarm-network
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=False

  node-3:
    build: .
    container_name: swarm-node-3
    privileged: true
    networks:
      - swarm-network
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=False

networks:
  swarm-network:
    driver: bridge

```