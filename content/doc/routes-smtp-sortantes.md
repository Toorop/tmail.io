+++
date = "2015-01-19T16:38:23+01:00"
draft = false
title = "Routes smtp sortantes"
[menu.main]
name = "Doc"
weight = 4

+++
**tmail vous permet de spécifier des routes sortantes pour les mails qu'il a à expédier.**  

Par défaut, lorsque tmail doit transmettre un mail il va faire une requête DNS MX pour obtenir les adresses IP du/des serveur(s) SMTP du domaine de destination. C'est le fonctionnement classique d'un serveur SMTP, mais vous pouvez aussi créer des règles de routage pour forcer les connexions sortantes vers des relais spécifiques. 

Les règles de routage vont êtres définies an fonction des paramètres suivants : 

* Le domaine de destination.
* L'utilisateur authentifié via SMTP AUTH qui a transmis le mail a tmail (le cas échéant).

Lorsque tmail à un mail à transmettre il va chercher parmi les règles suivantes si il y en a une qui correspond. Si oui il va utiliser les routes qui correspondent à cette règle. Chaque route à un poids, comme pour les MX classiques, tmail va donc essayer en premier lieu de se connecter au relais suivant en utilisant la route qui à le poids le plus faible.  

Les règles sont testées dans l'ordre suivant:

* **Si le mail à été transmis via SMTPAUTH:** tmail va chercher une règle qui correspond à l'utilisateur authentifié et au domaine de destination. 

* **Si le mail à été transmis via SMTPAUTH:** tmail va chercher une règle qui correspond à l'utilisateur authentifié indépendamment du domaine de destination. 

* **Si le mail à été transmis via SMTPAUTH et si le login de cet user est de la forme user@domain:** tmail va chercher une règle qui correspond au domaine de l'utilisateur authentifié et au domaine de destination. 

* **Si le mail à été transmis via SMTPAUTH et si le login de cet user est de la forme user@domain:** tmail va chercher une règle qui correspond au domaine de l'utilisateur authentifié indépendamment au domaine de destination. 

* tmail va chercher une règle qui correspond au domaine de destination.

* tmail va chercher une règle par défaut (wildcard "*" sur le domaine de destination)


#### A venir: Création des règles de routage
