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

## 🏗️ Architecture

### Structure du projet

```
ansible-demo/
├── compose.yml                          # Configuration Docker Compose
├── Dockerfile                           # Image Docker personnalisée (Python + sudo)
├── ansible.sh                           # Script de lancement du playbook
├── README.md                            # Ce fichier
├── GUIDE_SSH_ANSIBLE.md                 # Guide pour SSH (VMs/VPS)
├── DOCKER_VS_SSH_COMPARISON.md          # Comparaison Docker vs SSH
├── Responses.md                         # Exercices et réponses
└── ansible/
    ├── inventory.ini                    # Configuration des hosts (Docker)
    ├── inventory_ssh.ini                # Configuration des hosts (SSH)
    ├── init_swarm_cluster.yml           # Playbook principal (Docker)
    └── init_swarm_cluster_ssh.yml       # Playbook adapté pour SSH
```

### Cluster Docker

```
Docker Host (votre machine)
│
└─ Docker Network (esgi-2604-ansible_default)
   │
   ├─ Manager (DinD)
   │  └─ Docker Swarm: Manager (Leader)
   │
   ├─ Node 1 (DinD)
   │  └─ Docker Swarm: Worker
   │
   ├─ Node 2 (DinD)
   │  └─ Docker Swarm: Worker
   │
   ├─ Node 3 (DinD)
   │  └─ Docker Swarm: Worker
   │
   └─ Node 4 (DinD)
      └─ Docker Swarm: Worker
      
Total: 1 Manager + 4 Workers = 5 nœuds
```

---

## 🚀 Comment lancer ansible-demo

### Étape 1 : Cloner/Accéder au répertoire

```bash
cd esgi-2603-my-favorite-places/ansible-demo
```

### Étape 2 : Construire les images Docker

```bash
# Construire l'image personnalisée avec Python et sudo
docker compose build
```

**Qu'est-ce que le Dockerfile fait ?**
```dockerfile
FROM docker:dind                              # Image Docker-in-Docker
RUN apk add --update --no-cache python3 py3-pip && ln -sf python3 /usr/bin/python
RUN apk add sudo                              # Installe Python et sudo (requis par Ansible)
```

### Étape 3 : Lancer les containers

```bash
# Lancer 1 manager + 4 workers
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

---

## 🔍 Dépannage

### ❌ Erreur : "Command not found: python"
**Solution** : Reconstruire l'image Docker
```bash
docker compose build --no-cache
docker compose up -d
```

### ❌ Erreur : "Failed to establish SSH connection"
**Solution** : L'inventaire Docker ne nécessite pas SSH. Vérifier que `community.docker` est installé :
```bash
ansible-galaxy collection install community.docker
```

### ❌ Erreur : "Container not found"
**Solution** : Vérifier que les containers sont lancés :
```bash
docker ps | grep esgi-2603-my-favorite-places
```

### ❌ Erreur : "Swarm join failed"
**Solution** : 
1. Vérifier que le manager a initialisé le Swarm
2. Vérifier la connectivité réseau entre containers
```bash
docker exec esgi-2603-my-favorite-places-manager-1 docker info | grep "Swarm: active"
```

### ✅ Vérification globale du setup

```bash
# 1. Docker Compose
docker compose ps

# 2. Connectivité Ansible
ansible all -i ansible/inventory.ini -m ping

# 3. État Docker Swarm
docker exec esgi-2603-my-favorite-places-manager-1 docker swarm ca --rotate

# 4. État du réseau
docker network ls | grep esgi-2603
docker network inspect esgi-2603-my-favorite-places_default
```

---

## 📚 Documentation supplémentaire

- **[GUIDE_SSH_ANSIBLE.md](./GUIDE_SSH_ANSIBLE.md)** - Comment utiliser Ansible sur des VMs/VPS Linux réelles
- **[DOCKER_VS_SSH_COMPARISON.md](./DOCKER_VS_SSH_COMPARISON.md)** - Comparaison détaillée Docker vs SSH
- **[Responses.md](./Responses.md)** - Exercices et réponses des exercices 4 & 5

---

## 💡 Cas d'usage et prochaines étapes

### Déployer un service sur le cluster

```bash
# Créer un service simple
docker exec esgi-2603-my-favorite-places-manager-1 \
  docker service create --name web --replicas 3 -p 80:80 nginx

# Vérifier les tâches
docker exec esgi-2603-my-favorite-places-manager-1 \
  docker service ps web
```

### Ajouter un nouveau worker dynamiquement

```bash
# Lancer un nouveau container
docker compose up --scale node=5 -d

# Ajouter le nouveau worker à l'inventaire dans `ansible/inventory.ini`
# Puis relancer le playbook
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml
```

### Tester la résilience du cluster

```bash
# Arrêter un worker
docker stop esgi-2603-my-favorite-places-node-1

# Vérifier que les services restent opérationnels
docker exec esgi-2603-my-favorite-places-manager-1 docker service ls
```

---

## 🎯 Objectifs pédagogiques

Ce projet permet d'apprendre :
- ✅ Les bases de Docker Swarm
- ✅ Configuration et utilisation d'Ansible
- ✅ Gestion d'inventaire
- ✅ Playbooks YAML
- ✅ Docker-in-Docker (DinD)
- ✅ Automatisation d'infrastructure
- ✅ IaC (Infrastructure as Code)

---

## ⚙️ Configuration avancée

### Changer le nombre de workers

```bash
# 3 workers
docker compose up --scale manager=1 --scale node=3 -d

# 10 workers
docker compose up --scale manager=1 --scale node=10 -d

# Mettre à jour l'inventaire en conséquence
```

### Mode interactive pour le développement

```bash
# Accéder à un container en shell
docker exec -it esgi-2603-my-favorite-places-manager-1 sh

# Exécuter une commande directement
docker exec esgi-2603-my-favorite-places-manager-1 docker node inspect self
```

---

## 📄 Licence

Voir le parent repository pour les détails.

---

## 👨‍💻 Auteur

Projet ESGI - DevOps M2 - 2603/2604

---

## 🤝 Support

Pour plus d'informations ou d'aide, consultez la documentation officielle :
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
