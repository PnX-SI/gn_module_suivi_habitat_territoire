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
  public idSite;
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

        visit.state = pres + 'P / ' + visit.nb_species + 'A ';
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
      this.geojson.currentGeoJson$.subscribe(currentLayer => {
        this.mapService.map.fitBounds(currentLayer.getBounds());
      });
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