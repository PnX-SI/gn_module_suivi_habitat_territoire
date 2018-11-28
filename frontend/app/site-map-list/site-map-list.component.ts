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
  public columns = [
    {
     "name": "Identifiant",
     "prop": "id_base_site",
     "width": 90
    },
    {
     "name": "Habitat",
     "prop": "nom_habitat",
     "width": 350
    },
    {
     "name": "Nombre de visites",
     "prop": "nb_visit",
     "width": 120
    },
    {
     "name": "Date de la derni\u00e8re visite",
     "prop": "date_max",
     "width": 160
    },
    {
     "name": "Organisme",
     "prop": "organisme",
     "width": 200
    }
   ];
  public paramApp = {
  };

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public storeService: StoreService,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    //TODO params
    this.onChargeList(this.paramApp);
  }

  ngAfterViewInit() {
    this.mapListService.enableMapListConnexion(this.mapService.getMap());
  }
  
  //TODO params
  onChargeList(param) {
    this._api.getSites(param).subscribe(data => {
      this.sites = data;
      this.mapListService.loadTableData(data);
      this.filteredData = this.mapListService.tableData;
      console.log(this.filteredData);

    });
  }
}
