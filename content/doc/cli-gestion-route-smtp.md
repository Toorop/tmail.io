+++
date = "2015-01-28T09:15:12+01:00"
draft = true
title = "Gestion des routes SMTP en utilisant le CLI"

+++

Vous pouvez gérer les routes SMTP sortantes directement en ligne de commande, ce document vous donne les références concernant les fonctionnalités implémentées.

Avant d'aller plus loin je vous recommande la lecture de la [documentation expliquant le fonctionnement des routes SMTP](doc/routes-smtp-sortantes/)

### Aide en ligne

	tmail routes add --help
	NAME:
   		add - Add a route
	USAGE:
   		command add [command options] [arguments...]
	DESCRIPTION:
   		tmail routes add -d DESTINATION_HOST -rh REMOTE_HOST [-rp REMOTE_PORT] [-p PRORITY] [-l LOCAL_IP] [-u AUTHENTIFIED_USER] [-f MAIL_FROM] [-rl REMOTE_LOGIN] [-rpwd REMOTE_PASSWD]

	OPTIONS:
   		--destination, -d 		hostame destination, eg domain in rcpt user@domain
   		--remote host, --rh 		remote host, eg where email should be deliver
   		--remotePort, --rp "25"	Route port
   		--priority, -p "1"		Route priority. Lowest-numbered priority routes are the most preferred
   		--localIp, -l 		Local IP(s) to use. If you want to add multiple IP separate them by | for round-robin or & for failover. Don't mix & and |
   		--smtpUser, -u 		Routes for authentified user user.
   		--mailFrom, -f 		Routes for MAIL FROM. User need to be authentified
   		--remoteLogin, --rl 		SMTPauth login for remote host
   		--remotePasswd, --rpwd 	SMTPauth passwd for remote host


### Lister toutes les routes

La commande pour lister les routes est:

	tmail routes list

	1 - Destination host: toorop.fr - Prority: 1 - Local IPs: default - Remote host: mail.toorop.fr:25
	2 - Destination host: tmail.io - Prority: 1 - Local IPs: default - Remote host: mail.tmail.io:25


Pour le moment il n'y a pas de paramètres pour spécifier des critères de recherche. Si vous avez besoin de rechercher une route le plus simple pour le moment est d'utiliser l'outil *grep* pour filtrer la sortie de la commande *tmail routes list*.  
Par exemple si vous voulez chercher les routes faisant référence au domaine tmail.io :

	tmail routes list | grep tmail.io

### Ajouter une régle de routage SMTP

	tmail routes add -h HOST -r DESTINATION_HOST

#### Exemples
Ajouter une route pour relayer les mails à destination du domaine tmail.io vers mail.tmail.io 

	tmail routes add -d tmail.io -rh mail.tmail.io

Ajouter une route pour relayer les mails à destination du domaine tmail.io vers mail.tmail.io en utilisant le port distant 587 et une priorité 2. Concrètement si la règle précédente existe elle va être testée en premier, et si ça ne passe pas par le port 25 tmail va essayer de transmettre les mails en utilisant le port 587.

	tmail route add -h tmail.io -rh mail.tmail.io -rp 587 -p 2


Si le serveur distant nécessite une authentification SMTP ajouter les options rl et rpwd

	tmail route add -h tmail.io -rh mail.tmail.io -rl login -rpwd passwd

Vous pouvez créer des routes qui vont agir en fonction de l'utilisateur qui à soumis le mail, à la condition bien entendu qu'il ce soit authentifié. Imaginons par exemple que vous vouliez router les mails soumis par l'utilisateur toorop par le relais premium.tmail.io

	tmail route add -rh premium.tmail.io -u toorop



### Supprimer une règle de routage SMTP

	tmail routes del ROUTE_ID

### Tips
Vous pouvez mettre deux (ou plus) routes identiques. Bien entendu ça n'a aucun intérêt si ce sont les seules routes pour une destination donnée, mais dans le cas contraire cela permet de repartir les mails vers plusieurs relais en leur attribuant un poids. Par exemple imaginons que nous souhaitions faire passer deux fois plus de mails par big.smtp.tmail.io que par small.smtp.tmail.io :

	tmail route add -h tmail.io -rh big.smtp.tmail.io
	tmail route add -h tmail.io -rh big.smtp.tmail.io
	tmail route add -h tmail.io -rh small.smtp.tmail.io


