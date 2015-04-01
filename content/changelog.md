+++
date = "2015-03-14T19:38:45+01:00"
draft = false
title = "Changelog"
description = "changelog du serveur smtp tmail"
keywords = ["changelog","smtp","tmail"]
tags = ["changelog"]
[menu.main]
name = "Changelog"
weight = 4

+++
## v 0.0.5
 * Log to file
 * Improve log
 * Case sensitivity on local part
 * add RSET and NOOP SMTP verbs

## v 0.0.4 
* Add local deliveries
* Dovecot support
* SmtpUser replaced by Use
* Cli
* Refactoring


## v 0.0.3
* Bugfix: MySQL Datetime to Golang time.Time
* BugFix: Optimise/fix queries for Mysql

## v 0.0.2
* add Clamav support: http://tmail.io/doc/filtrage-smtp-antivirus-clamav/