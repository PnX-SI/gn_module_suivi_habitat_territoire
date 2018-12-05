import { Component, OnInit, AfterViewInit } from "@angular/core";
import { Router } from '@angular/router';

import { MapService } from '@geonature_common/map/map.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';

@Component({
  selector: "site-map-list",
  templateUrl: "site-map-list.component.html",
  styleUrls: ["site-map-list.component.scss"]
})
export class SiteMapListComponent implements OnInit, AfterViewInit {
  public sites;
  public filteredData = [];
  public paramApp = {
    id_application: ModuleConfig.id_application
  };
  public tabCom = [];
  public dataLoaded = false;

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public storeService: StoreService,
    public mapListService: MapListService,
    public router: Router
  ) {}

  ngOnInit() {
    this.mapListService.idName = 'id_infos_site';
    this.onChargeList(this.paramApp);
  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());

    // FIXME: 404 id_commune ?
    /*this._api
    .getCommune(ModuleConfig.id_application, {
      id_area_type: this.storeService.shtConfig.id_type_commune
    })
    .subscribe(info => {
      info.forEach(com => {
        this.tabCom.push(com.nom_commune);
        this.tabCom.sort((a, b) => {
          return a.localeCompare(b);
        });
      });
    });*/
  }
  
  onChargeList(param) {
    this._api.getSites(param).subscribe(data => {
      this.sites = data;
      this.mapListService.loadTableData(data);
      this.filteredData = this.mapListService.tableData;

      this.dataLoaded = true;

    });
  }

  onEachFeature(feature, layer) {
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
      click: e => {
        this.mapListService.toggleStyle(layer);
        this.mapListService.mapSelected.next(feature.id);
      }
    });
  }

  onInfo(id_base_site) {
    this.router.navigate([`${ModuleConfig.api_url}/listVisit`, id_base_site]);
  }
}
