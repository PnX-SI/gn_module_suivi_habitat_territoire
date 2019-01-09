import json
from flask import Blueprint, request, session, current_app, send_from_directory, abort
from geojson import FeatureCollection, Feature
from sqlalchemy.sql.expression import func
from sqlalchemy import and_ , distinct, desc
from sqlalchemy.exc import SQLAlchemyError

from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilssqlalchemy import json_resp, to_json_resp, to_csv_resp
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import (
    InsufficientRightsError,
    get_or_fetch_user_cruved,
)
from pypnusershub import routes as fnauth
from geonature.core.gn_monitoring.models import corVisitObserver, corSiteArea, corSiteApplication, TBaseVisits
from geonature.core.ref_geo.models import LAreas
from geonature.core.users.models import TRoles, BibOrganismes

from .repositories import check_user_cruved_visit, check_year_visit

from .models import TInfosSite, Habref, CorHabitatTaxon, Taxonomie, TVisitSHT, TInfosSite, CorVisitTaxon, CorVisitPerturbation, CorListHabitat

blueprint = Blueprint('pr_suivi_habitat_territoire', __name__)


@blueprint.route('/habitats/<id_list>', methods=['GET'])
@json_resp
def get_habitats(id_list):
    '''
    Récupère les habitats cor_list_habitat à partir de l'identifiant id_list de la table bib_lis_habitat
    '''
    q = DB.session.query(
        CorListHabitat.cd_hab,
        CorListHabitat.id_list,
        Habref.lb_hab_fr_complet
    ).join (
        Habref, CorListHabitat.cd_hab == Habref.cd_hab
    ).filter(
        CorListHabitat.id_list == id_list
    ).group_by(CorListHabitat.cd_hab, Habref.lb_hab_fr_complet, CorListHabitat.id_list,)

    data = q.all()
    habitats = []

    if data:
        for d in data:
            habitat = dict()
            habitat['cd_hab'] = str(d[0])
            habitat['nom_complet'] = str(d[2])
            habitats.append(habitat)
        return habitats
    return None


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

    id_type_commune = blueprint.config['id_type_commune']

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
                        feature['properties']['date_max'] = str(d[1])
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


@blueprint.route('/visits', methods=['GET'])
@json_resp
def get_visits():
    '''
    Retourne toutes les visites du module
    '''
    parameters = request.args
    q = DB.session.query(TVisitSHT)
    if 'id_base_site' in parameters:
        q = q.filter(TVisitSHT.id_base_site == parameters['id_base_site']).order_by(desc(TVisitSHT.visit_date_min))
    data = q.all()
    return [d.as_dict(True) for d in data]


@blueprint.route('/visits/<id_visit>', methods=['GET'])
@json_resp
def get_visit(id_visit):
    '''
    Retourne une visite
    '''
    data = DB.session.query(TVisitSHT).get(id_visit)
  
    visit = []
    if data:
        cvisit = data.as_dict(recursif=True)
        if 'cor_visit_perturbation' in cvisit:
            tab_visit_perturbation = cvisit.pop('cor_visit_perturbation')
            for index, per in enumerate(tab_visit_perturbation):
                visit.append(per['t_nomenclature'])
            cvisit['cor_visit_perturbation'] = visit
        else:
            cvisit['cor_visit_perturbation'] = []
        if 'cor_visit_taxons' not in cvisit:
            cvisit['cor_visit_taxons'] = []
        return cvisit
    return None


@blueprint.route('/visits', methods=['POST'])
@json_resp
def post_visit(info_role=None):
    '''
    Poster une nouvelle visite
    '''
    data = dict(request.get_json())
    tab_visit_taxons = []
    tab_observer = []
    tab_perturbation = []

    if 'cor_visit_taxons' in data:
        tab_visit_taxons = data.pop('cor_visit_taxons')
    if 'cor_visit_observer' in data:
        tab_observer = data.pop('cor_visit_observer')
    if 'cor_visit_perturbation' in data:
        tab_perturbation = data.pop('cor_visit_perturbation')

    visit = TVisitSHT(**data)


    for per in tab_perturbation:
        visit_per = CorVisitPerturbation(**per)
        visit.cor_visit_perturbation.append(visit_per)

    for t in tab_visit_taxons:
        visit_taxons = CorVisitTaxon(**t)
        visit.cor_visit_taxons.append(visit_taxons)

    observers = DB.session.query(TRoles).filter(
        TRoles.id_role.in_(tab_observer)
    ).all()
    for o in observers:
        visit.observers.append(o)

    visit.as_dict(True)

    DB.session.add(visit)

    DB.session.commit()

    return visit.as_dict(recursif=True)


@blueprint.route('/visits/<int:idv>', methods=['PATCH'])
@json_resp
def patch_visit(idv, info_role=None):
    '''
    Mettre à jour une visite
    Si une donnée n'est pas présente dans les objets observer, cor_visit_taxons ou cor_visit_perurbations, elle sera supprimée de la base de données
    '''
    data = dict(request.get_json())

    try:
        existingVisit = TVisitSHT.query.filter_by(id_base_visit = idv).first()
        if(existingVisit == None):
            raise ValueError('This visit does not exist')
    except ValueError:
        resp = jsonify({"error": 'This visit does not exist'})
        resp.status_code = 404
        return resp

    tab_visit_taxons = []
    tab_observer = []
    tab_perturbation = []

    if 'cor_visit_taxons' in data:
        tab_visit_taxons = data.pop('cor_visit_taxons')
    if 'cor_visit_observer' in data:
        tab_observer = data.pop('cor_visit_observer')
    if 'cor_visit_perturbation' in data:
        tab_perturbation = data.pop('cor_visit_perturbation')

    visit = TVisitSHT(**data)

    DB.session.query(CorVisitPerturbation).filter_by(id_base_visit = idv).delete()
    for per in tab_perturbation:
        visitPer = CorVisitPerturbation(**per)
        visit.cor_visit_perturbation.append(visitPer)

    DB.session.query(CorVisitTaxon).filter_by(id_base_visit = idv).delete()
    for taxon in tab_visit_taxons:
        visitTaxons = CorVisitTaxon(**taxon)
        visit.cor_visit_taxons.append(visitTaxons)

    visit.observers = []
    observers = DB.session.query(TRoles).filter(
        TRoles.id_role.in_(tab_observer)
    ).all()
    for o in observers:
        visit.observers.append(o)

    """ user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
    )
    update_cruved = user_cruved['U']
    check_user_cruved_visit(info_role, visit, update_cruved) """

    mergeVisit = DB.session.merge(visit)

    DB.session.commit()

    return visit.as_dict(recursif=True)



@blueprint.route('/organismes', methods=['GET'])
@json_resp
def get_organisme():
    '''
    Retourne la liste de tous les organismes présents
    '''

    q = DB.session.query(
        BibOrganismes.nom_organisme, TRoles.nom_role, TRoles.prenom_role).outerjoin(
        TRoles, BibOrganismes.id_organisme == TRoles.id_organisme).distinct().join(
        corVisitObserver, TRoles.id_role == corVisitObserver.c.id_role).outerjoin(
        TVisitSHT, corVisitObserver.c.id_base_visit == TVisitSHT.id_base_visit)

    data = q.all()
    if data:
        tab_orga = []
        for d in data:
            info_orga = dict()
            info_orga['nom_organisme'] = str(d[0])
            info_orga['observer'] = str(d[1]) + ' ' + str(d[2])
            tab_orga.append(info_orga)
        return tab_orga
    return None


@blueprint.route('/communes/<id_application>', methods=['GET'])
@json_resp
def get_commune(id_application):
    '''
    Retourne toutes les communes présents dans le module
    '''
    params = request.args

    q = DB.session.query(LAreas.area_name).distinct().outerjoin(
        corSiteArea, LAreas.id_area == corSiteArea.c.id_area).outerjoin(
        corSiteApplication, corSiteApplication.c.id_base_site == corSiteArea.c.id_base_site).filter(corSiteApplication.c.id_application == id_application)

    if 'id_area_type' in params:
        q = q.filter(LAreas.id_type == params['id_area_type'])

    data = q.all()
    if data:
        tab_commune = []

        for d in data:
            nom_com = dict()
            nom_com['nom_commune'] = str(d[0])
            tab_commune.append(nom_com)
        return tab_commune
    return None