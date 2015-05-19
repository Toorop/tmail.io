+++
date = "2015-05-17T10:24:01+02:00"
draft = true
title = "Microservices"
categories = ["doc"]
description = "étendre tmail via des micro-services "
keywords = ["microservice","plugin"]
tags = [ "api","microservices"]

+++

Comme il ne peux y avoir autant d'usages possibles que de fonctionnalités implémentées, il m'a semblé important de pourvoir ajouter très simplement des fonctionnalités à tmail.

Après avoir longuement réfléchis à la façon d'apporter cette "feature" il m'a semblé que l'usage de micro-services était la meilleure solution. 

<!--more-->

Pourquoi ?

Les contraintes:

* Fiable: Est il vraiment nécessaire de préciser ce point ? ;)
* Facile: N'importe qui, à condition d'avoir quelques base en programmation, doit être en mesure d'écrire une extension pour tmail.
* Multi langage: On ne doit pas être limité à un langage de programmation.
* Scalable: on doit pouvoir adapter simplement et rapidement les ressources aux besoins.

Les réponses à ces contraintes:

* HTTP pour le protocole de transfert: HTTP est un protocole répandu, fiable et maîtrisé par de nombreux dev.
* Protocol Buffers pour la sérialisation des messages à échanger: il permet un contrôle sur la structure et le type les donnés, par ailleurs il est très performant aussi bien en terme de vitesse de sérialisation/dé-sérialisation qu'en terme de bande passante (la taille de la structure sérialisée). Enfin des implémentations existent dans les langages les plus courant.


## Sommaire

* [Principes de base ]({{<ref "#authentification" >}})

## Principes de base

A différentes étapes du traitement tmail va vérifier si des microservices sont configurées et les cas échéant il va les interroger.

Prenons un exemple concret, pour le moment en guise de "proof of concept", il n'y a qu'à une étape que tmail est extensible par des micro-services, c'est à l'initialisation d'une nouvelle connexion avec un client SMTP qui à un mail (ou plus) à transmettre à tmail.  
Si un micro-service est configuré, tmail va sérialiser les informations pertinentes, à ce stade l'identifiant de la sessions SMTP et l'adresse IP du client distant, et va les transmettre via une requête HTTP POST vers le microservice défini par par une URL. 

Il va attendre (ou pas), là réponse et en fonction de cette dernière, va soit continuer le traitement, soit l'interrompre en transmettant un message au client.


## Configuration

On signifie à tmail qu'il doit interroger un microservice à une étape donnée via la configuration, donc pour le moment en éditant le fichier de configuration.

Pour chaque étape où des microservices sont appelables, vous allez trouver dans le fichier de configuration des variables de ce type :

	# Microservices
	# On new incomming SMTP connection
	TMAIL_MS_SMTPD_NEWCLIENT=""

Un microservice est défini par une URL:

	https://ms.tmail.io/smtpdnewclient?param1=x&param2=y

Avec:

* https://ms.tmail.io/smtpdnewclient: l'URL vers laquelle sera posté les données sérialisées
* "param1=x&param2=y" les paramètres de configuration de ce microservice (voir la liste plus bas)


Il est possible, d'appeler plusieurs microservices en séparant les URL d'un point virgule.  

Par exemple :

	TMAIL_MS_SMTPD_NEWCLIENT="https://ms.tmail.io/check-spamcop?timeout=15; https://ms.tmail.io/stats?fireandforget=true"

Dans ce cas tmail va appeler https://ms.tmail.io/check-spamcop et ensuite https://ms.tmail.io/stats


### Paramètres 
Les paramètres d'URL actuellement reconnu par tmail sont:

* **timeout** (default: 30): permet d'indiquer un timeout en seconde sur un appel. Par défaut il est de 30 secondes.
* **onfailure** (default: continue): permet de spécifier un action si un appel échoue. Globalement un appel échoue si le timeout est déclenché ou si le code de retour HTTP indique une erreur (4xx ou 5xx).
Les valeurs possibles pour ce paramètre sont:
	* continue: le traitement continue normalement.
	* tempfail: si une erreur à lieu pendant une transaction SMTP entrante, une temporaire (4xx) est retournée au client SMTP (xx), si c'est pendant la livraison d'un mail ou lors d'une transaction sortante le mail est remis en queue.
	* permfail: si une erreur à lieu pendant une transaction SMTP entrante, une erreur permanente (5xx) est retournée au client SMTP, si c'est pendant la livraison d'un mail ou lors d'une transaction sortante le mail est remis en queue.
* **fireandforget** (default false): si ce paramètre est défini à true, tmail va exécuter la requête dans un process parallèle et ne va pas tenir compte de la réponse. Autrement dit ce genre de traitement n'a auune incidence sur le traitement réalisé par tmail. Usages types: log, stat,...

## Réponses
Les réponses retournée par le microservice sont des structures sérialisés avec protobuf qui sont définies par leur fichier .proto

TODO: je vais mettre en lignes le .proto qui défini les messages et les réponses.

### SmtpdResponse
C'est cette structure que votre microservice doit retourner si il est appelé durant une transaction SMTP entrante.

Sa définition est la suivante :
	
	message SmtpdResponse {
		required int32 smtp_code = 1; 	// SMTP code
		required string smtp_msg = 2; 	// SMTP message

		optional bool close_connection = 16;		// if true connection wil be closed
		optional string data_link = 17; // link for downloading additional - large - data (ie raw mail)
		repeated string headers2add = 18; // headers to add 
	}


Avec:

* **smtp_code** (requis): le code SMTP qui, si il est différent de 0, va être retourné au client.
* **smtp_msg** (requis): le message qui, si il est différent de "" (chaîne vide), va être associé au code SMTP pour créer la réponse à retourner au client.
* **close_connection** (optionnel, défaut: false): si ce paramètre est à défini sur *true* alors tmail, va mettre fin à la transaction après avoir retourné au client les message "smtp_code smtp_msg" si il est défini, ou un message d'erreur temporaire dans le cas contraire.
* **data_link** (optionnel): lien pointant vers des données trop volumineuses pour êtres contenues dans la réponse. (TODO)
* **headers2add** (optionnel): d'éventuels headers à ajouter. (TODO)

Je suppose que certain d'entre vous se demandent: pourquoi est il passé de 2 à 16 ? Parce que protobuf ne va pas encoder les noms des variables mais va utiliser le *flag* qui lui est associé. Si ce flag est inférieur à 16, une fois encodé le flag et le type de la variable vont occuper un byte, à partir de 16, il va falloir utiliser 2 bytes. Autrement dit, il est judicieux de conserver les tags 1 à 15 pour les éléments requis et 16 et plus pour ceux qui sont optionnels histoire de gagner quelque bytes.


## Etapes "hookables"
Voici la liste des points (hook) où il est possible d'étendre tmail par l'usage de micro-services.

### SmtpdNewClient: Établissement d'une nouvelle connexion SMTP entrante
Le point d'entré dans la configuration est :

	TMAIL_MS_SMTPD_NEWCLIENT=""

La structure transmise au micro-service est la suivante:

	message SmtpdNewClientMsg {
		required string session_id = 1; // smtpd session ID
		required string remote_ip = 2; 	// remote (client) IP
	}	

Avec:

* **session_id** (requis): l'identifiant de la session SMTP qui traite cette transaction. Cet identifiant va être transmis dans tous les appels qui auront lieu durant une même transaction SMTP, il va donc permettre de suivre cette transaction, coté micro-service, et de lier les requêtes.

* **remote_ip** (requis): contient l'IP du client.

La réponse attendue par tmail doit être un message du type *SmtpdResponse*.

## Exemples d'implémentation :

Vous trouverez sur https://github.com/toorop/tmail-ms-server différent exemples de micro-services pour tmail.
N'hésitez pas à participer à ce repo en proposant vos propres exemples. Si vous souhaitez publier un exemple dans un langage qui n'a pas encore de dossier spécifique, créez le à la racine du repo.

## Micro-Services As Services - μsas

Un des intérêts de cette architecture est qu'il est possible de proposer des micro-services as service, autrement dit de mettre à dispositions des utilisateurs de tmail des micro-services que l'on a codé et que l'on héberge.

C'est ce que je vous propose ici, l'usage en est totalement libre et gratuit.  
Le code de ses micro-services est disponible ici: https://github.com/toorop/tmail-ms-server/tree/master/golang/ms.tmail.io


### SmtpdNewClient::GreySmtpd  

**URL:** https://ms.tmail.io/smtpdnewclientgreysmtpd

Ce service va accepter ou refuser temporairement la connexion en fonction de la réputation de l'IP du client. 

Un client SMTP légitime va tenter à plusieurs reprises de transmettre un mail en cas d'échec des tentatives précédentes (si le serveur à retourné une erreur temporaire), l'idée ici est donc d'exploiter cette fonctionnalité pour écarter un maximum de spambot.

Actuellement l'implémentation est la suivante:

* Si une IP est suspecte (pas de reverse || listée sur spamcop):
	* Si elle n'est pas en base de données, ou si elle y est depuis moins de 2 heures une erreur temporaire est retournée.
	* Si elle est en DB depuis plus de 2 heures et moins de 36 heures, on continue.
	* Si elle est en DB depuis plus de 36 heures, l'horodatage est réinitialisé et une erreur temporaire est retournée.













