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
cp data/sht.sql /tmp/sht.sql

cp data/sht_perturbations.sql /tmp/sht_perturbations.sql
cp data/habitat_data.sql /tmp/habitat_data.sql
cp data/sht_data.sql /tmp/sht_data.sql


sudo sed -i "s/MY_SRID_WORLD/$srid_world/g" /tmp/sht.sql

#Dont ask for a module ID as we dont know it...

sudo sed -i "s/MY_SRID_LOCAL/$srid_local/g" /tmp/sht_data.sql

sudo sed -i "s/MY_SRID_WORLD/$srid_world/g" /tmp/sht_data.sql


# Create habitat schema into GeoNature database
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/habitat.sql &>> var/log/install_habitat.log

# Create SHT schema into GeoNature database
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht.sql &>> var/log/install_sht.log


# Include sample data into database
if $insert_sample_data
then
    sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/mailles100z.shp pr_monitoring_habitat_territory.maille_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_maille.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/habitat_data.sql &>> var/log/install_habitat_data.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht_perturbations.sql &>> var/log/install_sht_perturbations.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht_data.sql &>>  var/log/install_sht_data.log
fi