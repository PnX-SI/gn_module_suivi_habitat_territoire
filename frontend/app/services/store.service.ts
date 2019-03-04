import { HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Layer } from 'leaflet';
import { ModuleConfig } from '../module.config';
import { BehaviorSubject } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class StoreService {
  public currentLayer: Layer;

  public shtConfig = ModuleConfig;

  public styleFreshVisit = {
    color: '#008000',
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };
  public styleOldVisit = {
    color: '#8B0000',
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };

  public selectedStyle = {
    color: '#3388ff',
    weight: 3
  };

  public originStyle = {
    color: '#333333',
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };


  public presence = 0;

  public queryString = new HttpParams();

  public currentSite$: BehaviorSubject<any> = new BehaviorSubject();

  public urlLoad = `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/export_visit`;

  getCurrentSite() {
    return this.currentSite$.asObservable();
  }

  setCurrentSite(cd_hab, nomhab, idBaseSite) {
    this.currentSite$.next({ "cd_hab": cd_hab, "nom_habitat": nomhab, "id_base_site": idBaseSite });
  }

  getLayerStyle(site) {
    let year: Number= 10;
    if(site) {
      let currentDate = new Date();
      let date_max = new Date(site.date_max);
      let isdate = this.isValidDate(date_max);
      if (isdate) {
        year= currentDate.getFullYear() - date_max.getFullYear();
      }
    }
  
    switch (year) {
      case 0:
        return this.styleFreshVisit
        break;
      case 1:
        return this.styleOldVisit;
        break;
      case 2:
        this.styleOldVisit.fillOpacity = 0.4;
        return this.styleOldVisit;
        break;
      case 3:
        this.styleOldVisit.fillOpacity = 0.6;
        return this.styleOldVisit;
        break;
      default:
        return this.originStyle;
        break;
    }
  }

  isValidDate(d) {
    let isvalid = false;
    var timestamp = Date.parse(d);
    if (isNaN(timestamp) == false) {
      isvalid = true;
    }
    return isvalid;
  }

}


