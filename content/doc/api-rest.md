+++
date = "2015-04-02T11:14:47+02:00"
draft = false
title = "Utilisez l'API REST"
categories = ["doc"]
description = "Utiliser l'API REST tmail"
keywords = ["api"]
tags = [ "api","rest"]

+++

Vous trouverez dans ce document toutes les informations nécessaires pour utiliser l'API REST tmail.

<!--more-->

## Sommaire

* [Authentification]({{<ref "#authentification" >}})
* [Requêtes]({{<ref "#requetes" >}})
* [Codes HTTP]({{<ref "#http_code" >}})
* [Erreurs]({{<ref "#erreurs" >}})

* [Gestion des utilisateurs]({{<ref "#users" >}})
	* [Ajouter un utilisateur]({{<ref "#usersAdd" >}})
	* [Supprimer un utilisateur]({{<ref "#usersDel" >}})
	* [Retrouver un utilisateur]({{<ref "#usersGetOne" >}})
	* [Retrouver tous les utilisateurs]({{<ref "#usersGetAll" >}})
* [Gestion de la queue]({{<ref "#queue" >}})
	* [Lister les messages en queue]({{<ref "#queueListMessages" >}})
	* [Récuperer les information concernant un message]({{<ref "#queueGetMessage" >}})
	* [Supprimer un message]({{<ref "#queueDiscardMessage" >}})
	* [Bouncer un message]({{<ref "#queueBounceMessage" >}})	


### Authentification {#authentification}
L'API utilise l'authentification <a href="http://fr.wikipedia.org/wiki/Authentification_HTTP#M.C3.A9thode_.C2.AB_Basic_.C2.BB" target="_blank">HTTP Basic</a>. 

Pourquoi ce type d’authentification ?

* simple à mettre en œuvre
* compatible avec tous les clients HTTP

Exemple avec curl:

	curl -v -u admin:admin -k https://127.0.0.1:8080/users/toorop@tmail.io

	
### Requêtes {#requetes}
Si il est nécessaire de transmettre des éléments à l'API (donc via POST, PUT ou PATCH), ils devront êtres encodés au format JSON.

### Réponses {#reponses}
Le corps, si il existe est lui aussi un message JSON. 

### Codes HTTP {#http_code}

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

### Erreurs {#erreurs}

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


## Gestion des utilisateurs	{#users}
### Ajouter un utilisateur {#usersAdd}

* Ressource: /users/LOGIN
* Méthode: POST
* Body: 
	* passwd (string): mot de passe de l'utilisateur.
	* authRelay (bool): défini si l'utilisateur peut utiliser tmail pour relayer. 
	* haveMailbox (bool): défini si l'utilisateur à une boite email.
	* mailboxQuota (string): le quota de la boite email de l'utilisateur en bytes. Vous pouvez utiliser K, M, ou G pour fénir les unités (par exemple 1G signifie un GB)

Exemple:

	curl -v -u admin:admin -k -H "Content-Type: application/json" -X POST -d '{"passwd": "mot de passe", "authRelay": true, "haveMailbox": true, "mailboxQuota": "1G"}' https://127.0.0.1:8080/users/test@tmail.io

	< HTTP/1.1 201 Created


### Supprimer un utilisateur {#usersDel}

* Ressource: /users/LOGIN
* Méthode: DELETE

Exemple:

	curl -v -u admin:admin -k  -X DELETE https://127.0.0.1:8080/users/test@tmail.io
	
	< HTTP/1.1 200 OK


### Retrouver un utilisateur {#usersGetOne}

* Ressource: /users/LOGIN
* Méthode: GET

Exemple:

	curl -v -u admin:admin -k https://127.0.0.1:8080/users/test@tmail.io
	
	< HTTP/1.1 200 OK
	< Content-Type: application/json; charset=UTF-8

	{"Id":10,"Login":"test@tmail.io","Passwd":"$2a$10$TGg8af6X08KFvWDnjljAqeBpwkXuQ78sc.xyTUrHN6nRzm1wMyIT.","DovePasswd":"$6$06a585cd9d0540d2$OYGaBsyonWxeuoRQkxsokLRkW/vUtx1qbZoEC1DG9DcX7NmHqgrqQtIuL0N6r0RuPpOOhgMdiXPYr/0Dg.wA41","Active":"Y","AuthRelay":true,"HaveMailbox":true,"MailboxQuota":"1G","Home":"/home/toorop/Projects/Go/src/github.com/toorop/tmail/dist/mailboxes/t/tmail.io/t/test"}



### Retrouver tous les utilisateurs {#usersGetAll}

* Ressource: /users
* Méthode: GET

Exemple:

	curl -v -u admin:admin -k https://127.0.0.1:8080/users

	< HTTP/1.1 200 OK
	< Content-Type: application/json; charset=UTF-8

	[{"Id":4,"Login":"texset@tmail.io","Passwd":"$2a$10$rih8MngreLiYl6KzB72jVuufgtIHYFF08c4Q.GNIx2UObPOrL18QW","DovePasswd":"$6$ba3b4fb33607b031$5.FuzhmYBHK5fBIGSMamG7nv7G/OfHxGBuGPBkfSU0FiE6AvWAJIplz/RJP5AQoTFrKC.vYulBeKlKm/Ua7Gj.","Active":"Y","AuthRelay":false,"HaveMailbox":false,"MailboxQuota":"","Home":""},{"Id":5,"Login":"texsdet@tmail.io","Passwd":"$2a$10$Lnvy5ViilsKwAKKLsxhrZOhlcZkW.gbDvffEpyEif6Fefc5NU0iOe","DovePasswd":"$6$8c69e981ea71fa91$WRbtGb6AnEKQo.wSRd2VecOkjiHKCr/SVK0ww.qqK/O.wAjLNUn6ztEpONycwFYwiLWU82rI52A8rLzqrNsE./","Active":"Y","AuthRelay":false,"HaveMailbox":false,"MailboxQuota":"","Home":""}]


## Gestion de la queue {#queue}
### Lister les messages en queue {#queueListMessages}

* Ressource: /queue
* Méthode: GET

Exemple:

	curl -v -u admin:admin -k https://127.0.0.1:8080/queue

	< HTTP/1.1 200 OK
	< Content-Type: application/json; charset=UTF-8

	[{"Id":1,"Uuid":"5217dfdc96d7216d7074b329f88d11f76dee997b","Key":"84855041283d1badc5224231b2afa57f6e1b12e2","MailFrom":"toorop@tmail.io","AuthUser":"toorop@tmail.io","RcptTo":"toorop@toorop.fr","MessageId":"5528C725.8060007@tmail.io","Host":"toorop.fr","AddedAt":"2015-04-11T09:03:02.737629459+02:00","NextDeliveryScheduledAt":"2015-04-11T16:44:35.994411773+02:00","Status":2,"DeliveryFailedCount":0},{"Id":2,"Uuid":"bd36f47dab0e27482ce5db8605415e32978f0185","Key":"38b27d32311b21f1e6afa6215a756c8f696979a8","MailFrom":"toorop@tmail.io","AuthUser":"toorop@tmail.io","RcptTo":"stephane@protecmail.com","MessageId":"5529331C.3050308@tmail.io","Host":"protecmail.com","AddedAt":"2015-04-11T16:43:41.965596115+02:00","NextDeliveryScheduledAt":"0001-01-01T00:09:21+00:09","Status":0,"DeliveryFailedCount":0}]


### Récuperer les information concernant un message {#queueGetMessage}

* Ressource: /queue/ID
* Méthode: GET

Exemple:

	curl -v -u admin:admin -k https://127.0.0.1:8080/queue/1

	< HTTP/1.1 200 OK
	< Content-Type: application/json; charset=UTF-8

	{"Id":1,"Uuid":"5217dfdc96d7216d7074b329f88d11f76dee997b","Key":"84855041283d1badc5224231b2afa57f6e1b12e2","MailFrom":"toorop@tmail.io","AuthUser":"toorop@tmail.io","RcptTo":"toorop@toorop.fr","MessageId":"5528C725.8060007@tmail.io","Host":"toorop.fr","AddedAt":"2015-04-11T09:03:02.737629459+02:00","NextDeliveryScheduledAt":"2015-04-11T17:15:36.290267337+02:00","Status":2,"DeliveryFailedCount":0}


### Supprimer un message {#queueDiscardMessage}

* Ressource: /queue/discard/ID
* Méthode: DELETE

Exemple:

	curl -v -u admin:admin -X DELETE -k https://127.0.0.1:8080/queue/discard/1

	< HTTP/1.1 200 OK

### Bouncer un message {#queueBounceMessage}

* Ressource: /queue/bounce/ID
* Méthode: DELETE

Exemple:

	curl -v -u admin:admin -X DELETE -k https://127.0.0.1:8080/queue/bounce/1

	< HTTP/1.1 200 OK

