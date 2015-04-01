+++
date = "2015-03-27T14:03:12+01:00"
draft = false
title = "Gestion des logs tmail"
categories = ["doc"]
description = "Gestion des logs du serveur smtp tmail"
keywords = ["logs","smtp","tmail"]
tags = [ "smtp","logs"]
+++

Par défaut tmail va afficher les logs sur la sortie standard *stdout*.  
Vous pouvez configurer tmail pour qu'il enregistre les logs dans un fichier texte.

<!--more-->

Pour cela, éditer le fichier de configuration et modifiez la variable *TMAIL_LOGPATH*.  

Pour enregistrer les logs dans le dossier */home/tmail/dist/log/* : 

	export TMAIL_LOGPATH="/home/tmail/dist/log/"

**Attention** le dossier doit exister, et l'utilisateur sous lequel est lancé tmail doit avoir les droits de lecture et d'écriture sur ce dossier.

Pour revenir vers un affichage des logs vers la sortie standard, mettez *stdout* à la place du chemin:

	export TMAIL_LOGPATH="stdout"

La verbosité des logs se configure via la variable *TMAIL_DEBUG_ENABLED*.  

En la mettant à *true*:

	export TMAIL_DEBUG_ENABLED=true

vous aurez un maximum de logs. Attention ce mode est très verbeux, si vous n'avez pas de problèmes particuliers je vous recommande de mettre cette variable à *false*:

	export TMAIL_DEBUG_ENABLED=false

dans ce mode vous aurez les logs nécessaires au suivi de la bonne marche de votre serveur mail.

Voici un exemple de logs avec TMAIL_DEBUG_ENABLED positionné à false:

	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:56.689099 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - starting new transaction
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:56.717078 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - remote greets as [192.168.0.1]
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.001558 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - remote greets as [192.168.0.1]
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.138727 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - auth succeed for user toorop@tmail.io
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.164773 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - new mail from toorop@tmail.io
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.192105 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - rcpt to: toorop@toorop.fr
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.267349 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - Message-ID: <5515651A.4000304@tmail.io>
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.305726 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - message queued as 3b0d652314a64d906b61a9658362f4d126400015
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.331292 INFO - smtpd  ba06fea8e42ee38d62cdb82c98a5221e6e7852cd - 88.178.118.205:50348 - EOT
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:11:57.332438 INFO - delivery-remote 30316f400ef44fe563dd2b8b9c06807124b32d75: starting new delivery from toorop@tmail.io to toorop@toorop.fr - Message-Id: <5515651A.4000304@tmail.io> - Queue-Id: 3b0d652314a64d906b61a9658362f4d126400015
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:12:01.396618 INFO - deliverd-remote 30316f400ef44fe563dd2b8b9c06807124b32d75: remote server 178.33.223.34 reply to data cmd: 250 - ok
	[mail.tmail.io - 127.0.0.1] 2015/03/27 15:12:01.396819 INFO - deliverd 30316f400ef44fe563dd2b8b9c06807124b32d75: success



