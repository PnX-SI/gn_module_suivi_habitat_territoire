import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import * as L from 'leaflet';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';
import { UserService } from '../services/user.service';

@Component({
  selector: 'pnx-list-visit',
  templateUrl: 'list-visit.component.html',
  styleUrls: ['./list-visit.component.scss']
})
export class ListVisitComponent implements OnInit, OnDestroy {
  public site;
  public currentSite = {};
  public show = true;
  public loadingIndicator = false;
  public idSite;
  public nomHabitat;
  public organisme;
  public nomCommune;
  public siteUuid;
  public siteName;
  public siteCode;
  public siteDesc;
  public cdHabitat;
  public taxons;
  public rows = [];
  public paramApp = this.storeService.queryString.append(
    'id_application',
    ModuleConfig.MODULE_CODE.toString()
  );
  public addIsAllowed = false;
  public exportIsAllowed = false;

  @ViewChild('geojson')
  geojson: GeojsonComponent;

  constructor(
    public mapService: MapService,
    public mapListService: MapListService,
    public storeService: StoreService,
    private router: Router,
    public _api: DataService,
    public activatedRoute: ActivatedRoute,
    private toastr: ToastrService,
    private userService: UserService
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];
    this.storeService.queryString = this.storeService.queryString.set('id_base_site', this.idSite);
    this.checkPermission();
  }

  checkPermission() {
    this.userService.check_user_cruved_visit('E').subscribe(ucruved => {
      this.exportIsAllowed = ucruved;
    });
    this.userService.check_user_cruved_visit('C').subscribe(ucruved => {
      this.addIsAllowed = ucruved;
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();
    this.getSites();
    this.addLegend();
  }

  onEachFeature(feature, layer) {
    let site = feature.properties;
    let currentStyle = this.storeService.getLayerStyle(site);
    layer.setStyle(currentStyle);
  }

  getSites() {
    this.loadingIndicator = true;

    this.paramApp = this.paramApp.append('id_base_site', this.idSite);
    this._api.getSites(this.paramApp).subscribe(
      data => {
        this.site = data[1];

        let properties = data[1].features[0].properties;
        this.organisme = properties.organisme;
        this.nomCommune = properties.nom_commune;
        this.nomHabitat = properties.nom_habitat;
        this.siteUuid = properties.base_site_uuid;
        this.siteName = properties.base_site_name;
        this.siteCode = properties.base_site_code;
        this.siteDesc = properties.base_site_description;
        this.cdHabitat = properties.cd_hab;

        // UP cd_hab nom_habitat id site
        this.storeService.setCurrentSite(properties.cd_hab, properties.nom_habitat, this.idSite);

        this.geojson.currentGeoJson$.subscribe(currentLayer => {
          this.mapService.map.fitBounds(currentLayer.getBounds());
        });

        // TODO: refact
        this._api.getTaxons(this.cdHabitat).subscribe(tax => {
          this.taxons = tax;
          this.getVisits();
        });
      },
      error => {
        let msg = '';
        if (error.status == 403) {
          msg = "Vous n'êtes pas autorisé à afficher ces données.";
        } else {
          msg = 'Une erreur est survenue lors de la récupération des informations sur le serveur.';
        }
        this.toastr.error(msg, '', { positionClass: 'toast-top-right' });
        console.log('Error: ', error);
      }
    );
  }

  getVisits() {
    this.loadingIndicator = true;

    this._api.getVisits({ id_base_site: this.idSite }).subscribe(
      data => {
        data.forEach(visit => {
          let observersList = [];
          visit.observers.forEach((obs, index) => {
            observersList.push(`${obs.userFullName} (${obs.organismName})`);
          });
          visit.observers = observersList.join(', ');
          let pres = 0;
          if (visit.cor_visit_taxons) {
            visit.cor_visit_taxons.forEach(taxon => {
              if (taxon.cd_nom) {
                pres += 1;
              }
            });
          }
          visit.state = pres + ' / ' + this.taxons.length;
        });

        this.loadingIndicator = false;
        this.rows = data;
      },
      error => {
        this.loadingIndicator = false;
        if (error.status != 404) {
          this.toastr.error(
            'Une erreur est survenue lors de la récupération des données du relevé.',
            '',
            { positionClass: 'toast-top-right' }
          );
        }
      }
    );
  }

  addLegend() {
    let legend = new L.Control({ position: 'bottomright' });
    legend.onAdd = () => {
      return this.storeService.buildMapLegend();
    };
    legend.addTo(this.mapService.map);
  }

  backToSites() {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/`]);
  }

  ngOnDestroy() {
    this.storeService.queryString = this.storeService.queryString.delete('id_base_site');
  }
}
