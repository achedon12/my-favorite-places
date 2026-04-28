#!/bin/bash

STACK_NAME="traefik"

echo "=========================================="
echo "Vérification de la stack Traefik"
echo "=========================================="

# Vérifier Swarm
if ! docker node ls > /dev/null 2>&1; then
    echo "❌ Docker Swarm n'est pas actif"
    exit 1
fi
echo "✓ Docker Swarm actif"

# Vérifier la stack
echo ""
echo "=========================================="
echo "État de la stack"
echo "=========================================="
if docker stack ls | grep -q "${STACK_NAME}"; then
    echo "✓ Stack '${STACK_NAME}' déployée"
    docker stack ps "${STACK_NAME}"
else
    echo "❌ Stack '${STACK_NAME}' non déployée"
    exit 1
fi

# Vérifier les services
echo ""
echo "=========================================="
echo "Services"
echo "=========================================="
docker service ls | grep "${STACK_NAME}"

# Vérifier le réseau
echo ""
echo "=========================================="
echo "Réseau overlay"
echo "=========================================="
docker network ls | grep web

# Vérifier les hosts
echo ""
echo "=========================================="
echo "Résolution DNS (/etc/hosts)"
echo "=========================================="
grep "swarm.localhost" /etc/hosts || echo "❌ Entrées /etc/hosts non trouvées"

# Vérifier la connectivité
echo ""
echo "=========================================="
echo "Connectivité"
echo "=========================================="
if ping -c 1 -W 2 traefik.swarm.localhost > /dev/null 2>&1; then
    echo "✓ traefik.swarm.localhost accessible"
else
    echo "⚠ traefik.swarm.localhost non accessible"
fi

if ping -c 1 -W 2 whoami.swarm.localhost > /dev/null 2>&1; then
    echo "✓ whoami.swarm.localhost accessible"
else
    echo "⚠ whoami.swarm.localhost non accessible"
fi

# Vérifier les logs
echo ""
echo "=========================================="
echo "Logs (dernières 10 lignes)"
echo "=========================================="
echo "--- Traefik ---"
docker service logs --tail 5 "${STACK_NAME}_traefik" 2>/dev/null || echo "Pas de logs disponibles"
echo ""
echo "--- Whoami ---"
docker service logs --tail 5 "${STACK_NAME}_whoami" 2>/dev/null || echo "Pas de logs disponibles"
