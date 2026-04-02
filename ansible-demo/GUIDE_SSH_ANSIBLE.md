# Guide d'authentification SSH pour Ansible

## 1. Authentification par clé SSH (recommandée - plus sécurisée)

### Étape 1 : Générer une clé SSH sur votre machine locale

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""
```

Cela crée deux fichiers :
- `~/.ssh/ansible_key` (clé privée)
- `~/.ssh/ansible_key.pub` (clé publique)

### Étape 2 : Copier la clé publique sur chaque VM/VPS

```bash
# Sur chaque VM/VPS manager et worker
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.10
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.11
# ... répéter pour chaque nœud
```

Ou manuellement (si ssh-copy-id ne fonctionne pas) :
```bash
# Sur chaque VM/VPS
cat >> ~/.ssh/authorized_keys << EOF
<contenu de ~/.ssh/ansible_key.pub>
EOF
chmod 600 ~/.ssh/authorized_keys
```

### Étape 3 : Configurer l'inventaire Ansible

```ini
[managers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/user/.ssh/ansible_key
```

## 2. Authentification par mot de passe

Plus simple à mettre en place, mais moins sécurisée.

### Étape 1 : Installer sshpass (permet à Ansible de gérer les mots de passe)

```bash
sudo apt-get install sshpass
```

### Étape 2 : Configurer l'inventaire Ansible

```ini
[managers:vars]
ansible_user=ubuntu
ansible_ssh_pass=votre_motdepasse
```

Ou utiliser le prompt Ansible :
```bash
ansible-playbook -i inventory_ssh.ini init_swarm_cluster_ssh.yml -k
```
L'option `-k` invite à entrer le mot de passe SSH.

## 3. Permissions sudoers

Assurez-vous que l'utilisateur SSH a les permissions sudo pour Docker :

```bash
# Sur chaque VM/VPS
sudo usermod -aG docker ubuntu
# ou si besoin de sudo sans mot de passe pour Docker :
sudo visudo
# Ajouter la ligne :
# ubuntu ALL=(ALL) NOPASSWD: /usr/bin/docker
```

## 4. Tester la connectivité

```bash
ansible all -i inventory_ssh.ini -m ping
```

Output attendu :
```
manager-vm-1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

