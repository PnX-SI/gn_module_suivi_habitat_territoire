export const ModuleConfig = {
    "zoom_center": [45.0609755, 6.2183926],
    "api_url":"suivi_habitat_territoire",
    "zoom":"13",
    "default_list_visit_columns": [
      {
       "name": "Date",
       "prop": "visit_date"
      },
      {
       "name": "Observateur(s)",
       "prop": "observers"
      },
      {
        "name": "Espèce(s) présente(s)",
        "prop": "state"
      }
    ],
    "default_site_columns": [
        {
         "name": "Identifiant",
         "prop": "id_infos_site",
         "width": 90
        },
        {
         "name": "Habitat",
         "prop": "nom_habitat",
         "width": 350
        },
        {
         "name": "Nombre de visites",
         "prop": "nb_visit",
         "width": 120
        },
        {
         "name": "Date de la derni\u00e8re visite",
         "prop": "date_max",
         "width": 160
        },
        {
         "name": "Organisme",
         "prop": "organisme",
         "width": 200
        }
       ],
    "site_message": {
        "emptyMessage": "Aucun site \u00e0 afficher ",
        "totalMessage": "site(s) au total"
    },
    "list_visit_message": {
      "emptyMessage": "Aucune visite sur ce site ",
      "totalMessage": "visites au total"
    },
    "id_application" : 9,
    "id_type_commune": 101,
    "export_available_format": [
      "geojson",
      "csv",
      "shapefile"
    ],
    "id_menu_list_user":1
}