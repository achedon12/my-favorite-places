# Exercice 2

1. Création du fichier [compose.yaml](./compose.yaml) avec le contenu suivant :
    ```yaml
    version: '3.8'
    
    services:
    
      manager:
        container_name: manager
        image: docker:dind
        privileged: true
    
      node-1:
        container_name: node-1
        image: docker:dind
        privileged: true
    
      node-2:
        container_name: node-2
        image: docker:dind
        privileged: true
    
      node-3:
        container_name: node-3
        image: docker:dind
        privileged: true
    ```

2. Vérification de des services

    ```bash
      docker ps
    ```

3. Installation de vim dans les containers

    ```bash
      docker exec -i manager apk add vim
      docker exec -i node-1 apk add vim
      docker exec -i node-2 apk add vim
      docker exec -i node-3 apk add vim
    ```
4. Rentrer dans les containers et vérifier que docker est installé

    ```bash
      docker exec -it manager ash
      docker exec -it node-1 ash
      docker exec -it node-2 ash
      docker exec -it node-3 ash
    ```

   ```bash
     docker --version
   ```

5. Création du cluster swarm

   > Attention : le cluster swarm doit être créé à partir du manager
    ```bash
      docker swarm init
    ```

   > Le retour :
   > ```text
   > Swarm initialized: current node (nueqo5oowvanekfruiep8tlff) is now a manager.
   > To add a worker to this swarm, run the following command:
   >
   > docker swarm join --token SWMTKN-1-2ob44cr1en5jddj52ntawymphr0l86zorq4odafhcw29npoudi-2jfgcfmu580cdnr2he3ciy88m 172.80.8.4:2377
   >
   > To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
   > ```

6. Ajouter les nodes au cluster swarm

   > Attention : les commandes suivantes doivent être exécutées à partir des nodes
    ```bash
      docker swarm join --token SWMTKN-1-2ob44cr1en5jddj52ntawymphr0l86zorq4odafhcw29npoudi-2jfgcfmu580cdnr2he3ciy88m manager:2377
    ```

7. Vérification du cluster swarm

   > Attention : la commande suivante doit être exécutée à partir du manager
    ```bash
      docker node ls
    ```
# Exercice 3