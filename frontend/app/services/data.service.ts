import { Injectable, Inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { Observable } from 'rxjs/Observable';

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) { }

  getSites(params) {
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/sites`, {
      params: myParams
    });
  }

 /* getSites(params) {
    let mock = { "features": [
      { "properties": { "id_base_site": 17, "base_site_code": "365074625", "organisme": "Aucun", "nb_visit": "0", "nom_commune": "La Grave", "id_infos_site": 1, "cd_hab": 16265, "date_max": "2018-01-01", "base_site_name": "HAB-171717", "nom_habitat": "<em>Caricion incurvae</em> Br.-Bl. in Volk 1940", "base_site_description": "Aucune description" }, "id": "1", "geometry": { "type": "MultiPolygon", "coordinates": [[[[6.22548499261293, 45.03411830052899], [6.225802182478404, 45.03410910784823], [6.225789217368525, 45.033884199906204], [6.2254720287750605, 45.033893392549466], [6.22548499261293, 45.03411830052899]]]] }, "type": "Feature" }, { "properties": { "id_base_site": 18, "base_site_code": "365074625", "organisme": "Aucun", "nb_visit": "0", "nom_commune": "La Grave", "id_infos_site": 2, "cd_hab": 16265, "date_max": "2016-01-01", "base_site_name": "HAB-181818", "nom_habitat": "<em>Caricion incurvae</em> Br.-Bl. in Volk 1940", "base_site_description": "Aucune description" }, "id": "2", "geometry": { "type": "MultiPolygon", "coordinates": [[[[6.225802182478404, 45.03410910784823], [6.226119372239717, 45.03409991426405], [6.2261064058578315, 45.033875006359494], [6.225789217368525, 45.033884199906204], [6.225802182478404, 45.03410910784823]]]] }, "type": "Feature" }, { "properties": { "id_base_site": 19, "base_site_code": "365074625", "organisme": "Aucun", "nb_visit": "0", "nom_commune": "La Grave", "id_infos_site": 3, "cd_hab": 16265, "date_max": "Aucune visite", "base_site_name": "HAB-191919", "nom_habitat": "<em>Caricion incurvae</em> Br.-Bl. in Volk 1940", "base_site_description": "Aucune description" }, "id": "3", "geometry": { "type": "MultiPolygon", "coordinates": [[[[6.225154840077446, 45.03390258428933], [6.2254720287750605, 45.033893392549466], [6.225459065041339, 45.03366848458207], [6.225141877615724, 45.03367767628443], [6.225154840077446, 45.03390258428933]]]] }, "type": "Feature" }, { "properties": { "id_base_site": 20, "base_site_code": "365074625", "organisme": "Aucun", "nb_visit": "0", "nom_commune": "La Grave", "id_infos_site": 4, "cd_hab": 16265, "date_max": "Aucune visite", "base_site_name": "HAB-202020", "nom_habitat": "<em>Caricion incurvae</em> Br.-Bl. in Volk 1940", "base_site_description": "Aucune description" }, "id": "4", "geometry": { "type": "MultiPolygon", "coordinates": [[[[6.2254720287750605, 45.033893392549466], [6.225789217368525, 45.033884199906204], [6.225776252362806, 45.03365929197627], [6.225459065041339, 45.03366848458207], [6.2254720287750605, 45.033893392549466]]]] }, "type": "Feature" }, { "properties": { "id_base_site": 21, "base_site_code": "365074625", "organisme": "Aucun", "nb_visit": "0", "nom_commune": "La Grave", "id_infos_site": 5, "cd_hab": 16265, "date_max": "Aucune visite", "base_site_name": "HAB-212121", "nom_habitat": "<em>Caricion incurvae</em> Br.-Bl. in Volk 1940", "base_site_description": "Aucune description" }, "id": "5", "geometry": { "type": "MultiPolygon", "coordinates": [[[[6.225789217368525, 45.033884199906204], [6.2261064058578315, 45.033875006359494], [6.226093439580115, 45.03365009846706], [6.225776252362806, 45.03365929197627], [6.225789217368525, 45.033884199906204]]]] }, "type": "Feature" }, { "properties": { "id_base_site": 22, "base_site_code": "365074625", "organisme": "Aucun", "nb_visit": "0", "nom_commune": "La Grave", "id_infos_site": 6, "cd_hab": 16265, "date_max": "Aucune visite", "base_site_name": "HAB-222222", "nom_habitat": "<em>Caricion incurvae</em> Br.-Bl. in Volk 1940", "base_site_description": "Aucune description" }, "id": "6", "geometry": { "type": "MultiPolygon", "coordinates": [[[[6.2261064058578315, 45.033875006359494], [6.226423594242966, 45.03386581190939], [6.226410626693254, 45.03364090405443], [6.226093439580115, 45.03365009846706], [6.2261064058578315, 45.033875006359494]]]] }, "type": "Feature" }], "type": "FeatureCollection" }
    return Observable.of(mock)
  }
*/

 getInfoSite(id_base_site) {
     return this._http.get<any>(
     `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/sites?id_base_site=${id_base_site}`
   );
 } 


/*  getInfoSite(id_base_site) {
    let mock = [{
      "id_infos_site": 1,
      "site_nom": "Mon site",
      "site_code": "896543",
      "organisme": "Organisme1",
      "type": "",
      "site_date": "2018-12-01",
      "nom_habitat": "Caricion incurvae",
      "id_base_site": 125,
      //"geom": [{ "type": "MultiPolygon", "coordinates": [[[[6.22548499261293, 45.03411830052899], [6.225802182478404, 45.03410910784823], [6.225789217368525, 45.033884199906204], [6.2254720287750605, 45.033893392549466], [6.22548499261293, 45.03411830052899]]]] }],
      "site_description": "description du site"
    }]
    return Observable.of(mock)
  }*/


  getVisits(params: any) {
     let myParams = new HttpParams();
 
     for (let key in params) {
       myParams = myParams.set(key, params[key]);
     }
 
     return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits`, {
       params: myParams
     });
   }

 /* getVisits(params: any) {
    let mock = [{
      "id_visit": 1,
      "visit_date": "2018-12-01",
      "id_site": 1,
      "observers": [{ "nom_role": "Nom-agent1", "prenom_role": "Prénom-agent1" }],
      "nb_species": 12,
      "cor_visit_taxons": [{ "cd_nom": "1" }]
    },
    {
      "id_visit": 2,
      "visit_date": "2017-12-01",
      "id_site": 1,
      "observers": [{ "nom_role": "Nom-agent1", "prenom_role": "Prénom-agent1" }],
      "nb_species": 12,
      "cor_visit_taxons": [{ "cd_nom": "1" }, { "cd_nom": "2" }]
    }
    ]

    return Observable.of(mock);
  }*/

  getOneVisit(id_visit) {
      return this._http.get<any>(
        `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits/${id_visit}`
      );
  }

  /*getOneVisit(id_visit) {
    let mock = [{
      "id_visit": 1,
      "visit_date": "2018-12-01",
      "id_site": 1,
      "observers": [{ "id_menu": 1, "id_role": 4, "nom_complet": "PAUL Pierre", "nom_role": "Paul", "prenom_role": "Pierre" }],
      "cor_visit_taxons": [{ "cd_nom": "104123" }],
      "cor_visit_perturbation": [{
        "id_nomenclature": "701", "mnemonique": "Elagage", "label_de": null,
        "label_default": "Elagage",
        "label_en": null,
        "label_es": null,
        "label_fr": "Elagage",
        "label_it": null,
      }],
      "comments": "Ceci est le commentaire d'une fausse données"
    }]
    return Observable.of(mock);
  }*/

  /*  getOrganisme() {
     return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/organisme`);
   } */

  getOrganisme() {
    let mock = [{
      "id_base_site": 1,
      "observer": "Nom-agent1 Prénom-agent1",
      "nom_organisme": "Organisme1",
    }]
    return Observable.of(mock);
  }

  /*getCommune(id_application: number, params: any) {
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }

    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/commune/${id_application}`,
      { params: myParams }
    );
  }*/

  getHabitats() {
    let mock = [{
      "cd_hab": 16265,
      "nom_habitat": "Caricion incurvae"
    },
    {
      "cd_hab": 23333,
      "nom_habitat": "Combe à neige"
    }]
    return Observable.of(mock);
  }

  getTaxons(cd_hab) {
    if (!cd_hab) cd_hab = 16265;
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/habitats/${cd_hab}/taxons`
    )
  }

  postVisit() {
    let mock = { "status": 200, "id": "" }
    return Observable.of(mock);
  }

  patchVisit(idVisit) {
    let mock = { "status": 200, "id": idVisit };
    return Observable.of(mock);
  }
}
