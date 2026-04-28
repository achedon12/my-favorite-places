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

