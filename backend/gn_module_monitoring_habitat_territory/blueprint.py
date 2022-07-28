import json
import datetime

from flask import Blueprint, request, session, current_app, send_from_directory, abort, jsonify
from sqlalchemy.sql.expression import func
from sqlalchemy import and_, distinct, desc
from sqlalchemy.orm import joinedload
from sqlalchemy.exc import SQLAlchemyError
from geoalchemy2.shape import to_shape
from geojson import FeatureCollection, Feature
from numpy import array
from shapely.geometry import *

from pypnusershub.db.tools import InsufficientRightsError
from pypnusershub.db.models import User
from pypnnomenclature.models import TNomenclatures
from pypn_habref_api.models import Habref, TypoRef, CorListHabitat
from utils_flask_sqla.response import json_resp, to_json_resp, to_csv_resp

from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilsgeometry import FionaShapeService
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
from geonature.core.gn_monitoring.models import corVisitObserver, corSiteArea, corSiteModule, TBaseVisits
from geonature.core.ref_geo.models import LAreas
from pypnusershub.db.models import Organisme
from geonature.core.taxonomie.models import Taxref

from .repositories import (
    check_user_cruved_visit,
    check_year_visit,
    get_taxonlist_by_cdhab,
    clean_string,
    striphtml,
    get_base_column_name,
    get_pro_column_name,
    get_mapping_columns
)
from .models import (
    TInfosSite,
    CorHabitatTaxon,
    TVisitSHT,
    TInfosSite,
    CorVisitTaxon,
    CorVisitPerturbation,
    ExportVisits
)


blueprint = Blueprint('SHT', __name__)


@blueprint.route('/habitats/<id_list>', methods=['GET'])
@json_resp
def get_habitats(id_list):
    '''
    Récupère les habitats cor_list_habitat à partir de l'identifiant id_list de la table bib_lis_habitat
    '''
    query = (DB.session
        .query(
            CorListHabitat.cd_hab,
            CorListHabitat.id_list,
            Habref.lb_hab_fr
        )
        .join(Habref, CorListHabitat.cd_hab == Habref.cd_hab)
        .filter(CorListHabitat.id_list == id_list)
        .group_by(
            CorListHabitat.cd_hab,
            CorListHabitat.id_list,
            Habref.lb_hab_fr,
        )
    )
    results = query.all()
    habitats = []
    if results:
        for data in results:
            habitat = {
                'cd_hab': str(data[0]),
                'nom_complet': str(data[2]),
            }
            habitats.append(habitat)
    return habitats


@blueprint.route('/habitats/<cd_hab>/taxons', methods=['GET'])
@json_resp
def get_taxa_by_habitats(cd_hab):
    '''
    tous les taxons d'un habitat
    '''
    q = DB.session.query(
        CorHabitatTaxon.cd_nom,
        Taxref.nom_complet
        ).join(
            Taxref, CorHabitatTaxon.cd_nom == Taxref.cd_nom
        ).group_by(CorHabitatTaxon.id_habitat, CorHabitatTaxon.id_cor_habitat_taxon, Taxref.nom_complet)

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
@permissions.check_cruved_scope('R', True, module_code='SHT')
@json_resp
def get_all_sites(info_role):
    '''
    Retourne tous les sites
    '''
    parameters = request.args
    id_type_commune = blueprint.config['id_type_commune']

    q = (
        DB.session.query(
            TInfosSite,
            func.max(TBaseVisits.visit_date_min),
            Habref.lb_hab_fr,
            func.count(distinct(TBaseVisits.id_base_visit)),
            func.string_agg(distinct(Organisme.nom_organisme), ', '),
            func.string_agg(distinct(LAreas.area_name), ', ')
        ).outerjoin(
            TBaseVisits, TBaseVisits.id_base_site == TInfosSite.id_base_site
        # get habitat cd_hab
        ).outerjoin(
            Habref, TInfosSite.cd_hab == Habref.cd_hab
        # get organisms of a site
        ).outerjoin(
            corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit
        ).outerjoin(
            User, User.id_role == corVisitObserver.c.id_role
        ).outerjoin(
            Organisme, Organisme.id_organisme == User.id_organisme
        )
        # get municipalities of a site
        .outerjoin(
            corSiteArea, corSiteArea.c.id_base_site == TInfosSite.id_base_site
        ).outerjoin(
            LAreas, and_(LAreas.id_area == corSiteArea.c.id_area, LAreas.id_type == id_type_commune)
        )
        .group_by(
            TInfosSite, Habref.lb_hab_fr
        )
    )

    if 'cd_hab' in parameters:
        q = q.filter(TInfosSite.cd_hab == parameters['cd_hab'])

    if 'id_base_site' in parameters:
        q = q.filter(TInfosSite.id_base_site == parameters['id_base_site'])

    if 'organisme' in parameters:
        q = q.filter(Organisme.id_organisme == parameters['organisme'])

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

    page = request.args.get('page', 1, type=int)
    items_per_page = blueprint.config['items_per_page']
    pagination_serverside = blueprint.config['pagination_serverside']

    if (pagination_serverside):
        pagination = q.paginate(page, items_per_page, False)
        data = pagination.items
        totalItems = pagination.total
    else:
        totalItems = 0
        data = q.all()

    pageInfo= {
        'totalItems' : totalItems,
        'items_per_page' : items_per_page,
    }
    features = []

    if data:
        for d in data:
            feature = d[0].get_geofeature()
            id_site = feature['properties']['id_base_site']
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
            features.append(feature)

        return [pageInfo,FeatureCollection(features)]
    return None


@blueprint.route('/visits', methods=['GET'])
@permissions.check_cruved_scope('R', True, module_code="SHT")
@json_resp
def get_visits(info_role):
    '''
    Retourne toutes les visites du module
    '''
    parameters = request.args
    query = (
        DB.session
        .query(TVisitSHT, User)
        .options(
            joinedload(TVisitSHT.cor_visit_taxons)
        )
        .outerjoin(
            corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit
        )
        .outerjoin(
            User, User.id_role == corVisitObserver.c.id_role
        )
    )
    if 'id_base_site' in parameters:
        query = (
            query
            .filter(TVisitSHT.id_base_site == parameters['id_base_site'])
            .order_by(desc(TVisitSHT.visit_date_min))
        )
    data = query.all()

    visits = {}
    for d in data:
        infos = d[0].as_dict(fields=['cor_visit_taxons'])
        if infos['id_base_visit'] not in visits:
            infos['observers'] = []
            visits[infos['id_base_visit']] = infos
        visits[infos['id_base_visit']]['observers'].append(d[1].as_dict())
    return list(visits.values())

@blueprint.route('/visits/years', methods=['GET'])
@json_resp
def get_years_visits():
    '''
    Retourne toutes les années de visites du module
    '''

    query = (
        DB.session
        .query(func.to_char(TVisitSHT.visit_date_min, 'YYYY'))
        .join(TInfosSite, TInfosSite.id_base_site == TVisitSHT.id_base_site)
        .order_by(desc(func.to_char(TVisitSHT.visit_date_min, 'YYYY')))
        .group_by(func.to_char(TVisitSHT.visit_date_min, 'YYYY'))
    )
    data = query.all()

    if data:
        tab_years = []
        for idx, d in enumerate(data):
            info_year = dict()
            info_year[idx] = d[0]
            tab_years.append(info_year)
        return tab_years
    return None

@blueprint.route('/visits/<id_visit>', methods=['GET'])
@permissions.check_cruved_scope('R', True, module_code="SHT")
@json_resp
def get_visit(id_visit, info_role):
    '''
    Retourne une visite
    '''
    return get_visit_details(id_visit)

def get_visit_details(id_visit):
    query = (
        DB.session
        .query(TVisitSHT, User)
        .options(
            joinedload(TVisitSHT.cor_visit_taxons),
            #joinedload(TVisitSHT.observers),
            joinedload(TVisitSHT.cor_visit_perturbation)
        )
        .outerjoin(
            corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit
        )
        .outerjoin(
            User, User.id_role == corVisitObserver.c.id_role
        )
        .filter(TBaseVisits.id_base_visit == id_visit)
    )
    data_all = query.all()

    if data_all:
        data = data_all[0]
        fields = ['cor_visit_taxons', 'cor_visit_perturbation', 'cor_visit_perturbation.t_nomenclature']
        cvisit = data[0].as_dict(fields=fields)
        cvisit['observers'] = [d[1].as_dict() for d in data_all]
        if 'cor_visit_perturbation' in cvisit:
            tab_visit_perturbation = cvisit.pop('cor_visit_perturbation')
            visit = []
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
@permissions.check_cruved_scope('C', True, module_code="SHT")
@json_resp
def post_visit(info_role):
    '''
    Poster une nouvelle visite
    '''
    # Get data from request
    data = dict(request.get_json())

    # Check data
    check_year_visit(data['id_base_site'], data['visit_date_min'][0:4])

    # Set generic infos got from config
    data['id_dataset'] = blueprint.config['id_dataset']
    data['module_code'] = blueprint.config['MODULE_CODE']

    # Remove data properties before create SQLA object with it
    perturbations = []
    if 'cor_visit_perturbation' in data:
        perturbations = data.pop('cor_visit_perturbation')
    taxons = []
    if 'cor_visit_taxons' in data:
        taxons = data.pop('cor_visit_taxons')
    observers_ids = []
    if 'cor_visit_observer' in data:
        observers_ids = data.pop('cor_visit_observer')


    # Build visit to insert in DB
    visit = TVisitSHT(**data)

    # Add perturbations
    for perturbation in perturbations:
        visit_perturbation = CorVisitPerturbation(**perturbation)
        visit.cor_visit_perturbation.append(visit_perturbation)

    # Add taxons
    for taxon in taxons:
        visit_taxon = CorVisitTaxon(**taxon)
        visit.cor_visit_taxons.append(visit_taxon)

    # Add observers
    observers = (
        DB.session
        .query(User)
        .filter(User.id_role.in_(observers_ids))
        .all()
    )
    for observer in observers:
        visit.observers.append(observer)

    # Insert visit in DB
    DB.session.add(visit)
    DB.session.commit()
    DB.session.refresh(visit)

    # Return new visit
    return get_visit_details(visit.id_base_visit)


@blueprint.route('/visits/<int:idv>', methods=['PATCH'])
@permissions.check_cruved_scope('U', True, module_code="SHT")
@json_resp
def patch_visit(idv, info_role):
    '''
    Mettre à jour une visite
    Si une donnée n'est pas présente dans les objets observer, cor_visit_taxons ou cor_visit_perurbations, elle sera supprimée de la base de données
    '''
    data = dict(request.get_json())
    try:
        existingVisit = TVisitSHT.query.filter_by(id_base_visit = idv).first()
        if (existingVisit == None):
            raise ValueError('This visit does not exist')
    except ValueError:
        resp = jsonify({"error": 'This visit does not exist'})
        resp.status_code = 404
        return resp

    existingVisit = existingVisit.as_dict()
    dateIsUp = data['visit_date_min'] != existingVisit['visit_date_min']

    if dateIsUp:
        check_year_visit(data['id_base_site'], data['visit_date_min'][0:4])


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
    observers = DB.session.query(User).filter(
        User.id_role.in_(tab_observer)
    ).all()
    for o in observers:
        visit.observers.append(o)

    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        module_code=blueprint.config['MODULE_CODE']
    )
    update_cruved = user_cruved['U']
    check_user_cruved_visit(info_role, visit, update_cruved)

    mergeVisit = DB.session.merge(visit)

    DB.session.commit()

    return get_visit_details(mergeVisit.id_base_visit)


@blueprint.route('/organismes', methods=['GET'])
@permissions.check_cruved_scope('R', True, module_code="SHT")
@json_resp
def get_organisme(info_role):
    '''
    Retourne la liste de tous les organismes présents
    '''

    q = DB.session.query(
        Organisme.nom_organisme, User.nom_role, User.prenom_role, User.id_organisme
        ).outerjoin(
            User, Organisme.id_organisme == User.id_organisme
        ).distinct().join(
            corVisitObserver, User.id_role == corVisitObserver.c.id_role
        ).join(
            TVisitSHT, corVisitObserver.c.id_base_visit == TVisitSHT.id_base_visit)

    data = q.all()
    if data:
        tab_orga = []
        for d in data:
            info_orga = dict()
            info_orga['nom_organisme'] = str(d[0])
            info_orga['observer'] = str(d[1]) + ' ' + str(d[2])
            info_orga['id_organisme'] = str(d[3])
            tab_orga.append(info_orga)
        return tab_orga
    return None


@blueprint.route('/communes/<module_code>', methods=['GET'])
@permissions.check_cruved_scope('R', True, module_code="SHT")
@json_resp
def get_commune(module_code, info_role):
    '''
    Retourne toutes les communes présents dans le module
    '''
    params = request.args
    q = DB.session.query(LAreas.area_name).distinct().outerjoin(
        corSiteArea, LAreas.id_area == corSiteArea.c.id_area).outerjoin(
        corSiteModule, corSiteModule.c.id_base_site == corSiteArea.c.id_base_site).filter(corSiteModule.c.module_code == module_code)

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


@blueprint.route('/user/cruved', methods=['GET'])
@permissions.check_cruved_scope('R', True)
@json_resp
def returnUserCruved(info_role):
    #récupérer le CRUVED complet de l'utilisateur courant
    user_cruved = get_or_fetch_user_cruved(
                session=session,
                id_role=info_role.id_role,
                module_code=blueprint.config['MODULE_CODE']
    )
    return  user_cruved


@blueprint.route('/export_visit', methods=['GET'])
@permissions.check_cruved_scope('E', True)
def export_visit(info_role):
    '''
    Télécharge les données d'une visite (ou des visites )
    '''
    parameters = request.args
    export_format = parameters['export_format'] if 'export_format' in request.args else 'shapefile'

    file_name = datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')

    # Build query
    query = DB.session.query(ExportVisits)
    if 'id_base_visit' in parameters:
        query = (
            DB.session
            .query(ExportVisits)
            .filter(ExportVisits.idbvisit == parameters['id_base_visit'])
        )
    elif 'id_base_site' in parameters:
        query = (
            DB.session
            .query(ExportVisits)
            .filter(ExportVisits.idbsite == parameters['id_base_site'])
        )
    elif 'organisme' in parameters:
        query = (
            DB.session.query(ExportVisits)
            .filter(ExportVisits.organisme == parameters['organisme'])
        )
    elif 'commune' in parameters:
        query = (
            DB.session.query(ExportVisits)
            .filter(ExportVisits.area_name == parameters['commune'])
        )
    elif 'year' in parameters:
        query = (
            DB.session.query(ExportVisits)
            .filter(func.date_part('year', ExportVisits.visitdate) == parameters['year'])
        )
    elif 'cd_hab' in parameters:
        query = (
            DB.session.query(ExportVisits)
            .filter(ExportVisits.cd_hab == parameters['cd_hab'])
        )
    data = query.all()

    features = []

    # Format data
    cor_hab_taxon = []
    flag_cdhab = 0
    tab_header = []
    column_name = get_base_column_name()
    column_name_pro = get_pro_column_name()
    mapping_columns = get_mapping_columns()
    tab_visit = []

    for d in data:
        visit = d.as_dict()

        # Get list hab/taxon
        cd_hab = visit['cd_hab']
        if flag_cdhab != cd_hab:
            cor_hab_taxon = get_taxonlist_by_cdhab(cd_hab)
            flag_cdhab = cd_hab

        # Remove html tag
        visit['lbhab'] = striphtml(visit['lbhab'])

        # Geom
        geom_wkt = to_shape(d.geom)
        if export_format == 'geojson':
            visit['geom_wkt'] = geom_wkt
        else:
            visit['geom'] = geom_wkt

        # Translate label column
        visit = dict((mapping_columns[key], value) for (key, value) in visit.items() if key in mapping_columns)

        # Pivot taxon
        if visit['nomvtaxon']:
            for taxon, cover in visit['nomvtaxon'].items():
                visit[taxon] = cover
        visit.pop('nomvtaxon', None)

        tab_visit.append(visit)

    # Run export
    if export_format == 'geojson':
        for d in tab_visit:
            feature = mapping(d['geom_wkt'])
            d.pop('geom_wkt', None)
            properties = d
            features.append(feature)
            features.append(properties)
        result = FeatureCollection(features)
        return to_json_resp(
            result,
            as_file=True,
            filename=file_name,
            indent=4
        )
    elif export_format == 'csv':
        tab_header = column_name + [clean_string(x) for x in cor_hab_taxon] + column_name_pro
        return to_csv_resp(
            file_name,
            tab_visit,
            tab_header,
            ';'
        )
    else:
        dir_path = str(ROOT_DIR / 'backend/static/shapefiles')

        FionaShapeService.create_shapes_struct(
            db_cols=ExportVisits.__mapper__.c,
            srid=2154,
            dir_path=dir_path,
            file_name=file_name,
        )

        for row in data:
            FionaShapeService.create_feature(row.as_dict(), row.geom)

        FionaShapeService.save_and_zip_shapefiles()

        return send_from_directory(
            dir_path,
            file_name+'.zip',
            as_attachment=True
        )
