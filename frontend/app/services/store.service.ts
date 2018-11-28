import { HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Layer } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import { ModuleConfig } from '../module.config';

@Injectable()
export class StoreService {
  public currentLayer: Layer;

  public shtConfig = ModuleConfig;

  public myStylePresent = {
    color: '#008000',
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };

  public presence = 0;

  public queryString = new HttpParams();

}
