import json
import datetime
import os

from flask import Blueprint, request, send_from_directory, g
from sqlalchemy.sql.expression import func
from sqlalchemy import and_, distinct, desc, delete
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.expression import  select
from geoalchemy2.shape import to_shape
from geojson import FeatureCollection
from shapely.geometry import *
from werkzeug.exceptions import Forbidden, BadRequest

from pypnusershub.db.models import User
from pypn_habref_api.models import Habref
from utils_flask_sqla.response import json_resp, to_json_resp, to_csv_resp

from geonature.utils.env import DB, ROOT_DIR
from utils_flask_sqla_geo.utilsgeometry  import FionaShapeService
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_monitoring.models import (
    corVisitObserver,
    corSiteArea,
    corSiteModule,
    TBaseVisits,
    TBaseSites,
)
from geonature.core.gn_commons.models import TModules
from ref_geo.models import LAreas
from pypnusershub.db.models import Organisme
from apptax.taxonomie.models import Taxref
from pypnnomenclature.models import TNomenclatures

from .repositories import (
    get_taxonlist_by_cdhab,
    clean_string,
    strip_html,
    get_export_columns_names,
    get_export_mapping_columns,
)
from .models import (
    TInfosSite,
    CorHabitatTaxon,
    TVisitSHT,
    TInfosSite,
    CorVisitTaxon,
    ExportVisits,
)

from gn_module_monitoring_habitat_territory import MODULE_CODE


blueprint = Blueprint("SHT", __name__)


@blueprint.route("/habitats/<id_list>", methods=["GET"])
@json_resp
def get_habitats(id_list):
    """
    Récupère les habitats cor_list_habitat à partir de l'identifiant
    id_list de la table bib_lis_habitat.
    """

    query = select(Habref).where(Habref.lists.any(id_list=id_list))
    results = DB.session.scalars(query).unique().all()
    return [h.as_dict(fields=["cd_hab", "lb_hab_fr"]) for h in results]


@blueprint.route("/habitats/<cd_hab>/taxons", methods=["GET"])
@json_resp
def get_taxa_by_habitats(cd_hab):
    """
    Récupère tous les taxons d'un habitat.
    """
    q = (
        select(CorHabitatTaxon).options(
            joinedload(CorHabitatTaxon.taxref)
        )
    )

    q = q.where(CorHabitatTaxon.id_habitat == cd_hab)
    data = DB.session.scalars(q).unique().all()

    taxons = []
    for d in data:
        taxon = dict(
            cd_nom = d.taxref.cd_nom,
            nom_complet = d.taxref.nom_complet
        )
        taxons.append(taxon)
    return taxons


# TODO: create 2 disctinct web service one for all sites and one for one site
# TODO: use service site pagination
# TODO: return a root object instead of an array
@blueprint.route("/sites", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SHT")
@json_resp
def get_all_sites():
    """
    Retourne tous les sites.
    """
    parameters = request.args
    id_type_commune = blueprint.config["id_type_commune"]

    # Get sites from visits
    query = (
        select(TBaseSites.id_base_site)
        .distinct()
        .join(TInfosSite, TInfosSite.id_base_site == TBaseSites.id_base_site)
        .join(Habref, TInfosSite.cd_hab == Habref.cd_hab)
        .outerjoin(TBaseVisits, TBaseVisits.id_base_site == TBaseSites.id_base_site)
        .outerjoin(corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit)
        .outerjoin(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TBaseSites.id_base_site)
    )
    if "id_base_site" in parameters:
        query = query.where(TBaseSites.id_base_site == parameters["id_base_site"])

    if "cd_hab" in parameters:
        query = query.where(TInfosSite.cd_hab == parameters["cd_hab"])

    if "organisme" in parameters:
        query = query.where(User.id_organisme == parameters["organisme"])

    if "commune" in parameters:
        query = query.where(corSiteArea.c.id_area == parameters["commune"])

    if "year" in parameters:
        query = query.where(
            func.date_part("year", TBaseVisits.visit_date_min) == parameters["year"]
        )
    sites_ids = DB.session.scalars(query).all()

    # Get sites infos
    query = (
        select(
            TInfosSite,
            Habref.lb_hab_fr,
            func.max(TBaseVisits.visit_date_min),
            func.count(distinct(TBaseVisits.id_base_visit)),
            func.string_agg(distinct(Organisme.nom_organisme), ", "),
            func.string_agg(
                distinct(func.concat(LAreas.area_name, " (", LAreas.area_code, ")")), ", "
            ),
        )
        .where(TInfosSite.id_base_site.in_(sites_ids))
        .where(LAreas.area_name != None)
        .outerjoin(TBaseVisits, TBaseVisits.id_base_site == TInfosSite.id_base_site)
        .join(Habref, Habref.cd_hab == TInfosSite.cd_hab)
        .outerjoin(corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit)
        .outerjoin(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(Organisme, Organisme.id_organisme == User.id_organisme)
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TInfosSite.id_base_site)
        .outerjoin(
            LAreas, and_(LAreas.id_area == corSiteArea.c.id_area, LAreas.id_type == id_type_commune)
        )
        .group_by(TInfosSite.id_infos_site, TBaseSites.id_base_site, Habref.lb_hab_fr)
    )
    # Manage pagination
    page = request.args.get("page", 0, type=int)
    items_per_page = blueprint.config["items_per_page"]
    total_items = DB.session.scalar(select(func.count("*")).select_from(query))

    # we can't use DB.paginate() here because it use a .scalars() which return only the first item of the select
    limited_query = query.limit(items_per_page).offset(page * items_per_page)
    results = DB.session.execute(limited_query).unique().all()

    # Build output
    pageInfo = {
        "totalItems": total_items,
        "items_per_page": items_per_page,
    }
    results = DB.session.execute(query).unique().all()
    features = []
    for d in results:
        feature = d[0].get_geofeature()
        feature["properties"]["nom_habitat"] = str(d[1])
        date_max = "Aucune visite" if d[2] == None else str(d[2])
        feature["properties"]["date_max"] = date_max
        feature["properties"]["nb_visit"] = str(d[3])
        organisms = "Aucun" if d[4] == None else str(d[4])
        feature["properties"]["organisme"] = organisms
        feature["properties"]["nom_commune"] = str(d[5])
        features.append(feature)

    return [pageInfo, FeatureCollection(features)]


@blueprint.route("/visits", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SHT")
@json_resp
def get_visits():
    """
    Retourne toutes les visites du module
    """
    parameters = request.args
    query = (
        select(TVisitSHT)
        .options(
            joinedload(TVisitSHT.cor_visit_taxons),
            joinedload(TVisitSHT.observers).joinedload(User.organisme)
        )
    )
    if "id_base_site" in parameters:
        query = query.where(TVisitSHT.id_base_site == parameters["id_base_site"]).order_by(
            desc(TVisitSHT.visit_date_min)
        )
    results = DB.session.scalars(query).unique().all()

    fields =["observers.nom_complet", "observers.organisme.nom_organisme", "cor_visit_taxons"]
    return [d.as_dict(fields=fields) for d in results]


@blueprint.route("/visits/years", methods=["GET"])
@json_resp
def get_years_visits():
    """
    Retourne toutes les années de visites du module
    """
    query = (
        select(func.to_char(TVisitSHT.visit_date_min, "YYYY"))
        .join(TInfosSite, TInfosSite.id_base_site == TVisitSHT.id_base_site)
        .order_by(desc(func.to_char(TVisitSHT.visit_date_min, "YYYY")))
        .group_by(func.to_char(TVisitSHT.visit_date_min, "YYYY"))
    )
    data = DB.session.scalars(query).all()
    return data


@blueprint.route("/visits/<id_visit>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SHT")
@json_resp
def get_visit(id_visit):
    """
    Retourne une visite
    """
    return get_visit_details(id_visit)


def get_visit_details(id_visit):
    data = DB.session.get(TVisitSHT, id_visit)

    fields = [
        "cor_visit_taxons",
        "perturbations",
        "observers"
    ]
    return data.as_dict(fields=fields)


@blueprint.route("/visits", methods=["POST"])
@permissions.check_cruved_scope("C", module_code="SHT")
@json_resp
def post_visit():
    """
    Poster une nouvelle visite
    """
    # Get data from request
    data = dict(request.get_json())

    # Check data
    if TInfosSite.has_already_visit_in_year(data["id_base_site"], data["visit_date_min"][0:4]):
        raise BadRequest(f"A visit already exist for year {data['visit_date_min'][0:4]} ")

    # Set generic infos got from config
    data["id_dataset"] = blueprint.config["id_dataset"]
    data["id_module"] = (
        DB.session.execute(select(TModules.id_module)
        .where(TModules.module_code == blueprint.config["MODULE_CODE"])
        ).scalar()
    )

    # Remove data properties before create SQLA object with it
    perturbations = []
    if "cor_visit_perturbation" in data:
        perturbations = data.pop("cor_visit_perturbation")
    taxons = []
    if "cor_visit_taxons" in data:
        taxons = data.pop("cor_visit_taxons")
    observers_ids = []
    if "cor_visit_observer" in data:
        observers_ids = data.pop("cor_visit_observer")

    # Build visit to insert in DB
    visit = TVisitSHT(**data)

    # Add perturbations
    if len(perturbations) > 0:
        list_id_nomenc = list(map(lambda n : n["id_nomenclature_perturbation"], perturbations))
        nomenclatures = DB.session.scalars(select(TNomenclatures).where(
            TNomenclatures.id_nomenclature.in_(list_id_nomenc)
        ))
        for nomenc in nomenclatures:
            visit.perturbations.append(nomenc)

    # Add taxons
    for taxon in taxons:
        visit_taxon = CorVisitTaxon(**taxon)
        visit.cor_visit_taxons.append(visit_taxon)

    # Add observers
    observers = DB.session.scalars(select(User).where(User.id_role.in_(observers_ids))).all()
    for observer in observers:
        visit.observers.append(observer)

    # Insert visit in DB
    DB.session.add(visit)
    DB.session.commit()
    DB.session.refresh(visit)

    # Return new visit
    return get_visit_details(visit.id_base_visit)


@blueprint.route("/visits/<int:idv>", methods=["PATCH"])
@permissions.check_cruved_scope("U", get_scope=True, module_code="SHT")
@json_resp
def patch_visit(idv, scope):
    """
    Mettre à jour une visite
    Si une donnée n'est pas présente dans les objets observer, cor_visit_taxons ou cor_visit_perurbations, elle sera supprimée de la base de données
    """
    data = dict(request.get_json())
    existingVisit = DB.get_or_404(TVisitSHT, idv)
    if not existingVisit.has_instance_permission(scope):
        raise Forbidden("You don't have the permissison to edit this Visit")

    tab_visit_taxons = []
    tab_observer = []
    tab_perturbation = []

    if "cor_visit_taxons" in data:
        tab_visit_taxons = data.pop("cor_visit_taxons")
    if "cor_visit_observer" in data:
        tab_observer = data.pop("cor_visit_observer")
    if "cor_visit_perturbation" in data:
        tab_perturbation = data.pop("cor_visit_perturbation")

    visit = TVisitSHT(**data)

    if len(tab_perturbation) > 0:
        list_id_nomenc = list(map(lambda n : n["id_nomenclature_perturbation"], tab_perturbation))
        nomenclatures = DB.session.scalars(select(TNomenclatures).where(
            TNomenclatures.id_nomenclature.in_(list_id_nomenc)
        ))
        # clean perturbations
        visit.perturbations = []
        for nomenc in nomenclatures:
            visit.perturbations.append(nomenc)

    delete_cor_visit_taxons = delete(CorVisitTaxon).where(CorVisitTaxon.id_base_visit == idv)
    DB.session.execute(delete_cor_visit_taxons)
    for taxon in tab_visit_taxons:
        visitTaxons = CorVisitTaxon(**taxon)
        visit.cor_visit_taxons.append(visitTaxons)

    visit.observers = []
    observers = DB.session.scalars(select(User).where(User.id_role.in_(tab_observer))).all()
    for o in observers:
        visit.observers.append(o)

    mergeVisit = DB.session.merge(visit)

    DB.session.commit()

    return get_visit_details(mergeVisit.id_base_visit)


@blueprint.route("/organismes", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SHT")
@json_resp
def get_organisme():
    """
    Retourne la liste de tous les organismes présents
    """
    q = DB.session.execute(
        select(
            Organisme.nom_organisme, User.nom_role, User.prenom_role, User.id_organisme
        ).outerjoin(User, Organisme.id_organisme == User.id_organisme)
        .join(corVisitObserver, User.id_role == corVisitObserver.c.id_role)
        .join(TVisitSHT, corVisitObserver.c.id_base_visit == TVisitSHT.id_base_visit)
    )

    data = q.unique().all()
    if data:
        tab_orga = []
        for d in data:
            info_orga = dict()
            info_orga["nom_organisme"] = str(d[0])
            info_orga["observer"] = str(d[1]) + " " + str(d[2])
            info_orga["id_organisme"] = str(d[3])
            tab_orga.append(info_orga)
        return tab_orga
    return None

# TODO: use module code via config parameter...
@blueprint.route("/communes/<module_code>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SHT")
@json_resp
def get_commune(module_code):
    """
    Retourne toutes les communes présents dans le module
    """
    params = request.args
    q = select(
        LAreas.id_area, LAreas.area_name) \
    .distinct() \
    .join(corSiteArea, LAreas.id_area == corSiteArea.c.id_area) \
    .join(corSiteModule, corSiteModule.c.id_base_site == corSiteArea.c.id_base_site) \
    .join(TModules, TModules.id_module == corSiteModule.c.id_module) \
    .where(TModules.module_code == module_code) \
    .order_by(LAreas.area_name)


    if "id_area_type" in params:
        q = q.where(LAreas.id_type == params["id_area_type"])

    data = DB.session.execute(q).all()
    if data:
        tab_commune = []

        for d in data:
            nom_com = dict()
            nom_com["id_area"] = d[0]
            nom_com["nom_commune"] = str(d[1])
            tab_commune.append(nom_com)
        return tab_commune
    return None


@blueprint.route("/user/cruved", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SHT")
@json_resp
def returnUserCruved():
    # récupérer le CRUVED complet de l'utilisateur courant
    user_cruved = get_scopes_by_action(
        id_role=g.current_user.id_role, module_code=MODULE_CODE
    )
    return user_cruved


@blueprint.route("/export_visit", methods=["GET"])
@permissions.check_cruved_scope("E", module_code="SHT")
def export_visit():
    """
    Télécharge les données d'une visite (ou des visites )
    """
    parameters = request.args
    export_format = parameters["export_format"] if "export_format" in request.args else "shapefile"

    # Build query
    query = select(ExportVisits).order_by(
        desc(ExportVisits.visit_date), ExportVisits.habitat_code
    )

    if "id_base_visit" in parameters:
        query = query.where(ExportVisits.id_base_visit == parameters["id_base_visit"])

    if "id_base_site" in parameters:
        query = query.where(ExportVisits.id_base_site == parameters["id_base_site"])

    if "organisme" in parameters:
        query = (
            query.join(
                corVisitObserver, corVisitObserver.c.id_base_visit == ExportVisits.id_base_visit
            )
            .join(User, User.id_role == corVisitObserver.c.id_role)
            .where(User.id_organisme == parameters["organisme"])
        )

    if "commune" in parameters:
        query = query.join(
            corSiteArea, corSiteArea.c.id_base_site == ExportVisits.id_base_site
        ).where(corSiteArea.c.id_area == parameters["commune"])

    if "year" in parameters:
        query = query.where(func.date_part("year", ExportVisits.visit_date) == parameters["year"])

    if "cd_hab" in parameters:
        query = query.where(ExportVisits.habitat_code == parameters["cd_hab"])

    data = DB.session.scalars(query).all()

    # Format data
    mapping_columns = get_export_mapping_columns()
    taxons = []
    visits = []
    for d in data:
        visit = d.as_dict()

        # Get list hab/taxon
        cd_hab = visit["habitat_code"]
        taxons = taxons + list(set(get_taxonlist_by_cdhab(cd_hab)) - set(taxons))
        taxons = sorted(taxons)

        # Remove html tags
        visit["habitat_name"] = strip_html(visit["habitat_name"])

        # Geom
        if export_format != "geojson":
            geom_wkt = to_shape(d.geom)
            visit["geom"] = geom_wkt

        # Translate label column
        translated_visit = dict(
            (mapping_columns[key], value)
            for (key, value) in visit.items()
            if key in mapping_columns
        )

        # Pivot taxon
        if visit["taxons_scinames"]:
            for taxon, cover in visit["taxons_scinames"].items():
                translated_visit[taxon] = cover

        visits.append(translated_visit)

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    # Run export
    if export_format == "geojson":
        features = []
        for d in visits:
            feature = {
                "type": "Feature",
                "geometry": json.loads(d["geojson"]),
            }
            d.pop("geojson", None)
            d.pop("geom", None)
            feature["properties"] = d
            features.append(feature)
        result = FeatureCollection(features)
        return to_json_resp(result, as_file=True, filename=file_name, indent=4)
    elif export_format == "csv":
        csv_header = get_export_columns_names() + [clean_string(x) for x in taxons]
        return to_csv_resp(file_name, visits, csv_header, ";")
    else:
        dir_path = str(ROOT_DIR / "backend/static/shapefiles")
        if not os.path.exists(dir_path):
            os.mkdir(dir_path)
        FionaShapeService.create_shapes_struct(
            db_cols=ExportVisits.__mapper__.c,
            srid=2154,
            dir_path=dir_path,
            file_name=file_name,
        )

        for row in data:
            FionaShapeService.create_feature(row.as_dict(), row.geom)

        FionaShapeService.save_and_zip_shapefiles()

        return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)
