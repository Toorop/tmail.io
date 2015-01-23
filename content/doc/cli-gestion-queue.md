+++
date = "2015-01-21T14:20:24+01:00"
draft = false
title = "Gestion de la queue en utilisant le CLI"
+++


#### Lister les messages en queue

La commande pour lister les messages en queue est:

	tmail queue list

Pour chaque mail en queue les informations suivantes sont retournées:

* Identifiant du mail en queue
* From: expéditeur du mail
* To:  destinataire du mail
* Status: status du mail. Actuellement les status sont "Delivery in progress", "Scheduled", "Will be discarded", "Will be bounced"
* Next delivery process scheduled at: Dans le cas ou un mail est en attente dans la queue ce paramètre indique le moment (approximatif) où le mail sera représenté au process tmail qui traite les message en queue. 

Cas où il n'y a pas de message en queue:

	tmail queue list

	There is no message in queue.

Cas où il y a un message en queue qui est en train d'être délivré:
 
 	tmail queue list

	1 messages in queue.
	
	2c7eb14bc32991995af0c2f3e79be612535cbfea - From: toorop@toorop.fr - To: toorop@toorop.fr - Status: Delivery in progress - Added: 2015-01-23 09:10:40.271449372 +0100 CET 


Cas où il y un message en queue en attente:

	1 messages in queue.
	2c7eb14bc32991995af0c2f3e79be612535cbfea - From: toorop@toorop.fr - To: toorop@toorop.fr - Status: Scheduled - Added: 2015-01-23 09:10:40.271449372 +0100 CET - Next delivery process scheduled at: 2015-01-23 09:14:40.464895229 +0100 CET



#### Supprimer un message (discard) 
La commande suivante va vous permettre de supprimer un message de la queue:

	tmail discard MESSAGE_ID

Attention le mail ne sera pas supprimé instantanément, il le sera lorsqu'il sera présenté à tmail pour être traité.

Dans la mesure du possible il est préférable de bouncer un mail plutôt que de le supprimer pour que l'expéditeur soit informé du fait que son mail n'a pas abouti.	

#### Bouncer un message
Bouncer un message consiste à le supprimer de la queue et à envoyer un message à l'expéditeur pour l'informer que son mail n'est pas arrivé à destination.

La commande pour bouncer un mail est:
		
		tmail bounce MESSAGE_ID

Comme pour la commande discard, le bounce n'est pas instantané il se fera lorsque le mail sera représenté à tmail pour être délivré.



#### Relancer la queue (flush)
Pour le moment cette commande n'est pas implémentée. En attendant, pour relancer la queue il vous suffit de relancer tmail.