+++
date = "2015-05-28T10:24:01+02:00"
draft = false
title = "Micro-services"
categories = ["doc"]
description = "étendre tmail via des micro-services "
keywords = ["microservice","plugin"]
tags = [ "api","microservices"]

+++

Comme un serveur SMTP peut avoir une infinité de fonctionnalités et que l'on ne peut les implémenter toutes, tmail dispose d'un systéme permettant d'ajouter des fonctionalités par le biais de micro-services servis via HTTP.

<!--more-->

Pourquoi des microservices pour étendre tmail ?

Voyons les contraintes liées à ce besoin:

* Fiable: est il vraiment nécessaire de préciser ce point ? ;)
* Facile: n'importe qui, à condition d'avoir quelques base en programmation, doit être en mesure d'étendre tmail pour l'adapter à ses besoins.
* Multi language: un langage de programmation spécifique ne doit pas être  imposé pour implémenter une nouvelle fonctionnalité.
* Scalable: on doit pouvoir adapter simplement et rapidement les ressources aux besoins.

Comment y répondre:

* De part leur indépendance vis à vis du logiciel client, les micro-services ne viendront pas impacter tmail en cas de problème. En clair si un micro-service plante, ca ne va pas faire planter tmail.
* HTTP est un protocole répandu, fiable et maîtrisé par de nombreux développeur, il est tout à fait adapté comme protocole de communication entre le client (tmail) et les micro-services. De plus il est facilement scalable.
* <a href="https://developers.google.com/protocol-buffers/" target="_blank" title="Protocol Buffers"> Protocol Buffers </a> est un format de sérialisation très performant, il permet un contrôle fin sur la structure et le type des donnés échangées, des implémentations existent dans les langages les plus courant,.. bref il semble le parfait candidat pour ce qui concerne le format d'échange de données..


## Sommaire

* [Principes de base ]({{<ref "#principes" >}})
* [Configuration ]({{<ref "#configuration" >}})
	* [Paramètres]({{<ref "#parametres" >}})
* [Structure des messages ]({{<ref "#protobuf" >}})
	* [SmtpdResponse ]({{<ref "#smtpdreponse" >}})
* [Points d'entré ]({{<ref "#hooks" >}})
	* [Initialisation de la connexion]({{<ref "#smtpdnewclient" >}})
	* [Commande SMTP RCPT TO]({{<ref "#smtpdrcptto" >}})
	* [Commande SMTP DATA]({{<ref "#smtpddata" >}})
	* [Livraison: routage dynamique]({{<ref "#deliverdgetroutes" >}})
* [Exemples d'implémentation]({{<ref "#exempleimpl" >}})
* [Micro-Services As Service]({{<ref "#msas" >}})
	* [Grey SMTP]({{<ref "#greysmtpd" >}})
	* [Vérification DKIL]({{<ref "#dkimverif" >}})

## Principes de base {#principes}

A différentes étapes de la "chaine SMTP", tmail va vérifier si des micro-services sont configurées et le cas échéant il va les interroger.

Prenons un exemple concret, si un micro-service est configuré pour être interrogé lors de l’établissement d'une connexion avec un nouveau client SMTP, tmail va sérialiser l'identifiant de la sessions SMTP et l'adresse IP du client distant et va les transmettre via une requête HTTP POST vers le micro service.

Il va attendre (ou pas) la réponse et en fonction de cette dernière va agir en conséquence.

La tache du micro-service pourrait être, par exemple, de vérifier si l'IP est blacklistée sur une RBL, et si c'est le cas alors le micro-service demanderait à tmail de refuser la connexion. (ce qui en passant n'est pas une bonne idée, mais bon, c'est pour l'exemple ;) )


## Configuration {#configuration}

Pour chaque étape où des micro-services sont appelables, vous allez trouver dans le fichier de configuration une variable de ce type :

	# Microservices
	# On new incomming SMTP connection
	TMAIL_MS_SMTPD_NEWCLIENT=""

Un micro-service est défini par une URL:

	https://ms.tmail.io/smtpdnewclient?param1=x&param2=y

Avec:

* https://ms.tmail.io/smtpdnewclient: l'URL vers laquelle sera posté les données sérialisées.
* "param1=x&param2=y" les paramètres de configuration de ce micro-service (voir la liste plus bas).
**Attention** ces paramètres ne seront pas transmis au micro-services.

Il est possible, d'appeler plusieurs micro-services en séparant les URL d'un point virgule.  

Par exemple :

	TMAIL_MS_SMTPD_NEWCLIENT="https://ms.tmail.io/check-spamcop?timeout=15; https://ms.tmail.io/stats?fireandforget=true"

Dans ce cas tmail va appeler https://ms.tmail.io/check-spamcop et ensuite https://ms.tmail.io/stats


### Paramètres {#parametres}
Les paramètres actuellement reconnus par tmail dans les URL sont:

* **timeout** (default: 30): permet d'indiquer un timeout (en seconde) sur un appel. Par défaut il est de 30 secondes. Au dela de ce delais, tmail va considérer qu'il ne peut joindre le micro-service.
* **onfailure** (default: continue): permet de spécifier une action si un appel échoue. Globalement un appel échoue si le timeout est déclenché ou si le code de retour HTTP indique une erreur (4xx ou 5xx).
Les valeurs possibles pour ce paramètre sont:
	* continue: On continue. Le traitement continue normalement.
	* tempfail: Erreur temporaire: si une erreur à lieu pendant une transaction SMTP entrante, une erreur temporaire (4xx) est retournée au client. Si c'est pendant la livraison d'un mail ou lors d'une transaction sortante le mail est remis en queue et sera représenté.
	* permfail: Erreur permanente: si une erreur à lieu pendant une transaction SMTP entrante une erreur permanente (5xx) est retournée au client. Si c'est pendant la livraison d'un mail ou lors d'une transaction sortante le mail est bouncé.
* **fireandforget** (default false): si ce paramètre est défini à **true**, tmail va exécuter la requête dans un process parallèle et ne va pas tenir compte de la réponse. Autrement dit ce genre de traitement n'a aucune incidence sur le traitement réalisé par tmail. Attention cette option n'est pas disponible pour tous les hooks.

## Struture des messages échangés {#protobuf}

Vous trouverez le fichier proto ici: <a href="https://github.com/toorop/tmail/blob/master/msproto/proto/tmail.proto" target="_blank" title="tmail proto"> https://github.com/toorop/tmail/blob/master/msproto/proto/tmail.proto</a>

Je ne peux que vous encourager à jeter un oeil sur ce fichier pour avoir un idée de la struture des messages et ce même si vous ne comptez pas developper de micro-services.

## Étapes "hookables" {#hooks}
Voici la liste des points (hook) où il actuellement  possible d'étendre tmail avec pour chacun d'entre eux

### SmtpdNewClient: Établissement d'une nouvelle connexion SMTP entrante {#smtpdnewclient}
Le point d'entré dans la configuration est :

	TMAIL_MS_SMTPD_NEWCLIENT=""

#### Structure du message transmis au micro service

	message SmtpdNewClientMsg {
		required string session_id = 1;
		required string remote_ip = 2;
	}

Avec:

* **session_id** (requis): l'identifiant de la session SMTP qui traite cette transaction. Cet identifiant va être transmis dans tous les appels qui auront lieu durant une même transaction SMTP, il va donc permettre de suivre cette transaction, coté microservice, et de lier les requêtes.

* **remote_ip** (requis): contient l'IP du client.

#### Structure de la réponse attendue par tmail

	message SmtpdNewClientResponse {
		required string session_id = 1;
		optional SmtpResponse smtp_response = 2;
		optional bool drop_connection = 3;
	}

Avec:

* **session_id**: l'identifiant de la session.
* **smtp_response**: un message de type SmtpResponse qui va permettre de definir, si besoin, la réponse SMTP que tmail doit retourner au client. Vous n'avez pas à sytématiquement renseigner cette structure, faites le uniquement si vous avez besoin de retourner un message spécial au client et faite le en ayant bien conscience des conséquences. Vous trouverez la définition de cette structure un peu plus bas.  
* **drop_connection**: un boolean qui si il est présent et positionné a *true* va demander a tmail de terminer dés que possible la transaction. N'abusez pas de cette option, couper une transaction SMTP à l'initiative du serveur n'est pas trés RFC compliant.

Structure du message SmtpResponse:

	message SmtpResponse {
		required int32 code = 1; 			// SMTP code (ignored if eq 0)
		required string msg = 2; 			// SMTP message (ignored if eq "")
	}

Avec:

* **code**: le code SMTP à retourner au client.
* **msg**: le message à retourner au client.

Vous trouverez cette structure dans de nombreux hook smtpd.


### SmtpdRcptto: Appelé après la commande SMTP RCPT TO {#smtpdrcptto}

Le point d'entré dans la configuration est :

	export TMAIL_MS_SMTPD_RTCPTTO=""

#### Structure du message transmis au micro service

	message SmtpdRcptToQuery {
		required string session_id = 1;
		required string rcptto = 2;
	}

Avec:

* **rcptto** (requis): le rcptto sous forme d'adresse email.

#### Structure de la réponse attendue par tmail

	message SmtpdRcptToResponse {
		required string session_id = 1;
		optional SmtpResponse smtp_response = 2;
		optional bool drop_connection = 3;
		optional bool relay_granted = 4;
	}

Avec:

* **relay_granted**: si renseignée permet d'authoriser ou pas le relai pour ce destinataire.


### SmtpdData: Après la commande SMTP DATA {#smtpddata}

Le point d'entré dans la configuration est :

	export TMAIL_MS_SMTPD_DATA=""

#### Structure du message transmis au micro service

	message SmtpdDataQuery {
		required string session_id = 1;
		required string data_link = 2;
	}

Avec:

* **data_link** (requis): Un lien HTTP depuis lequel le micro-service pourra télécharger le mail transmis à tmail lors de la commande DATA.

#### Structure de la réponse attendue par tmail

	message SmtpdDataResponse {
		required string session_id = 1;
		optional SmtpResponse smtp_response = 2;
		optional string data_link = 3;
		optional bool drop_connection = 4;
		repeated string extra_headers = 5;
	}

Avec:

* **data_link** (optionnel): POas utilisé pour le moment
* **extra_headers** (optionnel): d'éventuels headers à ajouter.

### DeliverdGetRoutes: Appelé par deliverd pour obtenir le routage d'un mail {#deliverdgetroutes}

Ce *hook* va vous permettre de faire du routage dynamique, d'adapter la route que doit prendre un message à un instant t en fonction de paramètres qui vous sont propres.

Le point d'entré dans la configuration est :

	export TMAIL_MS_DELIVERD_GET_ROUTES=""

#### Structure du message transmis au micro service

	message DeliverdGetRoutesQuery {
		required string deliverd_id = 1;
		required string mailfrom = 2;
		required string rcptto =  3;
		required string authentified_user = 4;
	}

Avec:

* **deliverd_id**: l'identifiant unique du process deliverd.
* **mailfrom**: l'adresse email de l'expéditeur.
* **rcptto**: l'adresse email du destinataire.
* **authentified_user**: si l'utilisateur qui a transmis le mail via SMTP s'est authentifié, alors cette variable contient son login.

#### Structure de la réponse attendue par tmail

	message DeliverdGetRoutesResponse {
		message Route {
			required string remote_host = 1;
			required int64 remote_port = 2;
			optional string local_ip = 3;
			optional int32 priority = 4;
			optional string smtpauth_login = 5;
			optional string smtpauth_password = 6;
		}
		required string deliverd_id = 1;
		repeated Route routes = 2;
	}

Avec:


* **deliverd_id**: l'identifiant unique correspondant au process deliverd (transmis par tmail lors de la requète)

* **routes**: la ou les routes à utiliser pour ce mail.

Voici les définitions de la structure *Routes*:
* **remote_host**: L'adresse IP ou le nom d'hôte du serveur à qui tmail doit transmettre le mail.

* **remote_port**: le port du serveur vers qui tmail doit transmettre le mail.

* **local_ip**: l'adresse IP locale que tmail doit utiliser pour établir la connexion.

* **priority**: la priorité de cette route. Plus le chiffre est petit plus la priorité est élevée. Dans le cas où plusieurs routes auraient la même priorité, elles seront sélectionnée aléatoirement par tmail, ce qui permet de faire simplement du round-robin.

* **smtpauth_login**: si le serveur distant requière une authentification, cette variable permet de renseigner le login.

* **smtpaut_passwd**: si le serveur distant requière une authentification, cette variable permet de renseigner le mot de passe.




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
