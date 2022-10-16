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
    color: 'rgba(123, 123, 123, .5)',
    fill: true,
    fillOpacity: 0.5,
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
    let diffYear = this.getDiffYear(site);
    return this.getStyle(diffYear);
  }

  getYearColor(site) {
    let diffYear = this.getDiffYear(site);
    return this.getColorName(diffYear);
  }

  private getDiffYear(site): Number {
    let diffYear: Number = 10;
    if (site) {
      let currentDate = new Date();
      let dateMax = new Date(site.date_max);
      let isDate = this.isValidDate(dateMax);
      if (isDate) {
        diffYear = currentDate.getFullYear() - dateMax.getFullYear();
      }
    }
    return diffYear;
  }

  private isValidDate(date) {
    var timestamp = Date.parse(date);
    return isNaN(timestamp) ? false : true;
  }

  private getStyle(diffYear) {
    let opacity = this.visitStyle.fillOpacity;
    switch (diffYear) {
      case 0:
        this.visitStyle.color = `rgba(42, 129, 203, ${opacity})`;
        return this.visitStyle;
      case 1:
        this.visitStyle.color = `rgba(42, 173, 39, ${opacity})`;
        return this.visitStyle;
      case 2:
        this.visitStyle.color = `rgba(255, 211, 38, ${opacity})`;
        return this.visitStyle;
      case 3:
        this.visitStyle.color = `rgba(203, 132, 39, ${opacity})`;
        return this.visitStyle;
      default:
        this.visitStyle.color = `rgba(203, 43, 62, ${opacity})`;
        return this.visitStyle;
    }
  }

  private getColorName(diffYear) {
    switch (diffYear) {
      case 0:
        return 'blue';
      case 1:
        return 'green';
      case 2:
        return 'yellow';
      case 3:
        return 'orange';
      default:
        return 'red';
    }
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
      let style = this.getStyle(diffYear);
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


