import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';

import { ConfigService } from '@geonature/services/config.service';


@Injectable()
export class DataService {
  constructor(private http: HttpClient, public config: ConfigService) {}

  private transformToHttpParams(params) {
    let httpParams = new HttpParams();
    for (let key in params) {
      httpParams = httpParams.set(key, params[key]);
    }
    return { params: httpParams };
  }

  getSites(params: HttpParams) {
    return this.http.get<any>(`${this.config.API_ENDPOINT}/sht/sites`, {
      params: params
    });
  }

  getInfoSite(id_base_site) {
    return this.http.get<any>(
      `${this.config.API_ENDPOINT}/sht/sites?id_base_site=${id_base_site}`
    );
  }

  getVisits(params) {
    return this.http.get<any>(
      `${this.config.API_ENDPOINT}/sht/visits`,
      this.transformToHttpParams(params)
    );
  }

  getOneVisit(id_visit) {
    return this.http.get<any>(
      `${this.config.API_ENDPOINT}/sht/visits/${id_visit}`
    );
  }

  getOrganisme() {
    return this.http.get<any>(`${this.config.API_ENDPOINT}/sht/organismes`);
  }

  getCommune(module_code: string, params: any) {
    return this.http.get<any>(
      `${this.config.API_ENDPOINT}/sht/communes/${module_code}`,
      this.transformToHttpParams(params)
    );
  }

  getVisitsYears() {
    return this.http.get<any>(`${this.config.API_ENDPOINT}/sht/visits/years`);
  }

  getTaxons(cd_hab) {
    return this.http.get<any>(
      `${this.config.API_ENDPOINT}/sht/habitats/${cd_hab}/taxons`
    );
  }

  getHabitatsList(idList) {
    return this.http.get<any>(
      `${this.config.API_ENDPOINT}/sht/habitats/${idList}`
    );
  }

  postVisit(data: any) {
    return this.http.post<any>(`${this.config.API_ENDPOINT}/sht/visits`, data);
  }

  patchVisit(data: any, idVisit) {
    return this.http.patch<any>(
      `${this.config.API_ENDPOINT}/sht/visits/${idVisit}`,
      data
    );
  }

  getTaxonsInfos(scinameCode) {
    return this.http.get<any>(`${this.config.API_TAXHUB}/taxref/${scinameCode}`);
  }
}
