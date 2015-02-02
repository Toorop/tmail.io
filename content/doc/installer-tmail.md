+++
date = "2015-01-29T17:00:44+01:00"
draft = false
title = "Installer et configurer tmail"

+++

Durant tout le cycle de développement de tmail je vais mettre à disposition le nécessaire pour qu'il soit possible de tester les fonctionnalités qui sont implémentées.

Qu'il n'y ait pas de malentendu, on ne parle pas ici de version bêta, ni même alpha, ce sera à chaque fois une version de développement, avec plein de choses non implémentées et forcement de nombreux bugs.

**En clair: ne pas utiliser en production**

Pour le moment tmail est très basique, mais il devrait cependant vous permettre d'envoyer et de relayer des mails.

On va partir sur une installation qui va nous permettre de mettre en place un service SMTP qui va:

* écouter sur les ports 25 et 587 (avec STARTTLS).
* écouter sur le port 465 en SSL.
* accepter tous les mails à destination du domaine *toorop.fr* et qui va les router vers *mail.toorop.fr*
* permettre à l'utilisateur *toorop@toorop.fr* ayant comme mot de passe *password* d'utiliser le service pour envoyer des mails (quelque soit la destination).

## Prérequis
Pour le moment je ne fournis que le binaire Linux 32bits, vous n'avez donc besoin de rien d'autre pour tester qu'une machine sous Linux. Pour cet exemple je vais utiliser un [VPS Classic 1 OVH](https://www.ovh.com/fr/vps/vps-classic.xml) sous *Ubuntu server 64bits*.

Pensez à vous assurer que vous pouvez utiliser les ports SMTP (ou alors testez sur des ports alternatifs).

Si vous comptez utiliser tmail pour envoyer des mails, pensez à mettre un reverse sur l'IP (ou les IP) de votre serveur.

Pensez aussi à renseigner les SPF des domaines que vous allez utiliser comme émetteurs le cas échéant.

A noter que comme backend pour la base de données vous pouvez utiliser sqlite, MySQl (et dérivés) ou Postgresql. Pour cette première phase je vous encourage chaudement à utiliser sqlite, ce sera amplement suffisant.

A terme, tmail sera splitté en composants sous forme de containers Docker, dans ce qui suit je vais juste expliquer l'installation "standalone" (vs cluster).

### Dependances & outils 
tmail est un binaire statique, vous n'avez besoin d'aucune librairie spécifique.

Par contre votre serveur devra disposer des softs suivant:

* unzip: pour décrompresser l'archive contenant le necessaire à la mise en place de tmail. Pour ceux qui se posent la question de savoir pourquoi j'utilise la format zip plutot qu'un format plus "générique" dans un environement *nix, la réponse est que tmail sera dispo sur plusieurs plateformes et du coup je préfére utiliser un format trés courant.

Si vous etes sous Debian/Ubuntu:

	apt-get install unzip


### Vous avez trouvé un bug ? Vous avez une suggestion ?
Utilisez exclusivement le [bugtracker dédié sur Github](https://github.com/Toorop/tmail-bugtracker)

### Note sur l'utilisation des ports inférieurs à 1024
Sur un système linux un processus ne peut ouvrir un port inférieur à 1024 que si il est root.
Une des limitations de Go fait que l'on ne peut pas lancer d'application sous l'utilisateur root pour ouvrir les ports nécessaires et ensuite *forker* sous un autre user.  
Il y à plusieurs autres solutions pour contourner ce problème, la plus simple à mettre en œuvre est d'utiliser iptables. C'est ce que nous allons faire ici.


## Installation
### Ajout de l'utilisateur tmail
On va commencer par ajouter un utilisateur tmail

	adduser tmail

### Téléchargement de tmail
J'ai mis sur mon FTP une archive comprenant le binaire et divers autre éléments utiles pour installer tmail. 

On va donc commencer par récupérer cette archive et la décompresser.

	# su tmail
	$ cd
	$ wget ftp://ftp.toorop.fr/softs/tmail/tmail.zip
	$ unzip tmail.zip
	$ cd dist

Le répertoire *dist* contient les éléments nécessaires pour lancer tmail:

	$ ls -la
	drwxrwxr-x 5 tmail tmail     4096 févr.  2 09:08 .
	drwxr-xr-x 3 tmail tmail     4096 févr.  2 09:08 ..
	drwxrwxr-x 2 tmail tmail     4096 févr.  2 09:08 conf
	-rw-rw-r-- 1 tmail tmail       38 janv. 16 15:14 run
	drwx------ 2 tmail tmail     4096 déc.  29 12:02 ssl
	-rwxr-xr-x 1 tmail tmail 14370520 janv. 28 16:34 tmail
	drwxrwxr-x 2 tmail tmail     4096 déc.  29 11:20 tpl

Avant de vous détailler ces différents éléments, on va fixer quelques droits, (il se peut que ce ne soit pas toujours nécessaire mais dans tous les cas pensez à vérifier):
	
	chmod 700 run tmail	

et on va rajouter deux répertoires:

	mkdir db
	mkdir store	

* conf: contient, oh surprise, le fichier de configuration.
* run: est un mini script qui va charger la config et lancer tmail.
* ssl: est le répertoire contenant le nécessaire pour gérer le SSL. Vous pouvez utiliser ce qui est inclus dans la distribution dans le cadre de tests mais pensez à créer vos propres certificat et clé en prod (si besoin je ferais un tuto).
* tmail: est l'exécutable.
* tpl: contient des templates, par exemple pour les bounces. 
* db: contiendra la base sqlite (si vous utilisez sqlite...)
* store: va servir au stockage des mails en queue. Vous pouvez le mettre ailleurs mais pensez à faire la modification dans le fichier de configuration. A terme, il va y avoir d'autre type se *store* que du stockage sur le disque local. 

## Configuration

On va commencer par copier le ficher tmail.cfg.base vers tmail.cfg car c'est ce dernier qui sera pris en compte:

	cp tmail.cfg.base tmail.cfg
	chmod 600 tmail.cfg 


Je ne vais parler que des options qu'il va être nécessaire de modifier:

* TMAIL_ME: C'est le nom d’hôte de votre serveur, celui qui va être utilisé, entre autre, dans la commande HELO/EHLO. Personnalisez cette valeur pour qu'elle corresponde au reverse de votre IP.

* TMAIL_DEBUG_ENABLED: si positionné à *true* vous allez avoir toutes les info de debug. Pour une sortie moins verbeuse mettez false, mais je ne vous le conseille pas dans le cadre de ces tests.

* TMAIL_DB_DRIVER: la base de données utilisées. Notez que pour le moment j'utilise exclusivement sqlite3, les autres devraient fonctionner mais je ne garantis rien.

* TMAIL_DB_SOURCE: la source des données. 

* TMAIL_SMTPD_DSNS: cette option va nous permettre de définir les IP:port d'écoute de tmail et si on doit activer SSL ou pas. A noter que si SSL n'est pas activé on a tout de même l'option ESMTP STARTTLS qui permet d'avoir des transactions chiffrées si le client supporte STARTTLS. 
Dans notre cas on veut que tmail écoute sur l'IP publique du serveur 151.80.115.83, sur les port 25 et 587 et sur le port 465 en SSL. Comme l'utilisateur tmail ne peut ouvrir ces ports on va utiliser 2525 5877 et 4655 et on fera de la redirection de port. On a donc: 
TMAIL_SMTPD_DSNS="151.80.115.83:2525:false,151.80.115.83:5877:false,151.80.115.83:4655:true"

* TMAIL_DELIVERD_LOCAL_IPS: c'est l'IP (ou les IP) locale(s) à utiliser pour envoyer des mails. Pour ce premier test on va faire simple, on va utiliser une seule adresse, celle par défaut du serveur: export TMAIL_DELIVERD_LOCAL_IPS="151.80.115.83"

* TMAIL_DELIVERD_MAX_IN_FLIGHT: correspond au nombre de "delivery", autrement dit d'envois concurrents.

* TMAIL_DELIVERD_QUEUE_LIFETIME: correspond au temps de rétention en queue avant qu'un mail ne soit bouncé si tmail n'arrive pas à l’expédier. Par défaut le temps est très court, si il vous prend l'envie d'utiliser tmail en prod (ce que je ne vous conseille pas de faire en l'état) augmentez le.


Un fois cette configuration faite, on peut lancer lancer tmail. 

Vu que c'est un premier lancement tmail va détecter que la base de données n'est pas initialisée et il va vous demander si il peut le faire:

	tmail@dev:~/dist$ ./run 
	Database 'driver: sqlite3, source: /home/tmail/dist/db/tmail.db' misses some tables.
	Should i create them ? (y/n): y

	je vous passe les info de debug..

	[dev.tmail.io - 127.0.0.1] 2015/02/02 12:42:32.449597 INFO - smtpd 151.80.115.83:2525 launched.
	[dev.tmail.io - 127.0.0.1] 2015/02/02 12:42:32.449931 INFO - smtpd 151.80.115.83:5877 launched.
	[dev.tmail.io - 127.0.0.1] 2015/02/02 12:42:32.450011 INFO - smtpd 151.80.115.83:4655 SSL launched.
	[dev.tmail.io - 127.0.0.1] 2015/02/02 12:42:32.499728 INFO - deliverd launched

### Redirection de ports via iptables
Pour que tmail écoute sur les ports standards nous allons mettre en place les trois règles suivantes. Attention assurez vous que vous n'avez pas déjà un serveur SMTP qui écoute sur ces ports, si c'est le cas et que vous ne souhaitez pas l’arrêter, utilisez simplement tmail sur les port alternatifs.

	iptables -t nat -A PREROUTING -p tcp --dport 25 -j REDIRECT --to-port 2525
	iptables -t nat -A PREROUTING -p tcp --dport 465 -j REDIRECT --to-port 4655
	iptables -t nat -A PREROUTING -p tcp --dport 587 -j REDIRECT --to-port 5877

### Le moment est venu de faire un premier test
Vous pouvez faire le test depuis la même machine mais tant qu'a faire, faites le depuis une autre.

	$ telnet dev.tmail.io 25
	Trying 151.80.115.83...
	Connected to dev.tmail.io.
	Escape character is '^]'.
	220 tmail.io  tmail ESMTP f22815e0988b8766b6fe69cbc73fb0d965754f60
	HELO toto
	250 tmail.io
	MAIL FROM: toorop@toorop.fr
	250 ok
	RCPT TO: toorop@toorop.fr
	554 5.7.1 <toorop@toorop.fr>: Relay access denied.
	Connection closed by foreign host.

Parfait !
Pour le moment le mail est refusé car nous n'avons défini aucune autorisation.

### Prise en charge des mails du domaine toorop.fr
Pour que tmail prenne en charge les mails du domaine toorop.fr il suffit tout simplement deexécuter la commande suivante:
	
	tmail smtpd addRcpthost toorop.fr

Si vous avez une erreur du type:

	2015/02/02 15:51:30 unable to load config from env, TMAIL_ME variable is missing.

C'est parce que la configuration n'est pas chargée dans votre environnement, pour y remédier exécuter:

	. /home/tmail/dist/conf/tmail.cfg

Vérifions que tmail accepte les mails pour toorop.fr:

	$ telnet dev.tmail.io 25
	Trying 151.80.115.83...
	Connected to dev.tmail.io.
	Escape character is '^]'.
	220 tmail.io  tmail ESMTP 96b78ef8f850253cc956820a874e8ce40773bfb7
	HELO toto
	250 tmail.io
	mail from: toorop@toorop.fr
	250 ok
	rcpt to: toorop@toorop.fr
	250 ok
	data
	354 End data with <CR><LF>.<CR><LF>
	subject: test tmail

	blabla
	.
	250 2.0.0 Ok: queued 2736698d73c044fd7f1994e76814d737c702a25e
	quit
	221 2.0.0 Bye
	Connection closed by foreign host.



### Router les mails à destination du domaine toorop.fr vers mail.toorop.fr
Par défaut quand tmail doit router un mail, il va utiliser les enregistrements DNS MX du domaine pour savoir à qui le transmettre. Mais nous pouvons aussi créer des routes "en dur". Par exemple si nous souhaitons que tmail transmette les mails à destination du domaine toorop.fr au relais mail.toorop.fr il suffit de lui indiquer via cette commande :

	tmail routes add -d toorop.fr -rh mail.toorop.fr

Je vous invite lire la documentation sur les [régles de routage SMTP](/doc/cli-gestion-route-smtp/) pour connaitre les possibilités offertes par tmail.

### Ajout de utilisateur SMTP toorop@toorop.fr

Si vous souhaitez ajouter un utilisateur *toorop@toorop.fr* qui pourra envoyer des mails via tmail en s'authentifiant via SMTPAUTH avec le mot de passe *password*:

	tmail smtpd addUser password

Pour supprimer un utilisateur:

	tmail smtpd delUser toorop@toorop.fr

Bon tests ;)	

