#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Déploiement de Traefik avec Docker Compose"
echo "=========================================="

# Déployer avec docker compose
echo ""
echo "Démarrage des services..."
cd "${SCRIPT_DIR}"
docker compose up -d

# Attendre que les services soient prêts
echo ""
echo "Attente du démarrage des services (15 secondes)..."
sleep 15

# Vérifier l'état
echo ""
echo "=========================================="
echo "Services déployés"
echo "=========================================="
docker compose ps

echo ""
echo "=========================================="
echo "Mise à jour du fichier /etc/hosts"
echo "=========================================="

# Mettre à jour /etc/hosts
if ! grep -q "traefik.swarm.localhost" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1  traefik.swarm.localhost" >> /etc/hosts 2>/dev/null || \
    (echo "⚠️  Vous devez ajouter manuellement à /etc/hosts:" && \
     echo "   127.0.0.1  traefik.swarm.localhost" && \
     echo "   127.0.0.1  whoami.swarm.localhost")
    echo "✓ traefik.swarm.localhost ajouté"
else
    echo "✓ traefik.swarm.localhost déjà présent"
fi

if ! grep -q "whoami.swarm.localhost" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1  whoami.swarm.localhost" >> /etc/hosts 2>/dev/null || true
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
echo "Commandes utiles:"
echo "  - Voir les logs: docker compose logs -f traefik"
echo "  - Arrêter: docker compose down"
echo "  - Redémarrer: docker compose restart"
echo ""
