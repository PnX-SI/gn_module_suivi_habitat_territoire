import { Injectable, Inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { Observable } from 'rxjs/Observable';

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) { }

  getSites(params) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/sites`, {
      params: params
    });
  }

  getInfoSite(id_base_site) {
      return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/sites?id_base_site=${id_base_site}`
    );
  } 

  getVisits(params: any) {
     let myParams = new HttpParams();
 
     for (let key in params) {
       myParams = myParams.set(key, params[key]);
     }
 
     return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits`, {
       params: myParams
     });
   }

  getOneVisit(id_visit) {
      return this._http.get<any>(
        `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits/${id_visit}`
      );
  }


  getOrganisme() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/organismes`
    );
  }

  getCommune(id_application: number, params: any) {
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }

    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/communes/${id_application}`,
      { params: myParams }
    );
  }

  getTaxons(cd_hab) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/habitats/${cd_hab}/taxons`
    )
  }

  getHabitatsList(idList) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/habitats/${idList}`);
  }

  postVisit(data: any) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits`, data);
  }

  patchVisit(data: any, idVisit) {
    return this._http.patch<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/visits/${idVisit}`, data);
  }

  userCruved() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_habitat_territoire/user/cruved`);
  }
}
