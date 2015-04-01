+++
date = "2015-04-01T15:05:07+02:00"
draft = true
title = "API REST tmail"
categories = ["doc"]
description = "Activation de l'API REST tmail"
keywords = ["api"]
tags = [ "api","http"]

+++

tmail embarque un <a href="http://fr.wikipedia.org/wiki/Serveur_HTTP" target="_blank" title="qu'est ce qu'un serveur HTTP"> serveur HTTP</a> qui expose une <a href="http://fr.wikipedia.org/wiki/Representational_State_Transfer" target="_blank" title="Qu'est ce qu'une API REST">API REST</a>. Cette API vous permet d’administrer votre serveur tmail et *\<teasing>* dans un futur "proche" votre cluster SMTP tmail*\</teasing>*.

<!--more-->

### Activation et configuration de l'API REST.

Vous devez d'abord spécifier que vous souhaitez activer le service:

	# Launch REST server
	export TMAIL_REST_SERVER_LAUNCH=true

Puis définir sur quelle IP il doit écouter: 

	# REST server IP
	export TMAIL_REST_SERVER_IP="127.0.0.1"

Et sur quel port:

	# REST server port
	export TMAIL_REST_SERVER_PORT=8080

Ce paramètre vous permet d'activer (ou non) le chiffrement de votre connexion:

	# REST server is TLS (https) ?
	export TMAIL_REST_SERVER_IS_TLS=true

tmail va utiliser le certificat dist/ssl/web_server.crt et la clé dist/ssl/web_server.key pour chiffrer les transactions. Vous pouvez utiliser ceux inclus dans la distribution pour vos tests mais attention cela va générer des alertes auprès des clients REST que vous allez utiliser.

**Si votre serveur REST écoute sur une IP publique, activer TLS n'est pas une option, c'est impératif car l'authentification se fait avec des mots de passe en clair  <a href="http://fr.wikipedia.org/wiki/Authentification_HTTP#M.C3.A9thode_.C2.AB_Basic_.C2.BB" target="_blank">(authentification HTTP Basic)</a>**

Enfin vous devez définir vos identifiants de connexion:

	# Login for HTTP auth
	export TMAIL_REST_SERVER_LOGIN="admin"

	# Passwd for HTTP auth
	export TMAIL_REST_SERVER_PASSWD="admin"

#### Test

Après avoir relancé tmail vous devriez voir dans vos logs une ligne de ce type:
	
	[trooper - 127.0.0.1] 2015/04/01 15:32:06.467484 INFO - httpd 127.0.0.1:8080 TLS launched

Vous pouvez tester le fonctionnement de l'API en appelant la ressource /ping. Par exemple avec <a href="http://curl.haxx.se/" target="_blank" title="tester une API REST avec curl">curl</a> :

	$ curl -k https://127.0.0.1:8080/ping
	{"msg": "pong"}

La ligne de log correspondant à cette requête : 

	[trooper - 127.0.0.1] 2015/04/01 15:48:58.183360 INFO - http 127.0.0.1:49536 - GET /ping - 200 OK 16.419µs

*Note: Non il n'y à pas d'erreur la requête à bien mis 0.000016 seconde pour être exécutée ;-)* 


## Généralités

### Authentification
L'API utilise l'authentification <a href="http://fr.wikipedia.org/wiki/Authentification_HTTP#M.C3.A9thode_.C2.AB_Basic_.C2.BB" target="_blank">HTTP Basic</a>. 

Pourquoi ce type d’authentification ?

* simple à mettre en œuvre
* compatible avec tous les clients HTTP


### Requêtes
Si il est nécessaire de transmettre des éléments à l'API (donc via POST, PUT ou PATCH), ils devront êtres encodés au format JSON.

### Réponses
Le corps, si il existe est lui aussi un message JSON. 

### Codes HTTP

Succès :

* 200 OK: La requête à été exécuté avec succès, la réponse contient un corps.
* 201 Created: L'entité à été crée. 
* 204 No Content: La requête à été exécuté avec succès, le corps de la réponse est vide. 

Erreurs :

* 400 Bad Request: Le requête est mal formée. 
* 401 Unauthorized: Une autorisation est nécessaire.
* 403 Forbidden: L’accès est refusé.
* 404 Not Found: La ressource demandée n'existe pas.
* 422 Unprocessable Entry: La requête visant à créer ou modifier une entité n'a pas pu être exécutée car les données transmises n'étaient pas conformes.
* 500, 501, 502, 503, etc: Une erreur à eu lieu au niveau du serveur.

### Erreurs

En cas d'erreur (4** ou 5**), un message sous forme d'un objet JSON est retourné.
Le message contient deux champs:
* msg: le message d'erreur générée par l'application
* raw: l'erreur levée (quand elle existe)

Exemple, si on essaye de créer un utilisateur qui existe déjà:

	curl -H "Content-Type: application/json" -X POST -d '{"passwd":"motdepasse","authRelay":true,"haveMailbox":true,"mailboxQuota":"1G"}' -u admin:admin -k https://127.0.0.1:8080/users/toorop@tmail.io

	< HTTP/1.1 422 status code 422
	< Content-Type: application/json; charset=UTF-8
	< Date: Wed, 01 Apr 2015 15:01:21 GMT
	< Content-Length: 85
	
	{"msg":"unable to create new user","raw":"UNIQUE constraint failed: users.login"}

	

