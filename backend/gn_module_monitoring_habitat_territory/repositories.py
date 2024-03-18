import re

from sqlalchemy.sql.expression import func, select
from pypnusershub.db.tools import InsufficientRightsError

from geonature.utils.errors import GeonatureApiError
from geonature.core.gn_monitoring.models import TBaseVisits
from apptax.taxonomie.models import Taxref
from geonature.utils.env import DB, ROOT_DIR

from .models import CorHabitatTaxon


class PostYearError(GeonatureApiError):
    pass


def get_taxonlist_by_cdhab(habitat_code):
    query = (
        select(CorHabitatTaxon.id_cor_habitat_taxon, Taxref.lb_nom)
        .join(Taxref, CorHabitatTaxon.cd_nom == Taxref.cd_nom)
        .where(CorHabitatTaxon.id_habitat == habitat_code)
    )
    data = DB.session.execute(query).unique().all()

    return  [str(d[1]) for d in data]


def clean_string(my_string):
    my_string = my_string.strip()
    chars_to_remove = ";,"
    for c in chars_to_remove:
        my_string = my_string.replace(c, "-")

    return my_string


def strip_html(data):
    p = re.compile(r"<.*?>")
    return p.sub("", data)


def get_export_columns_names():
    return [
        "visite_id",
        "visite_date",
        "site_id",
        "site_uuid",
        "site_code",
        "habitat_nom",
        "habitat_cd_hab",
        "communes",
        "observateurs",
        "organismes",
        "perturbations",
        "visite_commentaire",
        "geometrie",
        "taxons_cd_nom",
    ]


def get_export_mapping_columns():
    return {
        "id_base_visit": "visite_id",
        "visit_date": "visite_date",
        "visit_comment": "visite_commentaire",
        "id_base_site": "site_id",
        "base_site_name": "site_nom",
        "base_site_code": "site_code",
        "base_site_uuid": "site_uuid",
        "geom": "geometrie",
        "geojson": "geojson",
        "municipalities": "communes",
        "habitat_name": "habitat_nom",
        "habitat_code": "habitat_cd_hab",
        "perturbations": "perturbations",
        "observers": "observateurs",
        "organisms": "organismes",
        "taxons_scinames": "taxons_noms",
        "taxons_scinames_codes": "taxons_cd_nom",
    }
