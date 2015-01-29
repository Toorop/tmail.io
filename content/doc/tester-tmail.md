+++
date = "2015-01-29T17:00:44+01:00"
draft = true
title = "Tester tmail"

+++

Durant tout le cycle de développement je vais mettre à disposition le nécessaire pour qu'il soit possible de tester les fonctionnalités qui sont implémentées.

Qu'il n'y ait pas de malentendu, on ne parle pas ici de version bêta, ni même alpha, ce sera à chaque fois une version de dev, avec plein de choses non implémentées et forcement de nombreux bugs.

**En clair: n'utiliser pas ces versions en prod**

Pour le moment tmail est très basique, mais il devrait cependant vous permettre d'envoyer et de relayer des mails.

On va partir sur une installation qui va nous permettre de mettre en place un service SMTP basique qui va:

* écouter sur les ports 25 et 587 (avec STARTTLS).
* écouter sur le port 465 en SSL.
* accepter tous les mails à destination du domaine *toorop.fr* et qui va les router vers *mail.toorop.fr*
* permettre à l'utilisateur *toorop@toorop.fr* ayant comme mot de passe *passwd* d'utiliser le service pour envoyer des mails (quelque soit la destination).
* router tous les mails à destination de *gmail.com* vers mailjet.

## Prérequis
Pour le moment je ne fournis que le binaire Linux 32bits, vous n'avez donc besoin de rien d'autre pour tester qu'une machine sous Linux. Pour cet exemple je vais utiliser un [VPS Classic 1 OVH](https://www.ovh.com/fr/vps/vps-classic.xml) sous *Ubuntu server 64bits*.

Pensez à vous assurer que vous pouvez utiliser les ports SMTP (ou alors testez sur des ports alternatifs).

A noter que comme backend pour la base de données vous pouvez utiliser sqlite, MySQl (et dérivés) ou Postgresql. Pour cette première phase je vous encourage chaudement à utiliser sqlite ce sera amplement suffisant.

A terme, tmail sera splitté en composants sous forme de container Docker, dans ce qui suit je vais jsute expliquer l'installation "standalone" (vs cluster).

### Note sur l'utilisation des ports inférieurs à 1024
Sur un système linux un processus ne peut ouvrir un port inférieur à 1024 que si il est root.
Une des limitations de Go fait que l'on ne peut pas lancer d'application sous l'utilisateur root pour ouvrir les ports nécessaires et ensuite forker sous un autre user.  
Il y à plusieurs autres solutions pour contourner ce problème, la plus simple à mettre en œuvre est d'utiliser iptables :

	iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 25 -j REDIRECT --to-port 2525

## Installation


## Configuration

### Base

### Prise en charge des mails du domaine toorop.fr

### Router les mails à destination du domaine toorop.fr vers mail.toorop.fr

### Ajout de utilisateur toorop@toorop.fr

### Router les mails à destination de gmail.com vers Mailjet.


Si vous avez des questions, des remarques, des bugs à remonter
