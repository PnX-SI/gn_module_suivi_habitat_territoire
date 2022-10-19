import json
import datetime

from flask import Blueprint, request, session, send_from_directory, jsonify
from sqlalchemy.sql.expression import func
from sqlalchemy import and_, distinct, desc
from sqlalchemy.orm import joinedload
from geoalchemy2.shape import to_shape
from geojson import FeatureCollection
from shapely.geometry import *

from pypnusershub.db.models import User
from pypn_habref_api.models import Habref, CorListHabitat
from utils_flask_sqla.response import json_resp, to_json_resp, to_csv_resp

from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilsgeometry import FionaShapeService
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
from geonature.core.gn_monitoring.models import (
    corVisitObserver,
    corSiteArea,
    corSiteModule,
    TBaseVisits,
    TBaseSites,
)
from geonature.core.gn_commons.models import TModules
from geonature.core.ref_geo.models import LAreas
from pypnusershub.db.models import Organisme
from geonature.core.taxonomie.models import Taxref

from .repositories import (
    check_user_cruved_visit,
    check_year_visit,
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
    CorVisitPerturbation,
    ExportVisits,
)


blueprint = Blueprint("SHT", __name__)


@blueprint.route("/habitats/<id_list>", methods=["GET"])
@json_resp
def get_habitats(id_list):
    """
    Récupère les habitats cor_list_habitat à partir de l'identifiant
    id_list de la table bib_lis_habitat.
    """
    query = (
        DB.session.query(CorListHabitat.cd_hab, CorListHabitat.id_list, Habref.lb_hab_fr)
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
                "cd_hab": str(data[0]),
                "nom_complet": str(data[2]),
            }
            habitats.append(habitat)
    return habitats


@blueprint.route("/habitats/<cd_hab>/taxons", methods=["GET"])
@json_resp
def get_taxa_by_habitats(cd_hab):
    """
    Récupère tous les taxons d'un habitat.
    """
    q = (
        DB.session.query(CorHabitatTaxon.cd_nom, Taxref.nom_complet)
        .join(Taxref, CorHabitatTaxon.cd_nom == Taxref.cd_nom)
        .group_by(
            CorHabitatTaxon.id_habitat, CorHabitatTaxon.id_cor_habitat_taxon, Taxref.nom_complet
        )
        .order_by(Taxref.nom_complet)
    )

    q = q.filter(CorHabitatTaxon.id_habitat == cd_hab)
    data = q.all()

    taxons = []
    if data:
        for d in data:
            taxon = dict()
            taxon["cd_nom"] = str(d[0])
            taxon["nom_complet"] = str(d[1])
            taxons.append(taxon)
        return taxons
    return None


# TODO: create 2 disctinct web service one for all sites and one for one site
# TODO: use service site pagination
# TODO: return a root object instead of an array
@blueprint.route("/sites", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SHT")
@json_resp
def get_all_sites(info_role):
    """
    Retourne tous les sites.
    """
    parameters = request.args
    id_type_commune = blueprint.config["id_type_commune"]

    # Get sites from visits
    query = (
        DB.session.query(distinct(TBaseSites.id_base_site))
        .outerjoin(TBaseVisits, TBaseVisits.id_base_site == TBaseSites.id_base_site)
        .join(TInfosSite, TInfosSite.id_base_site == TBaseSites.id_base_site)
        .join(Habref, TInfosSite.cd_hab == Habref.cd_hab)
        .join(corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit)
        .join(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TBaseSites.id_base_site)
    )

    if "id_base_site" in parameters:
        query = query.filter(TBaseSites.id_base_site == parameters["id_base_site"])

    if "cd_hab" in parameters:
        query = query.filter(TInfosSite.cd_hab == parameters["cd_hab"])

    if "organisme" in parameters:
        query = query.filter(User.id_organisme == parameters["organisme"])

    if "commune" in parameters:
        query = query.filter(corSiteArea.c.id_area == parameters["commune"])

    if "year" in parameters:
        query = query.filter(
            func.date_part("year", TBaseVisits.visit_date_min) == parameters["year"]
        )

    sites_ids = [id[0] for id in query.all()]

    # Get sites infos
    query = (
        DB.session.query(
            TBaseSites,
            TInfosSite,
            Habref.lb_hab_fr,
            func.max(TBaseVisits.visit_date_min),
            func.count(distinct(TBaseVisits.id_base_visit)),
            func.string_agg(distinct(Organisme.nom_organisme), ", "),
            func.string_agg(
                distinct(func.concat(LAreas.area_name, " (", LAreas.area_code, ")")), ", "
            ).filter(LAreas.area_name != None),
        )
        .outerjoin(TBaseVisits, TBaseVisits.id_base_site == TBaseSites.id_base_site)
        .join(TInfosSite, TInfosSite.id_base_site == TBaseSites.id_base_site)
        .join(Habref, Habref.cd_hab == TInfosSite.cd_hab)
        .join(corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit)
        .join(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(Organisme, Organisme.id_organisme == User.id_organisme)
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TInfosSite.id_base_site)
        .outerjoin(
            LAreas, and_(LAreas.id_area == corSiteArea.c.id_area, LAreas.id_type == id_type_commune)
        )
        .group_by(TInfosSite.id_infos_site, TBaseSites.id_base_site, Habref.lb_hab_fr)
        .filter(TBaseSites.id_base_site.in_(sites_ids))
    )

    # Manage pagination
    page = request.args.get("page", 1, type=int)
    items_per_page = blueprint.config["items_per_page"]
    pagination = query.paginate(page, items_per_page, False)
    total_items = pagination.total

    data = query.all()

    # Build output
    pageInfo = {
        "totalItems": total_items,
        "items_per_page": items_per_page,
    }
    features = []
    if data:
        for d in data:
            feature = d[1].get_geofeature()

            base_site = d[0]
            # TODO: use simplify name, english and camelCase for properties
            feature["properties"]["base_site_uuid"] = base_site.uuid_base_site
            feature["properties"]["base_site_code"] = base_site.base_site_code
            feature["properties"]["base_site_description"] = base_site.base_site_description
            feature["properties"]["base_site_name"] = base_site.base_site_name

            feature["properties"]["nom_habitat"] = str(d[2])

            date_max = "Aucune visite" if d[3] == None else str(d[3])
            feature["properties"]["date_max"] = date_max

            feature["properties"]["nb_visit"] = str(d[4])

            organisms = "Aucun" if d[5] == None else str(d[5])
            feature["properties"]["organisme"] = organisms

            feature["properties"]["nom_commune"] = str(d[6])

            features.append(feature)

        return [pageInfo, FeatureCollection(features)]
    return [pageInfo, FeatureCollection(features)]


@blueprint.route("/visits", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SHT")
@json_resp
def get_visits(info_role):
    """
    Retourne toutes les visites du module
    """
    parameters = request.args
    query = (
        DB.session.query(TVisitSHT, User.nom_complet, Organisme.nom_organisme)
        .options(joinedload(TVisitSHT.cor_visit_taxons))
        .join(corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit)
        .join(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(Organisme, Organisme.id_organisme == User.id_organisme)
    )
    if "id_base_site" in parameters:
        query = query.filter(TVisitSHT.id_base_site == parameters["id_base_site"]).order_by(
            desc(TVisitSHT.visit_date_min)
        )
    data = query.all()

    visits = {}
    for d in data:
        infos = d[0].as_dict(fields=["cor_visit_taxons"])
        if infos["id_base_visit"] not in visits:
            infos["observers"] = []
            visits[infos["id_base_visit"]] = infos
        visits[infos["id_base_visit"]]["observers"].append(
            {"userFullName": d[1], "organismName": d[2]}
        )
    return list(visits.values())


@blueprint.route("/visits/years", methods=["GET"])
@json_resp
def get_years_visits():
    """
    Retourne toutes les années de visites du module
    """
    query = (
        DB.session.query(func.to_char(TVisitSHT.visit_date_min, "YYYY"))
        .join(TInfosSite, TInfosSite.id_base_site == TVisitSHT.id_base_site)
        .order_by(desc(func.to_char(TVisitSHT.visit_date_min, "YYYY")))
        .group_by(func.to_char(TVisitSHT.visit_date_min, "YYYY"))
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


@blueprint.route("/visits/<id_visit>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SHT")
@json_resp
def get_visit(id_visit, info_role):
    """
    Retourne une visite
    """
    return get_visit_details(id_visit)


def get_visit_details(id_visit):
    query = (
        DB.session.query(TVisitSHT, User)
        .options(
            joinedload(TVisitSHT.cor_visit_taxons),
            joinedload(TVisitSHT.cor_visit_perturbation),
        )
        .join(corVisitObserver, corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit)
        .join(User, User.id_role == corVisitObserver.c.id_role)
        .filter(TBaseVisits.id_base_visit == id_visit)
    )
    data_all = query.all()

    if data_all:
        data = data_all[0]
        fields = [
            "cor_visit_taxons",
            "cor_visit_perturbation",
            "cor_visit_perturbation.t_nomenclature",
        ]
        cvisit = data[0].as_dict(fields=fields)
        cvisit["observers"] = [d[1].as_dict() for d in data_all]
        if "cor_visit_perturbation" in cvisit:
            tab_visit_perturbation = cvisit.pop("cor_visit_perturbation")
            visit = []
            for index, per in enumerate(tab_visit_perturbation):
                visit.append(per["t_nomenclature"])
            cvisit["cor_visit_perturbation"] = visit
        else:
            cvisit["cor_visit_perturbation"] = []
        if "cor_visit_taxons" not in cvisit:
            cvisit["cor_visit_taxons"] = []
        return cvisit
    return None


@blueprint.route("/visits", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="SHT")
@json_resp
def post_visit(info_role):
    """
    Poster une nouvelle visite
    """
    # Get data from request
    data = dict(request.get_json())

    # Check data
    check_year_visit(data["id_base_site"], data["visit_date_min"][0:4])

    # Set generic infos got from config
    data["id_dataset"] = blueprint.config["id_dataset"]
    data["id_module"] = (
        DB.session.query(TModules.id_module)
        .filter(TModules.module_code == blueprint.config["MODULE_CODE"])
        .scalar()
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
    for perturbation in perturbations:
        visit_perturbation = CorVisitPerturbation(**perturbation)
        visit.cor_visit_perturbation.append(visit_perturbation)

    # Add taxons
    for taxon in taxons:
        visit_taxon = CorVisitTaxon(**taxon)
        visit.cor_visit_taxons.append(visit_taxon)

    # Add observers
    observers = DB.session.query(User).filter(User.id_role.in_(observers_ids)).all()
    for observer in observers:
        visit.observers.append(observer)

    # Insert visit in DB
    DB.session.add(visit)
    DB.session.commit()
    DB.session.refresh(visit)

    # Return new visit
    return get_visit_details(visit.id_base_visit)


@blueprint.route("/visits/<int:idv>", methods=["PATCH"])
@permissions.check_cruved_scope("U", True, module_code="SHT")
@json_resp
def patch_visit(idv, info_role):
    """
    Mettre à jour une visite
    Si une donnée n'est pas présente dans les objets observer, cor_visit_taxons ou cor_visit_perurbations, elle sera supprimée de la base de données
    """
    data = dict(request.get_json())
    try:
        existingVisit = TVisitSHT.query.filter_by(id_base_visit=idv).first()
        if existingVisit == None:
            raise ValueError("This visit does not exist")
    except ValueError:
        resp = jsonify({"error": "This visit does not exist"})
        resp.status_code = 404
        return resp

    existingVisit = existingVisit.as_dict()
    dateIsUp = data["visit_date_min"] != existingVisit["visit_date_min"]

    if dateIsUp:
        check_year_visit(data["id_base_site"], data["visit_date_min"][0:4])

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

    DB.session.query(CorVisitPerturbation).filter_by(id_base_visit=idv).delete()
    for per in tab_perturbation:
        visitPer = CorVisitPerturbation(**per)
        visit.cor_visit_perturbation.append(visitPer)

    DB.session.query(CorVisitTaxon).filter_by(id_base_visit=idv).delete()
    for taxon in tab_visit_taxons:
        visitTaxons = CorVisitTaxon(**taxon)
        visit.cor_visit_taxons.append(visitTaxons)

    visit.observers = []
    observers = DB.session.query(User).filter(User.id_role.in_(tab_observer)).all()
    for o in observers:
        visit.observers.append(o)

    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code=blueprint.config["MODULE_CODE"]
    )
    update_cruved = user_cruved["U"]
    check_user_cruved_visit(info_role, visit, update_cruved)

    mergeVisit = DB.session.merge(visit)

    DB.session.commit()

    return get_visit_details(mergeVisit.id_base_visit)


@blueprint.route("/organismes", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SHT")
@json_resp
def get_organisme(info_role):
    """
    Retourne la liste de tous les organismes présents
    """

    q = (
        DB.session.query(
            Organisme.nom_organisme, User.nom_role, User.prenom_role, User.id_organisme
        )
        .outerjoin(User, Organisme.id_organisme == User.id_organisme)
        .distinct()
        .join(corVisitObserver, User.id_role == corVisitObserver.c.id_role)
        .join(TVisitSHT, corVisitObserver.c.id_base_visit == TVisitSHT.id_base_visit)
    )

    data = q.all()
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
@permissions.check_cruved_scope("R", True, module_code="SHT")
@json_resp
def get_commune(module_code, info_role):
    """
    Retourne toutes les communes présents dans le module
    """
    params = request.args
    q = (
        DB.session.query(LAreas.id_area, LAreas.area_name)
        .distinct()
        .join(corSiteArea, LAreas.id_area == corSiteArea.c.id_area)
        .join(corSiteModule, corSiteModule.c.id_base_site == corSiteArea.c.id_base_site)
        .join(TModules, TModules.id_module == corSiteModule.c.id_module)
        .filter(TModules.module_code == module_code)
        .order_by(LAreas.area_name)
    )

    if "id_area_type" in params:
        q = q.filter(LAreas.id_type == params["id_area_type"])

    data = q.all()
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
@permissions.check_cruved_scope("R", True)
@json_resp
def returnUserCruved(info_role):
    # récupérer le CRUVED complet de l'utilisateur courant
    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code=blueprint.config["MODULE_CODE"]
    )
    return user_cruved


@blueprint.route("/export_visit", methods=["GET"])
@permissions.check_cruved_scope("E", True)
def export_visit(info_role):
    """
    Télécharge les données d'une visite (ou des visites )
    """
    parameters = request.args
    export_format = parameters["export_format"] if "export_format" in request.args else "shapefile"

    # Build query
    query = DB.session.query(ExportVisits).order_by(
        desc(ExportVisits.visit_date), ExportVisits.habitat_code
    )

    if "id_base_visit" in parameters:
        query = query.filter(ExportVisits.id_base_visit == parameters["id_base_visit"])

    if "id_base_site" in parameters:
        query = query.filter(ExportVisits.id_base_site == parameters["id_base_site"])

    if "organisme" in parameters:
        query = (
            query.join(
                corVisitObserver, corVisitObserver.c.id_base_visit == ExportVisits.id_base_visit
            )
            .join(User, User.id_role == corVisitObserver.c.id_role)
            .filter(User.id_organisme == parameters["organisme"])
        )

    if "commune" in parameters:
        query = query.join(
            corSiteArea, corSiteArea.c.id_base_site == ExportVisits.id_base_site
        ).filter(corSiteArea.c.id_area == parameters["commune"])

    if "year" in parameters:
        query = query.filter(func.date_part("year", ExportVisits.visit_date) == parameters["year"])

    if "cd_hab" in parameters:
        query = query.filter(ExportVisits.habitat_code == parameters["cd_hab"])

    data = query.all()

    # Format data
    mapping_columns = get_export_mapping_columns()
    taxons = []
    visits = []
    for d in data:
        visit = d.as_dict()

        # Get list hab/taxon
        cd_hab = visit["habitat_code"]
        taxons = taxons + list(set(get_taxonlist_by_cdhab(cd_hab)) - set(taxons))

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
