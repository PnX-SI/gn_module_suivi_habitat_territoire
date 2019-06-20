from flask import Blueprint, request, session, current_app

from sqlalchemy.sql.expression import func
from pypnusershub.db.tools import InsufficientRightsError
import re

from geonature.utils.errors import GeonatureApiError
from geonature.core.gn_monitoring.models import TBaseVisits
from geonature.utils.env import DB, ROOT_DIR
from .models import Taxonomie, CorHabitatTaxon


class PostYearError (GeonatureApiError):
    pass


def check_user_cruved_visit(user, visit, cruved_level):
    """
    Check if user have right on a visit object, related to his cruved
    if not, raise 403 error
    if allowed return void
    """

    is_allowed = False
    if cruved_level == '1':

        for role in visit.observers:
            if role.id_role == user.id_role:
                print('même id ')
                is_allowed = True
                break
            elif visit.id_digitiser == user.id_role:
                is_allowed = True
                break
        if not is_allowed:
            raise InsufficientRightsError(
                ('User "{}" cannot update visit number {} ')
                .format(user.id_role, visit.id_base_visit),
                403
            )

    elif cruved_level == '2':
        for role in visit.observers:
            if role.id_role == user.id_role:
                print('même role')
                is_allowed = True
                break
            elif visit.id_digitiser == user.id_role:
                is_allowed = True
                break
            elif role.id_organisme == user.id_organisme:
                is_allowed = True
                break
        if not is_allowed:
            raise InsufficientRightsError(
                ('User "{}" cannot update visit number {} ')
                .format(user.id_role, visit.id_base_visit),
                403
            )


def check_year_visit(id_base_site, new_visit_date):
    """
    Check if there is already a visit of the same year.
    If yes, observer is not allowed to post the new visit
    """
    q_year = DB.session.query(
        func.date_part('year', TBaseVisits.visit_date_min)).filter(
        TBaseVisits.id_base_site == id_base_site)
    tab_old_year = q_year.all()
    print(tab_old_year)
    year_new_visit = new_visit_date[0:4]

    for y in tab_old_year:
        year_old_visit = str(int(y[0]))
        if year_old_visit == year_new_visit:
            DB.session.rollback()
            raise PostYearError(
                ('Maille {} has already been visited in {} ')
                .format(id_base_site, year_old_visit),
                403)


def get_taxonlist_by_cdhab(cdhab):
    q = DB.session.query(
    CorHabitatTaxon.id_cor_habitat_taxon,
    Taxonomie.lb_nom
    ).join(
        Taxonomie, CorHabitatTaxon.cd_nom == Taxonomie.cd_nom
    ).group_by(CorHabitatTaxon.id_habitat, CorHabitatTaxon.id_cor_habitat_taxon, Taxonomie.lb_nom)

    q = q.filter(CorHabitatTaxon.id_habitat == cdhab)
    data = q.all()

    taxons = []
    if data:
        for d in data:
            taxons.append( str(d[1]) )
        return taxons
    return None


def clean_string(my_string):
    my_string = my_string.strip()
    chars_to_remove =  ";,"
    for c in chars_to_remove:
        my_string = my_string.replace(c, "-")

    return my_string

def clean_string(my_string):
    my_string = my_string.strip()
    chars_to_remove =  ";,"
    for c in chars_to_remove:
        my_string = my_string.replace(c, "-")

    return my_string


def striphtml(data):
    p = re.compile(r'<.*?>')
    return p.sub('', data)


def get_base_column_name():
    """
    mapping column name / label column

    "idbsite": "Identifiant site",
    "visitdate": "Date visite",
    "bsitename": "Nom du site",
    "area_name" : "Communes",
    "observers": "Observateurs",
    "organisme" : "Organisme",
    "lbhab": "Habitat",
    "lbperturb": "Perturbations",
    "comments": "Commentaires",
    "geom": "Géométrie"
    """
    return [
            "Identifiant site",
            "Date visite",
            "Nom du site",
            "Communes",
            "Observateurs",
            "Organisme",
            "Habitat",
            "Perturbations",
            "Commentaires",
            "Géométrie"
        ]

def get_pro_column_name():
    """
    mapping column name / label column
    "cd_hab": "cdhab",
    "covtaxons": "covtaxons"
    """
    return [
        "cdhab",
        "covtaxons",
        ]

def get_mapping_columns():
    return {
        "idbsite": "Identifiant site",
        "visitdate": "Date visite",
        "bsitename": "Nom du site",
        "area_name" : "Communes",
        "observers": "Observateurs",
        "organisme" : "Organisme",
        "lbhab": "Habitat",
        "lbperturb": "Perturbations",
        "comments": "Commentaires",
        "geom": "Géométrie",
        "geom_wkt": "geom_wkt",
        "cd_hab": "cdhab",
        "covtaxons": "covtaxons",
        "nomvtaxon": "nomvtaxon"
    }