# Comparaison : Docker Containers vs VMs/VPS SSH

## Vue d'ensemble

| Critère | Architecture Docker Compose | Architecture VMs/VPS SSH |
|---------|---------------------------|----------------------|
| **Déploiement** | Containers sur une machine hôte | VMs/VPS indépendantes |
| **Isolation** | Au niveau container | Au niveau système complet |
| **Performance** | Faible overhead | Plus d'overhead (hyperviseur) |
| **Complexité d'installation** | Simple (Docker + Compose) | Complexe (VMs + OS + Docker) |
| **Maintenance** | Gérée par l'hôte Docker | Chaque VM est responsable |

## Changements Ansible - Détail complet

### 1. INVENTAIRE - Comparaison côte à côte

#### ❌ Version Docker (actuel)

```ini
[managers]
esgi-2604-ansible-manager-1

[managers:vars]
ansible_connection=community.docker.docker
manager_ip=172.80.11.3

[workers]
esgi-2604-ansible-node-1
esgi-2604-ansible-node-2
esgi-2604-ansible-node-3
esgi-2604-ansible-node-4

[workers:vars]
ansible_connection=community.docker.docker
```

**Explication :**
- `esgi-2604-ansible-manager-1` : Nom du container Docker
- `ansible_connection=community.docker.docker` : Connexion via socket Docker
- Pas de `ansible_host` : Utilise directement le nom du container

#### ✅ Version SSH (nouvelle)

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

**Explication :**
- `manager-vm-1` : Alias facile à retenir
- `ansible_host=192.168.1.10` : Adresse IP réelle ou FQDN
- `ansible_connection=ssh` : Connexion standard SSH
- `ansible_user=ubuntu` : Utilisateur SSH (peut être root, debian, ec2-user, etc.)
- `ansible_ssh_private_key_file` : Authentification par clé RSA
- `manager_ip=192.168.1.10` : Adresse IP du manager (nécessaire pour Docker Swarm)

### 2. PLAYBOOK - Comparaison côte à côte

#### ❌ Version Docker (actuel)

```yaml
- name: Initialize Docker Swarm
  hosts: managers
  become: yes
  tasks:
    - name: Initialize swarm on first manager
      command: "docker swarm init"
      run_once: true
      # ...
```

**Problème:** Sans `--advertise-addr`, Docker Swarm sélectionne automatiquement l'adresse IP, ce qui fonctionne dans un container réseau Docker mais peut être imprévisible.

#### ✅ Version SSH (nouvelle)

```yaml
- name: Initialize Docker Swarm
  hosts: managers
  become: yes
  tasks:
    - name: Verify Docker is installed
      command: docker --version
      register: docker_version
      failed_when: docker_version.rc != 0

    - name: Initialize swarm on first manager
      command: "docker swarm init --advertise-addr {{ manager_ip }}"
      run_once: true
      # ...
```

**Améliorations :**
- Ajout de vérification que Docker est installé
- `--advertise-addr {{ manager_ip }}` : Force l'utilisation de l'IP spécifiée dans l'inventaire
- Évite les problèmes d'auto-détection d'adresse IP

### 3. FLUX DE COMMANDES

#### ❌ Docker Containers - Exécution

```bash
# Créer les containers
docker compose up --scale manager=1 --scale node=4 -d

# Exécuter le playbook
ansible-playbook -i ansible/inventory.ini ansible/init_swarm_cluster.yml
```

**Processus interne :**
1. Ansible se connecte via le socket Docker
2. Exécute `docker exec <container_name> <command>`
3. Les containers partagent le même réseau Docker

#### ✅ VMs/VPS SSH - Exécution

```bash
# Les VMs/VPS sont déjà en cours d'exécution
# (Créées avec VirtualBox, AWS, DigitalOcean, etc.)

# Configurer les clés SSH
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.10
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.11

# Tester la connectivité
ansible all -i ansible/inventory_ssh.ini -m ping

# Exécuter le playbook
ansible-playbook -i ansible/inventory_ssh.ini ansible/init_swarm_cluster_ssh.yml
```

**Processus interne :**
1. Ansible établit une connexion SSH standard
2. Transmet les commandes via SSH
3. Les VMs sont complètement isolées, chacune avec son OS

## Matrice de changements

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER CONTAINERS                            │
├─────────────────────────────────────────────────────────────────┤
│ ansible_connection = community.docker.docker                    │
│ Adresse = nom du container                                      │
│ Authentification = socket Docker                                │
│ Utilisateur = root (par défaut dans Docker)                     │
│ Commande init = docker swarm init                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓↓↓ MIGRATION ↓↓↓
┌─────────────────────────────────────────────────────────────────┐
│                    VMs/VPS SSH                                  │
├─────────────────────────────────────────────────────────────────┤
│ ansible_connection = ssh                                        │
│ Adresse = IP ou FQDN                                            │
│ Authentification = clé SSH ou mot de passe                      │
│ Utilisateur = ubuntu, debian, ec2-user, root                    │
│ Commande init = docker swarm init --advertise-addr {{ manager_ip }} │
└─────────────────────────────────────────────────────────────────┘
```

## Checklist de migration

- [ ] Créer un nouvel inventaire `inventory_ssh.ini` avec les adresses IP
- [ ] Générer des clés SSH pour l'authentification
- [ ] Configurer les autorités SSH publiques sur chaque VM/VPS
- [ ] Créer un nouveau playbook `init_swarm_cluster_ssh.yml`
- [ ] Ajouter `--advertise-addr {{ manager_ip }}` à `docker swarm init`
- [ ] Ajouter des vérifications Docker préalables
- [ ] Tester la connectivité avec `ansible all -i inventory_ssh.ini -m ping`
- [ ] Exécuter le playbook : `ansible-playbook -i inventory_ssh.ini init_swarm_cluster_ssh.yml`
- [ ] Vérifier le cluster avec `docker node ls` sur le manager

