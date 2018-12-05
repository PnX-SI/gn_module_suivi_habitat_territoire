from flask import Blueprint, request, session, current_app, send_from_directory, abort
from geojson import FeatureCollection, Feature
from sqlalchemy.sql.expression import func
from sqlalchemy import and_ , distinct

from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilssqlalchemy import json_resp, to_json_resp, to_csv_resp

from geonature.core.gn_monitoring.models import corVisitObserver, corSiteArea, corSiteApplication
from geonature.core.ref_geo.models import LAreas
from geonature.core.users.models import TRoles, BibOrganismes

from .models import TInfosSite, Habref, CorHabitatTaxon, Taxonomie, TBaseVisit, TInfosSite

blueprint = Blueprint('pr_suivi_habitat_territoire', __name__)


@blueprint.route('/habitats', methods=['GET'])
@json_resp
def get_habitats():
    '''
    TODO tous les habitats du protocole cor_lis_hab
    '''
    data= DB.session.query(CorHabitatTaxon)
    return [d.as_dict(True) for d in data]


@blueprint.route('/taxons/<cd_hab>', methods=['GET'])
@json_resp
def get_taxa_by_habitats(cd_hab):
    '''
    tous les taxons d'un habitat
    '''
     
    q = DB.session.query(
        CorHabitatTaxon.cd_nom,
        Taxonomie.nom_complet
        ).join(
            Taxonomie, CorHabitatTaxon.cd_nom == Taxonomie.cd_nom
        ).group_by(CorHabitatTaxon.id_habitat, CorHabitatTaxon.id_cor_habitat_taxon, Taxonomie.nom_complet)
        
    q = q.filter(CorHabitatTaxon.id_habitat == cd_hab)
    data = q.all()

    taxons = []
    print(data)

    if data:
        for d in data:
            taxon = dict()
            taxon['cd_nom'] = str(d[0])
            taxon['nom_complet'] = str(d[1])
            taxons.append(taxon)
        return taxons
    return None

@blueprint.route('/sites', methods=['GET'])
@json_resp
def get_all_sites():
    '''
    Retourne tous les sites
    '''
    parameters = request.args
    q = (
        DB.session.query(
            TInfosSite,
            func.max(TBaseVisit.visit_date_min),
            Habref.lb_hab_fr_complet,
            func.count(distinct(TBaseVisit.id_base_visit)),
            func.string_agg(distinct(BibOrganismes.nom_organisme), ', '),
            func.string_agg(LAreas.area_name, ', ')
            ).outerjoin(
            TBaseVisit, TBaseVisit.id_base_site == TInfosSite.id_base_site
            # get taxonomy lb_nom
            ).outerjoin(
                Habref, TInfosSite.cd_hab == Habref.cd_hab
            # get organisms of a site
            ).outerjoin(
                corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisit.id_base_visit
            ).outerjoin(
                TRoles, TRoles.id_role == corVisitObserver.c.id_role
            ).outerjoin(
                BibOrganismes, BibOrganismes.id_organisme == TRoles.id_organisme
            )
            # get municipalities of a site
            .outerjoin(
                corSiteArea, corSiteArea.c.id_base_site == TInfosSite.id_base_site
            )
            .group_by(
                TInfosSite, Habref.lb_hab_fr_complet
            )
        )

    if 'cd_hab' in parameters:
        q = q.filter(TInfosSite.cd_hab == parameters['cd_hab'])
    
    if 'id_base_site' in parameters:
        q = q.filter(TInfosSite.id_base_site == parameters['id_base_site'])

    if 'organisme' in parameters:
        q = q.filter(BibOrganismes.nom_organisme == parameters['organisme'])

    if 'year' in parameters:
        # relance la requête pour récupérer la date_max exacte si on filtre sur l'année
        q_year = (
            DB.session.query(
                TInfosSite.id_base_site,
                func.max(TBaseVisit.visit_date_min),
            ).outerjoin(
                TBaseVisit, TBaseVisit.id_base_site == TInfosSite.id_base_site
            ).group_by(TInfosSite.id_base_site)
        )

        data_year = q_year.all()

        q = q.filter(func.date_part('year', TBaseVisit.visit_date_min) == parameters['year'])
    data = q.all()

    features = []

    for d in data:
        feature = d[0].get_geofeature()
        id_site = feature['properties']['id_base_site']
        if feature['properties']['t_base_site']:
            del feature['properties']['t_base_site']
        if 'year' in parameters:
            for dy in data_year:
                #  récupérer la bonne date max du site si on filtre sur année
                if id_site == dy[0]:
                    feature['properties']['date_max'] = str(dy[1])
        else:
            feature['properties']['date_max'] = str(d[1])
            if d[1] == None:
                feature['properties']['date_max'] = 'Aucune visite'
        feature['properties']['nom_habitat'] = str(d[2])
        feature['properties']['nb_visit'] = str(d[3])
        feature['properties']['organisme'] = str(d[4])
        if d[4] == None:
            feature['properties']['organisme'] = 'Aucun'
        features.append(feature)

    return FeatureCollection(features)

