#!/bin/bash

set -e

STACK_NAME="traefik"

echo "=========================================="
echo "Nettoyage de la stack Traefik"
echo "=========================================="

# Vérifier que Docker Swarm est actif
if ! docker node ls > /dev/null 2>&1; then
    echo "❌ Erreur : Docker Swarm n'est pas actif"
    exit 1
fi

# Supprimer la stack
echo ""
echo "Suppression de la stack '${STACK_NAME}'..."
docker stack rm "${STACK_NAME}" || echo "  ℹ La stack n'existe pas"

# Attendre que la stack soit supprimée
echo "Attente (10 secondes)..."
sleep 10

# Supprimer le réseau overlay
echo ""
echo "Suppression du réseau 'web'..."
docker network rm web 2>/dev/null || echo "  ℹ Le réseau 'web' n'existe pas"

echo ""
echo "=========================================="
echo "✓ Nettoyage réussi!"
echo "=========================================="
echo ""
echo "Résumé:"
echo "  • Stack Traefik supprimée"
echo "  • Réseau overlay 'web' supprimé"
echo "  • Tous les services arrêtés"
echo ""
