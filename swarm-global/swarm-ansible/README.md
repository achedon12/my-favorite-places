1. Démarrer les conteneurs:
    ```bash
    docker compose up -d
    ```

2. Exécuter le playbook Ansible:
    ```bash
      docker compose exec manager ansible-playbook -i /ansible/inventory.ini /ansible/init_swarm_cluster.yml
    ```

3. Vérifier les nœuds du Swarm

    ```bash
      docker compose exec manager docker node ls
    ```

4. Vérifier les services en cours

    ```bash
    docker compose exec manager docker service ls
    ```
