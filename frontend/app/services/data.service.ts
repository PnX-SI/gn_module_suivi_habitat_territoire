import { Injectable, Inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { Observable } from 'rxjs/Observable'; 

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) {}

  getSites(params) {
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/sites`, {
      params: myParams
    });
  }

/*   getInfoSite(id_base_site) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/site?id_base_site=${id_base_site}`
    );
  } */


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
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }
    let mock = [{
      "id_visit": 1,
      "visit_date": "2018-12-01",
      "id_site": 1,
      "observers": [{"nom_role": "Nom-agent1", "prenom_role": "Prénom-agent1"}],
      "nb_species": 12,
      "cor_visit_taxons": [{"cd_nom": "1"}]  
    }]

    return Observable.of(mock);
  }

/*   getOneVisit(id_visit) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visit/${id_visit}`
    );
  } */

 /*  getOrganisme() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/organisme`);
  } */

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

}
