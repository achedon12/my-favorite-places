# Exercice 4

## 1. Démarrer avec 3 containers noeuds

```bash
docker compose up --scale manager=1 --scale node=3
```

## 2. Qu'est-ce que le playbook Ansible proposé ?

Le playbook `init_swarm_cluster.yml` effectue les opérations suivantes :

**Play 1 : Initialize Docker Swarm**
- Initialise un cluster Docker Swarm sur le nœud manager avec `docker swarm init`
- Récupère le token de jointure pour les workers avec `docker swarm join-token worker -q`
- Stocke le token et la commande de jointure en tant que faits Ansible

**Play 2 : Join workers to the Swarm cluster**
- Joint chaque nœud worker au cluster en utilisant la commande stockée
- Utilise l'IP du manager (172.80.11.3) pour se connecter au cluster

### Installation d'Ansible

```bash
sudo apt install ansible
ansible --version # Vérification de l'installation
```

### Modifications du fichier inventory.ini

L'inventaire a été modifié pour utiliser les noms de containers Docker avec la connexion `community.docker.docker` et pour stocker l'IP du manager en tant que variable :

```ini
[managers]
# it should be the docker container name of the manager node, in our case "manager" prefixed by docker compose
esgi-2604-ansible-manager-1

[managers:vars]
ansible_connection=community.docker.docker
manager_ip=172.80.11.3

[workers]
# it should be the docker container name of the worker nodes, in our case "node" prefixed by docker compose
esgi-2604-ansible-node-1
esgi-2604-ansible-node-2
esgi-2604-ansible-node-3

[workers:vars]
ansible_connection=community.docker.docker
```

### Exécution du playbook

```bash
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml
```

### Résultat

Le playbook s'est exécuté avec succès, et voici l'état du cluster Swarm :

```
docker exec esgi-2604-ansible-manager-1 docker node ls
ID                            HOSTNAME       STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
aerp7ht9dvruayknayeetct25     1e9af117c3e6   Ready     Active                          29.3.1
xptfpqmhnikhivhfjv0osv6jk     ad172d92cd28   Ready     Active                          29.3.1
3g58bggubzqedkl12lwy8lhd1     cc945a9d3f9e   Ready     Active                          29.3.1
2avvh8ccfxk8qbot61g41jy78 *   eef8ef687122   Ready     Active         Leader           29.3.1
```

✅ Cluster Docker Swarm initialisé avec succès : 1 manager (Leader) + 3 workers

## 3. Vérification du cluster Swarm et relancement du playbook

### État du Swarm - Vérification initiale

**État du Manager :**
```
Swarm: active
NodeID: 2avvh8ccfxk8qbot61g41jy78
Is Manager: true
ClusterID: o32afzs48ftyh6sfspgij1mp1
Managers: 1
Nodes: 4
```

**État d'un Worker :**
```
Swarm: active
NodeID: xptfpqmhnikhivhfjv0osv6jk
Is Manager: false
Node Address: 172.80.11.4
```

**Tous les nœuds du cluster :**
- 1 Manager (Leader) : Ready, Active
- 3 Workers : Ready, Active

✅ Le cluster Swarm est complètement opérationnel et tous les nœuds sont rejoints.

### Relancement du playbook - Observations

Lors de la **deuxième exécution** du playbook sur les mêmes machines, on constate :

**Tâches marquées comme `changed` :**
- `Initialize swarm on first manager` : **changed** (pas ok)
- `Retrieve worker join token` : **changed** (pas ok)
- `Join swarm as worker` : **changed** pour les 3 workers

**Résultat final :**
```
PLAY RECAP
esgi-2604-ansible-manager-1 : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-1   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-2   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-3   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Constatations importantes

1. **Pas d'idempotence** : Le playbook marque les tâches comme `changed` même si le Swarm est déjà initialisé
   - La commande `docker swarm init` s'exécute à nouveau (retourne une erreur capturée par `failed_when`)
   - La commande `docker swarm join-token worker -q` s'exécute à nouveau
   - Les workers exécutent à nouveau la commande join

2. **Pas de réelle modification** : Malgré les marqueurs `changed`, le cluster reste dans le même état :
   - Les nœuds restent tous `Ready` et `Active`
   - Le manager reste `Leader`
   - Aucun nœud n'est dupliqué ou supprimé

3. **Gestion d'erreur fonctionnelle** : La clause `failed_when` permet au playbook de continuer même si les commandes retournent une erreur, en vérifiant que le cluster existe déjà

4. **Idéal pour la robustesse** : Bien que le playbook ne soit pas idempotent, il est **robuste** et peut être relancé sans causer de problèmes au cluster

### Recommandation

Pour rendre le playbook véritablement idempotent, il faudrait :
- Vérifier d'abord si le Swarm est déjà initialisé avant d'exécuter `docker swarm init`
- Utiliser des conditions Ansible pour éviter les exécutions inutiles
   




# Exercice 5 - Comprendre Ansible

## 1. Exécuter un nœud supplémentaire et l'ajouter au cluster

### Étape 1 : Lancer un 4ème nœud

```bash
docker compose up --scale manager=1 --scale node=4 -d
```

Résultat :
- Un nouveau container `esgi-2604-ansible-node-4` a été créé et est maintenant en cours d'exécution

### Étape 2 : Adapter l'inventaire Ansible

Modification de `ansible/inventory.ini` pour ajouter le nouveau nœud :

```ini
[workers]
# it should be the docker container name of the worker nodes, in our case "node" prefixed by docker compose
esgi-2604-ansible-node-1
esgi-2604-ansible-node-2
esgi-2604-ansible-node-3
esgi-2604-ansible-node-4
```

### Étape 3 : Réexécuter le playbook

```bash
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml
```

**Résultat :**
```
PLAY RECAP
esgi-2604-ansible-manager-1 : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-1   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-2   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-3   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
esgi-2604-ansible-node-4   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Le playbook a bien exécuté les tâches sur le nouveau nœud.

### Étape 4 : Vérification que le nouveau nœud fait partie du cluster

**Tous les nœuds du cluster Swarm :**

```bash
docker exec esgi-2604-ansible-manager-1 docker node ls
```

Résultat :
```
ID                            HOSTNAME       STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
aerp7ht9dvruayknayeetct25     1e9af117c3e6   Ready     Active                          29.3.1
i1siq4dumu2aqhnad1rimp3tn     88f2c04e7647   Ready     Active                          29.3.1  <- NOUVEAU NŒUD
xptfpqmhnikhivhfjv0osv6jk     ad172d92cd28   Ready     Active                          29.3.1
3g58bggubzqedkl12lwy8lhd1     cc945a9d3f9e   Ready     Active                          29.3.1
2avvh8ccfxk8qbot61g41jy78 *   eef8ef687122   Ready     Active         Leader           29.3.1
```

**État du nouveau nœud dans le Swarm :**

```bash
docker exec esgi-2604-ansible-node-4 docker info | grep -A 3 "Swarm"
```

Résultat :
```
 Swarm: active
  NodeID: i1siq4dumu2aqhnad1rimp3tn
  Is Manager: false
  Node Address: 172.80.11.6
```

✅ **Le nouveau nœud a bien rejoint le cluster Swarm :**
- Status : `Ready`
- Availability : `Active`
- Est un worker (Is Manager: false)
- Adresse IP : 172.80.11.6
- Total du cluster : 1 Manager + 4 Workers = 5 nœuds

# Exercice 5 - Suite : Migration vers VMs/VPS Linux classiques en SSH

## 2. Changements nécessaires pour utiliser Ansible sur des VMs/VPS Linux classiques

### 📋 Résumé des changements

Pour adapter Ansible d'une infrastructure de containers Docker à des VMs/VPS Linux classiques accessibles en SSH, les changements sont mineurs mais importants :

| Aspect | Docker Containers | VMs/VPS SSH |
|--------|-----------------|------------|
| **Connexion** | `ansible_connection=community.docker.docker` | `ansible_connection=ssh` (défaut) |
| **Adresses** | Noms de containers | Adresses IP ou noms de domaine |
| **Authentification** | Socket Docker | Clés SSH ou mots de passe |
| **Utilisateur** | root par défaut | ubuntu, debian, ec2-user, etc. |
| **Initialisation Swarm** | Sans `--advertise-addr` | Avec `--advertise-addr {{ manager_ip }}` |

### 📝 Inventaire pour SSH

Un nouvel inventaire `inventory_ssh.ini` a été créé avec la structure suivante :

```ini
[managers]
manager-vm-1 ansible_host=192.168.1.10

[managers:vars]
ansible_connection=ssh
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/user/.ssh/ansible_key
manager_ip=192.168.1.10

[workers]
worker-vm-1 ansible_host=192.168.1.11
worker-vm-2 ansible_host=192.168.1.12
worker-vm-3 ansible_host=192.168.1.13
worker-vm-4 ansible_host=192.168.1.14

[workers:vars]
ansible_connection=ssh
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/user/.ssh/ansible_key
```

**Points clés :**
- `ansible_host` : Adresse IP ou nom de domaine (remplace le nom du container)
- `ansible_user` : Utilisateur SSH pour la connexion
- `ansible_ssh_private_key_file` : Chemin vers la clé privée SSH
- `manager_ip` : IP du manager pour la configuration du Swarm

### 🎬 Playbook adapté pour SSH

Un nouveau playbook `init_swarm_cluster_ssh.yml` a été créé avec les changements suivants :

**Changement clé :**
```yaml
# Avant (Docker) :
command: "docker swarm init"

# Après (SSH) :
command: "docker swarm init --advertise-addr {{ manager_ip }}"
```

**Ajout de vérifications :**
```yaml
- name: Verify Docker is installed
  command: docker --version
  register: docker_version
  failed_when: docker_version.rc != 0
```

Cela garantit que Docker est installé sur chaque VM/VPS avant d'essayer l'initialiser le Swarm.

### 🔐 Configuration de l'authentification SSH

Deux approches possibles :

#### Option 1 : Authentification par clé SSH (recommandée)

```bash
# 1. Générer une clé SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""

# 2. Copier la clé sur chaque VM/VPS
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.10
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.11
# ... etc.

# 3. Tester la connectivité
ansible all -i inventory_ssh.ini -m ping
```

#### Option 2 : Authentification par mot de passe

```bash
# 1. Installer sshpass
sudo apt-get install sshpass

# 2. Configurer l'inventaire avec le mot de passe
ansible_ssh_pass=votre_motdepasse

# 3. Ou utiliser le prompt Ansible
ansible-playbook -i inventory_ssh.ini init_swarm_cluster_ssh.yml -k
```

### 🚀 Exécution du playbook sur SSH

```bash
# Exécuter le playbook
ansible-playbook -i inventory_ssh.ini init_swarm_cluster_ssh.yml

# Avec verification préalable
ansible all -i inventory_ssh.ini -m ping

# Avec détails verbeux
ansible-playbook -i inventory_ssh.ini init_swarm_cluster_ssh.yml -v
```

### ✅ Vérification du cluster Swarm

```bash
# Sur la VM manager, vérifier l'état du cluster
ssh ubuntu@192.168.1.10
docker node ls
docker info | grep -A 5 "Swarm"

# Ou via Ansible
ansible managers -i inventory_ssh.ini -m shell -a "docker node ls"
```

### 📚 Fichiers créés

1. **`ansible/inventory_ssh.ini`** : Inventaire pour SSH avec commentaires
2. **`ansible/init_swarm_cluster_ssh.yml`** : Playbook adapté pour SSH
3. **`GUIDE_SSH_ANSIBLE.md`** : Guide complet de configuration SSH

### 🔍 Différences clés résumées

**Inventaire Docker :**
```ini
esgi-2604-ansible-manager-1
[managers:vars]
ansible_connection=community.docker.docker
```

**Inventaire SSH :**
```ini
manager-vm-1 ansible_host=192.168.1.10
[managers:vars]
ansible_connection=ssh
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ansible_key
```

**Playbook Docker :**
```yaml
command: "docker swarm init"
```

**Playbook SSH :**
```yaml
command: "docker swarm init --advertise-addr {{ manager_ip }}"
```

### ⚠️ Note sur le Bonus : Test avec VirtualBox

Le bonus proposé était de tester avec VirtualBox ou équivalent. Cependant :
- L'environnement actuel n'a pas accès à VirtualBox ou Hypervisor
- Les VMs créées nécessiteraient Docker installé (Ubuntu Server + Docker)
- Le réseau des VMs devrait être configuré en Bridge mode pour la communication inter-VM

**Pour effectuer le test en production :**
1. Créer 5 VMs Ubuntu avec Docker installé
2. Configurer un réseau Bridge
3. Noter les adresses IP des VMs
4. Adapter l'inventaire `inventory_ssh.ini`
5. Exécuter le playbook : `ansible-playbook -i ansible/inventory_ssh.ini ansible/init_swarm_cluster_ssh.yml`
6. Vérifier avec `docker node ls` sur la VM manager

## Fichiers créés pour la migration SSH

### 📁 Nouveau contenu du dossier `ansible/`

```
ansible/
├── init_swarm_cluster.yml          # Playbook original (Docker)
├── init_swarm_cluster_ssh.yml      # Playbook adapté (SSH) ✨ NOUVEAU
├── inventory.ini                   # Inventaire original (Docker)
└── inventory_ssh.ini               # Inventaire adapté (SSH) ✨ NOUVEAU
```

### 📁 Fichiers de documentation

```
root/
├── GUIDE_SSH_ANSIBLE.md            # Guide d'authentification SSH ✨ NOUVEAU
├── DOCKER_VS_SSH_COMPARISON.md     # Comparaison détaillée ✨ NOUVEAU
├── Responses.md                    # Ce fichier (exercices 4 & 5)
└── README.md                       # Documentation générale
```

## Résumé des changements - Tableau récapitulatif

### Configuration de l'inventaire

| Aspect                           | Docker                    | SSH                       |
|----------------------------------|---------------------------|---------------------------|
| **Fichier**                      | `inventory.ini`           | `inventory_ssh.ini`       |
| **Adresses**                     | Noms containers           | IPs/FQDNs                 |
| **ansible_host**                 | ❌ Non utilisé             | ✅ Obligatoire             |
| **ansible_connection**           | `community.docker.docker` | `ssh`                     |
| **ansible_user**                 | Non spécifié              | ✅ ubuntu/debian/etc       |
| **Authentification**             | Socket Docker             | Clés SSH ou mots de passe |
| **ansible_ssh_private_key_file** | ❌ Non applicable          | ✅ Recommandé              |
| **manager_ip**                   | `172.80.11.3`             | `192.168.1.10`            |

### Configuration du playbook

| Tâche                 | Docker                   | SSH                                                   |
|-----------------------|--------------------------|-------------------------------------------------------|
| **Fichier**           | `init_swarm_cluster.yml` | `init_swarm_cluster_ssh.yml`                          |
| **Vérif Docker**      | ❌ Non                    | ✅ Ajouté                                              |
| **docker swarm init** | `docker swarm init`      | `docker swarm init --advertise-addr {{ manager_ip }}` |
| **become: yes**       | ✅ Utilisé                | ✅ Utilisé                                             |
| **Logique Swarm**     | Identique                | Identique                                             |

## Exemple de test avec SSH

```bash
# 1. Configuration des clés SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""
for i in {10..14}; do
  ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.$i
done

# 2. Tester la connectivité
ansible all -i ansible/inventory_ssh.ini -m ping

# 3. Vérifier les détails des hôtes
ansible all -i ansible/inventory_ssh.ini -m setup | head -50

# 4. Exécuter le playbook
ansible-playbook -i ansible/inventory_ssh.ini ansible/init_swarm_cluster_ssh.yml -v

# 5. Vérifier le cluster
ansible managers -i ansible/inventory_ssh.ini -m shell -a "docker node ls"
```

## Conclusion - Exercice 5

✅ **Changements identifiés et documentés :**
1. Remplacement de la connexion Docker par SSH
2. Utilisation d'adresses IP au lieu de noms de containers
3. Ajout de paramètres d'authentification SSH
4. Modification du playbook pour ajouter `--advertise-addr`
5. Ajout de vérifications préalables (Docker installé)

📚 **Ressources créées :**
1. `inventory_ssh.ini` - Inventaire prêt à l'emploi
2. `init_swarm_cluster_ssh.yml` - Playbook adapté
3. `GUIDE_SSH_ANSIBLE.md` - Guide d'authentification
4. `DOCKER_VS_SSH_COMPARISON.md` - Comparaison détaillée

🎯 **Avantages de cette approche :**
- Infrastructure plus scalable (VMs indépendantes)
- Meilleure isolation entre les nœuds
- Compatible avec les services cloud (AWS, Azure, DigitalOcean, etc.)
- Même logique Ansible, juste des paramètres différents
   


