# Exercice 1

1. Lancer le docker compose avec une configuration de 1 manager et 3 workers :
   ```bash
     docker compose up --scale manager=1 --scale node=3 -d
   ```

2. init le swarm cluster et joindre les nodes au manager :
   ```bash
      docker exec ansible-demo-manager-1 docker swarm init
   ```
   
3. ajouter les nodes au cluster :
   ```bash
   docker exec ansible-demo-node-1 docker swarm join --token SWMTKN-1-26nnxx8xx7b3kl9o8szwkeb599oz5zsfcbmhwbwdq5e5oppuim-64j9zro0ynztepa5rycysxk52 172.80.11.3:2377
   docker exec ansible-demo-node-2 docker swarm join --token SWMTKN-1-26nnxx8xx7b3kl9o8szwkeb599oz5zsfcbmhwbwdq5e5oppuim-64j9zro0ynztepa5rycysxk52 172.80.11.3:2377
   docker exec ansible-demo-node-3 docker swarm join --token SWMTKN-1-26nnxx8xx7b3kl9o8szwkeb599oz5zsfcbmhwbwdq5e5oppuim-64j9zro0ynztepa5rycysxk52 172.80.11.3:2377
   ```
4. Ajouter l'overlay network pour traefik :
   ```bash
     docker exec ansible-demo-manager-1 docker network create -d overlay --attachable web
   ```

5. Déployer la stack traefik :
   ```bash
   docker exec -i ansible-demo-manager-1 docker stack deploy -c - traefik < traefik/stacks/traefik-stack.yml
   ```
   
6. Vérifier que les services sont en cours d'exécution :
   ```bash
     docker exec ansible-demo-manager-1 docker stack services traefik
   ```

# Exercice 2 et 3

Rajouté dans treafik-stack.yml