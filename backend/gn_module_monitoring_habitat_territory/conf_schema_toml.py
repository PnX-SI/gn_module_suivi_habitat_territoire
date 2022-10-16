'''
   Spécification du schéma TOML des paramètres de configurations
'''

from marshmallow import Schema, fields

export_available_format = ['geojson', 'csv', 'shapefile']
zoom_center = [44.63891, 6.11608]
site_message = {
    "emptyMessage": "Aucun site à afficher ",
    "totalMessage": "sites(s) au total"
}
list_visit_message = {
    "emptyMessage": "Aucune visite sur ce site ",
    "totalMessage": "visites au total"
}
detail_list_visit_message = {
    "emptyMessage": "Aucune autre visite sur ce site ",
    "totalMessage" : "visites au total"
}
default_site_columns = [
    { "name" : "Identifiant", "prop" : "id_base_site", "width" : "90"},
    { "name" : "Habitat", "prop" : "nom_habitat", "width" : "350"},
    { "name" : "Nombre de visites", "prop" : "nb_visit", "width" : "120"},
    { "name" : "Date de la dernière visite", "prop" : "date_max", "width" : "160"},
    { "name" : "Organisme", "prop" : "organisme", "width" : "200"}
]
default_list_visit_columns = [
    { "name" : "Date", "prop" : "visit_date_min", "width": "120"},
    { "name" : "Observateur(s)", "prop" : "observers", "width": "350"},
    { "name" : "Espèce(s) présente(s)", "prop" : "state", "width": "120"}
]

class GnModuleSchemaConf(Schema):
    zoom_center = fields.List(fields.Float(), load_default=zoom_center)
    zoom = fields.Integer(load_default=8)

    export_srid = fields.Integer(load_default=2154)
    export_available_format = fields.List(fields.String(), load_default=export_available_format)

    id_dataset = fields.Integer(load_default=1)
    id_type_commune = fields.Integer(load_default=25)
    id_menu_list_user = fields.Integer(load_default=1)
    id_bib_list_habitat = fields.Integer(load_default=1)

    site_message=fields.Dict(load_default=site_message)
    list_visit_message = fields.Dict(load_default=list_visit_message)
    detail_list_visit_message = fields.Dict(load_default=detail_list_visit_message)

    default_site_columns = fields.List(fields.Dict(), load_default=default_site_columns)
    default_list_visit_columns = fields.List(fields.Dict(), load_default=default_list_visit_columns)

    pagination_serverside = fields.Boolean(load_default=False)
    items_per_page = fields.Integer(load_default=5)
