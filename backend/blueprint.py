import json
from flask import Blueprint, request, session, current_app, send_from_directory, abort
from geojson import FeatureCollection, Feature
from sqlalchemy.sql.expression import func
from sqlalchemy import and_ , distinct
from sqlalchemy.exc import SQLAlchemyError

from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilssqlalchemy import json_resp, to_json_resp, to_csv_resp
from pypnnomenclature.models import TNomenclatures
from pypnusershub import routes as fnauth
from geonature.core.gn_monitoring.models import corVisitObserver, corSiteArea, corSiteApplication, TBaseVisits
from geonature.core.ref_geo.models import LAreas
from geonature.core.users.models import TRoles, BibOrganismes

from .models import TInfosSite, Habref, CorHabitatTaxon, Taxonomie, TVisitSHT, TInfosSite, CorVisitTaxon

blueprint = Blueprint('pr_suivi_habitat_territoire', __name__)


@blueprint.route('/habitats', methods=['GET'])
@json_resp
def get_habitats():
    '''
    TODO tous les habitats du protocole cor_lis_hab
    '''
    data= DB.session.query(CorHabitatTaxon)
    return [d.as_dict(True) for d in data]


@blueprint.route('/habitats/<cd_hab>/taxons', methods=['GET'])
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

    # TODO Blueprint config ne fonctionne pas ??
    #id_type_commune = blueprint.config['id_type_commune']
    id_type_commune = 25

    q = (
        DB.session.query(
            TInfosSite,
            func.max(TBaseVisits.visit_date_min),
            Habref.lb_hab_fr_complet,
            func.count(distinct(TBaseVisits.id_base_visit)),
            func.string_agg(distinct(BibOrganismes.nom_organisme), ', '),
            func.string_agg(LAreas.area_name, ', ')
            ).outerjoin(
            TBaseVisits, TBaseVisits.id_base_site == TInfosSite.id_base_site
            # get habitat cd_hab
            ).outerjoin(
                Habref, TInfosSite.cd_hab == Habref.cd_hab
            # get organisms of a site
            ).outerjoin(
                corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit
            ).outerjoin(
                TRoles, TRoles.id_role == corVisitObserver.c.id_role
            ).outerjoin(
                BibOrganismes, BibOrganismes.id_organisme == TRoles.id_organisme
            )
            # get municipalities of a site
            .outerjoin(
                corSiteArea, corSiteArea.c.id_base_site == TInfosSite.id_base_site
            ).outerjoin(
                LAreas, and_(LAreas.id_area == corSiteArea.c.id_area, LAreas.id_type == id_type_commune)
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

    if 'commune' in parameters:
        q = q.filter(LAreas.area_name == parameters['commune'])

    if 'year' in parameters:
        # relance la requête pour récupérer la date_max exacte si on filtre sur l'année
        q_year = (
            DB.session.query(
                TInfosSite.id_base_site,
                func.max(TBaseVisits.visit_date_min),
            ).outerjoin(
                TBaseVisits, TBaseVisits.id_base_site == TInfosSite.id_base_site
            ).group_by(TInfosSite.id_base_site)
        )

        data_year = q_year.all()

        q = q.filter(func.date_part('year', TBaseVisits.visit_date_min) == parameters['year'])
    data = q.all()

    features = []

    print("data", data)
    if data:
        for d in data:
            feature = d[0].get_geofeature()
            id_site = feature['properties']['id_base_site']
            base_site_code = feature['properties']['t_base_site']['base_site_code']
            base_site_description = feature['properties']['t_base_site']['base_site_description'] or 'Aucune description'
            base_site_name = feature['properties']['t_base_site']['base_site_name']
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
            feature['properties']['nom_commune'] = str(d[5])
            if d[4] == None:
                feature['properties']['organisme'] = 'Aucun'
            feature['properties']['base_site_code'] = base_site_code
            feature['properties']['base_site_description'] = base_site_description
            feature['properties']['base_site_name'] = base_site_name
            features.append(feature)

        return FeatureCollection(features)
    return None


@blueprint.route('/visit', methods=['POST', 'PATCH'])
@json_resp
def post_visit(info_role=None):
    '''
    Poste une nouvelle visite 
    '''
    data = dict(request.get_json())

    tab_visit_taxons = data.pop('cor_visit_taxons')
    tab_observer = data.pop('cor_visit_observer')
    tab_perturbation = data.pop('cor_visit_perturbation')

    visit = TVisitSHT(**data)

    perturs = DB.session.query(TNomenclatures).filter(
        TNomenclatures.id_nomenclature.in_(tab_perturbation)).all()
    for per in perturs:
        visit.cor_visit_perturbation.append(per)
   

    for t in tab_visit_taxons:
        visit_taxons = CorVisitTaxon(**t)
        visit.cor_visit_taxons.append(visit_taxons)


    observers = DB.session.query(TRoles).filter(
        TRoles.id_role.in_(tab_observer)
    ).all()
    for o in observers:
        visit.observers.append(o)

    visit.as_dict(True)
    print(visit)

    if visit.id_base_visit:
        user_cruved = get_or_fetch_user_cruved(
            session=session,
            id_role=info_role.id_role,
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        update_cruved = user_cruved['U']
        check_user_cruved_visit(info_role, visit, update_cruved)
        DB.session.merge(visit)
    else:
        DB.session.add(visit)

    DB.session.commit()

    return visit.as_dict(recursif=True)