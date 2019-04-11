import { Injectable, Inject } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { Observable } from "rxjs/Observable";
import { ModuleConfig } from '../module.config';


@Injectable()
export class DataService {
  constructor(private _http: HttpClient) {}

  getSites(params) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/sites`,
      {
        params: params
      }
    );
  }

  getInfoSite(id_base_site) {
    return this._http.get<any>(
      `${
        AppConfig.API_ENDPOINT
      }/${ModuleConfig.MODULE_URL}/sites?id_base_site=${id_base_site}`
    );
  }

  getVisits(params: any) {
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }

    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits`,
      {
        params: myParams
      }
    );
  }

  getOneVisit(id_visit) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/${id_visit}`
    );
  }

  getOrganisme() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/organismes`
    );
  }

  getCommune(id_module: number, params: any) {
    let myParams = new HttpParams();

    for (let key in params) {
      myParams = myParams.set(key, params[key]);
    }

    return this._http.get<any>(
      `${
        AppConfig.API_ENDPOINT
      }/${ModuleConfig.MODULE_URL}/communes/${id_module}`,
      { params: myParams }
    );
  }

  getVisitsYears() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/years`
    );
  }

  getTaxons(cd_hab) {
    return this._http.get<any>(
      `${
        AppConfig.API_ENDPOINT
      }/${ModuleConfig.MODULE_URL}/habitats/${cd_hab}/taxons`
    );
  }

  getHabitatsList(idList) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/habitats/${idList}`
    );
  }

  postVisit(data: any) {
    return this._http.post<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits`,
      data
    );
  }

  patchVisit(data: any, idVisit) {
    return this._http.patch<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/${idVisit}`,
      data
    );
  }
}
