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
    echo ""
    docker stack ps "${STACK_NAME}" | awk '{print "  " $0}'
else
    echo "❌ Stack '${STACK_NAME}' non déployée"
    exit 1
fi

# Vérifier les services
echo ""
echo "=========================================="
echo "Services"
echo "=========================================="
docker service ls | grep "${STACK_NAME}" | awk '{print "  " $0}'

# Vérifier le réseau
echo ""
echo "=========================================="
echo "Réseau overlay"
echo "=========================================="
docker network ls | grep web | awk '{print "  " $0}'

# Vérifier les hosts
echo ""
echo "=========================================="
echo "Résolution DNS (/etc/hosts)"
echo "=========================================="
if grep -q "swarm.localhost" /etc/hosts; then
    grep "swarm.localhost" /etc/hosts | awk '{print "  " $0}'
    echo "✓ Entrées /etc/hosts trouvées"
else
    echo "❌ Entrées /etc/hosts non trouvées"
fi

# Vérifier la connectivité
echo ""
echo "=========================================="
echo "Connectivité"
echo "=========================================="
if ping -c 1 -W 2 traefik.swarm.localhost > /dev/null 2>&1; then
    echo "✓ traefik.swarm.localhost accessible"
else
    echo "⚠️  traefik.swarm.localhost pas accessible"
fi

if ping -c 1 -W 2 whoami.swarm.localhost > /dev/null 2>&1; then
    echo "✓ whoami.swarm.localhost accessible"
else
    echo "⚠️  whoami.swarm.localhost pas accessible"
fi

# Tester HTTP
echo ""
echo "=========================================="
echo "Test HTTP"
echo "=========================================="

if curl -s -I http://traefik.swarm.localhost/ 2>&1 | grep -q "HTTP"; then
    STATUS=$(curl -s -I http://traefik.swarm.localhost/ 2>&1 | head -1)
    echo "✓ Dashboard Traefik: $STATUS"
else
    echo "⚠️  Dashboard Traefik ne répond pas"
fi

if curl -s -I http://whoami.swarm.localhost/ 2>&1 | grep -q "HTTP"; then
    STATUS=$(curl -s -I http://whoami.swarm.localhost/ 2>&1 | head -1)
    echo "✓ Service Whoami: $STATUS"
else
    echo "⚠️  Service Whoami ne répond pas"
fi

# Logs
echo ""
echo "=========================================="
echo "Logs (dernières 5 lignes)"
echo "=========================================="
echo ""
echo "--- Traefik ---"
docker service logs traefik_traefik 2>/dev/null | tail -5 || echo "Pas de logs disponibles"
echo ""
echo "--- Whoami ---"
docker service logs traefik_whoami 2>/dev/null | tail -5 || echo "Pas de logs disponibles"
