import {
  Component,
  OnInit,
  AfterViewInit,
  Output,
  EventEmitter,
  OnDestroy
} from "@angular/core";
import { Router } from "@angular/router";
import { ToastrService } from "ngx-toastr";
import { FormGroup, FormBuilder, FormControl } from "@angular/forms";
import { Page } from "../shared/page";
import * as L from "leaflet";

import { MapService } from "@geonature_common/map/map.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";

import { DataService } from "../services/data.service";
import { StoreService } from "../services/store.service";
import { ModuleConfig } from "../module.config";
import { UserService } from "../services/user.service";

@Component({
  selector: "site-map-list",
  templateUrl: "site-map-list.component.html",
  styleUrls: ["site-map-list.component.scss"]
})
export class SiteMapListComponent implements OnInit, AfterViewInit, OnDestroy {
  public sites;
  public filteredData = [];
  public tabOrganism = [];
  public tabCom = [];
  public tabHab = [];
  public tabYears = [];
  public dataLoaded = false;
  public center;
  public zoom;
  private _map;
  public filterForm: FormGroup;
  public oldFilterDate;
  public page = new Page();
  public isAllowed = false;

  @Output()
  onDeleteFiltre = new EventEmitter<any>();

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public storeService: StoreService,
    public mapListService: MapListService,
    public router: Router,
    private toastr: ToastrService,
    private _fb: FormBuilder,
    private userService: UserService
  ) {}

  ngOnInit() {
    this.onChargeList();
    this.center = this.storeService.shtConfig.zoom_center;
    this.zoom = this.storeService.shtConfig.zoom;

    /*
    previous Filters in progress...
    let filterkey = this.storeService.queryString.keys();
    console.log(filterkey)
    console.log("this.storeService.queryString.getAll(): ", this.storeService.queryString.getAll('year'));
    const prevfilterForm = {'year': null};
    if (this.storeService.queryString.getAll('year')) {
      let year = JSON.parse(this.storeService.queryString.getAll('year')) 
      console.log('year parse: ', year)
      prevfilterForm.year = year
    }*/

    this.filterForm = this._fb.group({
      filterYear: null,
      filterOrga: null,
      filterCom: null,
      filterHab: null
    });

    this.filterForm.controls.filterYear.valueChanges
      .filter(input => {
        return input != null && input.toString().length === 4;
      })
      .subscribe(year => {
        this.onSearchDate(year);
      });

    this.filterForm.controls.filterYear.valueChanges
      .filter(input => {
        return input === null;
      })
      .subscribe(year => {
        this.onDeleteParams("year", year);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterOrga.valueChanges
      .filter(select => {
        return select !== null;
      })
      .subscribe(org => {
        this.onSearchOrganisme(org);
      });

    this.filterForm.controls.filterOrga.valueChanges
      .filter(input => {
        return input === null;
      })
      .subscribe(org => {
        this.onDeleteParams("organisme", org);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterCom.valueChanges
      .filter(select => {
        return select !== null;
      })
      .subscribe(com => {
        this.onSearchCom(com);
      });

    this.filterForm.controls.filterCom.valueChanges
      .filter(input => {
        return input === null;
      })
      .subscribe(com => {
        this.onDeleteParams("commune", com);
        this.onDeleteFiltre.emit();
      });

    this.filterForm.controls.filterHab.valueChanges
      .filter(select => {
        return select !== null;
      })
      .subscribe(hab => {
        this.onSearchHab(hab);
      });

    this.filterForm.controls.filterHab.valueChanges
      .filter(input => {
        return input === null;
      })
      .subscribe(hab => {
        this.onDeleteParams("cd_hab", hab);
        this.onDeleteFiltre.emit();
      });
  }

  checkPermission() {
    this.userService.check_user_cruved_visit('E').subscribe(ucruved => {
      console.log("ucruved E", ucruved)
      this.isAllowed = ucruved;
    })
  }

  ngAfterViewInit() {
    this._map = this.mapService.getMap();
    this.addCustomControl();

    this._api.getOrganisme().subscribe(elem => {
      elem.forEach(orga => {
        this.tabOrganism.push(orga.nom_organisme);
        this.tabOrganism.sort((a, b) => {
          return a.localeCompare(b);
        });
      });
    });

    this._api
      .getCommune(ModuleConfig.ID_MODULE, {
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

    this._api
      .getHabitatsList(ModuleConfig.id_bib_list_habitat)
      .subscribe(habs => {
        habs.forEach(hab => {
          this.tabHab.push({ label: hab.nom_complet, id: hab.cd_hab });
          this.tabHab.sort((a, b) => {
            return a.localeCompare(b);
          });
        });
      });

    this._api
      .getVisitsYears()
      .subscribe(years => {
        years.forEach((year, i) => {
          this.tabYears.push({ label: year[i], id: year[i] });
          console.log('year', year[i])
        });
      });
  }

  onChargeList(param?) {
    this._api.getSites(param).subscribe(
      data => {
        this.sites = data[1];
        this.page.totalElements = data[0].totalItmes;
        this.page.size = data[0].items_per_page;
        this.mapListService.loadTableData(data[1]);
        this.filteredData = this.mapListService.tableData;

        this.dataLoaded = true;
      },
      error => {
        let msg = "Une erreur est survenue lors de la récupération des informations sur le serveur.";
        if (error.status == 404) {
          this.page.totalElements = 0;
          this.page.size = 0;
          this.filteredData = [];
        } else if (error.status == 403) {
          msg = "Vous n'êtes pas autorisé à afficher ces données.";
        } else {
          this.toastr.error(
            msg,
            "",
            {
              positionClass: "toast-top-right"
            }
          );
          console.log("error getsites: ", error);
        }
        this.dataLoaded = true;
      }
    );
  }
  setPage(pageInfo) {
    this.page.pageNumber = pageInfo.offset;
    if (this.storeService.shtConfig.pagination_serverside) {
      this.onSetParams("page", pageInfo.offset + 1);
      this.onChargeList(this.storeService.queryString.toString());
    }
  }
  // Map-list
  onEachFeature(feature, layer) {
    let site = feature.properties;
    this.mapListService.layerDict[feature.id] = layer;

    const customPopup = '<div class="title">' + site.date_max + "</div>";
    const customOptions = {
      className: "custom-popup"
    };
    layer.bindPopup(customPopup, customOptions);
    layer.on({
      click: e => {
        this.toggleStyle(layer);
        this.onMapClick(feature.id);
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
      this.mapListService.selectedLayer.closePopup();
    }
    this.mapListService.selectedLayer = selectedLayer;
    this.mapListService.selectedLayer.openPopup();
  }

  onMapClick(id): void {
    const integerId = parseInt(id);
    this.mapListService.selectedRow = [];
    this.mapListService.selectedRow.push(
      this.mapListService.tableData[integerId]
    );
  }

  onRowSelect(row) {
    let id = row.selected[0]["id_infos_site"];
    let site = row.selected[0];
    const selectedLayer = this.mapListService.layerDict[id];
    this.toggleStyle(selectedLayer);
    this.zoomOnSelectedLayer(this._map, selectedLayer, 16);
  }

  zoomOnSelectedLayer(map, layer, zoom) {
    let latlng;

    if (layer instanceof L.Polygon || layer instanceof L.Polyline) {
      latlng = (layer as any).getCenter();
      map.setView(latlng, zoom);
    } else {
      latlng = layer._latlng;
    }
  }

  onInfo(id_base_site) {
    this.router.navigate([
      `${ModuleConfig.MODULE_URL}/listVisit`,
      id_base_site
    ]);
  }

  addCustomControl() {
    let initzoomcontrol = new L.Control();
    initzoomcontrol.setPosition("topleft");
    initzoomcontrol.onAdd = () => {
      var container = L.DomUtil.create(
        "button",
        " btn btn-sm btn-outline-shadow leaflet-bar leaflet-control leaflet-control-custom"
      );
      container.innerHTML =
        '<i class="material-icons" style="line-height:normal;">crop_free</i>';
      container.style.padding = "1px 4px";
      container.title = "Réinitialiser l'emprise de la carte";
      container.onclick = () => {
        console.log("buttonClicked");
        this._map.setView(this.center, this.zoom);
      };
      return container;
    };
    initzoomcontrol.addTo(this._map);
  }

  // Filters
  onDelete() {
    console.log("ondelete");
    this.onChargeList();
  }

  onSetParams(param: string, value) {
    //  ajouter le queryString pour télécharger les données
    this.storeService.queryString = this.storeService.queryString.set(
      param,
      value
    );
  }

  onDeleteParams(param: string, value) {
    // effacer le queryString
    console.log("ondelete params", param + " value: " + value);
    this.storeService.queryString = this.storeService.queryString.delete(param);
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchDate(event) {
    this.onSetParams("year", event);
    this.oldFilterDate = event;
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchOrganisme(event) {
    this.onSetParams("organisme", event);
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchCom(event) {
    this.onSetParams("commune", event);
    this.onChargeList(this.storeService.queryString.toString());
  }

  onSearchHab(event) {
    this.onSetParams("cd_hab", event);
    this.onChargeList(this.storeService.queryString.toString());
  }

  ngOnDestroy() {
    let filterkey = this.storeService.queryString.keys();
    filterkey.forEach(key => {
      this.storeService.queryString= this.storeService.queryString.delete(key);
    });
  }
}
