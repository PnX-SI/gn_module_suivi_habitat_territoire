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

  /*
 getInfoSite(id_base_site) {
     return this._http.get<any>(
     `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/site?id_base_site=${id_base_site}`
   );
 } 
 */

  getInfoSite(id_base_site) {
    let mock = [{
      "id_infos_site": 1,
      "site_nom": "Mon site",
      "site_code": "896543",
      "organisme": "Organisme1",
      "type": "",
      "site_date": "2018-12-01",
      "nom_habitat": "Caricion incurvae",
      "id_base_site": 125,
      "geom": [{ "type": "MultiPolygon", "coordinates": [[[[6.22548499261293, 45.03411830052899], [6.225802182478404, 45.03410910784823], [6.225789217368525, 45.033884199906204], [6.2254720287750605, 45.033893392549466], [6.22548499261293, 45.03411830052899]]]] }],
      "site_description": "description du site"
    }]
    return Observable.of(mock)
  }


  /*  getVisits(params: any) {
     let myParams = new HttpParams();
 
     for (let key in params) {
       myParams = myParams.set(key, params[key]);
     }
 
     return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits`, {
       params: myParams
     });
   } */

  getVisits(params: any) {
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
  }

  /*getOneVisit(id_visit) {
      return this._http.get<any>(
        `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visit/${id_visit}`
      );
    } */

  getOneVisit(id_visit) {
    let mock = [{
      "id_visit": 1,
      "visit_date": "2018-12-01",
      "id_site": 1,
      "observers": [{ "nom_role": "Nom-agent1", "prenom_role": "Prénom-agent1" }],
      "cor_visit_taxons": [{ "cd_nom": "Juncus arcticus" }]
    }]
    return Observable.of(mock);
  }

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
      "cd_hab": 23333 ,
      "nom_habitat": "Combe à neige"
    }]
    return Observable.of(mock);
  }

  getTaxons(cd_hab) {
    if (! cd_hab) cd_hab = 16265;
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/taxons/${cd_hab}`
    )
  }
}
