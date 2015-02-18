+++
date = "2015-01-28T09:15:12+01:00"
draft = false
title = "Gestion des routes SMTP en utilisant le CLI"

+++

Vous pouvez gérer les routes SMTP sortantes directement en ligne de commande, ce document vous donne les références concernant les fonctionnalités implémentées.

Avant d'aller plus loin je vous recommande la lecture de la [documentation expliquant le fonctionnement des routes SMTP](doc/routes-smtp-sortantes/) principalement pour savoir l'ordre dans lequel les règles sont testées. Il faut savoir que la première route qui correspond sera celle qui sera utilisée, donc si vous ne voulez pas avoir de surprise il est capital de bien assimiler ce point.


<!--more-->

### Lister toutes les routes

La commande pour lister les routes est:

	tmail routes list

	1 - Destination host: toorop.fr - Prority: 1 - Local IPs: default - Remote host: mail.toorop.fr:25
	2 - Destination host: tmail.io - Prority: 1 - Local IPs: default - Remote host: mail.tmail.io:25


Pour le moment il n'y a pas de paramètres pour spécifier des critères de recherche. Si vous avez besoin de rechercher une route particulière, le plus simple pour le moment est d'utiliser l'outil *grep* pour filtrer la sortie de la commande *tmail routes list*.  
Par exemple si vous voulez chercher les routes faisant référence au domaine tmail.io :

	tmail routes list | grep tmail.io

### Ajouter une régle de routage SMTP

#### Aide en ligne

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


#### Exemples
Ajouter une route pour relayer les mails à destination du domaine tmail.io vers mail.tmail.io 

	tmail routes add -d tmail.io -rh mail.tmail.io

Vous pouvez spécifier un port distant 

	tmail routes add -d tmail.io -rh mail.tmail.io -rp 2525	

Si le serveur distant nécessite une authentification SMTP ajouter les options rl et rpwd

	tmail route add -d tmail.io -rh mail.tmail.io -rp 587 -rl login -rpwd passwd

Vous pouvez créer des routes qui vont agir en fonction de l'utilisateur qui à soumis le mail ( à la condition bien entendu qu'il se soit authentifié via SMTPAUTH). Imaginons par exemple que vous souhaitiez router les mails soumis par l'utilisateur toorop@tmail.io vers le relais premium.tmail.io

	tmail route add -rh premium.tmail.io -u toorop@tmail.io


Si vous voulez attribuer une route spécifique à tous les utilisateurs d'un domaine, la solution consiste  à utiliser leur adresse email comme login SMTP et ensuite de créer une règle en mettant le domaine comme valeur pour l'option u. Par exemple si vous souhaitez que les mails de tous les utilisateurs identifiés comme faisant partie du domaine domaine tmail.io aient leurs mails routés par Mailjet :

	tmail route add -rh in.mailjet.com -u tmail.io -rl mailjet_login -rpwd mailjet_passwd

Si vous voulez ajouter comme contrainte que l’expéditeur du mail (MAIL FROM) doit etre en @tmail.io :

	 tmail route add -rh in.mailjet.com -u tmail.io -f tmail.io -rl mailjet_login -rpwd mailjet_passwd

#### Round Robin
Vous pouvez mettre deux (ou plus) routes identiques. Bien entendu ça n'a aucun intérêt si ce sont les seules routes pour une destination donnée, mais dans le cas contraire cela permet de repartir les mails vers plusieurs relais en leur attribuant un poids. Par exemple imaginons que nous souhaitions faire passer deux fois plus de mails par big.smtp.tmail.io que par small.smtp.tmail.io :

	tmail route add -d tmail.io -rh big.smtp.tmail.io
	tmail route add -d tmail.io -rh big.smtp.tmail.io
	tmail route add -d tmail.io -rh small.smtp.tmail.io

#### Failover
En ajoutant un paramètre de priorité, vous pouvez créer des routes secondaires qui vont qui vont etres utilisé sur les routes de priorité plus élevées sont en échecs.

Par exemple:
	
	tmail route add -d tmail.io -rh main.smtp.tmail.io -p 1
	tmail route add -d tmail.io -rh alt1.smtp.tmail.io -p 2
	tmail route add -d tmail.io -rh alt2.smtp.tmail.io -p 3

Dans ce cas tmail va d'abord tenter de transmettre le mail à main.smtp.tmail.io puis ça ça échoue à alt1.smtp.tmail.io et si ça échoue toujours à alt2.smtp.tmail.io

Notez que vous pouvez mixer failover et roundrobin, par exemple: 
	
	tmail route add -d tmail.io -rh main.smtp.tmail.io -p 1
	tmail route add -d tmail.io -rh alt1.smtp.tmail.io -p 2
	tmail route add -d tmail.io -rh alt2.smtp.tmail.io -p 2

Dans ce cas si tmail n'arrive pas a transmettre le mail à main.smtp.tmail.io il va faire le second essais vers alt1 ou alt2.

### Supprimer une règle de routage SMTP

	tmail routes del ROUTE_ID




	



