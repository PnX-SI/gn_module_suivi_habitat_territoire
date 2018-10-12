#!/bin/bash

. config/settings.ini

# Create log folder in module folders if it don't already exists
if [ ! -d 'var' ]
then
  mkdir var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
fi

# Copy SQL files into /tmp system folder in order to edit it with variables
cp data/habitat.sql /tmp/habitat.sql

# Create SFT schema into GeoNature database
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/habitat.sql &>> var/log/install_habitat.log