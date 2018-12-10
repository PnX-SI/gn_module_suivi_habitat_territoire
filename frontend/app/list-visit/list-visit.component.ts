import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { Location } from '@angular/common';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';

@Component({
  selector: 'pnx-list-visit',
  templateUrl: 'list-visit.component.html',
  styleUrls: ['./list-visit.component.scss']
})
export class ListVisitComponent implements OnInit {
  public site;
  public currentSite = {};
  public show = true;
  public idSite;
  public nomHabitat;
  public organisme;
  public nomCommune;
  public siteName;
  public siteCode;
  public siteDesc;
  public cdHabitat;
  public rows = [];

  @ViewChild('geojson')
  geojson: GeojsonComponent;

  constructor(
    public mapService: MapService,
    public mapListService: MapListService,
    public storeService: StoreService,
    private _location: Location,
    public _api: DataService,
    public activatedRoute: ActivatedRoute
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];

    this._api.getVisits({ id_base_site: this.idSite }).subscribe(data => {
      data.forEach(visit => {
        let fullName;
        visit.observers.forEach(obs => {
          fullName = obs.nom_role + ' ' + obs.prenom_role;
        });
        visit.observers = fullName;
        let pres = 0;

        visit.cor_visit_taxons.forEach(taxon => {
          if (taxon.cd_nom) {
            pres += 1;
          } 
        });

        visit.state = pres + ' / ' + visit.nb_species ;
      });

      this.rows = data;
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();
    const parametre = {
      id_base_site: this.idSite,
      id_application: ModuleConfig.id_application
    };

    this._api.getSites(parametre).subscribe(data => {
      this.site = data;

      let properties = data.features[0].properties;
      this.organisme = properties.organisme;
      this.nomCommune = properties.nom_commune;
      this.nomHabitat = properties.nom_habitat;
      this.siteName = properties.base_site_name;
      this.siteCode = properties.base_site_code;
      this.siteDesc = properties.base_site_description;

      // UP cd_hab nom_habitat id site
      this.storeService.setCurrentSite(properties.cd_hab, properties.nom_habitat, this.idSite);

      this.geojson.currentGeoJson$.subscribe(currentLayer => {
        this.mapService.map.fitBounds(currentLayer.getBounds());
      });
    }, error => {
      console.log("error: ", error)
    });
}
 

  onEachFeature(feature, layer) {
  }

  onEdit(id_visit) {
  }

  onInfo(id_visit) {
  }

  backToSites(){
    this._location.back();
  }
}