+++
date = "2015-06-09T14:33:39+02:00"
draft = false
title = "DKIM"
categories = ["doc"]
description = "tmail et DKIM "
keywords = ["dkim"]
tags = [ "dkim"]

+++

Je suppose que vous avez déjà lu des docs expliquant comment mettre en place et configurer DKIM ?  
Ça vous à paru compliqué, long et pénible ?  
Moi aussi et c'est pour ces raisons que j'ai voulu simplifier au maximum la procédure avec tmail. 

<!--more-->

Tout d'abord un petit rappel sur ce qu'est DKIM.  

Pour faire court DKIM permet :

* De faire le lien entre un mail et une autorité, celle qui l'a signé.
* De s'assurer de l'intégrité d'un mail, autrement dit qu'il n'a pas été modifié entre le moment où il à été signé et le moment où la signature à été vérifiée.

Attention aux légendes urbaines:

* Ce n'est pas parce qu'un mail ayant comme expéditeur contact@mabanque.com à une signature DKIM valide que ce mail vient de contact@mabanque.com et plus globalement qu'il n'est pas un spam ou un phishing.
* Ce n'est pas parce qu’un mail à une signature DKIM non valide que c'est un spam ou un phishing.

**Comme toutes les sections de cette documentation, cette page reflète ce qui est implémenté dans tmail au moment de sa rédaction. Autrement dit pensez à visiter cette page régulièrement car elle sera fréquemment mise à jour**


## Support de DKIM

Le support de DKIM à été introduit dans la version 0.0.8, mais il vous faudra au moins la 0.0.8.3 pour suivre ce tutoriel.

Je ne vais traiter ici que de la signature des mails sortant, si vous voulez vérifier la signature des mails entrant, je vous invite à utiliser le [micro-service de vérification DKIM](/doc/microservices/#dkimverif:24c62ab0ae8d6139f10d3d52cfeca2af)

## Activer DKIM

D'abord assurez vous d'avoir une version de tmail supérieure ou égale à la 0.0.8.3

Ensuite il vous suffit juste de modifier:

	# DKIM sign outgoing (remote) emails
	export TMAIL_DELIVERD_DKIM_SIGN=false

pour:

	# DKIM sign outgoing (remote) emails
	export TMAIL_DELIVERD_DKIM_SIGN=true

## Configurer DKIM pour un domaine

Pour ce tuto je vais utiliser le domaine tmail.io comme exemple.

Pour configurer et activer DKIM pour le domaine tmail.io il vous suffit d’exécuter cette commande:

	$ tmail dkim enable tmail.io
	Done !
	It remains for you to create this TXT record on dkim._domainkey.tmail.io zone:

	v=DKIM1;k=rsa;s=email;h=sha256;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcfgB0bQfGnuDJKtB2/9oT6NIs2WTnnNfFMGMGEBR1TyuGhya6CjXPaOJSZKFsHWz98uzaaXNGIXIJKPIkboSmnVg4X9ezp7JeqbyWf/T3Bi1QL7lKSJLWrtHzEaDAchitFwH+y8ByCQb6nQO8/ptCeFJZg+yDv/8uYddovOZh3QIDAQAB

	And... That's all.

Comme indiqué, il ne vous reste plus qu'a ajouter l'enregistrement TXT fournis aux DNS du domaine et c'est fini. Tous les mails ayant comme domaine d'expédition tmail.io seront dés lors signés.

Je vous avez dis que ce serait simple et rapide ;)


Vous ne savez pas trop comment crée cet enregistrement au niveau de votre serveur DNS ?

Si vous utilisez *Bind*, ajoutez dans la zone du domaine:

	dkim._domainkey.tmail.io IN TXT "v=DKIM1;k=rsa;s=email;h=sha256;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcfgB0bQfGnuDJKtB2/9oT6NIs2WTnnNfFMGMGEBR1TyuGhya6CjXPaOJSZKFsHWz98uzaaXNGIXIJKPIkboSmnVg4X9ezp7JeqbyWf/T3Bi1QL7lKSJLWrtHzEaDAchitFwH+y8ByCQb6nQO8/ptCeFJZg+yDv/8uYddovOZh3QIDAQAB"	

Pensez aussi à incrémenter le serial.	

Si vous utilisé *djbdns* ou un dérivé (pour un ttl de 300 secondes):

	'dkim._domainkey.tmail.io:v=DKIM1;k=rsa;s=email;h=sha256;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcfgB0bQfGnuDJKtB2/9oT6NIs2WTnnNfFMGMGEBR1TyuGhya6CjXPaOJSZKFsHWz98uzaaXNGIXIJKPIkboSmnVg4X9ezp7JeqbyWf/T3Bi1QL7lKSJLWrtHzEaDAchitFwH+y8ByCQb6nQO8/ptCeFJZg+yDv/8uYddovOZh3QIDAQAB:300::


## Quelques commandes utiles
### Désactiver DKIM

Il vous suffit d'éxecuter la commande:
	
		$ tmail dkim disable tmail.io

Attention en exécutant cette commande toute la configuration DKIM du domaine va être supprimée et donc entre autre la clé privée qui permet de signer le message. Donc si vous souhaitez réactiver le domaine ultérieurement il vous faudra penser à mettre à jour votre enregistrement DNS avec la nouvelle clé publique.


### Obtenir la clé publique

	$ tmail dkim getpubkey tmail.io

	MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcfgB0bQfGnuDJKtB2/9oT6NIs2WTnnNfFMGMGEBR1TyuGhya6CjXPaOJSZKFsHWz98uzaaXNGIXIJKPIkboSmnVg4X9ezp7JeqbyWf/T3Bi1QL7lKSJLWrtHzEaDAchitFwH+y8ByCQb6nQO8/ptCeFJZg+yDv/8uYddovOZh3QIDAQAB

### Obtenir la clé privée

	$ tmail dkim getprivkey tmail.io

	-----BEGIN RSA PRIVATE KEY-----
	MIICWwIBAAKBgQDcfgB0bQfGnuDJKtB2/9oT6NIs2WTnnNfFMGMGEBR1TyuGhya6
	CjXPaOJSZKFsHWz98uzaaXNGIXIJKPIkboSmnVg4X9ezp7JeqbyWf/T3Bi1QL7lK
	SJLWrtHzEaDAchitFwH+y8ByCQb6nQO8/ptCeFJZg+yDv/8uYddovOZh3QIDAQAB
	AoGALETIBpgVZZVkgD8uV5YKzNCD0ilbjvz4fUi3uPHliZ/5lyrvZY7DOv9N4Uj+
	99v4lAv/7eIaGMyCPsCPzSy7SPDgf00yPX/LO4k5rMZv292zLe4bQO4PPIuLcy/q
	4yzkhMZqZVBSCcUMh8fNUbqGC84R2QFCH3WiW1P8fZgmfUECQQD8Ges5rOopvLkS
	Ee2Qmu17CYmo8Fh/zcro5guakbifYTdoaNNYYCg35S40HngCHbOvNBAIMaNbQxPR
	W41Hxv05AkEA3+bw7zGfO7e2ZLUqgjsisGWVFWmDSdYnxjuetmfORumzfpjxB8JO
	HW6YESrQVQTY6P5lwCdZLhs5YDKsKtatxQJBAJEY+eIAO+Y50OstlmYcRYMDQlAR
	xV4JvDe/7/3O0UwqUBGwA7Rh48QIDEfDIZ9WKQ02EeQlbbghK07cOryNM0ECQEcT
	RIBpvCZ01w15BRl6NDTSylSVvft+Y/nliyhUI4MXRMd3PWw9HhbxuIwajy+t7j1o
	JFyvIPwl4DzNWSHwLBECPzFI7mKE2r9aDMP6nD+srX2Dy/xhqngveiiacPipaTAT
	R+h7IZIHP3Of7G9J7enMvg0L6bkhEFkQFkqC+Ns5mA==
	-----END RSA PRIVATE KEY-----

### Obtenir l'enregistrement DNS TXT

	$ dist/tmail dkim getdnsrecord tmail.io

	dkim._domainkey.tmail.io zone:

	v=DKIM1;k=rsa;s=email;h=sha256;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcfgB0bQfGnuDJKtB2/9oT6NIs2WTnnNfFMGMGEBR1TyuGhya6CjXPaOJSZKFsHWz98uzaaXNGIXIJKPIkboSmnVg4X9ezp7JeqbyWf/T3Bi1QL7lKSJLWrtHzEaDAchitFwH+y8ByCQb6nQO8/ptCeFJZg+yDv/8uYddovOZh3QIDAQAB
