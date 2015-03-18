+++
date = "2015-03-18T14:34:28+01:00"
draft = true
title = "Gérez vos boites mail avec tmail"

+++

Initialement j'avais prévu d'ajouter le support de comptes mail bien plus tard dans le cycle de développement car mon usage principal de tmail est avant tout celui de relais SMTP.  
Le fait que l'on me demande si ça allait être bientôt disponible m'a fait réaliser que gérer des comptes mails était quand même l'usage principal d'un serveur de messagerie, j'ai donc décidé de remonter cette tache dans ma todo-list.  

Pour vous proposer cette fonctionnalité plus rapidement, j'ai fait quelques compromis sur ce que je voulais initialement faire. Mon idée de départ était de ne pas utiliser le classique stockage des mails via Mailbox/maildir + accès POP ou IMAP, mais d’utiliser une simple **interface de stockage de type PUT/GET pour stocker les mails et une API HTTP REST pour y accéder et les gérer.** 

L’intérêt de cette solution solution c'est que l'on peut implémenter l'interface pour une multitude de types de stockage "physique", du simple espace disque sur le serveur, ou déporté sur un NAS/Filer, mais aussi du Amazon S3, ou plus proche de nous du Runabove.
Par ailleurs proposer une API REST pour gérer les mails permettait de développer simplement des clients de messagerie adaptés et pourquoi des "connecteurs/proxy" pour rendre ce stockage compatible avec les clients classique (par exemple un proxy IMAP).

Rassurez vous - ou pas - je n'ai pas abandonné ces idées, ce sera implémenté, mai en attendant pour offrir le plus rapidement la possibilité d'utiliser tmail comme serveur mail classique, j'ai décidé de prendre un raccourcis en implémentant le nécessaire pour utiliser Dovecot avec tmail.

**Concrètement il est aujourd'hui possible d'utiliser tmail comme serveur de destination pour un domaine - celui qui va héberger les mails du domaine donc - et d'accéder aux boites mails via POP et IMAP.**

Voila pour cette - longue - introduction, passons à la pratique.

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

Il va maintenant falloir installer le support de base de données pour que dovecot puisse se connecter à la base de données utilisée par tmail. Il faudra donc en fonction de vos besoin installer soit dovecot-sqlite si vous utilisez SQLite, soit dovecot-mysql si vous utilisez MySQL,soit dovecot-pgsql si vous utilisez PostgreSQL.  

Dans mon cas comme je vais avoir besoin de tester sur les 3 SGDB, j'installe les trois:
	
	apt-get install dovecot-sqlite dovecot-mysql dovecot-pgsql


On va en rester là pour le moment, on ferra la configuration aprés avoir installé tmail.

### Installation de tmail
Si vous avez déja tmail installé, je vous recommande de supprimer les tables de votre base de données.
Beaucoup de modifications on été faites et il est plus prudent de repartir de zéro.

Dans un premier temps suivez ce tutoriel: [installer tmail](/doc/installer-tmail/)


### Configuration de tmail

Nous avons besoin de configurer trois parametres

Le répertoire dans lequel seront stockes les boites mails, par défaut c'est /home/tmail/dist/mailboxes.  
Assurez vosu que l'utilisateur tmail ait les droits de lecture et d'écriture sur ce répertoire.

	# Base path for users "home". Currently ysed to store mailboxes
	export TMAIL_USERS_HOME_BASE="/home/tmail/dist/mailboxes"

On doit ensuite activer le support de Dovecot

	# Enabled dovecot for local deliveries
	export TMAIL_DOVECOT_SUPPORT_ENABLED=true

Et enfin indiquer à tmail où se trouve l'agent de livraison de dovecot

	# Dovecot LDA path
	export TMAIL_DOVECOT_LDA="/usr/lib/dovecot/dovecot-lda"

### Creation d'une boite mail

Dans cet exemple tmail devra gerer les boites du domaine tmail.io. 
Si dans votre cas vous avez déja utilisé le domaine sur lequel vous souhaitez créer des boites vopus devez le supprimer.

	tmail rcpthost del tmail.io

On crée le compte toorop@tmail.io avec l'option *-m* pour signifier à tmail que cet utilisateur aura une boite mail et avec loption *-r* pour indiquer que cet utilisateur pour utiliser tmaiul comme relais SMTP (aprés authentification).

	tmail user add -m -r toorop@tmail.io MOT_DE_PASSE

### Configuration de dovecot

La premiere chose à faire est d'augmenter au maximum les niveaux de logs, comme ça si il y a un probléme ce sera plus facile de le localiser.

Pour cela on édite le ficher */usr/share/dovecot/conf.d/10-logging.conf* et on modifie les parametres suivant:

	auth_verbose = yes
	auth_debug = yes
	auth_debug_passwords = yes
	mail_debug = yes

On va à présent devoir indiquer à dovecot comment allez récuperer les info sur les utilisateurs.
Pour cela on va lui indiquer la requete SQL qu'il doit executer.
On édite le fichier: */etc/dovecot/dovecot-sql.conf.ext*

Il faut d'abord spécifier le driver que l'on va utiliser, dans mon cas sqlite:

	# Database driver: mysql, pgsql, sqlite
	driver = sqlite

Ensuite la "connection string", autrement dit les indications qui vont permettre à dovecot de se connecter à la base de données tmail:

	connect = /home/tmail/dist/db/tmail.db	 

L'algorytme utilisé pour hasher les mots de passe:
	
	default_pass_scheme = SHA512-CRYPT

La requete pour réaliser un authetification:

	password_query = SELECT login AS user, dove_passwd AS password \
   	FROM users WHERE login = '%u' AND active = 'Y'	

Pour la requete suivante, celle qui va permettre a dovecot de récuperer des informations sur l'utilisateur, on va avoir besoin de connaitre les UID/GID de l'utilisateur tmail sur votre systéme, pour cela exécuter en root la commande suivante:

	cat /etc/passwd | grep tmail
	tmail:x:1000:1000:,,,:/home/tmail:/bin/bash

Dans mon cas l'UID de tmail est 1000 son GID est aussi 1000, la requete user_query va donc être:

	user_query = SELECT home, 1000 AS uid, 1000 AS gid FROM users WHERE login = '%u'

Il faut à présent spécifier à dovecot que l'on souhaite utiliser l'authentifcation via SQL, on édite */etc/dovecot/conf.d/10-auth.conf* et on commente : 

	#!include auth-system.conf.ext

et on décommente:

	!include auth-sql.conf.ext


Il nous reste à configurer le format de stockage des boites mails, on va utiliser Mailbox.
On édite le fichier  */etc/dovecot/conf.d/10-mail.conf*:

	mail_location = maildir:~/Maildir


Il ne vous reste plus qu'a relancer dovecot:

	service dovecot restart

Voila normalement tout devrait fonctionner, si ce n'est pas le cas, consultez les logs dovecot et tmail, et si vous ne trouvez pas poster un SOS en commentaire de cet article.	 

Si tout fonctionne bien reduisez petit à petit le niveau de log de dovecot.


	