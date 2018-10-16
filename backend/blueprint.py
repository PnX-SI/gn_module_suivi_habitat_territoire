from flask import Blueprint, request, session, current_app, send_from_directory
from geojson import FeatureCollection, Feature

from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilssqlalchemy import json_resp, to_json_resp, to_csv_resp

from .models import TInfosSite, Habref

blueprint = Blueprint('pr_suivi_habitat_territoire', __name__)


@blueprint.route('/habitats', methods=['GET'])
@json_resp
def get_habitats():
    '''
    tous les habitats
    '''
    data= DB.session.query(Habref)
    return [d.as_dict(True) for d in data]


@blueprint.route('/site', methods=['GET'])
@json_resp
def get_all_sites():
    '''
    Retourne tous les sites
    '''
    parameters = request.args
    q = (DB.session.query(TInfosSite))

    if 'cd_hab' in parameters:
        q = q.filter(TInfosSite.cd_hab == parameters['cd_hab'])

    if q:
        data = q.all()
        return FeatureCollection([d.get_geofeature() for d in data])
    return None
    