import { Component, OnInit, AfterViewInit, Output, EventEmitter, OnDestroy } from "@angular/core";
import { Router } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { FormGroup, FormBuilder, FormControl } from '@angular/forms';

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
export class SiteMapListComponent implements OnInit, AfterViewInit, OnDestroy {
  public sites;
  public filteredData = [];
  public tabOrganism = [];
  public paramApp = this.storeService.queryString.append(
    'id_application', ModuleConfig.id_application
  );
  public tabCom = [];
  public tabHab = []
  public dataLoaded = false;
  public center;
  public zoom;
  private _map;
  public filterForm: FormGroup;
  public oldFilterDate;

  @Output()
  onDeleteFiltre = new EventEmitter<any>();

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public storeService: StoreService,
    public mapListService: MapListService,
    public router: Router,
    private toastr: ToastrService,
    private _fb: FormBuilder
  ) { }

  ngOnInit() {

    this.onChargeList(this.paramApp);
    this.center = this.storeService.shtConfig.zoom_center;
    this.zoom = this.storeService.shtConfig.zoom;

    /*
    next Filters in progress...
    let filterkey = this.storeService.queryString.keys();
    console.log(filterkey)
    console.log("this.storeService.queryString.getAll(): ", this.storeService.queryString.getAll('year'));
    const nextfilterForm = {'year': null};
    if (this.storeService.queryString.getAll('year')) {
      let year = JSON.parse(this.storeService.queryString.getAll('year')) 
      console.log('year parse: ', year)
      nextfilterForm.year = year
    }*/

    this.filterForm = this._fb.group({
      filterYear: null,
      filterOrga: null,
      filterCom: null,
      filterHab: null
    });

    this.filterForm.controls.filterYear.valueChanges
      .filter(input => {
        return input != null && input.toString().length === 4
      })
      .subscribe(year => {
        this.onSearchDate(year);
      });

    this.filterForm.controls.filterYear.valueChanges
      .filter(input => {
        return input === null
      })
      .subscribe(year => {
        this.onDeleteParams('year', year);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterOrga.valueChanges
      .filter(select => {
        return select !== null
      })
      .subscribe(org => {
        this.onSearchOrganisme(org);
      });

    this.filterForm.controls.filterOrga.valueChanges
      .filter(input => {
        return input === null
      })
      .subscribe(org => {
        this.onDeleteParams('organisme', org);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterCom.valueChanges
      .filter(select => {
        return select !== null
      })
      .subscribe(com => {
        this.onSearchCom(com);
      });

    this.filterForm.controls.filterCom.valueChanges
      .filter(input => {
        return input === null
      })
      .subscribe(com => {
        this.onDeleteParams('commune', com);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterHab.valueChanges
      .filter(select => {
        return select !== null
      })
      .subscribe(hab => {
        this.onSearchHab(hab);
      });

    this.filterForm.controls.filterHab.valueChanges
      .filter(input => {
        return input === null
      })
      .subscribe(hab => {
        this.onDeleteParams('cd_hab', hab);
        this.onDeleteFiltre.emit();
      });

  }

  ngAfterViewInit() {
    this._map = this.mapService.getMap()
    this.addCustomControl();


    this._api.getOrganisme().subscribe(elem => {
      elem.forEach(orga => {
        this.tabOrganism.push(orga.nom_organisme);
        this.tabOrganism.sort((a, b) => {
          return a.localeCompare(b);
        });
      });
    });

    this._api.getCommune(ModuleConfig.id_application, {
      id_area_type: this.storeService.shtConfig.id_type_commune
    })
      .subscribe(info => {
        info.forEach(com => {
          this.tabCom.push(com.nom_commune);
          this.tabCom.sort((a, b) => {
            return a.localeCompare(b);
          });
        });
      });

    this._api.getHabitatsList(ModuleConfig.id_bib_list_habitat)
      .subscribe(habs => {
        habs.forEach(hab => {
          this.tabHab.push({ 'label': hab.nom_complet, 'id': hab.cd_hab });
          this.tabHab.sort((a, b) => {
            return a.localeCompare(b);
          });
        });
      });
  }

  onChargeList(param) {
    this._api.getSites(param).subscribe(data => {
      this.sites = data;
      this.mapListService.loadTableData(data);
      this.filteredData = this.mapListService.tableData;

      this.dataLoaded = true;

    }, error => {
      if (error.status == 404) {
        this.filteredData = [];
      } else {
        this.toastr.error('Une erreur est survenue lors de la récupération des données', '', {
          positionClass: 'toast-top-right'
        });
        console.log("error getsites: ", error)
      }
      this.dataLoaded = true;
    });
  }

  // Map-list
  onEachFeature(feature, layer) {
    let site = feature.properties;
    this.mapListService.layerDict[feature.id] = layer;

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
    this.zoomOnSelectedLayer(this._map, selectedLayer, 16);
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

  addCustomControl() {
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

  // Filters
  onDelete() {
    console.log('ondelete')
    this.onChargeList(this.paramApp);
  }

  onSetParams(param: string, value) {
    //  ajouter le queryString pour télécharger les données
    this.storeService.queryString = this.storeService.queryString.set(param, value);
    this.storeService.queryString.append('id_application', ModuleConfig.id_application);
  }

  onDeleteParams(param: string, value) {
    // effacer le queryString
    console.log('ondelete params', param + ' value: ' + value)
    this.storeService.queryString = this.storeService.queryString.delete(param);
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchDate(event) {
    this.onSetParams('year', event);
    this.oldFilterDate = event;
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchOrganisme(event) {
    this.onSetParams('organisme', event);
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchCom(event) {
    this.onSetParams('commune', event);
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchHab(event) {
    this.onSetParams('cd_hab', event);
    this.onChargeList(this.storeService.queryString.toString());
  }

  ngOnDestroy() {
    let filterkey = this.storeService.queryString.keys();
    console.log(filterkey)
    filterkey.forEach(key => {
      this.storeService.queryString= this.storeService.queryString.delete(key);
    }); 
    console.log("queryString map-list: ", this.storeService.queryString.toString())

  }
}
