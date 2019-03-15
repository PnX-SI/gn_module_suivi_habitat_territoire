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


###################
# ADD ref_habitat #
###################
# TODO: Version in config ?

if [ ! -d 'tmp/taxref/' ]
then
  mkdir tmp/taxref
fi

echo "Download and extract habref file..."

  if [ ! -f 'tmp/habref/HABREF_40.zip' ]
    wget https://geonature.fr/data/inpn/habitats/HABREF_40.zip -P tmp/habref
  then
    echo HABREF_40.zip exists
  unzip tmp/habref/HABREF_40.zip

cp data/habitat.sql /tmp/taxref/habref.sql
cp data/habitat.sql /tmp/taxref/habref_data.sql
cp data/habitat.sql /tmp/taxref/habref_bib_list.sql

echo "Creating 'habitat' schema..."
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxref/habref.sql &>> var/log/install_habref.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxref/habref_bib_list.sql &>> var/log/install_habref_bib_list.log

echo "Inserting INPN habitat data... "
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxref/habref_data.sql &>> var/log/install_habref_data.log



###########
# ADD SHT #
###########

# Copy SQL files into /tmp system folder in order to edit it with variables
cp data/sht.sql /tmp/sht.sql

cp data/sht_perturbations.sql /tmp/sht_perturbations.sql
cp data/sht_data.sql /tmp/sht_data.sql


sudo sed -i "s/MY_SRID_LOCAL/$srid_local/g" /tmp/sht_data.sql

sudo sed -i "s/MY_SRID_WORLD/$srid_world/g" /tmp/sht_data.sql


# Create SHT schema into GeoNature database
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht.sql &>> var/log/install_sht.log


# Include sample data into database
if $insert_sample_data
then
    sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/maille100z93.shp pr_monitoring_habitat_territory.maille_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_maille.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht_perturbations.sql &>> var/log/install_sht_perturbations.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht_data.sql &>>  var/log/install_sht_data.log
fi
