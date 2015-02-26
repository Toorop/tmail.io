#!/bin/sh

# generate
hugo --theme=hyde --buildDrafts;

# send everything in public to the root of blog
rsync -avz --del public/* root@tmail.io:/var/www/tmail.io/