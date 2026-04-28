#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_FILE="${SCRIPT_DIR}/stacks/traefik-stack.yml"
STACK_NAME="traefik"

echo "=========================================="
echo "Déploiement de la stack Traefik"
echo "=========================================="

# Vérifier que Docker Swarm est initialisé
if ! docker node ls > /dev/null 2>&1; then
    echo "❌ Erreur : Docker Swarm n'est pas initialisé"
    echo "Veuillez d'abord initialiser le Swarm avec: docker swarm init --advertise-addr <IP>"
    exit 1
fi

echo "✓ Docker Swarm est actif"

# Créer le réseau overlay
echo ""
echo "Création du réseau overlay 'web'..."
docker network create --driver overlay --opt com.docker.network.driver.overlay.vxlanid=4096 web 2>/dev/null || echo "Le réseau 'web' existe déjà"
echo "✓ Réseau 'web' prêt"

# Déployer la stack
echo ""
echo "Déploiement de la stack Traefik..."
docker stack deploy -c "${STACK_FILE}" "${STACK_NAME}"
echo "✓ Stack déployée"

# Attendre que les services démarre
echo ""
echo "Attente du démarrage des services (30 secondes)..."
sleep 30

# Vérifier l'état
echo ""
echo "=========================================="
echo "État de la stack"
echo "=========================================="
docker stack ps "${STACK_NAME}"

echo ""
echo "=========================================="
echo "Services"
echo "=========================================="
docker service ls | grep "${STACK_NAME}"

echo ""
echo "=========================================="
echo "Mise à jour du fichier /etc/hosts"
echo "=========================================="

# Mettre à jour /etc/hosts
if ! grep -q "traefik.swarm.localhost" /etc/hosts; then
    echo "127.0.0.1  traefik.swarm.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "✓ traefik.swarm.localhost ajouté"
else
    echo "✓ traefik.swarm.localhost déjà présent"
fi

if ! grep -q "whoami.swarm.localhost" /etc/hosts; then
    echo "127.0.0.1  whoami.swarm.localhost" | sudo tee -a /etc/hosts > /dev/null
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
echo "  - Traefik Dashboard : http://traefik.swarm.localhost:8080/dashboard/"
echo "  - Whoami Service   : http://whoami.swarm.localhost"
echo ""
echo "Pour voir les logs:"
echo "  - Traefik : docker service logs ${STACK_NAME}_traefik"
echo "  - Whoami  : docker service logs ${STACK_NAME}_whoami"
echo ""
