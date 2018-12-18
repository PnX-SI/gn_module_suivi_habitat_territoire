import { Component, OnInit, AfterViewInit } from "@angular/core";
import { Router } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

import * as L from 'leaflet';

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
  public center;
  public zoom;
  private _map;

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public storeService: StoreService,
    public mapListService: MapListService,
    public router: Router,
    private toastr: ToastrService,
  ) { }

  ngOnInit() {
    this.onChargeList(this.paramApp);
    this.center = this.storeService.shtConfig.zoom_center;
    this.zoom = this.storeService.shtConfig.zoom;
  }

  ngAfterViewInit() {
    this._map = this.mapService.getMap()
    this.addCustomControl();


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

    }, error => {
      this.dataLoaded = true;
      this.toastr.error('Une erreur est survenue lors de la récupération des données', '', {
        positionClass: 'toast-top-right'
      });
      console.log("error getsites: ", error)
    });
  }

  onEachFeature(feature, layer) {
    let site = feature.properties;
    this.mapListService.layerDict[feature.id] = layer;

    //TODO add code/name maille ?
    const customPopup = '<div class="title">' + site.date_max + '</div>';
    const customOptions = {
      'className': 'custom-popup',
    };
    layer.bindPopup(customPopup, customOptions);
    layer.on({
      click: e => {
        this.toggleStyle(layer);

        this.mapListService.mapSelected.next(feature.id);
      }
    });

    //manage color with date
    let currentStyle = this.storeService.getLayerStyle(feature.properties);
    layer.setStyle(currentStyle);
  }

  toggleStyle(selectedLayer) {
    let site;
    // override toogle style map-list toggle the style of selected layer
    if (this.mapListService.selectedLayer !== undefined) {
      site = this.mapListService.selectedLayer.feature.properties;
      this.mapListService.selectedLayer.setStyle(this.storeService.getLayerStyle(site));
      this.mapListService.selectedLayer.closePopup();
    }
    this.mapListService.selectedLayer = selectedLayer;
    this.mapListService.selectedLayer.setStyle(this.storeService.selectedStyle);
    this.mapListService.selectedLayer.openPopup();
  }


  onRowSelect(row) {
    let id = row.selected[0]['id_infos_site'];
    let site = row.selected[0];
    const selectedLayer = this.mapListService.layerDict[id];
    this.toggleStyle(selectedLayer);
    this.zoomOnSelectedLayer(this._map, selectedLayer, 18);
  }

  zoomOnSelectedLayer(map, layer, zoom) {
    const currentZoom = map.getZoom();
    // latlng is different between polygons and point
    let latlng;

    if (layer instanceof L.Polygon || layer instanceof L.Polyline) {
      latlng = (layer as any)._bounds._northEast;
    } else {
      latlng = layer._latlng;
    }
    if (zoom > currentZoom)
      map.setView(latlng, zoom);
  }

  onInfo(id_base_site) {
    this.router.navigate([`${ModuleConfig.api_url}/listVisit`, id_base_site]);
  }

  addCustomControl () {
    let initzoomcontrol = new L.Control();
    initzoomcontrol.setPosition('topleft');
    initzoomcontrol.onAdd = () => {
      var container = L.DomUtil.create('button', ' btn btn-sm btn-outline-shadow leaflet-bar leaflet-control leaflet-control-custom');
      container.innerHTML = '<i class="material-icons" style="line-height:normal;">crop_free</i>'
      container.style.padding = '1px 4px';
      container.title = "Réinitialiser l\'emprise de la carte";
      container.onclick = () => {
        console.log('buttonClicked');
        this._map.setView(this.center, this.zoom)
      }
      return container;
    };
    initzoomcontrol.addTo(this._map);
  }
}
