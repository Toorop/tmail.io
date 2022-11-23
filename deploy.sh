#!/bin/sh

# generate
hugo --theme=tmail;

# send everything in public to the root of blog
rsync -avz --del public/* root@tmail.dpp.st:/var/www/tmail.dpp.st/