#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Vérification de Traefik"
echo "=========================================="

cd "${SCRIPT_DIR}"

# Vérifier les services
echo ""
echo "État des services:"
echo "=========================================="
docker compose ps

# Vérifier les logs
echo ""
echo "Logs Traefik (dernières 10 lignes):"
echo "=========================================="
docker compose logs --tail 10 traefik

# Vérifier la connectivité
echo ""
echo "Connectivité:"
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

# Tester avec curl
echo ""
echo "Test HTTP:"
echo "=========================================="
if curl -s -I http://whoami.swarm.localhost/ | grep -q "200\|301\|302"; then
    echo "✓ Whoami service répond"
else
    echo "⚠ Whoami service ne répond pas"
fi

if curl -s -I http://traefik.swarm.localhost:8080/ | grep -q "200"; then
    echo "✓ Dashboard Traefik répond"
else
    echo "⚠ Dashboard Traefik ne répond pas"
fi
