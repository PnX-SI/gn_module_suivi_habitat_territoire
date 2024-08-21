import { Component, OnInit, AfterViewInit, Output, EventEmitter, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { FormGroup, FormBuilder } from '@angular/forms';

import { ToastrService } from 'ngx-toastr';
import * as L from 'leaflet';
import 'Leaflet.Deflate';
import { filter } from 'rxjs/operators';

import { MapService } from '@geonature_common/map/map.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { ConfigService } from '@geonature/services/config.service';

import { Page } from '../shared/page';
import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { UserService } from '../services/user.service';

@Component({
  selector: 'site-map-list',
  templateUrl: 'site-map-list.component.html',
  styleUrls: ['site-map-list.component.scss']
})
export class SiteMapListComponent implements OnInit, AfterViewInit, OnDestroy {
  public sites;
  public filteredData = [];
  public tabOrganism = [];
  public tabCom = [];
  public tabHab = [];
  public tabYears = [];
  public loadingIndicator = true;
  public center;
  public zoom;
  private map;
  public filterForm: FormGroup;
  public oldFilterDate;
  public page = new Page();
  public isAllowed = false;
  private deflateFeatures;

  @Output()
  onDeleteFiltre = new EventEmitter<any>();

  constructor(
    public config: ConfigService,
    public mapService: MapService,
    private api: DataService,
    public storeService: StoreService,
    public mapListService: MapListService,
    public router: Router,
    private toastr: ToastrService,
    private formBuilder: FormBuilder,
    private userService: UserService
  ) {}

  ngOnInit() {
    this.center = this.storeService.shtConfig.zoom_center;
    this.zoom = this.storeService.shtConfig.zoom;

    this.loadInitialData();
    this.checkPermission();
    this.initializeFilterForm();
    this.initializeFilterControls();
  }

  private loadInitialData() {
    this.storeService.loadQueryString();
    this.onChargeList(this.storeService.queryString);
  }

  private initializeFilterForm() {
    this.filterForm = this.formBuilder.group({
      filterYear: this.getInitialFilterValue('year'),
      filterOrga: this.getInitialFilterValue('organisme'),
      filterCom: this.getInitialFilterValue('commune'),
      filterHab: this.getInitialFilterValue('cd_hab')
    });
  }

  private getInitialFilterValue(filterName) {
    let value = null;
    if (this.storeService.queryString.has(filterName)) {
      value = this.storeService.queryString.get(filterName);
    }
    return value;
  }

  private initializeFilterControls() {
    this.filterForm.controls.filterYear.valueChanges.pipe(
      filter(input => {
        return input != null && input.toString().length === 4;
      })
    )
      .subscribe(year => {
        this.onSearchDate(year);
      });

    this.filterForm.controls.filterYear.valueChanges.pipe(
      filter(input => {
        return input === null;
      })
    )
      .subscribe(year => {
        this.onDeleteParams('year', year);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterOrga.valueChanges.pipe(
      filter(select => {
        return select !== null;
      })
    )
      .subscribe(org => {
        this.onSearchOrganisme(org);
      });

    this.filterForm.controls.filterOrga.valueChanges.pipe(
      filter(input => {
        return input === null;
      })
    )
      .subscribe(org => {
        this.onDeleteParams('organisme', org);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterCom.valueChanges.pipe(
      filter(select => {
        return select !== null;
      })
    )
      .subscribe(com => {
        this.onSearchCom(com);
      });

    this.filterForm.controls.filterCom.valueChanges.pipe(
      filter(input => {
        return input === null;
      })
    )
      .subscribe(com => {
        this.onDeleteParams('commune', com);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterHab.valueChanges.pipe(
      filter(select => {
        return select !== null;
      })
    )
      .subscribe(hab => {
        this.onSearchHab(hab);
      });

    this.filterForm.controls.filterHab.valueChanges.pipe(
      filter(input => {
        return input === null;
      })
    )
      .subscribe(hab => {
        this.onDeleteParams('cd_hab', hab);
        this.onDeleteFiltre.emit();
      });
  }

  ngOnDestroy() {
    this.storeService.saveQueryString();
    this.storeService.clearQueryString();
  }

  ngAfterViewInit() {
    this.map = this.mapService.getMap();
    this.addDeflateFeature();
    this.addCustomControl();
    this.addLegend();

    this.api.getOrganisme().subscribe(elem => {
      elem.forEach(orga => {
        if (!this.findWithAttr(this.tabOrganism, 'label', orga.nom_organisme)) {
          this.tabOrganism.push({ label: orga.nom_organisme, id: orga.id_organisme });
        }
      });
      this.tabOrganism.sort((a, b) => {
        return ('' + a.label).localeCompare('' + b.label);
      });
    });

    this.api
      .getCommune(this.config['SHT']['MODULE_CODE'], {
        id_area_type: this.storeService.shtConfig.id_type_commune
      })
      .subscribe(info => {
        info.forEach(com => {
          this.tabCom.push({ label: com.nom_commune, id: com.id_area });
        });
        this.tabCom.sort((a, b) => {
          return ('' + a).localeCompare('' + b);
        });
      });

    this.api.getHabitatsList(this.config['SHT'].id_bib_list_habitat).subscribe(habs => {
      habs.forEach(hab => {
        this.tabHab.push({ label: hab.lb_hab_fr, id: hab.cd_hab });
      });
      this.tabHab.sort((a, b) => {
        return ('' + a).localeCompare('' + b);
      });
    });

    this.api.getVisitsYears().subscribe(years => {
      this.tabYears = years
    });
  }

  private findWithAttr(array, attr, value) {
    for (let i = 0; i < array.length; i++) {
      if (array[i][attr] === value) {
        return true;
      }
    }
    return false;
  }

  private checkPermission() {
    this.userService.check_user_cruved_visit('E').subscribe(ucruved => {
      this.isAllowed = ucruved;
    });
  }

  setPage(pageInfo) {
    this.page.pageNumber = pageInfo.offset;
    if (this.storeService.shtConfig.pagination_serverside) {
      this.onSetParams('page', (pageInfo.offset + 1).toString());
    }
  }

  onEachFeature(feature, layer) {
    let site = feature.properties;
    this.mapListService.layerDict[site.id_base_site] = layer;
    const customPopup = `<div class="title">${site.date_max}</div>`;
    const customOptions = {
      className: 'custom-popup'
    };
    layer.bindPopup(customPopup, customOptions);
    layer.on({
      click: e => {
        this.togglePopup(layer);
        this.onMapClick(site.id_base_site);
      }
    });

    // Manage color with date
    let currentStyle = this.storeService.getLayerStyle(site);
    layer.setStyle(currentStyle);

    // Add deflate to layer
    layer.addTo(this.deflateFeatures);
  }

  private onMapClick(id): void {
    const integerId = parseInt(id);
    this.mapListService.selectedRow = [];
    this.mapListService.selectedRow.push(this.mapListService.tableData[integerId]);
  }

  onRowSelect(row) {
    let id = row.selected[0]['id_base_site'];
    const selectedLayer = this.mapListService.layerDict[id];
    this.mapListService.zoomOnSelectedLayer(this.map, selectedLayer);
    this.togglePopup(selectedLayer);
  }

  private togglePopup(selectedLayer) {
    // override toogle style map-list toggle the style of selected layer
    if (this.mapListService.selectedLayer !== undefined) {
      this.mapListService.selectedLayer.closePopup();
    }
    this.mapListService.selectedLayer = selectedLayer;
    this.mapListService.selectedLayer.openPopup();
  }

  onInfo(id_base_site) {
    this.router.navigate([`${this.config['SHT']['MODULE_URL']}/listVisit`, id_base_site]);
  }

  private addDeflateFeature() {
    // Init leaflet.deflate
    this.deflateFeatures = (L as any).deflate({
      minSize: 10,
      markerOptions: layer => {
        let color = this.storeService.getYearColor(layer['feature'].properties);
        let iconMarker = {
          icon: new L.Icon({
            iconUrl: `./assets/sht/assets/marker-icon-2x-${color}.png`,
            shadowUrl: `./assets/sht/assets/marker-shadow.png`,
            iconSize: [25, 41],
            iconAnchor: [12, 41],
            popupAnchor: [1, -34],
            shadowSize: [41, 41],
          }),
        };
        return iconMarker;
      }
    });
    this.deflateFeatures.addTo(this.map);
  }

  private addCustomControl() {
    let initzoomcontrol = new L.Control();
    initzoomcontrol.setPosition('topleft');
    initzoomcontrol.onAdd = () => {
      var container = L.DomUtil.create(
        'button',
        ' btn btn-sm btn-outline-shadow leaflet-bar leaflet-control leaflet-control-custom'
      );
      container.innerHTML =
        '<i class="material-icons" style="vertical-align: text-bottom">crop_free</i>';
      container.style.padding = '4px 4px 1px';
      container.title = "Réinitialiser l'emprise de la carte";
      container.onclick = () => {
        this.map.setView(this.center, this.zoom);
      };
      return container;
    };
    initzoomcontrol.addTo(this.map);
  }

  private addLegend() {
    let legend = new L.Control({ position: 'bottomright' });
    legend.onAdd = () => {
      return this.storeService.buildMapLegend();
    };
    legend.addTo(this.map);
  }

  private onSearchDate(event) {
    this.onSetParams('year', event);
    this.oldFilterDate = event;
  }

  private onSearchOrganisme(event) {
    this.onSetParams('organisme', event);
  }

  private onSearchCom(event) {
    this.onSetParams('commune', event);
  }

  private onSearchHab(event) {
    this.onSetParams('cd_hab', event);
  }

  private onSetParams(param: string, value) {
    this.storeService.queryString = this.storeService.queryString.set(param, value);
    this.storeService.saveQueryString();
    this.onChargeList(this.storeService.queryString);
  }

  private onDeleteParams(param: string, value) {
    this.storeService.queryString = this.storeService.queryString.delete(param);
    this.storeService.saveQueryString();
    this.onChargeList(this.storeService.queryString);
  }

  private onChargeList(param?) {
    this.loadingIndicator = true;
    this.api.getSites(param).subscribe(
      data => {
        this.page.totalElements = data[0].totalItems;
        this.page.size = data[0].items_per_page;
        this.sites = data[1];
        this.mapListService.loadTableData(data[1]);
        this.filteredData = this.mapListService.tableData;
        if (data[0].totalItems == 0) {
          let msg = "Aucune donnée n'est disponible avec ces paramètres.";
          this.toastr.warning(msg, '', {
            positionClass: 'toast-top-right'
          });
        }
        this.loadingIndicator = false;
      },
      error => {
        let msg =
          'Une erreur est survenue lors de la récupération des informations sur le serveur.';
        if (error.status == 404) {
          this.page.totalElements = 0;
          this.page.size = 0;
          this.filteredData = [];
        } else if (error.status == 403) {
          msg = "Vous n'êtes pas autorisé à afficher ces données.";
        } else {
          this.toastr.error(msg, '', {
            positionClass: 'toast-top-right'
          });
          console.log('Error getsites: ', error);
        }
        this.loadingIndicator = false;
      }
    );
  }
}
