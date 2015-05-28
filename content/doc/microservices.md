+++
date = "2015-05-28T10:24:01+02:00"
draft = false
title = "Micro-services"
categories = ["doc"]
description = "étendre tmail via des micro-services "
keywords = ["microservice","plugin"]
tags = [ "api","microservices"]

+++

Comme il ne peux y avoir autant d'usages possibles que de fonctionnalités implémentées, il m'a semblé important de pourvoir ajouter simplement des fonctionnalités à tmail.

Après avoir longuement réfléchis à la façon d'implémenter la chose, il m'a semblé que l'usage de micro-services était la meilleure solution. 

<!--more-->

Pourquoi ?

Voyons les contraintes:

* Fiable: est il vraiment nécessaire de préciser ce point ? ;)
* Facile: n'importe qui, à condition d'avoir quelques base en programmation, doit être en mesure d'écrire une extension pour tmail.
* Multi langage: on ne doit pas être limité à un langage de programmation.
* Scalable: on doit pouvoir adapter simplement et rapidement les ressources aux besoins.

Comment y répondre:

* De part leur indépendance vis à vis du logiciel client, ici tmail, les micro-services ne viendront impacter ce dernier en cas de problème. En clair si un micro-service plante, il n'y aura pas d'impact sur pas la fiabilité et le disponibilité du service.
* HTTP est un protocole répandu, fiable et maîtrisé par de nombreux dev, il est donc tout à fait adapté comme protocole de communication entre le client (tmail) et les micro-services.
* <a href="https://developers.google.com/protocol-buffers/" target="_blank" title="Protocol Buffers"> Protocol Buffers </a> est un format de sérialisation très performant, il permet un contrôle sur la structure et le type des donnés échangées, des implémentations existent dans les langages les plus courant,.. bref il semble le parfait candidat pour ce qui concerne le format d'échange de données.. 


## Sommaire

* [Principes de base ]({{<ref "#principes" >}})
* [Configuration ]({{<ref "#configuration" >}})
	* [Paramètres]({{<ref "#parametres" >}})
* [Réponses ]({{<ref "#reponses" >}})	
	* [SmtpdResponse ]({{<ref "#smtpdreponse" >}})	 
* [Points d'entré ]({{<ref "#hooks" >}})	
	* [Initialisation de la connexion]({{<ref "#smtpdnewclient" >}})	
	* [Après la commande DATA]({{<ref "#smtpddata" >}}) 	
* [Exemples d'implémentation]({{<ref "#exempleimpl" >}})
* [Micro-Services As Service]({{<ref "#msas" >}})
	* [Grey SMTP]({{<ref "#greysmtpd" >}}) 
	* [Vérification DKIL]({{<ref "#dkimverif" >}}) 

## Principes de base {#principes}

A différentes étapes du traitement, tmail va vérifier si des micro-services sont configurées et le cas échéant il va les interroger.

Prenons un exemple concret, si un micro-service est configuré pour être interrogé lors de l’établissement d'une connexion avec un nouveau client SMTP, tmail va sérialiser l'identifiant de la sessions SMTP et l'adresse IP du client distant et va les transmettre via une requête HTTP POST vers le micro service. 

Il va attendre (ou pas), là réponse et en fonction de cette dernière, va soit continuer le traitement, soit l'interrompre en transmettant un message au client.

La tache du micro-service pourrait être, par exemple, de vérifier si l'IP est blacklistée sur une RBL, et si c'est le cas alors le micro-service "demanderait" à tmail de refuser la connexion. (ce qui en passant n'est pas une bonne idée, mais bon, c'est pour l'exemple ;) )


## Configuration {#configuration}

Pour chaque étape où des micro-services sont appelables, vous allez trouver dans le fichier de configuration une variable de ce type :

	# Microservices
	# On new incomming SMTP connection
	TMAIL_MS_SMTPD_NEWCLIENT=""

Un micro-service est défini par une URL:

	https://ms.tmail.io/smtpdnewclient?param1=x&param2=y

Avec:

* https://ms.tmail.io/smtpdnewclient: l'URL vers laquelle sera posté les données sérialisées
* "param1=x&param2=y" les paramètres de configuration de ce micro-service (voir la liste plus bas). Attention ces paramètres ne seront pas transmis au micro-services.

Il est possible, d'appeler plusieurs micro-services en séparant les URL d'un point virgule.  

Par exemple :

	TMAIL_MS_SMTPD_NEWCLIENT="https://ms.tmail.io/check-spamcop?timeout=15; https://ms.tmail.io/stats?fireandforget=true"

Dans ce cas tmail va appeler https://ms.tmail.io/check-spamcop et ensuite https://ms.tmail.io/stats


### Paramètres {#parametres} 
Les paramètres d'URL actuellement reconnu par tmail sont:

* **timeout** (default: 30): permet d'indiquer un timeout (en seconde) sur un appel. Par défaut il est de 30 secondes.
* **onfailure** (default: continue): permet de spécifier une action si un appel échoue. Globalement un appel échoue si le timeout est déclenché ou si le code de retour HTTP indique une erreur (4xx ou 5xx).
Les valeurs possibles pour ce paramètre sont:
	* continue: le traitement continue normalement.
	* tempfail: si une erreur à lieu pendant une transaction SMTP entrante, une temporaire (4xx) est retournée au client SMTP (xx), si c'est pendant la livraison d'un mail ou lors d'une transaction sortante le mail est remis en queue.
	* permfail: si une erreur à lieu pendant une transaction SMTP entrante, une erreur permanente (5xx) est retournée au client SMTP, si c'est pendant la livraison d'un mail ou lors d'une transaction sortante le mail est remis en queue.
* **fireandforget** (default false): si ce paramètre est défini à true, tmail va exécuter la requête dans un process parallèle et ne va pas tenir compte de la réponse. Autrement dit ce genre de traitement n'a aucune incidence sur le traitement réalisé par tmail. Attention cette option n'est pas disponible pour tous les hooks.

## Réponses {#reponses} 
Les réponses retournée par le micro-service sont des structures sérialisés avec protobuf, elles sont définies par leur fichier .proto

Vous trouverez le fichier proto <a href="hhttps://github.com/toorop/tmail-ms-server/tree/master/proto" target="_blank" title="tmail proto"> https://github.com/toorop/tmail-ms-server/tree/master/proto</a>

### SmtpdResponse {#smtpdreponse} 
C'est cette structure que votre microservice doit retourner si il est appelé durant une transaction SMTP entrante.

Sa définition est la suivante :
	
	message SmtpdResponse {
		required int32 smtp_code = 1; 	// SMTP code
		required string smtp_msg = 2; 	// SMTP message

		optional bool close_connection = 16;// if true connection wil be closed
		optional string data_link = 17; 	// link for downloading additional (large) data 
		repeated string extra_headers = 18; // headers to add 
	}


Avec:

* **smtp_code** (requis): le code SMTP qui, si il est différent de 0, va être retourné au client.
* **smtp_msg** (requis): le message qui, si il est différent de "" (chaîne vide), va être associé au code SMTP pour créer la réponse à retourner au client.
* **close_connection** (optionnel, défaut: false): si ce paramètre est à défini sur *true* alors tmail, va mettre fin à la transaction après avoir retourné au client les message "smtp_code smtp_msg" si il est défini, ou un message d'erreur temporaire dans le cas contraire.
* **data_link** (optionnel): lien pointant vers des données trop volumineuses pour êtres contenues dans la réponse.
* **extra_headers** (optionnel): d'éventuels headers à ajouter.

Je suppose que certain d'entre vous se demandent: pourquoi est il passé de 2 à 16 ? Parce que protobuf ne va pas encoder les noms des variables mais va utiliser le *flag* qui lui est associé. Si ce flag est inférieur à 16, une fois encodé le flag et le type de la variable vont occuper un byte, à partir de 16, il va falloir utiliser 2 bytes. Autrement dit, il est judicieux de conserver les tags 1 à 15 pour les éléments requis et 16 et plus pour ceux qui sont optionnels histoire de gagner quelque bytes.


## Étapes "hookables" {#hooks} 
Voici la liste des points (hook) où il est possible d'étendre tmail par l'usage de micro-services.

### SmtpdNewClient: Établissement d'une nouvelle connexion SMTP entrante {#smtpdnewclient} 
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


### SmtpdData: Après la commande SMTP DATA {#smtpddata} 

Le point d'entré dans la configuration est :

	export TMAIL_MS_SMTPD_DATA=""

La structure transmise au micro-service est la suivante:

	message SmtpdDataMsg {
		required string session_id = 1;
		required string data_link = 2;
	}

Avec:

* **session_id** (requis): l'identifiant de la session SMTP qui traite cette transaction. Cet identifiant va être transmis dans tous les appels qui auront lieu durant une même transaction SMTP, il va donc permettre de suivre cette transaction, coté micro-service, et de lier les requêtes.

* **data_link** (requis): Un lien HTTP depuis lequel le micro-service pourra télécharger le mail transmis par le commande DATA.

La réponse attendue par tmail doit être un message du type *SmtpdResponse*.

## Exemples d'implémentation {#exempleimpl}

Vous trouverez sur https://github.com/toorop/tmail-ms-server différent exemples de micro-services pour tmail.
N'hésitez pas à participer à ce repo en proposant vos propres exemples. Si vous souhaitez publier un exemple dans un langage qui n'a pas encore de dossier spécifique, créez le à la racine du repo.


## μsas: Micro-Services As Services {#msas}

Un des autres intérêts de cette architecture est qu'il est possible de proposer des **micro-services as service**, autrement dit de mettre à dispositions des utilisateurs de tmail des micro-services que l'on a codé et que l'on héberge.

C'est ce que je vous propose ici, l'usage en est totalement libre et gratuit.  

Le code de ses micro-services est disponible ici: https://github.com/toorop/tmail-ms-server/tree/master/golang/ms.tmail.io


### SMTPD_NEWCLIENT: GreySmtpd  {#greysmtpd}

**URL:** https://ms.tmail.io/smtpdnewclientgreysmtpd

Ce service va accepter ou refuser temporairement la connexion en fonction de la réputation de l'IP du client. 

Un client SMTP légitime va tenter à plusieurs reprises de transmettre un mail en cas d'échec des tentatives précédentes (si le serveur à retourné une erreur temporaire), l'idée ici est donc d'exploiter cette fonctionnalité pour écarter un maximum de spambot.

Actuellement l'implémentation est la suivante:

* Si une IP est suspecte (pas de reverse || listée sur spamcop):
	* Si elle n'est pas connue du micro-service, ou si elle est connue depuis moins de 2 heures, une erreur temporaire est retournée.
	* Si elle est connue depuis plus de 3 heures et moins de 24 heures, on continue.
	* Si elle connue depuis plus de 24 heures, l'horodatage est réinitialisé, le micro-service l'oubli, et une erreur temporaire est retournée.


### SMTPD_DATA: DKIM verification {#dkimverif}
**URL:** https://ms.tmail.io/smtpddatadkimverif

Ce micro-service va vérifier la signature DKIM du mail, si le mail en a une, et va ajouter un header Authentication-Results.

Par exemple en cas de succès:

	Authentication-Results: dkim=success

En cas d'échec:

	Authentication-Results: dkim=permfail testing body hash did not verify
