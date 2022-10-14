import { HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { BehaviorSubject } from 'rxjs';
import { Layer } from 'leaflet';
import * as L from 'leaflet';

import { ModuleConfig } from '../module.config';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class StoreService {
  public currentLayer: Layer;

  public shtConfig = ModuleConfig;

  public visitStyle = {
    color: 'rgb(0,128,0)',
    fill: true,
    fillOpacity: 0.3,
    weight: 3
  };
  public originStyle = {
    color: 'rgb(51,51,51)',
    fill: true,
    fillOpacity: 0.3,
    weight: 3
  };

  public presence = 0;

  public queryString = new HttpParams();

  public currentSite$: BehaviorSubject<any | undefined> = new BehaviorSubject(undefined);

  public urlLoad = `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/export_visit`;

  getCurrentSite() {
    return this.currentSite$.asObservable();
  }

  setCurrentSite(cd_hab, nomhab, idBaseSite) {
    this.currentSite$.next({ cd_hab: cd_hab, nom_habitat: nomhab, id_base_site: idBaseSite });
  }

  getLayerStyle(site) {
    let diffYear: Number = 10;
    if (site) {
      let currentDate = new Date();
      let dateMax = new Date(site.date_max);
      let isDate = this.isValidDate(dateMax);
      if (isDate) {
        diffYear = currentDate.getFullYear() - dateMax.getFullYear();
      }
    }
    return this.getColor(diffYear);
  }

  getColor(diffYear) {
    switch (diffYear) {
      case 0:
        this.visitStyle.color = 'rgba(0,128,0,.5)';
        return this.visitStyle;
      case 1:
        this.visitStyle.color = 'rgba(255,182,193,.5)';
        return this.visitStyle;
      case 2:
        this.visitStyle.color = 'rgba(255,20,147,.5)';
        return this.visitStyle;
      case 3:
        this.visitStyle.color = 'rgba(138,43,226,.5)';
        return this.visitStyle;
      default:
        return this.originStyle;
    }
  }

  isValidDate(date) {
    var timestamp = Date.parse(date);
    return isNaN(timestamp) ? false : true;
  }

  buildMapLegend() {
    const currentYear = new Date().getFullYear();
    let div = L.DomUtil.create('div', 'info legend'),
      grades = {
        0: currentYear.toString(),
        1: (currentYear - 1).toString(),
        2: (currentYear - 2).toString(),
        3: (currentYear - 3).toString(),
        4: (currentYear - 4).toString() + ', avant ou jamais '
      };

    let keys = Object.keys(grades);
    div.innerHTML = '<p>Dernière visite en :</p>';
    for (let i = 0; i < keys.length; i++) {
      let diffYear = Number(keys[i]);
      let style = this.getColor(diffYear);
      div.innerHTML += `
        <div style= "width: 20px; height: 20px; display: inline-block;
          border: 1px solid ${style.color};
          background-color: ${style.color};
          "></div>
        ${grades[i]}
        <br>`;
    }
    return div;
  }
}


