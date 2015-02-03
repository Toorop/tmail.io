+++
date = "2015-01-14T14:14:40+01:00"
draft = false
title = "FAQ"
[menu.main]
name = "FAQ"
weight = 5
+++

* [Qu'est ce que tmail ? ]({{<ref "#tmail" >}})
* [Est ce que tmail est opensource ? ]({{<ref "#opensource" >}})
* [Peut on tester tmail ? ]({{<ref "#tester-tmail" >}})
* [J'ai trouvé un bug !]({{<ref "#bugtracker" >}})
* [J'ai une suggestion]({{<ref "#suggestion" >}})
* [tmail est codé en quel langage ? ]({{<ref "#golang-tmail" >}})

## Qu'est ce que tmail ? {#tmail}

Réponse courte: tmail est un serveur [SMTP](http://fr.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol)  
 
**Mais pourquoi créer un nouveau serveur smtp !?** 

Oui c'est vrai ça pourquoi créer un nouveau serveur SMTP alors qu'il existe déjà qmail, postfix, exim, sendmail, .. ?  
Parce que :

* Ces serveurs ont été conçu à une époque où les problématiques et donc les besoins liés à l’émail étaient différents. Je pense en particulier à la problématique du spam, aujourd'hui il est indispensable de filtrer ce qui entre et ce qui sort d'un serveur SMTP, d'établir de règles strictes quant à l'usage du service: par exemple l'user X ne peux envoyer plus de x mails par jour, chaque mail ne doit pas faire plus de x Mo et il ne peut utiliser le service le week-end ou encore de pas envoyer plus de x mails par minute vers telle destination...  

* Avoir un système fiable et parfaitement redondant nécessite pas mal de compromis. 

* La scalabilité apportée par les solutions actuelles n'est pas simple à mettre en place et est difficilement linéaire. 

* Plus globalement, la mise en place et l'administration de ces serveurs n'est pas forcement simple non plus. Attention le but n'est pas de permettre à n'importe qui ne mettre en place un service SMTP, mais plutôt de libérer les sysadmins de contraintes inutiles.

* Enfin ça fait des années que je travaille dans ce secteur (pour <a href="http://protecmail.com/" target="_blank" title="Protection de messagerie">Protecmail</a>) et ça fait presque aussi longtemps que je me dis:  
*Un jour je coderais mon propre serveur* ;) 



## Est ce que tmail est opensource ? {#opensource}

Pour le moment je ne souhaite pas "libérer" les sources, mais à terme ce sera le cas.

La raison principale est que le projet est trop jeune, je préfère attendre que les grandes lignes soient posées, que ce que j'ai prévu soit implémenté - au moins en partie - pour éviter d'une part trop de dispersions et d'autre part pour pouvoir concentrer mon temps disponible au code plutôt qu'à la gestion du projet.

## Peut on tester tmail ? {#tester-tmail}
Oui vous avez [la procédure pour installer tmail ici](/doc/installer-tmail/)
Bien entendu les versions proposées seront des versions de dev qui implémenteront que.. ce qui est implémenté et qui ne seront pas exemptes de bugs. 

## J'ai trouvé un bug {#bugtracker}
Utilisez le [bugtracker dédié sur Github](https://github.com/Toorop/tmail-bugtracker) pour me le remonter.

## J'ai une suggestion {#suggestion}
Un [un groupe de discutions](https://groups.google.com/d/forum/tmail-dev) est à votre disposition pour discuter de tmail. Toute suggestion est la bienvenue ;)


## tmail est codé en quel langage ? {#golang-tmail}
<a href="http://golang.org/" target="_blank" title="golang">Go</a>

