+++
date = "2015-05-15T14:33:39+02:00"
draft = false
title = "DKIM"
categories = ["doc"]
description = "tmail et DKIM "
keywords = ["dkim"]
tags = [ "dkim"]

+++

Vous trouverez dans cette section les informations vous permettant d'activer et de configurer DKIM.

Tout d'abord un petit rappel sur ce qu'est DKIM.  

Pour faire court DKIM permet :

* De faire le lien entre un mail et une autorité, celle qui l'a signé.
* De s'assurer de l'intégrité d'un mail, autrement dit qu'il n'a pas été modifié entre le moment où il à été signé et le moment où la signature à été vérifiée.

Attention aux légendes urbaines:

* Ce n'est pas parce qu'un mail ayant comme expéditeur contact@mabanque.com à une signature DKIM valide que ce mail  vient de contact@mabanque.com et plus globalement qu'il n'est pas un spam ou un phishing.
* Ce n'est pas parce qu’un mail à une signature DKIM non valide que c'est un spam ou un phishing.

<!--more-->

**Comme toutes les sections de cette documentation, cette page reflète ce qui est implémenté dans tmail au moment de sa rédaction. Autrement dit pensez à visiter cette page régulièrement car elle sera fréquemment mise à jour**


## Support de DKIM

Le support de DKIM à été introduit dans la version 0.0.8.
Pour le moment il est sommaire, le but est avant tout de tester l'implémentation. Autrement dit, actuellement si vous activez DKIM:

* Aucune vérification n'est faite sur les mails entrant.
* Tous les mails sortant sont signés en utilisant la même clé privée, le domaine "tmail.io" et le 'selector' "test".
* La clé publique, ou plus exactement sa représentation, contient le flag indiquant que c'est une signature de test. Autrement dit, l'entité qui va vérifier la signature, ne doit pas tenir compte du résultat de cette vérification si elle échoue.

Dans la pratique, vous ne prenez aucun risque à activer DKIM et comme ça va être très utile par valider l'implémentation je ne peux que vous encourager à la faire.

## Activer DKIM

D'abord assurez vous d'avoir une version de tmail supérieure ou égale à la 0.0.8.

Ensuite il vous suffit juste de modifier:

	# DKIM sign outgoing (remote) emails
	export TMAIL_DELIVERD_DKIM_SIGN=false

pour:

	# DKIM sign outgoing (remote) emails
	export TMAIL_DELIVERD_DKIM_SIGN=true

Et de relancer tmail. 		
