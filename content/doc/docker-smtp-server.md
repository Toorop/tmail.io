+++
date = "2015-05-26T18:23:15+02:00"
draft = false
title = "tmail + Docker = un SMTP déployé en moins de 5 minutes "
categories = ["doc"]
description = "ce tuto va vous permettre de mettre en place un serveur SMTP en moins de 5 minutes avec tmail et docker"
keywords = ["docker"]
tags = [ "docker"]

+++

Ça vous dirait de tester tmail mais vous vous dites que vous n'avez pas le temps et/ou pas de serveur de disponible ?

Vous aimeriez avoir votre relais SMTP mais vous vous dites que c'est trop compliqué à mettre en place ?

Pfff balayez moi toute ces excuses bidons, dans ce tuto je vais vous montrer comment déployer tmail en tant que relais SMTP en quelques minutes et pour quelques centimes d'euro (voir rien du tout si vous êtes client OVH).

<img class="center" src="/img/amazing.png">

<!--more-->
<br>
Avant toute chose, tmail est en plein développement, donc considérez ce tuto comme un <a href="http://fr.wikipedia.org/wiki/Preuve_de_concept" target="_blank" title="preuve de concept"> poc </a> et n'utilisez pas le SMTP pour des choses importantes, il y à forcement des bugs qui traînent.

Bien commençons par le commencement, il va nous falloir un serveur, nos amis de chez OVH ont eu la bonne idée de sortir <a href="http://www.ovh.com/fr/cloud/" target="_blank" title="cloud OVH"> leur offre cloud </a> cette semaine, ne cherchons pas plus loin.  

A moins que vous ayez des millions de mails à envoyer par jour leur offre KS1 sera largement suffisante et à 0.008 € de l'heure elle ne devrait pas vous ruiner. On va donc lancer une instance de ce type avec Ubuntu 14.04 comme distribution.

Comptez jusqu’à 30:

	30 29 28 27 26 25 24 23 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1


Ça y est ?  
L'instance est donc prête, on s'y connecte:

	ssh admin@IP

On passe en root et on met le système à jour:

	sudo su
	apt-get update && apt-get -y upgrade

On installe Docker:
	
	wget -qO- https://get.docker.com/ | sh

On ajoute un utilisateur *tmail* qui va avoir le droit d'utiliser Docker:

	adduser -q --disabled-password  tmail	
	usermod -aG docker tmail


On bascule sous l'user tmail :

	su tmail 
	cd

Si vous êtes vraiment pressé il ne vous reste plus qu'a faire:
	
	docker build -t tmail https://raw.githubusercontent.com/toorop/dockerfiles/master/tmail/Dokerfile
	docker run -d -p 587:2525 tmail


Et voila, c'est fini vous pouvez utiliser le smtp pour envoyer vos mails.

Voici la configuration à utiliser:

* Adresse du serveur: adresse IP publique de votre instance
* Port: 587
* STARTTLS
* SMTPAUTH: mots de passe en clair (pensez bien à activer STARTTLS)
* Utilisateur: tmail
* Mot de passe: tmailpasswd

Votre client va couiner car le certificat est auto-signé, il vous faudra ajouter une exception de sécurité.  

Tant que j'y pense les mails sortant auront une signature DKIM. La <a href="https://github.com/toorop/go-dkim" target="_blank" title="DKIM library for Golang"> lib DKIM </a> étant toute fraîche je ne garantie rien, mais dans tous les cas ça ne doit pas poser de problème car la signature est signalée comme étant en test (en clair si à la vérification la signature n'est pas valide, on ne doit pas en tenir compte) .

Bien entendu le couple login/passwd étant le même pour tout le monde, et surtout connu de tous, je vous conseille fortement de couper ce container dés que vous avez fini les tests.

Si vous souhaitez aller plus loin, autrement dit si vous souhaitez garder le service SMTP, il vous faut changer le couple user/passwd.

Pour cela stopper et supprimer le container:
	
		docker stop CONTAINER_ID
		docker rm CONTAINER_ID

Téléchargez le *dokerfile*:

	wget https://raw.githubusercontent.com/toorop/dockerfiles/master/tmail/Dokerfile

Éditez le pour modifier *tmail* et *tmailpasswd*:

	RUN . conf/tmail.cfg && \
    ./tmail user add -r USER MOT_DE_PASSE

Et construisez/lancez le container:

	docker build -t tmail .
	docker run -d -p 587:2525 tmail


Un dernier petit tips pour la route, si vous n'êtes pas adepte de Docker, pour avoir les logs de tmail:

	docker logs -f ID_CONTAINER

Attention, le debug est activé, c'est très verbeux.	


Finalement il m'en reste encore un, pour connaître l'identifiant du container:
	
	core@coreos ~ $ docker ps -a

	CONTAINER ID  IMAGE       	COMMAND                
	b60c7b7cc31f  tmail:latest  "/home/tmail/dist/ru   


Voila enjoy ;)	





	










