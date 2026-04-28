#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Nettoyage de Traefik"
echo "=========================================="

cd "${SCRIPT_DIR}"

echo "Arrêt des services..."
docker compose down

echo ""
echo "=========================================="
echo "✓ Services arrêtés et supprimés!"
echo "=========================================="
