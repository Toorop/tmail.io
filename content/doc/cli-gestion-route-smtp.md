+++
date = "2015-01-28T09:15:12+01:00"
draft = true
title = "Gestion des routes SMTP en utilisant le CLI"

+++

Vous pouvez gérer les routes SMTP sortantes directement en ligne de commande, ce document vous donne les références concernant les fonctinnalités implémentées.

Avant d'aller plus loin je vous recommande la lecture de la [documentation expliquant le fonctionnement des routes SMTP](doc/routes-smtp-sortantes/)

### Lister toutes les routes

La commande pour lister les routes est:

	tmail routes list

Pour le moment il n'y a pas de paramétres pour spécifier des critéres de recherche. Si vous avez besoin de rechercher une route le plus simple pour le moment est d'utiliser l'outil *grep* pour filtrer la sortie de la commande *tmail routes list*.  
Par exemple si vous voulez chercher les routes faisant référence au domaine tmail.io :

	tmail routes list | grep tmail.io

### Ajouter une régle de routage SMTP

	tmail routes add -h HOST -r DESTINATION_HOST

#### Exmples

	tmail route add -h tmail.io -r mail.tmail.io -p 2525


### Supprimer une régle de routage SMTP

	tmail routes del ROUTE_ID

