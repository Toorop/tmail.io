+++
date = "2015-03-20T16:34:28+01:00"
draft = false
title = "Gérez vos boites mail avec Dovecot"
categories = ["doc"]

+++

Initialement j'avais prévu d'ajouter le support de comptes mail bien plus tard dans le cycle de développement car mon usage principal de tmail est avant tout celui de relais SMTP.  
Le fait que l'on m'ait demandé si ça allait être bientôt disponible m'a fait réaliser que gérer des comptes mails était quand même l'usage principal d'un serveur de messagerie - gnééééé... - , j'ai donc décidé de remonter cette tache dans ma todo-list.  

Pour vous proposer cette fonctionnalité plus rapidement, j'ai fait quelques compromis par rapport à ce que je voulais initialement faire. Mon idée de départ était de ne pas utiliser le classique stockage des mails via Mailbox/maildir + accès POP ou IMAP, mais d’utiliser une **interface de stockage de type PUT/GET pour stocker les mails et une API HTTP REST pour y accéder et les gérer.** 

L’intérêt de cette solution c'est que l'on peut implémenter l'interface pour une multitude de types de stockage, du simple espace disque sur le serveur, ou déporté sur un NAS/Filer, mais aussi du Amazon S3, ou encore du Runabove.
Par ailleurs proposer une API REST pour gérer les mails permettait de développer simplement des clients de messagerie, des "connecteurs/proxy" pour rendre ce stockage compatible avec les clients classique (par exemple un proxy IMAP), mais aussi d'interfacer simplement de nombreux outils au service de messagerie.

Rassurez vous - ou pas - je n'ai pas abandonné ces idées, ce sera implémenté, mais en attendant pour offrir le plus rapidement la possibilité d'utiliser tmail comme serveur mail classique, j'ai décidé de prendre un raccourci en implémentant le nécessaire pour utiliser Dovecot avec tmail.

**Concrètement il est donc aujourd'hui possible d'utiliser tmail comme serveur de destination pour un domaine - celui qui va héberger les mails du domaine donc - et d'accéder aux boites mails via POP et IMAP.**

Voila pour cette - longue - introduction, passons à la pratique.

<!--more-->

## Mise en œuvre

### Pre-requis 
Je vais utiliser une distribution Ubuntu server 14.10, si vous utilisez une distribution Debian ou dérivée l'installation devrait être sensiblement la même.

On commence par s'assurer que notre système est a jour:

	apt-get update && apt-get upgrade

Si l’utilisateur tmail n'existe pas, on va le créer:

	adduser tmail

### Installation de Dovecot

On va commencer par la base, en fin d'article vous trouverez comment ajouter le support de sieve:

 	apt-get install dovecot-imapd dovecot-pop3d

Il va vous être demandé si vous souhaitez créer un certificat SSL, répondez *oui*, cela va générer un certificat auto-signé.

Il va maintenant falloir installer le support de base de données pour que Dovecot puisse se connecter à la base de données utilisée par tmail. Il faudra donc en fonction de vos besoins installer soit dovecot-sqlite si vous utilisez SQLite, soit dovecot-mysql si vous utilisez MySQL,soit dovecot-pgsql si vous utilisez PostgreSQL.  

Dans mon cas comme je vais avoir besoin de tester sur les 3 SGDB, j'installe les donc trois:
	
	apt-get install dovecot-sqlite dovecot-mysql dovecot-pgsql


On va en rester là pour le moment, on ferra la configuration après avoir installé tmail.

### Installation de tmail
Si vous avez déjà tmail installé, je vous recommande de supprimer les tables de votre base de données.
Beaucoup de modifications on été faites et il est plus prudent de repartir de zéro.

Suivez ce tutoriel pour [installer tmail](/doc/installer-tmail/)


### Configuration de tmail

Nous avons besoin de configurer trois paramètres

Le répertoire dans lequel seront stockés les boites mails, par défaut c'est /home/tmail/dist/mailboxes.  
Assurez vous que l'utilisateur tmail ait les droits de lecture et d'écriture sur ce répertoire.

	# Base path for users "home". Currently ysed to store mailboxes
	export TMAIL_USERS_HOME_BASE="/home/tmail/dist/mailboxes"

On doit ensuite activer le support de Dovecot:

	# Enabled dovecot for local deliveries
	export TMAIL_DOVECOT_SUPPORT_ENABLED=true

Et enfin indiquer à tmail où se trouve l'agent de livraison dovecot-lda:

	# Dovecot LDA path
	export TMAIL_DOVECOT_LDA="/usr/lib/dovecot/dovecot-lda"

### Création d'une boite mail

Dans cet exemple tmail devra gérer les boites du domaine tmail.io. 
Si dans votre cas vous avez déjà utilisé le domaine sur lequel vous souhaitez créer des boites vous devez le supprimer car le cli ne permet pas pour le moment de modifier la configuration d'un domaine.

	tmail rcpthost del tmail.io

On crée le compte toorop@tmail.io avec l'option *-m* pour signifier à tmail que cet utilisateur aura une boite mail et avec l’option *-r* pour lui indiquer que cet utilisateur pourra utiliser tmail comme relais SMTP (après authentification).

	tmail user add -m -r toorop@tmail.io MOT_DE_PASSE

### Configuration de Dovecot

La première chose à faire est d'augmenter au maximum les niveaux de logs, comme ça si il y a un problème ce sera plus facile de le localiser.

Pour cela on édite le ficher */usr/share/dovecot/conf.d/10-logging.conf* et on modifie les parametres suivant:

	auth_verbose = yes
	auth_debug = yes
	auth_debug_passwords = yes
	mail_debug = yes

On va à présent devoir indiquer à Dovecot comment allez récupérer les informations sur les utilisateurs.
Pour cela on va lui indiquer la requête SQL qu'il doit exécuter.
On édite le fichier: */etc/dovecot/dovecot-sql.conf.ext*

Il faut d'abord spécifier le driver que l'on va utiliser, dans mon cas sqlite:

	# Database driver: mysql, pgsql, sqlite
	driver = sqlite

Ensuite la "connection string", autrement dit les indications qui vont permettre à Dovecot de se connecter à la base de données tmail:

	connect = /home/tmail/dist/db/tmail.db	 

l'algorithme utilisé pour "hasher" les mots de passe:
	
	default_pass_scheme = SHA512-CRYPT

La requête pour réaliser une authentification:

	password_query = SELECT login AS user, dove_passwd AS password \
   	FROM users WHERE login = '%u' AND active = 'Y'	

Pour la requête suivante, celle qui va permettre à Dovecot de récupérer des informations sur l'utilisateur, on va avoir besoin de connaître les UID/GID de l'utilisateur tmail sur votre système, pour cela exécuter en root la commande suivante:

	cat /etc/passwd | grep tmail
	tmail:x:1000:1000:,,,:/home/tmail:/bin/bash

Dans mon cas l'UID de tmail est 1000 son GID est aussi 1000.

Cette requête va varier en fonction du SGDB que vous utilisez, si vous utilisez SQLite ou PostgreSQL utilisez cette requête:

	user_query = SELECT 1000 AS uid, 1000 AS gid, home, \
  	'*:bytes=' || mailbox_quota AS quota_rule \
  	FROM users WHERE login = '%u'

si vous utilisez MySQL:
	
	user_query = SELECT 1000 as uid, 1000 as gid, home, \
  	concat('*:bytes=', mailbox_quota) AS quota_rule \
  	FROM users WHERE login = '%u'  	


Il faut à présent spécifier à Dovecot que l'on souhaite utiliser l’authentification via SQL, on édite */etc/dovecot/conf.d/10-auth.conf* et on commente : 

	#!include auth-system.conf.ext

et on dé-commente:

	!include auth-sql.conf.ext


Ensuite **on configure l'agent de livraison dovecot-lda**, en éditant le fichier */etc/dovecot/conf.d/15-lda.conf*.

L'adresse postmaster: cette adresse va être, entre utilisée, si EDovecot à besoin d'envoyer des mails pour informer d'un problème. Par exemple pour bouncer un mail. Il va sans dire que cette adresse doit exister et je vous recommande fortement d'utiliser une adresse du type postmaster@domain (on pourra utiliser un alias quand ce sera implémenté en attendant créez une boite via *tmail user add -m postmaster@tmail.io MOT_DE_PASSE*).

	postmaster_address = postmaster@tmail.io

Dovecot doit pouvoir utiliser tmail pour envoyer des mails, par exemple les bounces évoqués au dessus, on va donc le configurer pour:

	submission_host = 127.0.0.1:2525		

Bien entendu il faut que dans votre configuration vous ayez dit à tmail d'écouter, entre autre, sur l'IP 127.0.0.1 et sur le port 2525 (*export TMAIL_SMTPD_DSNS="127.0.0.1:2525:false;IP:PORT:true"* par exemple) et il faut également que l'IP qui va contacter tmail soit autorisée à relayer, pour ça il vous suffit d’exécuter la commande :

	tmail relayip add 127.0.0.1


Il nous faut à présent **configurer le format de stockage des boites mails**, on va utiliser Maildir.  
On édite le fichier  */etc/dovecot/conf.d/10-mail.conf*:

	mail_location = maildir:~/Maildir

**On va activer les quotas**, ce n'est pas une obligation mais je vous recommande fortement de le faire sinon vous courrez le risque de voir votre partition saturée si vous veniez à recevoir de nombreux mails.

Toujours dans le fichier */etc/dovecot/conf.d/10-mail.conf* :

	mail_plugins = $mail_plugins quota

Il nous faut aussi l'activer pour IMAP ce qui va nous permettre de connaître l'usage de la boite mail depuis le client IMAP. On édite le fichier */etc/dovecot/conf.d/20-imap.conf*:
	
	# Space separated list of plugins to load (default is global mail_plugins).
  	mail_plugins = $mail_plugins quota imap_quota

et dire à Dovecot ce qu'il doit utiliser comme méthode pour calculer les quotas. Ici on va faire au plus simple, il va directement regarder l'espace disque utilisé.  
Éditez  */etc/dovecot/conf.d/90-quota.conf* et de-commentez la ligne:

	quota = dirsize:User quota	

Coté client, si vous utilisez Thunderbird voici<a href="https://addons.mozilla.org/fr/thunderbird/addon/display-quota/?src=search" target="_blank">un plugin vous permettant d'afficher le quota de votre boite mail</a>	


Voila c'est fini, il ne vous reste plus qu'a relancer Dovecot:

	service dovecot restart

Normalement tout devrait fonctionner, si ce n'est pas le cas, consultez les logs de Dovecot et de tmail, et si vous n'arriver pas à résoudre le problème, postez un SOS en commentaire de cet article (si ça fonctionne vous pouvez aussi laisser un commentaire ;))

Si tout fonctionne correctement penser à réduire le niveau de log de Dovecot.


## Sieve 

Ce qui suit n'est pas du tout indispensable, mais puisque vous avez les mains dans le cambouis je vous encourage à faire encore un petit effort, vous ne le regretterez pas.

### Qu'est ce que Sieve ? 
Je vais reprendre la <a href="http://fr.wikipedia.org/wiki/Sieve" target="_blank"> définition donnée par Wikipédia </a>:
<blockquote cite="http://fr.wikipedia.org/wiki/Sieve">Sieve (du mot anglais crible comme dans le crible d'Ératosthène) est un langage de filtrage du courrier électronique. Il est normalisé dans le RFC 5228. Sieve permet de filtrer sur les en-têtes d'un message qui suit le format du RFC 5322, c'est-à-dire un message Internet typique.</blockquote>

Dans notre cas, Sieve va être utilisé par l'agent de livraison, dovecot-lda, il va nous permettre, entre autre, de classer les mails dans différents dossiers. Je vous donnerais quelques exemples plus bas.

### Installation de du plugin sieve et de manageSieve

ManageSieve est un serveur qui va vous permettre de modifier vos règles Sieve depuis votre client de messagerie. Bien entendu il faut que le client le supporte. 

Sur Debian et dérivés un simple:

	apt-get install dovecot-sieve dovecot-managesieved

va vous installer le nécessaire.

Pour les autres je vous renvoie vers <a href="http://wiki2.dovecot.org/Pigeonhole/Sieve" target="_blank">la documentation officielle de Pigeonhole Sieve</a> où vous trouverez le nécessaire pour installer le plugin Sieve et ManageSieve.

### Configuration 
On édite le fichier */etc/dovecot/conf.d/15-lda.conf* pour signifier à dovecot qu'il doit charger le plugin Sieve:

	   mail_plugins = $mail_plugins sieve

Il faut que l'agent de livraison soit capable de créer un sous dossier si il n'existe pas:

	lda_mailbox_autocreate = yes	

On va aussi activer l'abonnement automatique aux dossiers créés:

	lda_mailbox_autosubscribe = yes	   

Le fichier de configuration de sieve est */etc/dovecot/conf.d/90-sieve.conf*, la configuration par défaut est suffisante, on ne va donc rien modifier. Je vous invite quand même à y jeter un œil.

Pour ManageSieve, le fichier de configuration est */etc/dovecot/conf.d/30-managesieve.conf* et comme pour sieve la configuration par défaut nous convient.

Vous pouvez relancer dovecot.	   

### Quelques exemples d'utilisation de Sieve
Si comme moi vous utiliser Thunderbird comme client mail, n'utilise pas le module Sieve présent sur le repo Mozilla, cette version ne fonctionne pas avec les version récente de Thunderbird. <a href="https://github.com/thsmi/sieve/tree/master/nightly/">téléchargez la dernière version du plugin ManageSieve pour thunderbird ici</a>.

En début de script ajoutez :
	
	require "fileinto";

Classer les messages de la mailing-list bar@ovh.net dans le dossier Inbox/ml/bar@ovh

	if address :is ["To","Cc"] "bar@ml.ovh.net" {
   		fileinto "ml.bar@ovh";
   		stop;
	}

Classer les spams dans un dossier Inbox/Spams si le sujet commence par [SPAM]
	
	if header :comparator "i;ascii-casemap" :contains "Subject" "[SPAM]"  {
        fileinto "spams";
        stop;
	}

Pour aller plus loin, voici <a href="http://wiki2.dovecot.org/Pigeonhole/Sieve/Examples" target="_blank"> des exemples de scripts Sieve </a>

