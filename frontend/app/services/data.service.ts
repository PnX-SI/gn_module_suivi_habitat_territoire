import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';

import { AppConfig } from '@geonature_config/app.config';
import { ModuleConfig } from '../module.config';


@Injectable()
export class DataService {
  constructor(private http: HttpClient) {}

  private transformToHttpParams(params) {
    let httpParams = new HttpParams();
    for (let key in params) {
      httpParams = httpParams.set(key, params[key]);
    }
    return {params: httpParams};
  }

  getSites(params: HttpParams) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/sites`,
      {params: params}
    );
  }

  getInfoSite(id_base_site) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/sites?id_base_site=${id_base_site}`
    );
  }

  getVisits(params) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits`,
      this.transformToHttpParams(params)
    );
  }

  getOneVisit(id_visit) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/${id_visit}`
    );
  }

  getOrganisme() {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/organismes`
    );
  }

  getCommune(id_module: number, params: any) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/communes/${id_module}`,
      this.transformToHttpParams(params)
    );
  }

  getVisitsYears() {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/years`
    );
  }

  getTaxons(cd_hab) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/habitats/${cd_hab}/taxons`
    );
  }

  getHabitatsList(idList) {
    return this.http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/habitats/${idList}`
    );
  }

  postVisit(data: any) {
    return this.http.post<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits`,
      data
    );
  }

  patchVisit(data: any, idVisit) {
    return this.http.patch<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/${idVisit}`,
      data
    );
  }
}
