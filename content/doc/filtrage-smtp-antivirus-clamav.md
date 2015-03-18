+++
date = "2015-02-18T14:19:22+01:00"
draft = false
title = "Filtrage antivirus en utilisant Clamav"
categories = [ "doc"]
tags = [ "filtrage", "antivirus" ]

+++
Vous trouverez dans ce billet les explications nécessaires pour installer l'antivirus opensource [Clamav](http://www.clamav.net/index.html) et activer le filtrage de votre flux SMTP par tmail.

<!--more--> 

### Installation de clamav

Je vais prendre le cas où vous utilisez une distribution Linux Debian ou Ubuntu, dans ce cas l’installation de Clamav est on ne peut plus simple :

	sudo apt-get install clamav

Comme tout antivirus il est nécessaire de maintenir à jour la base de signatures du scanner, normalement l'installation de Clamav va aussi entraîner l'installation de l'outil *freshclam* dédié à cet effet. 

Il ne nous reste plus qu'à lancer les services, le scanner en tant que tel:

	sudo service clamav-daemon start

et le daemon freshclam qui va maintenir à jour la base de signatures:

	sudo service clamav-freshclam start


### Configuration de tmail pour activer le filtrage antivirus

Il y à deux paramètres à configurer/vérifier pour activer le filtrage de votre flux SMTP. Tout d'abord il faut indiquer à tmail le socket unix sur lequel écoute le scanner. Le fichier de config contient le chemin par défaut lors d'une installation sous Ubuntu, si vous n'utilisez pas cette distribution, vous trouverez le chemin dans votre fichier de configuration de clamav.

	# Clamd DSNS
	export TMAIL_SMTPD_SCAN_CLAMAV_DSNS="/var/run/clamav/clamd.ctl"

Ensuite il ne reste plus qu'a activer le filtrage:

	# Clamav
	export TMAIL_SMTPD_SCAN_CLAMAV_ENABLED=true

Et voila !

Il faut savoir qu'actuellement le comportement va être le suivant:

* Les mails vont êtres filtrés durant la transaction SMTP.
* Si un virus est détecté le mail va être refusé. 

A terme je pense ajouter des option permettant par exemple de taguer les mails.
	