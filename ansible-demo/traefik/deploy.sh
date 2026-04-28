#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_FILE="${SCRIPT_DIR}/stacks/traefik-stack.yml"
STACK_NAME="traefik"

echo "=========================================="
echo "Déploiement de Traefik v3.6 sur Docker Swarm"
echo "=========================================="

# Vérifier que Docker Swarm est initialisé
if ! docker node ls > /dev/null 2>&1; then
    echo "❌ Erreur : Docker Swarm n'est pas initialisé"
    echo ""
    echo "Pour initialiser le Swarm:"
    echo "  docker swarm init --advertise-addr <VOTRE_IP>"
    echo ""
    echo "Pour joindre un worker au Swarm:"
    echo "  docker swarm join --token <TOKEN> <MANAGER_IP>:2377"
    exit 1
fi

echo "✓ Docker Swarm est actif"
echo ""

# Afficher l'état du Swarm
echo "Nœuds du cluster:"
docker node ls | awk '{print "  " $0}'
echo ""

# Créer le réseau overlay
echo "Création du réseau overlay 'web'..."
docker network create --driver overlay \
  --opt com.docker.network.driver.overlay.vxlanid=4096 \
  web 2>/dev/null || echo "  ℹ Le réseau 'web' existe déjà"
echo "✓ Réseau 'web' prêt"
echo ""

# Déployer la stack
echo "Déploiement de la stack Traefik..."
docker stack deploy -c "${STACK_FILE}" "${STACK_NAME}"
echo "✓ Stack déployée"
echo ""

# Attendre que les services démarre
echo "Attente du démarrage des services (20 secondes)..."
sleep 20

# Vérifier l'état
echo ""
echo "=========================================="
echo "État de la stack"
echo "=========================================="
docker stack ps "${STACK_NAME}" | awk '{print "  " $0}'

echo ""
echo "=========================================="
echo "Services"
echo "=========================================="
docker service ls | grep "${STACK_NAME}" | awk '{print "  " $0}'

echo ""
echo "=========================================="
echo "Mise à jour du fichier /etc/hosts"
echo "=========================================="

# Mettre à jour /etc/hosts
if ! grep -q "traefik.swarm.localhost" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1  traefik.swarm.localhost" >> /etc/hosts
    echo "✓ traefik.swarm.localhost ajouté"
else
    echo "✓ traefik.swarm.localhost déjà présent"
fi

if ! grep -q "whoami.swarm.localhost" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1  whoami.swarm.localhost" >> /etc/hosts
    echo "✓ whoami.swarm.localhost ajouté"
else
    echo "✓ whoami.swarm.localhost déjà présent"
fi

echo ""
echo "=========================================="
echo "✓ Déploiement réussi!"
echo "=========================================="
echo ""
echo "Accédez aux services:"
echo "  • Dashboard Traefik : http://traefik.swarm.localhost"
echo "  • Service Whoami    : http://whoami.swarm.localhost"
echo ""
echo "Commandes utiles:"
echo "  • Logs Traefik     : docker service logs traefik_traefik"
echo "  • Logs Whoami      : docker service logs traefik_whoami"
echo "  • Vérifier         : ./check.sh"
echo "  • Nettoyer         : ./cleanup.sh"
echo ""
